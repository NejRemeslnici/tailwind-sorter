#!/usr/bin/env -S ruby --disable-gems

require "yaml"

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
# "custom-class"    "00,00,00,0000"
def sorting_key(css_class_with_variants, variants_order:, classes_order:, class_groups:, sort_order:, stdout:,
                default_index: 0)
  *variants, css_class = css_class_with_variants.split(":")
  key = [
    format("%02d", class_groups.index { |group| classes_order[group].include?(css_class) } || default_index),
    format("%02d", variants_order.index(variants[0]) || default_index),
    format("%02d", variants_order.index(variants[1]) || default_index),
    format("%04d", sort_order.index(css_class) || default_index)
  ].join(",")

  # stdout.puts "#{css_class_with_variants} #{key}"
  key
end

def sort_classes(file, regexps:, variants_order:, classes_order:, default_index: 0, warn_only: false)
  class_groups = classes_order.keys
  sort_order = classes_order.values.flatten

  # inplace file editing
  old_stdout = $stdout
  argf = ARGF.clone
  argf.argv.replace [file]
  argf.inplace_mode = ""

  calculate_sorting_key = lambda do |css_class_with_variants|
    sorting_key(css_class_with_variants,
                variants_order: variants_order,
                classes_order: classes_order,
                class_groups: class_groups,
                sort_order: sort_order,
                stdout: old_stdout,
                default_index: default_index)
  end

  argf.each_line do |line|
    line_number = argf.file.lineno

    regexps.each do |_regexp_name, regexp_config|
      regexp = regexp_config["regexp"]
      prefix = regexp_config["class_prefix"]
      split_by = "#{regexp_config['class_splitter']}#{prefix}"

      next unless (match = line.match(regexp))

      matched_classes = match["classes"]
      # old_stdout.puts "#{line_number}: #{matched_classes}"

      classes = matched_classes.split(split_by).map(&:strip).reject(&:empty?).uniq.map do |css_class_with_variants|
        sort_variants(css_class_with_variants, variants_order: variants_order)
      end

      sorted_classes = classes.sort_by { |css_class| calculate_sorting_key.call(css_class) }
      # old_stdout.puts sorted_classes.join('.')

      if warn_only
        orig_keys = classes.map { |css_class| calculate_sorting_key.call(css_class) }
        sorted_keys = sorted_classes.map { |css_class| calculate_sorting_key.call(css_class) }
        # old_stdout.puts orig_keys.inspect
        # old_stdout.puts sorted_keys.inspect
        if orig_keys != sorted_keys
          old_stdout.puts("#{file}:#{line_number}:CSS classes are not sorted properly. Please run 'bin/tailwind_sorter.rb #{file}'.")
        end
      else
        line.sub!(regexp, "\\k<before>#{prefix}#{sorted_classes.join(split_by)}")
      end
    end

    puts line
  end

  argf.close
  $stdout = old_stdout
end

config = YAML.load_file(File.join(__dir__, "../config/tailwind_sorter.yml"))

# is this run from Overcommit?
warn_only = false
if ARGV.first == "-w"
  warn_only = true
  ARGV.shift
end

file_name = ARGV.first
file_extension = File.extname(file_name)

regexps = config["regexps"].select { |_k, v| v["file_extension"] == file_extension }
regexps.each { |_k, v| v["regexp"] = Regexp.new(v["regexp"]) }

sort_classes(file_name, regexps: regexps,
                        classes_order: config["classes_order"],
                        variants_order: config["variants_order"],
                        warn_only: warn_only)
