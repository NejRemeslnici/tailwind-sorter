# frozen_string_literal: true

require "tailwind_sorter/config"
require "tailwind_sorter/string_sorter"
require "tailwind_sorter/file_sorter"

module TailwindSorter
    def sort_file(file, warn_only: false, config_file: Config::DEFAULT_CONFIG_FILE)
      TailwindSorter::FileSorter.new(warn_only:, config_file:).sort(file)
    end
  end
end
