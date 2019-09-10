describe Fastlane::Actions::TakeScreenshotAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The snapshot_test plugin is working!")

      Fastlane::Actions::TakeScreenshotAction.run(nil)
    end
  end
end

describe Fastlane::Actions::CompareSnapshotAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The snapshot_test plugin is working!")

      Fastlane::Actions::CompareSnapshotAction.run(nil)
    end
  end
end

describe Fastlane::Actions::UploadSnapshotAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The snapshot_test plugin is working!")

      Fastlane::Actions::UploadSnapshotAction.run(nil)
    end
  end
end

describe Fastlane::Actions::ScreenshotNotifierAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The snapshot_test plugin is working!")

      Fastlane::Actions::ScreenshotNotifierAction.run(nil)
    end
  end
end
