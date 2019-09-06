require "json"

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Comparator
    def self.compare(expected_file, actual_file, diff_path, fuzz)
      UI.message "compare #{actual_file} and #{expected_file}"
      system("compare -metric AE -fuzz #{fuzz} #{actual_file.shellescape} #{expected_file.shellescape} #{diff_path.shellescape}")
    end

    def self.compare_dir(expected_dir, actual_dir, diff_dir, fuzz)
      UI.message "Compare #{expected_dir} and #{actual_dir}"
      expect_items = Dir.glob("#{expected_dir}/*.jpg").map { |path| File.basename(path) }
      actual_items = Dir.glob("#{actual_dir}/*.jpg").map { |path| File.basename(path) }

      new_items = actual_items - expect_items
      deleted_items = expect_items - actual_items
      passed_items = []
      changed_items = []

      (actual_items & expect_items).each { |fileName|
        is_passed = compare("#{actual_dir}/#{fileName}", "#{expected_dir}/#{fileName}", "#{diff_dir}/#{fileName}", fuzz)
        if is_passed
          passed_items << fileName
        else
          changed_items << fileName
        end
      }

      {
          :passed_items => passed_items,
          :changed_items => changed_items,
          :new_items => new_items,
          :deleted_items => deleted_items
      }
    end
  end
end