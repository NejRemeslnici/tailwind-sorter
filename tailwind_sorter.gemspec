# frozen_string_literal: true

require_relative "lib/tailwind_sorter/version"

Gem::Specification.new do |spec|
  spec.name = "tailwind-sorter"
  spec.version = TailwindSorter::VERSION
  spec.authors = ["NejŘemeslníci.cz"]
  spec.email = ["support@nejremeslnici.cz"]

  spec.summary = "Customizable TailwindCSS classes sorter"
  spec.description = "Simple but customizable sorter for TailwindCSS classes"
  spec.homepage = "https://github.com/NejRemeslnici/tailwind-sorter"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://github.com"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/NejRemeslnici/tailwind-sorter"
  spec.metadata["changelog_uri"] = "https://github.com/NejRemeslnici/tailwind-sorter"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{exe,lib}/**/*", "Rakefile", "README.md"]
  end

  spec.bindir = "exe"
  spec.executables << "tailwind_sorter"
  spec.require_paths = ["lib"]
end
