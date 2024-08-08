# frozen_string_literal: true

require "tempfile"
require "yaml"
require "tailwind_sorter/config"

module TailwindSorter
  # Sorts Tailwind CSS classes in a file on lines matched by the configured "regexp" patterns.
  class FileSorter
    def initialize(warn_only: false, config_file: Config::DEFAULT_CONFIG_FILE)
      unless config_file && File.exist?(config_file)
        raise ArgumentError, "Configuration file '#{config_file}' does not exist"
      end

      @warn_only = warn_only
      @config = YAML.load_file(config_file)
      @sorting_keys_cache = {}
    end

    def sort(file_name)
      raise ArgumentError, "File '#{file_name}' does not exist" unless file_name && File.exist?(file_name)

      sort_classes(file_name)
    end

    private

    def sort_classes(file, default_index: 0)
      file_extension = File.extname(file)
      line_regexps = @config["regexps"].select { |_k, v| v["file_extension"] == file_extension }
      line_regexps.each_value { |v| v["regexp"] = Regexp.new(v["regexp"]) }

      classes_order = @config["classes_order"]
      variants_order = @config["variants_order"]

      convert_class_order_regexps!(classes_order)
      class_groups = classes_order.keys
      warnings = []

      infile = File.open(file)
      outfile = Tempfile.create("#{File.basename(file)}.sorted")

      calculate_sorting_key = lambda do |css_class_with_variants|
        sorting_key(css_class_with_variants, variants_order:, classes_order:, class_groups:, default_index:)
      end

      changed = false
      infile.each_line do |line|
        line_number = infile.lineno

        line_regexps.each do |_regexp_name, regexp_config|
          regexp = regexp_config["regexp"]
          prefix = regexp_config["class_prefix"]
          split_by = "#{regexp_config['class_splitter']}#{prefix}"

          next unless (match = line.match(regexp))

          matched_classes = match["classes"]
          # puts "#{line_number}: #{matched_classes}"

          classes = matched_classes.split(split_by).map(&:strip).reject(&:empty?).uniq.map do |css_class_with_variants|
            sort_variants(css_class_with_variants, variants_order:)
          end

          sorted_classes = classes.sort_by { |css_class| calculate_sorting_key.call(css_class) }
          # puts sorted_classes.join('.')

          if @warn_only
            orig_keys = classes.map { |css_class| calculate_sorting_key.call(css_class) }
            sorted_keys = sorted_classes.map { |css_class| calculate_sorting_key.call(css_class) }
            # puts orig_keys.inspect
            # puts sorted_keys.inspect
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

    # reorders multiple variants, e.g.: "focus:sm:block" -> "sm:focus:block"
    def sort_variants(css_class_with_variants, variants_order:)
      *variants, css_class = css_class_with_variants.split(":")
      return css_class_with_variants if variants.length <= 1

      variants.sort_by! { |variant| variants_order.index(variant) }
      "#{variants.join(':')}:#{css_class}"
    end

    # Constructs the sorting key for sorting CSS classes in the following way:
    #
    # group_index, variant1_index, variant2_index, class_index
    # "sm:focus:flex" -> "01,01,11,0010"
    # "flex"          -> "01,00,00,0010"
    # "custom-class"  -> "00,00,00,0000"
    def sorting_key(css_class_with_variants, variants_order:, classes_order:, class_groups:, default_index: 0)
      return @sorting_keys_cache[css_class_with_variants] if @sorting_keys_cache[css_class_with_variants]

      *variants, css_class = css_class_with_variants.split(":")

      matching_index_in_group = nil
      matching_group = class_groups.find do |group|
        matching_index_in_group ||= classes_order[group].index { _1 === css_class }
      end

      key = [
        format("%02d", (matching_group && class_groups.index(matching_group)) || default_index),
        format("%02d", variants_order.index(variants[0]) || default_index),
        format("%02d", variants_order.index(variants[1]) || default_index),
        format("%04d", matching_index_in_group || default_index)
      ].join(",")

      # puts "#{css_class_with_variants} #{key}"
      @sorting_keys_cache[css_class_with_variants] = key
    end

    def convert_class_order_regexps!(classes_order)
      classes_order.each do |group, class_patterns|
        class_patterns.map! do |class_or_pattern|
          if (patterns = class_or_pattern.match(%r{\A/(.*)/\z}).to_a).empty?
            class_or_pattern
          else
            /\A#{patterns.last}\z/
          end
        end
      end

      classes_order
    end
  end
end
