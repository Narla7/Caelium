import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "io.github.warfollowsme.pixel-player"

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []
  readonly property var mediaService: bar?.shell?.firstPartyServiceFor("omarchy.media")
  readonly property var activePlayer: mediaService ? mediaService.activePlayer : null
  // A paused MPRIS player may belong to a different process than the stream
  // currently producing sound (notably when two cliamp instances are open).
  // Never route controls or metadata to that unrelated player.
  readonly property var controlPlayer: activePlayer && (activePlayer.isPlaying || !playing) ? activePlayer : null
  readonly property var playbackStreams: {
    var result = []
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i]
      // Track output streams before their optional audio interface is bound.
      // Requiring node.audio here creates a chicken-and-egg dependency: the
      // tracker below is what binds that interface in the first place.
      if (node && node.isStream && node.isSink) result.push(node)
    }
    return result
  }
  readonly property string sourceName: {
    if (controlPlayer)
      return controlPlayer.identity || controlPlayer.desktopEntry || "Media player"
    if (playbackStreams.length > 0)
      return playbackStreams[0].description || playbackStreams[0].name || "Audio application"
    return "Audio output"
  }
  readonly property string trackTitle: controlPlayer
    ? (controlPlayer.trackTitle || controlPlayer.trackAlbum || sourceName)
    : sourceName
  readonly property string trackDetail: controlPlayer
    ? (controlPlayer.trackArtist || sourceName)
    : (playbackStreams.length > 1 ? playbackStreams.length + " active audio sources" : "PipeWire audio stream")
  readonly property string trackArtist: controlPlayer
    ? ((mediaService && mediaService.artist) || controlPlayer.trackArtist || "")
    : ""
  property var levels: [0, 0, 0, 0, 0]
  property double lastSoundAt: 0
  property real smoothedPeak: 0
  property int silentFrames: 0
  property bool popupOpen: false
  property bool playing: false

  // Build a stable tonal hierarchy from the active theme. Mixing toward the
  // popup text makes every level darker on light themes and lighter on dark
  // themes, while a small accent contribution preserves the theme character.
  function mixColor(a, b, amount) {
    var t = Math.max(0, Math.min(1, amount))
    return Qt.rgba(
      a.r + (b.r - a.r) * t,
      a.g + (b.g - a.g) * t,
      a.b + (b.b - a.b) * t,
      1
    )
  }

  readonly property color playerOutline: mixColor(mixColor(Color.popups.background, Color.popups.text, 0.30), Color.accent, 0.12)
  readonly property color artworkOutline: mixColor(Color.popups.background, Color.popups.text, 0.28)
  readonly property color speakerHole: mixColor(Color.popups.background, Color.popups.text, 0.38)
  readonly property color controlWell: mixColor(mixColor(Color.popups.background, Color.popups.text, 0.24), Color.accent, 0.08)
  readonly property color buttonIdle: mixColor(Color.popups.background, Color.popups.text, 0.07)
  readonly property color buttonHover: mixColor(mixColor(Color.popups.background, Color.popups.text, 0.40), Color.accent, 0.08)
  readonly property color buttonPressed: mixColor(mixColor(Color.popups.background, Color.popups.text, 0.52), Color.accent, 0.08)
  readonly property color iconShadow: mixColor(Color.popups.background, Color.popups.text, 0.46)

  // Stay as a quiet five-pixel handle while a source is paused, so playback
  // controls remain reachable even when there is no audible signal.
  visible: playing || popupOpen || activePlayer !== null || playbackStreams.length > 0
  implicitWidth: visible ? meter.width + Style.space(10) : 0
  implicitHeight: barSize

  function close() { popupOpen = false }

  function runMediaAction(action) {
    if (!mediaService || !controlPlayer) return
    mediaService.runAction(action, false, mediaService.playerKey(controlPlayer))
  }

  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
  }

  PwObjectTracker {
    objects: root.playbackStreams
  }

  PwNodePeakMonitor {
    id: peakMonitor
    node: root.sink
    enabled: root.sink !== null
  }

  Timer {
    interval: 85
    running: root.sink !== null
    repeat: true
    onTriggered: {
      var raw = Math.max(0, peakMonitor.peak || 0)
      root.smoothedPeak = Math.max(raw, root.smoothedPeak * 0.68)

      if (raw > 0.008) {
        root.lastSoundAt = Date.now()
        root.silentFrames = 0
        root.playing = true
      } else {
        root.silentFrames += 1
        if (root.silentFrames >= 10) root.playing = false
      }

      if (raw > 0.008) {
        var strength = Math.max(1, Math.min(5, Math.ceil(Math.sqrt(root.smoothedPeak) * 6)))
        var next = []
        for (var i = 0; i < 5; i++) {
          var shape = 1 - Math.abs(i - 2) * 0.12
          var jitter = Math.floor(Math.random() * 3) - 1
          next.push(Math.max(1, Math.min(5, Math.round(strength * shape) + jitter)))
        }
        root.levels = next
      } else {
        var decay = []
        for (var j = 0; j < 5; j++) decay.push(Math.max(0, root.levels[j] - 1))
        root.levels = decay
        if (!root.playing) root.smoothedPeak = 0
      }
    }
  }

  Item {
    id: meter
    width: 27
    height: 17
    anchors.centerIn: parent

    Repeater {
      model: 25

      Rectangle {
        required property int index
        readonly property int column: index % 5
        readonly property int row: Math.floor(index / 5)

        width: 2.5
        height: width
        x: column * 6 + 0.25
        y: row * 3.5 + 0.25
        radius: width / 2
        visible: root.playing ? (5 - row) <= root.levels[column] : row === 4
        color: root.bar ? root.bar.barForeground : Color.foreground
        opacity: root.playing ? 0.55 + (row * 0.1) : 0.4
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton
    onClicked: {
      root.popupOpen = !root.popupOpen
      if (root.bar) root.bar.hideTooltip(root)
    }
    onEntered: if (root.bar) root.bar.showTooltip(root, root.playing ? "Audio is playing" : "Open audio controls")
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    padding: 0
    contentWidth: popup.fittedContentWidth(Style.space(360))
    contentHeight: popup.fittedContentHeight(Style.space(360))
    borderSpec: Border.none()

    ClippingRectangle {
      anchors.fill: parent
      // PopupCard normally paints its own rectangular card behind custom
      // content. Make that backing surface transparent so only this rounded
      // player body remains visible in the corners.
      Component.onCompleted: {
        if (parent && parent.parent) parent.parent.color = "transparent"
      }
      radius: Style.space(52)
      // Follow the active Omarchy theme and update live on theme changes.
      color: Color.popups.background
      border.width: 1
      border.color: root.playerOutline
      clip: true

      Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, parent.radius - 1)
        gradient: Gradient {
          orientation: Gradient.Vertical
          GradientStop { position: 0.0; color: root.mixColor(Color.popups.background, Color.popups.text, 0.035) }
          GradientStop { position: 0.42; color: Color.popups.background }
          GradientStop { position: 1.0; color: root.mixColor(Color.popups.background, Color.popups.text, 0.065) }
        }
      }

      Image {
        anchors.fill: parent
        anchors.margins: 1
        source: Qt.resolvedUrl("assets/matte-plastic-noise.png")
        fillMode: Image.Tile
        smooth: false
        opacity: 0.035
      }

      Column {
        anchors.fill: parent
        anchors.margins: Style.space(10)
        spacing: 0

        ClippingRectangle {
          id: artworkFrame
          width: parent.width
          height: Style.space(212)
          radius: Style.space(40)
          bottomLeftRadius: Style.space(12)
          bottomRightRadius: Style.space(12)
          color: Color.popups.background
          border.width: 0

          ClippingRectangle {
            id: artworkContent
            anchors.fill: parent
            radius: artworkFrame.radius
            bottomLeftRadius: artworkFrame.bottomLeftRadius
            bottomRightRadius: artworkFrame.bottomRightRadius
            color: "transparent"

            Image {
              anchors.fill: parent
              source: root.controlPlayer && root.controlPlayer.trackArtUrl ? root.controlPlayer.trackArtUrl : ""
              asynchronous: true
              fillMode: Image.PreserveAspectCrop
            }

            Rectangle {
              anchors.fill: parent
              visible: !root.controlPlayer || !root.controlPlayer.trackArtUrl
              color: "#202522"
              Text { anchors.centerIn: parent; text: "♫"; textFormat: Text.PlainText; color: "#737b76"; font.pixelSize: Style.space(76) }
            }

            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: Style.space(48)
              color: "#b4111312"

              Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Style.space(12)
                spacing: Style.space(8)

                Rectangle {
                  width: Style.space(7); height: width; radius: width / 2
                  color: root.controlPlayer && root.controlPlayer.isPlaying ? Color.urgent : Color.muted
                  anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                  id: playbackStatus
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.controlPlayer
                    ? (root.controlPlayer.isPlaying ? "Playing now  ·" : "Paused  ·")
                    : ""
                  textFormat: Text.PlainText
                  color: "#f1f1ec"
                  font.family: "monospace"
                  font.pixelSize: Style.font.bodySmall
                }
                Item {
                  id: marqueeViewport
                  width: parent.width - Style.space(7) - playbackStatus.paintedWidth - parent.spacing * 2
                  height: parent.height
                  clip: true
                  readonly property string label: root.controlPlayer
                    ? (root.trackTitle + (root.trackArtist ? "  ·  " + root.trackArtist : ""))
                    : "No controllable player"
                  readonly property real marqueeGap: Style.space(36)

                  onLabelChanged: marqueeText.x = 0

                  Text {
                    id: marqueeText
                    anchors.verticalCenter: parent.verticalCenter
                    text: marqueeViewport.label
                    textFormat: Text.PlainText
                    color: "#f1f1ec"
                    font.family: "monospace"
                    font.pixelSize: Style.font.bodySmall

                    NumberAnimation on x {
                      from: 0
                      to: -(marqueeText.paintedWidth + marqueeViewport.marqueeGap)
                      duration: Math.max(1, (marqueeText.paintedWidth + marqueeViewport.marqueeGap) * 34)
                      loops: Animation.Infinite
                      running: marqueeText.paintedWidth > marqueeViewport.width
                    }
                  }

                  Text {
                    x: marqueeText.x + marqueeText.paintedWidth + marqueeViewport.marqueeGap
                    anchors.verticalCenter: parent.verticalCenter
                    visible: marqueeText.paintedWidth > marqueeViewport.width
                    text: marqueeViewport.label
                    textFormat: Text.PlainText
                    color: marqueeText.color
                    font: marqueeText.font
                  }
                }
              }
            }
          }

          ClippingRectangle {
            anchors.fill: parent
            radius: artworkFrame.radius
            bottomLeftRadius: artworkFrame.bottomLeftRadius
            bottomRightRadius: artworkFrame.bottomRightRadius
            color: "transparent"
            border.width: 1
            border.color: root.artworkOutline
          }
        }

        Item {
          width: parent.width
          height: Style.space(48)
          Grid {
            anchors.centerIn: parent
            columns: 37
            rowSpacing: Style.space(4)
            columnSpacing: Style.space(5)
            Repeater {
              model: 185
              Rectangle { width: Style.space(3); height: width; radius: width / 2; color: root.speakerHole }
            }
          }
        }

        ClippingRectangle {
          id: controls
          width: parent.width
          height: Style.space(80)
          radius: Style.space(12)
          bottomLeftRadius: Style.space(40)
          bottomRightRadius: Style.space(40)
          color: root.controlWell

          Row {
            id: buttonRow
            anchors.fill: parent
            anchors.margins: Style.space(4)
            spacing: Style.space(4)

            Repeater {
              model: [
                { icon: "󰒮", action: "previous", enabled: root.controlPlayer && root.controlPlayer.canGoPrevious },
                { icon: root.controlPlayer && root.controlPlayer.isPlaying ? "󰏤" : "󰐊", action: "playPause", enabled: root.controlPlayer && (root.controlPlayer.canTogglePlaying || root.controlPlayer.canPlay || root.controlPlayer.canPause) },
                { icon: "󰒭", action: "next", enabled: root.controlPlayer && root.controlPlayer.canGoNext }
              ]

              ClippingRectangle {
                id: controlButton
                required property var modelData
                width: (buttonRow.width - buttonRow.spacing * 2) / 3
                height: buttonRow.height
                radius: Style.space(8)
                bottomLeftRadius: modelData.action === "previous" ? Style.space(36) : radius
                bottomRightRadius: modelData.action === "next" ? Style.space(36) : radius
                color: buttonMouse.pressed
                  ? root.buttonPressed
                  : (buttonMouse.containsMouse ? root.buttonHover : root.buttonIdle)
                opacity: modelData.enabled ? 1 : 0.35
                readonly property bool showingPause: modelData.action === "playPause" && root.controlPlayer && root.controlPlayer.isPlaying
                readonly property url vectorSource: modelData.action === "previous"
                  ? Qt.resolvedUrl("assets/previous.svg")
                  : (modelData.action === "next" ? Qt.resolvedUrl("assets/next.svg") : Qt.resolvedUrl("assets/play.svg"))
                Item {
                  id: svgIcon
                  anchors.centerIn: parent
                  width: Style.space(38)
                  height: width
                  readonly property real glyphSize: controlButton.modelData.action === "playPause" ? Style.space(28) : Style.space(26)

                  Image {
                    id: vectorSourceImage
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: Style.space(1)
                    anchors.verticalCenterOffset: Style.space(2)
                    width: svgIcon.glyphSize
                    height: width
                    source: controlButton.vectorSource
                    sourceSize.width: 128
                    sourceSize.height: 128
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    visible: !controlButton.showingPause
                    layer.enabled: true
                    layer.effect: MultiEffect {
                      colorization: 1
                      colorizationColor: root.iconShadow
                    }
                  }

                  Image {
                    anchors.centerIn: parent
                    width: svgIcon.glyphSize
                    height: width
                    source: controlButton.vectorSource
                    sourceSize.width: 128
                    sourceSize.height: 128
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    visible: !controlButton.showingPause
                    layer.enabled: true
                    layer.effect: MultiEffect {
                      colorization: 1
                      colorizationColor: Color.popups.text
                    }
                  }

                  Item {
                    anchors.fill: parent
                    visible: controlButton.showingPause

                    Repeater {
                      model: [Style.space(10), Style.space(22)]
                      Rectangle {
                        required property real modelData
                        x: modelData + Style.space(1)
                        y: Style.space(7)
                        width: Style.space(6)
                        height: Style.space(26)
                        radius: width / 2
                        color: root.iconShadow
                      }
                    }
                    Repeater {
                      model: [Style.space(10), Style.space(22)]
                      Rectangle {
                        required property real modelData
                        x: modelData
                        y: Style.space(5)
                        width: Style.space(6)
                        height: Style.space(26)
                        radius: width / 2
                        color: Color.popups.text
                      }
                    }
                  }
                }
                MouseArea {
                  id: buttonMouse
                  anchors.fill: parent
                  enabled: controlButton.modelData.enabled
                  hoverEnabled: true
                  cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                  onClicked: root.runMediaAction(controlButton.modelData.action)
                }
              }
            }
          }
        }
      }
    }
  }
}
