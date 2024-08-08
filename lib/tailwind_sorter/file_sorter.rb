# frozen_string_literal: true

require "tempfile"
require "yaml"

require "tailwind_sorter/config"
require "tailwind_sorter/sortable"

module TailwindSorter
  class FileSorter
    include Sortable

    def initialize(warn_only: false, config_file: Config::DEFAULT_CONFIG_FILE)
      @warn_only = warn_only
      @config = Config.new(config_file).load

      @sorting_keys_cache = {}
    end

    def sort(file_name)
      raise ArgumentError, "File '#{file_name}' does not exist" unless file_name && File.exist?(file_name)

      sort_classes(file_name)
    end

    private

    def sort_classes(file)
      warnings = []

      infile = File.open(file)
      outfile = Tempfile.create("#{File.basename(file)}.sorted")
      changed = false

      infile.each_line do |line|
        line_number = infile.lineno

        line_regexps_for(file).each_value do |regexp_config|
          regexp = regexp_config["regexp"]
          prefix = regexp_config["class_prefix"]
          split_by = "#{regexp_config['class_splitter']}#{prefix}"

          next unless (match = line.match(regexp))

          classes = match["classes"]
          classes = classes.split(split_by).map(&:strip).reject(&:empty?).uniq
          sorted_classes = sort_classes_array(classes)

          if @warn_only
            orig_keys = classes.map { |css_class| sorting_key_lambda.call(css_class) }
            sorted_keys = sorted_classes.map { |css_class| sorting_key_lambda.call(css_class) }

            if orig_keys != sorted_keys
              warning = "#{file}:#{line_number}:CSS classes are not sorted well. Please run 'tailwind_sorter #{file}'."
              warnings << warning
              puts(warning)
            end
          else
            orig_line = line.dup unless changed
            line.sub!(regexp, "\\k<before>#{prefix}#{sorted_classes.join(split_by)}")
            changed = true if !changed && line != orig_line
          end
        end

        outfile.puts line
      end

      success = true

      warnings
    rescue StandardError => e
      warn "An error occurred: #{e}"
      success = false
    ensure
      infile.close
      outfile.close

      success && changed ? FileUtils.mv(outfile, file) : File.unlink(outfile)
    end

    def line_regexps_for(file)
      line_regexps = @config["regexps"].select { |_k, v| v["file_extension"] == File.extname(file) }
      line_regexps.each_value { |v| v["regexp"] = Regexp.new(v["regexp"]) }
      line_regexps
    end
  end
end
