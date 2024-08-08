# frozen_string_literal: true

require "tailwind_sorter"

RSpec.describe TailwindSorter do
  describe ".sort" do
    it "calls StringSorter with default config" do
      string_sorter_double = instance_double(TailwindSorter::StringSorter, sort: "sorted classes")
      allow(TailwindSorter::StringSorter).to receive(:new).with(config_file: TailwindSorter::Config::DEFAULT_CONFIG_FILE)
                                                          .and_return(string_sorter_double)

      TailwindSorter.sort("unsorted classes")

      expect(TailwindSorter::StringSorter).to have_received(:new).once
      expect(string_sorter_double).to have_received(:sort).with("unsorted classes")
    end

    it "calls StringSorter with custom config" do
      string_sorter_double = instance_double(TailwindSorter::StringSorter, sort: "sorted classes")
      allow(TailwindSorter::StringSorter).to receive(:new).with(config_file: "custom_config.yml")
                                                          .and_return(string_sorter_double)

      TailwindSorter.sort("unsorted classes", config_file: "custom_config.yml")

      expect(TailwindSorter::StringSorter).to have_received(:new).once
      expect(string_sorter_double).to have_received(:sort).with("unsorted classes")
    end
  end

  describe ".sort_file" do
    it "calls FileSorter with default config" do
      file_sorter_double = instance_double(TailwindSorter::FileSorter, sort: "sorted.classes")
      allow(TailwindSorter::FileSorter).to receive(:new).with(config_file: TailwindSorter::Config::DEFAULT_CONFIG_FILE,
                                                              warn_only: false)
                                                        .and_return(file_sorter_double)

      TailwindSorter.sort_file("test_file")

      expect(TailwindSorter::FileSorter).to have_received(:new).once
      expect(file_sorter_double).to have_received(:sort).with("test_file")
    end

    it "calls FileSorter with custom config" do
      file_sorter_double = instance_double(TailwindSorter::FileSorter, sort: "sorted.classes")
      allow(TailwindSorter::FileSorter).to receive(:new).with(config_file: "custom_config.yml", warn_only: false)
                                                        .and_return(file_sorter_double)

      TailwindSorter.sort_file("test_file", config_file: "custom_config.yml")

      expect(TailwindSorter::FileSorter).to have_received(:new).once
      expect(file_sorter_double).to have_received(:sort).with("test_file")
    end

    it "calls FileSorter in warn_only mode" do
      file_sorter_double = instance_double(TailwindSorter::FileSorter, sort: "sorted.classes")
      allow(TailwindSorter::FileSorter).to receive(:new).with(config_file: TailwindSorter::Config::DEFAULT_CONFIG_FILE,
                                                              warn_only: true)
                                                        .and_return(file_sorter_double)

      TailwindSorter.sort_file("test_file", warn_only: true)

      expect(TailwindSorter::FileSorter).to have_received(:new).once
      expect(file_sorter_double).to have_received(:sort).with("test_file")
    end
  end
end
