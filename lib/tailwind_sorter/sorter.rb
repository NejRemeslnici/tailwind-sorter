require "tempfile"
require "yaml"

module TailwindSorter
  class Sorter
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
    # "sm:focus:flex"   "01,01,11,0010"
    # "flex"            "01,00,00,0010"
    # "nr-custom-class" "00,00,00,0000"
    def sorting_key(css_class_with_variants, variants_order:, classes_order:, class_groups:, sort_order:, default_index: 0)
      *variants, css_class = css_class_with_variants.split(":")
      key = [
        format("%02d", class_groups.index { |group| classes_order[group].include?(css_class) } || default_index),
        format("%02d", variants_order.index(variants[0]) || default_index),
        format("%02d", variants_order.index(variants[1]) || default_index),
        format("%04d", sort_order.index(css_class) || default_index)
      ].join(",")

      # puts "#{css_class_with_variants} #{key}"
      key
    end

    def sort_classes(file, regexps:, variants_order:, classes_order:, default_index: 0, warn_only: false)
      class_groups = classes_order.keys
      sort_order = classes_order.values.flatten

      infile = File.open(file)
      outfile = Tempfile.create("#{File.basename(file)}.sorted")

      calculate_sorting_key = lambda do |css_class_with_variants|
        sorting_key(css_class_with_variants, variants_order:, classes_order:, class_groups:, sort_order:, default_index:)
      end

      changed = false
      infile.each_line do |line|
        line_number = infile.lineno

        regexps.each do |_regexp_name, regexp_config|
          regexp = regexp_config["regexp"]
          prefix = regexp_config["class_prefix"]
          split_by = "#{regexp_config['class_splitter']}#{prefix}"

          next unless (match = line.match(regexp))

          matched_classes = match["classes"]
          # puts "#{line_number}: #{matched_classes}"

          classes = matched_classes.split(split_by).map(&:strip).reject(&:empty?).uniq.map do |css_class_with_variants|
            sort_variants(css_class_with_variants, variants_order: variants_order)
          end

          sorted_classes = classes.sort_by { |css_class| calculate_sorting_key.call(css_class) }
          # puts sorted_classes.join('.')

          if warn_only
            orig_keys = classes.map { |css_class| calculate_sorting_key.call(css_class) }
            sorted_keys = sorted_classes.map { |css_class| calculate_sorting_key.call(css_class) }
            # puts orig_keys.inspect
            # puts sorted_keys.inspect
            if orig_keys != sorted_keys
              puts("#{file}:#{line_number}:CSS classes are not sorted well. Please run 'tailwind_sorter #{file}'.")
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

    rescue StandardError
      success = false

    ensure
      infile.close
      outfile.close

      success && changed ? FileUtils.mv(outfile, file) : File.unlink(outfile)
    end

    def sort(file_name, warn_only: false, config_file: "config/tailwind_sorter.yml")
      raise ArgumentError, "File '#{file_name}' does not exist" unless file_name && File.exist?(file_name)
      raise ArgumentError, "Configuration file '#{config_file}' does not exist" unless config_file && File.exist?(config_file)

      config = YAML.load_file(config_file)
      file_extension = File.extname(file_name)

      regexps = config["regexps"].select { |_k, v| v["file_extension"] == file_extension }
      regexps.each { |_k, v| v["regexp"] = Regexp.new(v["regexp"]) }

      sort_classes(file_name, regexps:,
                              classes_order: config["classes_order"],
                              variants_order: config["variants_order"],
                              warn_only:)
    end

    def self.sort(...)
      new.sort(...)
    end
  end
end