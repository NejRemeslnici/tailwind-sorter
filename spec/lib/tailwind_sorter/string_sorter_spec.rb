# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "bundler"

require "tailwind_sorter"

RSpec.describe TailwindSorter::StringSorter do
  let(:config_file) { "spec/support/basic_config.yml" }

  def run_tailwind_sorter(content)
    TailwindSorter::StringSorter.new(config_file:).sort(content)
  end

  describe "class reordering with pure strings in the config" do
    it "does basic class reordering" do
      expect(run_tailwind_sorter("rounded my-4 block")).to eq("block my-4 rounded")
    end

    it "orders unknown classes first" do
      expect(run_tailwind_sorter("rounded my-4 block nr-class")).to eq("nr-class block my-4 rounded")
    end

    it "orders variants to the end of the same group" do
      expect(run_tailwind_sorter("sm:block block lg:my-4 my-8")).to eq("block sm:block my-8 lg:my-4")
    end

    it "orders multiple variants" do
      expect(run_tailwind_sorter("focus:hover:sm:block my-4")).to eq("sm:hover:focus:block my-4")
    end
  end

  describe "class reordering with regexps in classes_order config" do
    let(:config_file) { "spec/support/regexp_config.yml" }

    it "does basic class reordering" do
      expect(run_tailwind_sorter("rounded my-4 block")).to eq("block my-4 rounded")
    end

    it "orders unknown classes first" do
      expect(run_tailwind_sorter("rounded my-4 block nr-class")).to eq("nr-class block my-4 rounded")
    end

    it "orders variants to the end of the same group" do
      expect(run_tailwind_sorter("sm:block block lg:my-4 my-8")).to eq("block sm:block my-8 lg:my-4")
    end

    it "orders multiple variants" do
      expect(run_tailwind_sorter("focus:hover:sm:block my-4")).to eq("sm:hover:focus:block my-4")
    end
  end

  it "removes duplicate classes" do
    expect(run_tailwind_sorter("block my-4 block")).to eq("block my-4")
  end
end
