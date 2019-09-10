# snapshot_test plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-snapshot_test)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-snapshot_test`, add it to your project by running:

```bash
fastlane add_plugin snapshot_test
```

This plugin depends Firebase Cloud Storage to store snapshots.
If you don't have a Firebase account, see [this](https://github.com/cats-oss/fastlane-plugin-firebase_test_lab_android#if-you-are-not-current-user-of-firebase) and create a bucket. 

## About snapshot_test
compare screenshots with previous commit's screenshots.

## Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

In case of `screenshot_dir` like below,

```
.screenshot
  ├ Nexus6
  |  ├ MainPage.jpg
  |  └ SubPage.jpg
  └ Nexus6P
     ├ MainPage.jpg
     └ SubPage.jpg
```

## Run tests for this plugin

To run both the tests, and code style validation, run

```
rake
```

To automatically fix many of the styling issues, use
```
rubocop -a
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
