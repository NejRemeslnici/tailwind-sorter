# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "bundler"

RSpec.describe "tailwind_sorter integration tests" do # rubocop:disable RSpec/DescribeClass
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

      Bundler.with_unbundled_env do
        system("exe/tailwind_sorter", "-c", config_file, file)
      end

      file_content
    end

    def file_content(file: test_file)
      File.read(file).strip
    end

    it "does basic class reordering" do
      expect(run_tailwind_sorter(".rounded.my-4.block")).to eq(".block.my-4.rounded")
    end
  end

  context "when only checking the classes" do
    def run_tailwind_sorter_in_warning_mode(content, file: test_file)
      File.open(file, "w") do |f|
        f.print(content)
      end

      Bundler.with_unbundled_env do
        system("exe/tailwind_sorter", "-w", "-c", config_file, file)
      end
    end

    it "prints an error when css classes order is not proper" do
      expect { run_tailwind_sorter_in_warning_mode(".rounded.my-4.block") }.to(
        output(/^#{test_file}:1:CSS classes are not sorted well/).to_stdout_from_any_process
      )
    end
  end

  context "when multiple files are given" do
    let(:file1) { "tmp/tailwind_sorter_test1.slim" }
    let(:file2) { "tmp/tailwind_sorter_test2.slim" }

    after do
      FileUtils.rm_f(file1)
      FileUtils.rm_f(file2)
    end

    it "sorts classes in all files" do
      File.open(file1, "w") { _1.print(".rounded.my-4.block") }
      File.open(file2, "w") { _1.print(".my-8.rounded.fixed") }

      Bundler.with_unbundled_env do
        system("exe/tailwind_sorter", "-c", config_file, file1, file2)
      end

      expect(File.read(file1).strip).to eq(".block.my-4.rounded")
      expect(File.read(file2).strip).to eq(".fixed.my-8.rounded")
    end
  end
end
