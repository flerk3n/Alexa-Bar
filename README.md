# Alexa Bar

Control your Alexa smart home from the macOS menu bar: lights, plugs,
switches and Echo speakers in one panel.

Not affiliated with Amazon. Alexa Bar uses the same private web service as
the Alexa website (through [AlexaPy](https://gitlab.com/keatontaylor/alexapy)),
which Amazon can change at any time.

## Requirements

- macOS 14 Sonoma or later, Apple silicon
- An Amazon account with Alexa devices

Nothing else: the app ships with its own Python runtime.

## Install

1. Open `Alexa-Bar-<version>.dmg` and drag **Alexa Bar** to **Applications**.
2. Open it from Applications. A ring icon appears in the menu bar.
3. Click it, enter your Amazon email, pick your region and choose
   **Continue with Amazon**. Amazon's own sign-in page opens in your browser;
   sign in there (password and any verification code). The panel updates
   when you're done.
4. Accept **Open at login** when offered, or turn it on later in Settings.

If the app was built without a Developer ID signature, macOS blocks the first
launch on other Macs. Right-click the app, choose **Open**, then **Open** again.

## Features

- **Lights**: on/off, brightness slider, 5 white temperatures, 12 colours.
  Cards are tinted with the bulb's current colour.
- **Plugs and switches**: one-click tiles and "Turn all off" per section.
- **Echo**: volume, make it speak any text, stop playback.
- **Ask Alexa**: type anything you'd say ("turn off the lights in 10 minutes").
- **Voice fallback**: if Amazon refuses direct control of a device, the
  command goes through your Echo instead.
- **Live status**: refreshed on a timer, when the panel opens, after wake from
  sleep and when the network comes back. Changes appear instantly and roll
  back if Amazon rejects them.
- **Mac app basics**: Open at Login, no Dock icon, single instance, offline
  banner, standard About window, keyboard shortcuts (⌘R refresh, ⌘, settings,
  Esc back, ⌘Q quit), VoiceOver labels, light and dark mode.
- **Settings**: account and region, sign out, default Echo, refresh interval,
  on-count in the menu bar, hidden devices, logs, reconnect.

## Privacy

- Your password is typed only into Amazon's page. Alexa Bar keeps the session
  tokens Amazon returns in `~/Library/Application Support/Alexa Bar/`
  (owner-only permissions). **Sign Out** deletes them.
- The sign-in page is served by a temporary local proxy on `127.0.0.1` that
  stops as soon as sign-in finishes.
- Logs are in `~/Library/Logs/Alexa Bar/helper.log` and don't contain
  passwords or tokens.

## Build from source

Needs the Xcode Command Line Tools (`xcode-select --install`) and internet
access for the first build (downloads a pinned, checksum-verified Python).

```sh
make app       # build/Alexa Bar.app
make dmg       # build/Alexa-Bar-<version>.dmg
make install   # copy to /Applications and open
```

Release signing and notarization:

```sh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" make app
NOTARY_PROFILE=<notarytool keychain profile> scripts/make_dmg.sh
```

`VERSION` and `BUNDLE_ID` can be set the same way.

## How it works

```
Alexa Bar.app
├── Contents/MacOS/AlexaBar          SwiftUI menu bar app (all UI and state)
└── Contents/Resources/helper/
    ├── python/                      standalone CPython 3.12
    ├── site-packages/               AlexaPy and its dependencies
    ├── alexabar_helper/             helper package (backend/ in this repo)
    └── run_helper.py
```

The app starts the helper as a child process and exchanges one JSON object per
line over stdin/stdout (`backend/alexabar_helper/protocol.py`). The helper
exits when the app quits.

Amazon endpoints used: `/api/behaviors/entities` (device list),
`/api/phoenix/state` (status and control), `/api/behaviors/preview` (Echo
speak, volume, stop, typed commands), `/api/devices-v2/device` and
`.../allDeviceVolumes` (Echo list and volume).

### Rate limiting (HTTP 429)

Amazon answers `429 Too Many Requests` when one account sends too many
commands in a short time, especially Echo commands. Alexa Bar avoids it:
sliders send one request after you stop moving them (350 ms debounce), the
helper drops queued values that a newer one has replaced, and a 429 is
retried up to twice with back-off before you see "Amazon is limiting
requests".

## Repository layout

| Path | Contents |
| --- | --- |
| `Sources/AlexaBar/` | Swift app: `App/`, `Backend/`, `Models/`, `Support/`, `Views/` |
| `backend/` | Python helper package and pinned requirements |
| `Packaging/` | Info.plist template and entitlements |
| `scripts/` | build, DMG, install, Python fetcher, icon renderer |
| `prototype/` | the original CLI and rumps prototypes, unchanged |

Note: on recent SDKs SwiftUI's `@State` is a macro whose plugin ships only
with Xcode. The views use `@ViewState`, an alias for the `State` property
wrapper, so the app builds with the Command Line Tools alone.
