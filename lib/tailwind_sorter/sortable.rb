# frozen_string_literal: true

module TailwindSorter
  module Sortable
    private

    # Returns the Tailwind classes array sorted according to the config file.
    def sort_classes_array(classes)
      classes = classes.map do |css_class_with_variants|
        sort_variants(css_class_with_variants)
      end

      classes.sort_by { |css_class| sorting_key_lambda.call(css_class) }
    end

    # Lambda for sorting the Tailwind CSS classes. It is memoized to avoid repeated class groups lookups.
    def sorting_key_lambda(default_index: 0)
      @sorting_key_lambda ||= begin
        class_groups = @config["classes_order"].keys
        ->(tw_class) { sorting_key(tw_class, class_groups:, default_index:) }
      end
    end

    # Reorders multiple variants, e.g.: "focus:sm:block" -> "sm:focus:block".
    def sort_variants(css_class_with_variants)
      *variants, css_class = css_class_with_variants.split(":")
      return css_class_with_variants if variants.length <= 1

      variants.sort_by! { |variant| @config["variants_order"].index(variant) }
      "#{variants.join(':')}:#{css_class}"
    end

    # Constructs the sorting key for sorting CSS classes in the following way:
    #
    # group_index, variant1_index, variant2_index, class_index
    # "sm:focus:flex" -> "01,01,11,0010"
    # "flex"          -> "01,00,00,0010"
    # "custom-class"  -> "00,00,00,0000"
    def sorting_key(css_class_with_variants, class_groups:, default_index: 0)
      return @sorting_keys_cache[css_class_with_variants] if @sorting_keys_cache[css_class_with_variants]

      *variants, css_class = css_class_with_variants.split(":")

      matching_index_in_group = nil
      matching_group = class_groups.find do |group|
        matching_index_in_group ||= @config["classes_order"][group].index { _1 === css_class }
      end

      key = [
        format("%02d", (matching_group && class_groups.index(matching_group)) || default_index),
        format("%02d", @config["variants_order"].index(variants[0]) || default_index),
        format("%02d", @config["variants_order"].index(variants[1]) || default_index),
        format("%04d", matching_index_in_group || default_index)
      ].join(",")

      @sorting_keys_cache[css_class_with_variants] = key
    end
  end
end
