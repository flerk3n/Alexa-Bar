# Changelog

All notable changes to Alexa Bar are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org).

## [1.0.0] - 2026-11-23

First public release.

### Added
- Menu bar panel listing Alexa smart home lights, plugs and switches, and
  Echo speakers.
- Lights: power, brightness slider and presets, 5 white temperatures,
  12 colours, cards tinted with the bulb's current colour.
- Plugs and switches: one-click tiles and "Turn all off".
- Echo: volume, speak any text, stop playback.
- Ask Alexa: send any typed command through an Echo.
- Voice fallback when Amazon refuses direct control of a device.
- Sign in through Amazon's own page in the browser, 12 Amazon regions.
- Open at Login, single instance, offline banner, refresh after wake,
  automatic helper restart, optional count of devices that are on next to
  the menu bar icon.
- Rate-limit protection: debounced sliders, coalesced commands and retry
  with back-off on HTTP 429.
- Keyboard shortcuts (⌘R, ⌘,, Esc, ⌘Q), VoiceOver labels, light and dark mode.
- Self-contained app: bundled Python 3.12 runtime and AlexaPy.

[1.0.0]: https://github.com/flerk3n/Alexa-Bar/releases/tag/v1.0.0
