# MusatPlay

<img src="MusatPlay/Assets.xcassets/AppIcon.appiconset/icon.png" width="96" alt="MusatPlay icon">

An unofficial macOS wrapper for YouTube Music, built with SwiftUI and WKWebView.

## Features

- **Dedicated window:** access YouTube Music without keeping a browser tab open.
- **Background playback:** the red close button hides the window while music keeps playing. Minimizing also preserves playback; use Command + Q to quit completely.
- **Dock restore:** click the Dock icon to bring back a hidden or minimized window.
- **Track notifications:** a translucent panel in the top-right corner shows the current track, artist, and artwork. Track changes update the existing panel in place.
- **Notification controls:** previous track, play / pause, next track, shuffle, and repeat, with playback and mode indicators.
- **Hover to keep open:** notifications fade and slide in and out. Hover over the panel to keep it visible; it dismisses five seconds after the pointer leaves.
- **Full-screen awareness:** notifications are suppressed when another app is detected as filling the screen.
- **Global keyboard shortcuts:** control playback even while MusatPlay is in the background.

| Shortcut | Action |
| --- | --- |
| Control + Option + Space | Play / pause |
| Control + Option + Right | Next track |
| Control + Option + Left | Previous track |
| Control + Option + S | Shuffle |
| Control + Option + R | Cycle repeat mode |

## Download

| Requirement | Support |
| --- | --- |
| macOS | Ventura 13.5 or later |
| Intel Macs | x86_64 |
| Apple Silicon Macs | arm64 (M1 and later) |

The download is a universal app containing both architectures. Tested on macOS 26.7.1 on an Intel Mac; Apple Silicon and older macOS versions have not been runtime-tested.

Download the DMG from [Releases](https://github.com/musatDev/MusatPlay/releases/latest), open it, and drag MusatPlay into Applications.

This release is not notarized; macOS may display a security warning.

## Build

Open `MusatPlay.xcodeproj` in Xcode, select your signing team, and build the MusatPlay scheme.

## Notice

MusatPlay is an independent, unofficial project and is not affiliated with, endorsed by, or sponsored by Google LLC or YouTube. YouTube and YouTube Music are trademarks of Google LLC.

Playback and account features are provided by YouTube Music and remain subject to its terms of service. MusatPlay does not provide music downloads or ad blocking.

## License

MusatPlay's original source code is available under the [MIT License](LICENSE). Third-party trademarks and content remain the property of their respective owners.
