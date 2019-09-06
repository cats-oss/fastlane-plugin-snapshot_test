require_relative '../../helper/github_notifier'
require_relative '../../helper/helper'
require 'json'

module Fastlane
  module Actions
    class CompareSnapshotAction < Action
      def self.run(params)
        Helper.authenticate(params[:gcloud_service_key_file])

        UI.message "Copy screenshots to working directory"
        working_dir = params[:working_dir]
        screenshot_dir = params[:screenshot_dir]
        `mkdir #{working_dir}`
        `rm -rf #{working_dir}/actual`
        `mkdir #{working_dir}/actual`
        Action.sh "cp -pR #{screenshot_dir}/* #{working_dir}/actual"

        UI.message "Fetch previous snapshot"
        snapshot_bucket = params[:snapshot_bucket]
        previous_commit = Helper.find_base_commit_hash(snapshot_bucket, params[:base_branch], Helper.get_current_branch)
        if previous_commit == nil
          UI.message "Previous snapshot not found"
          return
        end
        UI.message "Previous Snapshot: #{previous_commit}"
        UI.message "Fetch images from gs://#{snapshot_bucket}/#{previous_commit}"
        `mkdir #{working_dir}/expected`
        Action.sh "gsutil -m rsync -d -r gs://#{snapshot_bucket}/#{previous_commit}/actual #{working_dir}/expected"

        UI.message "Compare snapshots"
        `rm -rf #{working_dir}/diff`
        `mkdir #{working_dir}/diff`
        result = Comparator.compare_dir("#{working_dir}/expected", "#{working_dir}/actual", "#{working_dir}/diff", params[:fuzz])
        open("#{working_dir}/result.json", "w") { |io| io.puts(JSON.pretty_generate(result)) }
        Action.sh "gsutil -m rsync -d -r #{working_dir} gs://#{snapshot_bucket}/#{Helper.get_current_commit_hash}"

        UI.message result
        UI.message "Notify to GitHub"
        notify_github(params, result)
      end

      def self.notify_github(params, result)
        return if params[:github_pr_number] == nil

        bucket = params[:snapshot_bucket]
        commit_hash = Helper.get_current_commit_hash

        message = <<-EOS
## Snapshot Test Result
Commit Hash: #{commit_hash}

#{summary_table(result[:new_items], result[:deleted_items], result[:changed_items], result[:passed_items])}

#{changed_items_table(result[:changed_items], bucket, commit_hash, params[:working_dir], params[:image_length])}

#{new_items_table(result[:new_items], bucket, commit_hash, params[:working_dir], params[:image_length])}

#{deleted_items_list(result[:deleted_items])}
        EOS

        GitHubNotifier.fold_comments(
            params[:github_owner],
            params[:github_repository],
            params[:github_pr_number],
            "## Snapshot Test Result",
            "Open past snapshot test result",
            params[:github_api_token]
        )
        GitHubNotifier.put_comment(
            params[:github_owner],
            params[:github_repository],
            params[:github_pr_number],
            message,
            params[:github_api_token]
        )
      end

      def self.summary_table(new_items, deleted_items, changed_items, passed_items)
        <<-EOS
### Summary
|  | Count |
| --- | --- |
| New Screenshots | #{new_items.size} |
| Deleted Screenshots | #{deleted_items.size} |
| Changed Screenshots | #{changed_items.size} |
| Passed Screenshots | #{passed_items.size} |
        EOS
      end

      def self.changed_items_table(changed_items, bucket, commit_hash, working_dir, image_height)
        return "" if changed_items.empty?

        header = "<tr><td></td><td>Before</td><td>After</td><td>Diff</td></tr>"
        cells = changed_items.map { |item|
          size_attr = generate_size_attr("#{working_dir}/actual/#{item}", image_height)

          before = "<img src=\"#{object_url(bucket, commit_hash, item, "expected")}\" #{size_attr} />"
          after = "<img src=\"#{object_url(bucket, commit_hash, item, "actual")}\" #{size_attr} />"
          diff = "<img src=\"#{object_url(bucket, commit_hash, item, "diff")}\" #{size_attr} />"
          "<tr><td>#{item}</td><td>#{before}</td><td>#{after}</td><td>#{diff}</td></tr>"
        }.inject(&:+)

        "### Changed Screenshots\n\n<table>#{header + cells}</table>"
      end

      def self.new_items_table(new_items, bucket, commit_hash, working_dir, image_height)
        return "" if new_items.empty?

        rows = new_items.each_slice(3).map { |oneline_items|
          labels = oneline_items.map { |item| "<td>#{item}</td>" }.inject(&:+)
          imgs = oneline_items.map { |item|
            size_attr = generate_size_attr("#{working_dir}/actual/#{item}", image_height)
            "<td><img src=\"#{object_url(bucket, commit_hash, item, "actual")}\" #{size_attr} /></td>"
          }.inject(&:+)
          "<tr>#{labels}</tr><tr>#{imgs}</tr>"
        }.inject(&:+)

        "### New Screenshots\n<details><summary>Open</summary>\n\n<table>#{rows}</table></details>\n"
      end

      def self.deleted_items_list(deleted_items)
        return "" if deleted_items.empty?

        "### Deleted Screenshots\n<details><summary>Open</summary>\n\n#{deleted_items.map { |item| "- #{item}\n" }.inject(&:+)}</details>\n"
      end

      def self.object_url(bucket, commit_hash, item_name, image_type)
        path = "#{commit_hash}/#{image_type}/#{item_name}"
        Helper.firebase_object_url(bucket, path)
      end

      def self.generate_size_attr(image_path, image_length)
        return "" if image_length == nil

        ratio = Helper.calc_aspect_ratio(image_path)
        is_portrait = ratio >= 1.0
        if is_portrait
          height = image_length
          width = height / ratio
          "height=\"#{height}px\" width=\"#{width}px\""
        else
          width = image_length * ratio
          height = width * ratio
          "height=\"#{height}px\" width=\"#{width}px\""
        end
      end

      def self.description
        "Compare snapshots"
      end

      def self.authors
        ["MoyuruAizawa"]
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :gcloud_service_key_file,
                                         env_name: "GCLOUD_SERVICE_KEY_FILE",
                                         description: "File path containing the gcloud auth key. Default: Created from GCLOUD_SERVICE_KEY environment variable",
                                         type: String,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :base_branch,
                                         env_name: "BASE_BRANCH",
                                         description: "Name of base branch",
                                         type: String,
                                         optional: true,
                                         default_value: "master"),
            FastlaneCore::ConfigItem.new(key: :snapshot_bucket,
                                         env_name: "SNAPSHOT_BUCKET",
                                         description: "GCS Bucket that stores expected images",
                                         type: String,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :fuzz,
                                         env_name: "FUZZ",
                                         description: "Colors within this distance are considered equal",
                                         is_string: true,
                                         optional: false,
                                         default_value: "5%"),
            FastlaneCore::ConfigItem.new(key: :working_dir,
                                         env_name: "WORKING_DIR",
                                         description: "Working directory",
                                         type: String,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :screenshot_dir,
                                         env_name: "SCREENSHOT_DIR",
                                         description: "Working directory",
                                         type: String,
                                         optional: false),
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
                                         optional: true),
            FastlaneCore::ConfigItem.new(key: :github_api_token,
                                         env_name: "GITHUB_API_TOKEN",
                                         description: "GitHub API Token",
                                         type: String,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :image_length,
                                         env_name: "IMAGE_LENGTH",
                                         description: "Length px of the log side of screenshots",
                                         is_string: false,
                                         optional: true)
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
