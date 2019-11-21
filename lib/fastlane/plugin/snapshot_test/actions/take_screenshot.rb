require 'fastlane/action'

module Fastlane
  module Actions
    class TakeScreenshotAction < Action
      def self.run(params)
        download_dir = params[:download_dir]

        results_bucket = params[:firebase_test_lab_results_bucket] ? "#{params[:project_id]}_test_results" : params[:firebase_test_lab_results_bucket]
        results_dir = "firebase_screenshot_#{DateTime.now.strftime('%Y-%m-%d-%H:%M:%S')}"
        devices = params[:devices]
        Fastlane::Actions::FirebaseTestLabAndroidAction.run(
          project_id: params[:project_id],
          gcloud_service_key_file: params[:gcloud_service_key_file],
          type: "instrumentation",
          devices: devices,
          app_apk: params[:app_apk],
          app_test_apk: params[:app_test_apk],
          console_log_file_name: "#{download_dir}/firebase_os_test_console.log",
          timeout: params[:timeout],
          firebase_test_lab_results_bucket: results_bucket,
          firebase_test_lab_results_dir: results_dir,
          extra_options: "--no-record-video"
        )

        UI.message("Fetch screenshots from Firebase Test Lab results bucket")
        device_names = devices.map(&method(:device_name))
        device_names.each do |device_name|
          `mkdir -p #{download_dir}/#{device_name}`
          Action.sh("gsutil -m rsync -d -r gs://#{results_bucket}/#{results_dir}/#{device_name}/artifacts #{download_dir}/#{device_name}")
          `rm -rf #{download_dir}/#{device_name}/sdcard`

          entries = Dir.entries("#{download_dir}/#{device_name}").select { |entry| entry =~ /^.*\.(jpg|jpeg|png)/ }
          for entry in entries do
            filePath = "#{download_dir}/#{device_name}/#{entry}"
            Action.sh("convert #{filePath} -scale 320x #{filePath}")
          end
        end
      end

      def self.device_name(device)
        "#{device[:model]}-#{device[:version]}-#{device[:locale]}-#{device[:orientation]}"
      end

      def self.description
        "Take screenshots"
      end

      def self.details
        "Take screenshots"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :project_id,
                                       env_name: "PROJECT_ID",
                                       description: "Your Firebase project id",
                                       type: String,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :gcloud_service_key_file,
                                       env_name: "GCLOUD_SERVICE_KEY_FILE",
                                       description: "File path containing the gcloud auth key. Default: Created from GCLOUD_SERVICE_KEY environment variable",
                                       type: String,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :devices,
                                       env_name: "DEVICES",
                                       description: "Devices to test the app on",
                                       type: Array,
                                       verify_block: proc do |value|
                                         UI.user_error!("Devices have to be at least one") if value.empty?
                                         value.each do |device|
                                           check_has_property(device, :model)
                                           check_has_property(device, :version)
                                           set_default_property(device, :locale, "en_US")
                                           set_default_property(device, :orientation, "portrait")
                                         end
                                       end),
          FastlaneCore::ConfigItem.new(key: :timeout,
                                       env_name: "TIMEOUT",
                                       description: "The max time this test execution can run before it is cancelled. Default: 5m (this value must be greater than or equal to 1m)",
                                       type: String,
                                       optional: true,
                                       default_value: "5m"),
          FastlaneCore::ConfigItem.new(key: :app_apk,
                                       env_name: "APP_APK",
                                       description: "The path for your android app apk",
                                       type: String,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :app_test_apk,
                                       env_name: "APP_TEST_APK",
                                       description: "The path for your android test apk. Default: empty string",
                                       type: String,
                                       optional: true,
                                       default_value: nil),
          FastlaneCore::ConfigItem.new(key: :firebase_test_lab_results_bucket,
                                       env_name: "FIREBASE_TEST_LAB_RESULTS_BUCKET",
                                       description: "Name of Firebase Test Lab results bucket",
                                       type: String,
                                       optional: true,
                                       default_value: nil),
          FastlaneCore::ConfigItem.new(key: :download_dir,
                                       env_name: "DOWNLOAD_DIR",
                                       description: "Target directory to download screenshots from firebase",
                                       type: String,
                                       optional: false)
        ]
      end

      def self.authors
        ["MoyuruAizawa"]
      end

      def self.is_supported?(platform)
        platform == :android
      end

      def self.check_has_property(hash_obj, property)
        UI.user_error!("Each device must have #{property} property") unless hash_obj.key?(property)
      end

      def self.set_default_property(hash_obj, property, default)
        unless hash_obj.key?(property)
          hash_obj[property] = default
        end
      end

      def self.example_code
        ['take_screenshot(
            project_id: "cats-firebase",
            gcloud_service_key_file: "fastlane/client-secret.json",
            devices: [
              {
                  model: "shamu",
                  version: "22",
                  locale: "ja_JP",
                  orientation: "portrait"
              },
              {
                  model: "Pixel2",
                  version: "28"
              }
            ],
            app_apk: "tools/app-snapshot-debug.apk",
            app_test_apk: "app/build/outputs/apk/androidTest/snapshot/debug/installedapp-snapshot-debug-androidTest.apk",
            firebase_test_lab_results_bucket: "cats-android-firebase-instrumented-test",
            timeout: "10m",
            download_dir: ".screenshot"
        )']
      end
    end
  end
end
