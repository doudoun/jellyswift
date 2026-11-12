//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// REDESIGN: Single source of truth for the redesigned player's look.
// Retouching the aesthetics should only require editing this file.

extension PlayerRedesign {

    enum Tokens {

        // MARK: - Colors

        enum Colors {

            static let background = rgb(0x050504)
            static let text = rgb(0xF4F1EA)
            static let textSecondary = rgb(0xA3A097)
            static let textSelectedDetail = rgb(0xC9C4B8)
            static let accent = rgb(0xE8B04A)
            static let accentFill = rgb(0xE8B04A, 0.14)
            static let accentFillStrong = rgb(0xE8B04A, 0.18)

            static let pill = Color.white.opacity(0.09)
            static let pillReducedTransparency = rgb(0x2A2A2E)
            static let closeBorder = Color.white.opacity(0.16)

            static let panel = rgb(0x1E1E23, 0.97)
            static let panelReducedTransparency = rgb(0x1E1E23)
            static let panelBorder = Color.white.opacity(0.10)
            static let panelShadow = Color.black.opacity(0.55)

            static let primaryButton = rgb(0xF4F1EA)
            static let primaryButtonIcon = rgb(0x101012)

            static let trackBackground = Color.white.opacity(0.18)
            static let knob = Color.white
            static let knobShadow = Color.black.opacity(0.5)

            static let hiddenTrackBackground = Color.white.opacity(0.12)
            static let hiddenTrackOpacity: Double = 0.85

            static let scrim = rgb(0x050504, 0.9)
            static let pauseDim = rgb(0x050504, 0.45)

            static let previewBorder = Color.white
            static let previewChip = Color.black.opacity(0.6)

            static func rgb(_ hex: UInt32, _ opacity: Double = 1) -> Color {
                Color(
                    .sRGB,
                    red: Double((hex >> 16) & 0xFF) / 255,
                    green: Double((hex >> 8) & 0xFF) / 255,
                    blue: Double(hex & 0xFF) / 255,
                    opacity: opacity
                )
            }
        }

        // MARK: - Layout

        enum Layout {

            static let edgeMargin: CGFloat = 40
            static let topBarHeight: CGFloat = 76
            static let topBarSpacing: CGFloat = 16
            static let scrimHeight: CGFloat = 300

            static let timelineSpacing: CGFloat = 18
            static let timelineToRowSpacing: CGFloat = 14
            static let bottomPadding: CGFloat = 16

            static let elapsedWidth: CGFloat = 44
            static let remainingWidth: CGFloat = 56

            static let groupSpacing: CGFloat = 8
            static let transportSpacing: CGFloat = 20
            /// Smallest gap kept between the transport buttons and the pills.
            static let transportToPillsMinimumGap: CGFloat = 24
        }

        // MARK: - Sizes

        enum Size {

            static let minimumHitTarget: CGFloat = 44

            static let closeButton: CGFloat = 48
            static let closeIcon: CGFloat = 18

            static let pillHeight: CGFloat = 44
            static let pillIcon: CGFloat = 18
            static let pillSlashWidth: CGFloat = 2
            static let pillLeadingPadding: CGFloat = 14
            static let pillTrailingPadding: CGFloat = 14

            static let skipEpisodeButton: CGFloat = 44
            static let skipEpisodeIcon: CGFloat = 20
            static let jumpButton: CGFloat = 48
            static let jumpIcon: CGFloat = 28
            static let playButton: CGFloat = 64
            static let playIcon: CGFloat = 24
            static let roundButton: CGFloat = 44

            static let trackHeight: CGFloat = 8
            static let trackHitHeight: CGFloat = 44
            static let knob: CGFloat = 16
            static let knobScrubbing: CGFloat = 22

            static let hiddenTrackHeight: CGFloat = 4

            static let previewSize = CGSize(width: 208, height: 117)
            static let previewBorder: CGFloat = 2
            static let previewOffset: CGFloat = 30

            static let panelRowSingle: CGFloat = 50
            static let panelRowDouble: CGFloat = 60
            static let panelCheck: CGFloat = 16
            static let panelGap: CGFloat = 10
            static let panelScreenMargin: CGFloat = 16
        }

        enum PanelWidth {

            static let audio: CGFloat = 320
            static let subtitles: CGFloat = 310
            static let speed: CGFloat = 230
            static let quality: CGFloat = 250
            static let more: CGFloat = 280
        }

        // MARK: - Radii

        enum Radius {

            static let pill: CGFloat = 22
            static let track: CGFloat = 4
            static let panel: CGFloat = 22
            static let panelRow: CGFloat = 14
            static let preview: CGFloat = 14
            static let previewChip: CGFloat = 10
        }

        // MARK: - Padding

        enum Padding {

            static let panel: CGFloat = 8
            static let panelHeader = EdgeInsets(top: 10, leading: 14, bottom: 6, trailing: 14)
            static let panelRowHorizontal: CGFloat = 14
            static let previewChip = EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10)
        }

        // MARK: - Typography

        enum Typography {

            static let title = Font.system(size: 18, weight: .semibold)
            static let subtitle = Font.system(size: 13)
            static let elapsed = Font.system(size: 14, weight: .bold).monospacedDigit()
            static let remaining = Font.system(size: 14, weight: .medium).monospacedDigit()
            static let pill = Font.system(size: 14, weight: .semibold)
            static let panelHeader = Font.system(size: 11.5, weight: .semibold)
            static let panelHeaderTracking: CGFloat = 1.15
            static let panelRow = Font.system(size: 16)
            static let panelRowSelected = Font.system(size: 16, weight: .semibold)
            static let panelRowDetail = Font.system(size: 12.5)
            static let previewChip = Font.system(size: 14, weight: .bold).monospacedDigit()
        }

        // MARK: - Shadows

        enum Shadow {

            static let panelRadius: CGFloat = 25
            static let panelY: CGFloat = 20
            static let knobRadius: CGFloat = 4
            static let knobY: CGFloat = 2
            static let previewRadius: CGFloat = 18
            static let previewY: CGFloat = 12
        }

        // MARK: - Icons (SF Symbols)

        enum Icons {

            static let close = "xmark"
            static let closeSupplement = "chevron.down"
            static let play = "play.fill"
            static let pause = "pause.fill"
            static let previousEpisode = "backward.end.fill"
            static let nextEpisode = "forward.end.fill"
            static let audio = "speaker.wave.2"
            static let subtitles = "captions.bubble"
            static let speed = "gauge.with.dots.needle.33percent"
            static let quality = "tv"
            static let more = "ellipsis"
            static let checkmark = "checkmark"
        }

        // MARK: - Options

        enum Options {

            /// Thin progress line at the bottom of the picture while controls are hidden.
            /// Off: a hidden overlay leaves the picture completely clean.
            static let showsProgressLineWhenHidden = false
        }

        // MARK: - Animation

        enum Motion {

            static let controls = Animation.easeInOut(duration: 0.2)
            static let panel = Animation.spring(duration: 0.25, bounce: 0.15)
            static let scrub = Animation.easeOut(duration: 0.12)
        }
    }
}
