# Pixel Player

Pixel Player is a compact media widget for the Omarchy Quattro bar. It shows a
five-column dot equalizer that reacts to PipeWire output and opens a tactile,
hardware-inspired player on click.

## Features

- Live PipeWire peak visualization
- MPRIS album art and track metadata
- Overflow-only marquee for long track and artist metadata
- Previous, play/pause, and next controls
- Automatic paused-player handling
- Contrast-balanced colors that adapt to the active Omarchy theme
- Matte-plastic texture, transparent popup corners, and hardware-inspired controls

## Requirements

- Omarchy Quattro with `omarchy-shell`
- PipeWire (included with Omarchy)
- An MPRIS-compatible media player for metadata and transport controls

No additional packages, background services, privileged access, or network
access are required. The equalizer can detect ordinary PipeWire playback even
when the source does not expose MPRIS controls.

## Install

```bash
omarchy plugin add https://github.com/warfollowsme/omarchy-pixel-player.git --enable
omarchy restart shell
```

The widget defaults to the left section of the bar. Move it with Omarchy's bar
configuration if you prefer a different position.

## Usage

- Left-click the animated dots to open or close the player.
- Use the three popup buttons for previous, play/pause, and next.
- Click outside the popup to dismiss it.

MPRIS controls are disabled when the active audio source cannot be matched to a
controllable media player.

## Remove

```bash
omarchy plugin remove io.github.warfollowsme.pixel-player --yes
omarchy restart shell
```

Removal only removes the plugin checkout and its bar entry. Pixel Player does
not create caches, state files, services, or configuration outside its plugin
directory.

## Security

Omarchy plugins execute as unsandboxed user code inside `omarchy-shell`. Review
the source before installation. Pixel Player only reads PipeWire and MPRIS
state through Quickshell and sends explicit MPRIS transport actions when its
buttons are clicked.

## License

MIT — see [LICENSE](LICENSE).

The play, previous, and next control shapes are adapted from SVG Repo assets
[204978](https://www.svgrepo.com/svg/204978/play),
[204981](https://www.svgrepo.com/svg/204981/previous), and
[204973](https://www.svgrepo.com/svg/204973/next).
