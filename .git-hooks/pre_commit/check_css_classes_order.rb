module Overcommit::Hook::PreCommit
  class CheckCssClassesOrder < Base
    def run
      errors = []
      applicable_files.each do |file_path|
        errors += `bin/tailwind_sorter.rb -w #{file_path}`.split("\n")
      end

      return :fail, errors.join("\n") if errors.any?

      :pass
    end
  end
end
