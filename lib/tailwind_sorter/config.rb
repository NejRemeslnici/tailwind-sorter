# frozen_string_literal: true

module TailwindSorter
  class Config
    DEFAULT_CONFIG_FILE = "config/tailwind_sorter.yml"

    def initialize(config_file = DEFAULT_CONFIG_FILE)
      unless config_file && File.exist?(config_file)
        raise ArgumentError, "Configuration file '#{config_file}' does not exist"
      end

      @config_file = config_file
    end

    def load
      @config = YAML.load_file(@config_file)
      convert_class_order_regexps!
      @config
    end

    private

    def convert_class_order_regexps!
      @config["classes_order"].each_value do |class_patterns|
        class_patterns.map! do |class_or_pattern|
          if (patterns = class_or_pattern.match(%r{\A/(.*)/\z}).to_a).empty?
            class_or_pattern
          else
            /\A#{patterns.last}\z/
          end
        end
      end
    end
  end
end
