require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    def self.authenticate(gcloud_key_file)
      UI.message "Authenticate with GCP"
      Action.sh("gcloud auth activate-service-account --key-file #{gcloud_key_file}")
    end

    def self.get_current_commit_hash
      Action.sh("git rev-parse HEAD").chomp!
    end

    def self.get_current_branch
      Action.sh("git symbolic-ref --short HEAD").chomp!
    end

    def self.find_base_commit_hash(bucket_name, base_branch, current_branch)
      base_commit_hash = Action.sh("git merge-base origin/#{base_branch} #{current_branch}").chomp!
      dirs = `gsutil ls gs://#{bucket_name}/ | grep -e "/$"`.split("\n")
                 .map {|s| s[/(?<=gs:\/\/#{bucket_name}\/)(.*)(?=\/)/]}
      hashes = Action.sh("git log origin/#{base_branch} --pretty=%H").split("\n")
      hashes[hashes.index(base_commit_hash)..-1].each {|hash|
        if dirs.include?(hash)
          return hash
        end
      }
      nil
    end

    def self.firebase_object_url(bucket, path)
      "https://firebasestorage.googleapis.com/v0/b/#{bucket}/o/#{CGI.escape(path)}?alt=media"
    end

    def self.calc_aspect_ratio(imagePath)
      width, height = FastImage.size(imagePath)
      height / width.to_f
    end
  end
end
