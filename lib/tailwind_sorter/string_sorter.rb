# frozen_string_literal: true

require "yaml"

require "tailwind_sorter/config"
require "tailwind_sorter/sortable"

module TailwindSorter
  class StringSorter
    include Sortable

    def initialize(config_file: Config::DEFAULT_CONFIG_FILE)
      @config = Config.new(config_file).load
      @sorting_keys_cache = {}
    end

    def sort(classes_string)
      sort_classes_array(classes_string.split.map(&:strip).reject(&:empty?).uniq).join(" ")
    end
  end
end
