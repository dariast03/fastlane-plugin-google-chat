# google_chat plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-google_chat)


![](https://narlei.com/fastlane-plugin-google.jpg)
## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-google_chat`, add it to your project by running:

```bash
fastlane add_plugin google_chat
```

## About google_chat

Send messages to Google Chat. This fork uses the **Google Chat API v2** (`cardsV2`) and adds support for plain-text messages that preserve newlines.

Key improvements over the original:
- Uses `cardsV2` (the legacy `cards` field is deprecated).
- Newlines in `description` / `section1Description` are converted to `<br>` so multi-line changelogs render correctly in cards.
- New `message_type` option to send a plain text message (`{"text": ...}`) that keeps newlines as-is.
- Optional parameters (only `webhook` is required).
- Reports the HTTP error code/body when the webhook call fails.

## Example

````ruby
# Card message (default) — newlines become <br>
google_chat(
  webhook: 'URL_OF_WEBHOOK',
  title: 'TITLE',
  description: 'line1\nline2',
  section1Title: 'TITLE_SECTION',
  section1Description: 'DESCRIPTION_SECTION',
  buttonTitle: 'BUTTON_TITLE',
  buttonUrl: 'URL_ACTION'
)

# Plain text message — newlines are preserved as-is
google_chat(
  webhook: 'URL_OF_WEBHOOK',
  description: "Feature A\nFix B",
  message_type: 'plain'
)
````



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
