describe Fastlane::Actions::SnapshotTestAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The snapshot_test plugin is working!")

      Fastlane::Actions::SnapshotTestAction.run(nil)
    end
  end
end
