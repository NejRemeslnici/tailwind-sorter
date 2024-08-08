# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "bundler"

require "tailwind_sorter"

RSpec.describe TailwindSorter::FileSorter do
  let(:test_file) { "tmp/tailwind_sorter_test.slim" }
  let(:config_file) { "spec/support/basic_config.yml" }

  after do
    FileUtils.rm_f(test_file)
  end

  context "when rewriting Slim input file" do
    def run_tailwind_sorter(content, file: test_file)
      File.open(file, "w") do |f|
        f.print(content)
      end

      TailwindSorter::FileSorter.new(config_file:).sort(file)

      file_content
    end

    def file_content(file: test_file)
      File.read(file).strip
    end

    context "with regexp 'slim_html'" do
      describe "class reordering with pure strings" do
        it "does basic class reordering" do
          expect(run_tailwind_sorter(".rounded.my-4.block")).to eq(".block.my-4.rounded")
        end

        it "orders unknown classes first" do
          expect(run_tailwind_sorter(".rounded.my-4.block.nr-class")).to eq(".nr-class.block.my-4.rounded")
        end

        it "orders variants to the end of the same group" do
          expect(run_tailwind_sorter(".sm:block.block.lg:my-4.my-8")).to eq(".block.sm:block.my-8.lg:my-4")
        end

        it "orders multiple variants" do
          expect(run_tailwind_sorter(".focus:hover:sm:block.my-4")).to eq(".sm:hover:focus:block.my-4")
        end
      end

      describe "class reordering with regexps in classes_order config" do
        let(:config_file) { "spec/support/regexp_config.yml" }

        it "does basic class reordering" do
          expect(run_tailwind_sorter(".rounded.my-4.block")).to eq(".block.my-4.rounded")
        end

        it "orders unknown classes first" do
          expect(run_tailwind_sorter(".rounded.my-4.block.nr-class")).to eq(".nr-class.block.my-4.rounded")
        end

        it "orders variants to the end of the same group" do
          expect(run_tailwind_sorter(".sm:block.block.lg:my-4.my-8")).to eq(".block.sm:block.my-8.lg:my-4")
        end

        it "orders multiple variants" do
          expect(run_tailwind_sorter(".focus:hover:sm:block.my-4")).to eq(".sm:hover:focus:block.my-4")
        end
      end

      it "removes duplicate classes" do
        expect(run_tailwind_sorter(".block.my-4.block")).to eq(".block.my-4")
      end

      it "reorders classes up to equal sign (inline ruby)" do
        expect(run_tailwind_sorter(".my-4.block = link_to(...)")).to eq(".block.my-4 = link_to(...)")
      end

      it "ignores lines in that appear to be CSS" do
        expect(run_tailwind_sorter(".my-4.block {")).to eq(".my-4.block {")
      end

      it "ignores lines in that appear to be JS function call" do
        expect(run_tailwind_sorter("something.block.element.hide()")).to eq("something.block.element.hide()")
      end

      it "ignores lines in that appear to be JS line" do
        expect(run_tailwind_sorter("something.block.element;")).to eq("something.block.element;")
      end
    end

    context "with regexp 'ruby_class_attribute'" do
      it "does basic class reordering" do
        expect(run_tailwind_sorter('class: "rounded my-4 block"')).to eq('class: "block my-4 rounded"')
      end

      it "reorders classes only before interpolation" do
        expect(run_tailwind_sorter('class: "rounded my-4 block #{...} mx-8"')).to(
          eq('class: "block my-4 rounded #{...} mx-8"')
        )
      end
    end
  end

  context "when only checking the classes" do
    def run_tailwind_sorter_in_warning_mode(content, file: test_file)
      File.open(file, "w") do |f|
        f.print(content)
      end

      TailwindSorter::FileSorter.new(config_file:, warn_only: true).sort(file)
    end

    it "prints nothing when css classes order is proper" do
      expect { run_tailwind_sorter_in_warning_mode(".block.my-4.rounded") }.not_to output.to_stdout_from_any_process
    end

    it "prints an error when css classes order is not proper" do
      expect { run_tailwind_sorter_in_warning_mode(".rounded.my-4.block") }.to(
        output(/^#{test_file}:1:CSS classes are not sorted well/).to_stdout_from_any_process
      )
    end
  end
end
