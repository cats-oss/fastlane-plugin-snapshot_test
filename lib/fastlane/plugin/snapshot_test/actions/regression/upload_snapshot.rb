require 'fastlane/action'

require_relative '../../helper/helper'

module Fastlane
  module Actions
    class UploadSnapshotAction < Action
      def self.run(params)
        Helper.authenticate(params[:gcloud_service_key_file])

        UI.message "Copy screenshots to working directory"
        working_dir = params[:working_dir]
        screenshot_dir = params[:screenshot_dir]
        `mkdir #{working_dir}`
        `rm -rf #{working_dir}/actual`
        `mkdir #{working_dir}/actual`
        Action.sh "cp -pR #{screenshot_dir}/* #{working_dir}/actual"
        Action.sh "gsutil -m rsync -d -r #{working_dir} gs://#{params[:snapshot_bucket]}/#{Helper.get_current_commit_hash}"
      end

      def self.description
        "Upload Snapshot"
      end

      def self.details
        "Upload Snapshot"
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :gcloud_service_key_file,
                                         env_name: "GCLOUD_SERVICE_KEY_FILE",
                                         description: "File path containing the gcloud auth key. Default: Created from GCLOUD_SERVICE_KEY environment variable",
                                         type: String,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :snapshot_bucket,
                                         env_name: "SNAPSHOT_BUCKET",
                                         description: "GCS Bucket that stores expected images",
                                         type: String,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :working_dir,
                                         env_name: "WORKING_DIR",
                                         description: "Working directory",
                                         type: String,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :screenshot_dir,
                                         env_name: "SCREENSHOT_DIR",
                                         description: "Working directory",
                                         type: String,
                                         optional: false)
        ]
      end

      def self.authors
        ["MoyuruAizawa"]
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        ['upload_snapshot(
            gcloud_service_key_file: "fastlane/client-secret.json",
            snapshot_bucket: "cats-android-snapshot",
            working_dir: ".snapshot_test",
            screenshot_dir: ".screenshot/shamu-22-ja_JP-portrait"
        )']
      end

    end
  end
end
