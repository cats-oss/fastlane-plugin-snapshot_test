require 'fastlane/action'
require_relative '../helper/screenshot_notifier_helper'

module Fastlane
  module Actions
    class ScreenshotNotifierAction < Action
      def self.run(params)
        Helper.authenticate(params[:gcloud_service_key_file])
        commit_hash = Helper.get_current_commit_hash

        UI.message "Upload screenshots to cloud storage"
        Action.sh "gsutil -m rsync -d -r #{params[:screenshot_dir]} gs://#{params[:screenshot_bucket]}/#{commit_hash}"

        UI.message "Delete previous PR comments"
        GitHubNotifier.delete_comments(
            params[:github_owner],
            params[:github_repository],
            params[:github_pr_number],
            "## Screenshots of each devices",
            params[:github_api_token]
        )

        UI.message "Post screenshots as PR comments"
        screenshot_dir = params[:screenshot_dir]
        devices = Dir.chdir("#{screenshot_dir}") do
          Dir.glob("*").select { |path| FileTest.directory? path }.sort
        end
        if devices.empty?
          UI.message("That screenshot dir is empty")
          return
        end

        header = "<tr><td>Screen Name</td>\n#{devices.map { |device| "<td>#{device}</td>\n" }.inject(&:+)}</tr>"
        rows = Dir.glob("#{screenshot_dir}/#{devices[0]}/*.jpg")
                   .map { |path| File.basename(path) }
                   .map { |file_name|
                     cells = devices.map { |device|
                       file_path = "#{screenshot_dir}/#{device}/#{file_name}"
                       next "<td></td>" unless File.exist?(file_path)
                       ratio = Helper.calc_aspect_ratio(file_path)
                       is_portrait = ratio >= 1.0
                       size_attr = if params[:image_length] != nil
                                     if is_portrait
                                       height = params[:image_length]
                                       width = height / ratio
                                       "height=\"#{height}px\" width=\"#{width}px\""
                                     else
                                       width = params[:image_length] * ratio
                                       height = width * ratio
                                       "height=\"#{height}px\" width=\"#{width}px\""
                                     end
                                   else
                                     ""
                                   end

                       url = object_url(params[:screenshot_bucket], "#{commit_hash}/#{device}/#{file_name}")
                       "<td><img src=\"#{url}\" #{size_attr}/></td>\n"
                     }.inject(&:+)
                     "<tr><td>#{file_name}</td>\n#{cells}</tr>\n"
                   }.inject(&:+)

        table = "<table>#{header}#{rows}</table>"
        comment = if params[:fold_result]
                    "## Screenshots of each devices\n\n"\
                    "<details>"\
                    "<summary>Open</summary>"\
                    "#{table}"\
                    "</details>"
                  else
                    "## Screenshots of each devices\n\n"\
                    "#{table}"
                  end
        UI.message comment
        GitHubNotifier.put_comment(
            params[:github_owner],
            params[:github_repository],
            params[:github_pr_number],
            comment,
            params[:github_api_token]
        )
      end

      def self.object_url(bucket, path)
        Helper.firebase_object_url(bucket, path)
      end

      def self.description
        "Post Screenshots to Pull Request"
      end

      def self.details
        "Post Screenshots to Pull Request"
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :gcloud_service_key_file,
                                         env_name: "GCLOUD_SERVICE_KEY_FILE",
                                         description: "File path containing the gcloud auth key. Default: Created from GCLOUD_SERVICE_KEY environment variable",
                                         type: String,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :screenshot_bucket,
                                         env_name: "SCREENSHOT_BUCKET",
                                         description: "Bucket name to store screenshots",
                                         type: String,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :screenshot_dir,
                                         env_name: "SCREENSHOT_DIR",
                                         description: "Directory that has screenshots",
                                         type: String,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :fold_result,
                                         env_name: "FOLD_RESULT",
                                         description: "Fold screenshots table",
                                         type: Boolean,
                                         optional: false,
                                         default_value: false),
            FastlaneCore::ConfigItem.new(key: :github_owner,
                                         env_name: "GITHUB_OWNER",
                                         description: "Owner name",
                                         type: String,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :github_repository,
                                         env_name: "GITHUB_REPOSITORY",
                                         description: "Repository name",
                                         type: String,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :github_pr_number,
                                         env_name: "GITHUB_PR_NUMBER",
                                         description: "Pull request number",
                                         type: String,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :github_api_token,
                                         env_name: "GITHUB_API_TOKEN",
                                         description: "GitHub API Token",
                                         type: String,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :image_length,
                                         env_name: "IMAGE_LENGTH",
                                         description: "Length px of the long side of screenshots",
                                         is_string: false,
                                         optional: true)
        ]
      end

      def self.output
        # Define the shared values you are going to provide
        # Example
        []
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.authors
        ["MoyuruAizawa"]
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end