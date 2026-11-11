//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// REDESIGN: Bottom row: transport (centre) and settings pills (right).
// Info / Episodes keep their upstream tabs below this row (user choice).

extension PlayerRedesign {

    enum PanelKind: String, Hashable {

        case audio
        case subtitles
        case speed
        case quality
    }

    struct TransportButtons: View {

        let adapter: Adapter

        private typealias Size = Tokens.Size

        @ContentBuilder
        private var playButton: some View {
            Button {
                adapter.togglePlayPause()
            } label: {
                Image(systemName: adapter.isPaused ? Tokens.Icons.play : Tokens.Icons.pause)
                    .font(.system(size: Size.playIcon, weight: .bold))
                    .foregroundStyle(Tokens.Colors.primaryButtonIcon)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: Size.playButton, height: Size.playButton)
                    .background(Circle().fill(Tokens.Colors.primaryButton))
                    .contentShape(Circle())
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!adapter.canControlPlayback)
            .accessibilityLabel(adapter.isPaused ? Strings.play : Strings.pause)
        }

        @ContentBuilder
        var body: some View {
            HStack(spacing: Tokens.Layout.transportSpacing) {
                if adapter.showsEpisodeButtons {
                    IconButton(
                        systemImage: Tokens.Icons.previousEpisode,
                        size: Size.skipEpisodeButton,
                        iconSize: Size.skipEpisodeIcon,
                        accessibilityLabel: Strings.previousEpisode,
                        action: adapter.playPrevious
                    )
                    .disabled(!adapter.canPlayPrevious)
                }

                if adapter.showsJumpButtons {
                    IconButton(
                        systemImage: adapter.jumpBackwardSystemImage,
                        size: Size.jumpButton,
                        iconSize: Size.jumpIcon,
                        accessibilityLabel: Strings.jumpBackward(adapter.jumpBackwardSeconds),
                        action: adapter.jumpBackward
                    )
                    .disabled(!adapter.canSeek)
                }

                playButton

                if adapter.showsJumpButtons {
                    IconButton(
                        systemImage: adapter.jumpForwardSystemImage,
                        size: Size.jumpButton,
                        iconSize: Size.jumpIcon,
                        accessibilityLabel: Strings.jumpForward(adapter.jumpForwardSeconds),
                        action: adapter.jumpForward
                    )
                    .disabled(!adapter.canSeek)
                }

                if adapter.showsEpisodeButtons {
                    IconButton(
                        systemImage: Tokens.Icons.nextEpisode,
                        size: Size.skipEpisodeButton,
                        iconSize: Size.skipEpisodeIcon,
                        accessibilityLabel: Strings.nextEpisode,
                        action: adapter.playNext
                    )
                    .disabled(!adapter.canPlayNext)
                }
            }
        }
    }

    struct SettingsPills: View {

        let adapter: Adapter

        @Binding
        var openPanel: PanelKind?

        private func toggle(_ kind: PanelKind) {
            openPanel = openPanel == kind ? nil : kind
        }

        @ContentBuilder
        private func pill(_ kind: PanelKind, systemImage: String, title: String, value: PillValue) -> some View {
            Pill(
                systemImage: systemImage,
                text: value.short,
                accessibilityLabel: Strings.pill(title, value: value.spoken),
                isActive: openPanel == kind
            ) {
                toggle(kind)
            }
            .anchorPreference(key: PillAnchorKey.self, value: .bounds) { [kind: $0] }
        }

        @ContentBuilder
        var body: some View {
            HStack(spacing: Tokens.Layout.groupSpacing) {
                if adapter.showsAudio {
                    pill(.audio, systemImage: Tokens.Icons.audio, title: Strings.audio, value: adapter.audioValue)
                }

                if adapter.showsSubtitles {
                    pill(.subtitles, systemImage: Tokens.Icons.subtitles, title: Strings.subtitles, value: adapter.subtitleValue)
                        .disabled(!adapter.canSelectSubtitles)
                }

                if adapter.showsSpeed {
                    pill(.speed, systemImage: Tokens.Icons.speed, title: Strings.speed, value: adapter.speedValue)
                }

                if adapter.showsQuality {
                    pill(.quality, systemImage: Tokens.Icons.quality, title: Strings.quality, value: adapter.qualityValue)
                }

                if adapter.showsAspectFill {
                    Pill(
                        systemImage: adapter.aspectFillSystemImage,
                        accessibilityLabel: adapter.isVideoEnlarged ? Strings.fitScreen : Strings.fillScreen,
                        action: adapter.toggleAspectFill
                    )
                }

                MoreMenu(adapter: adapter)
            }
        }
    }

    struct ControlsRow: View {

        let adapter: Adapter

        @Binding
        var openPanel: PanelKind?

        /// Below this width the centred transport would collide with the pills.
        private static let stackedThreshold: CGFloat = 1000

        @State
        private var width: CGFloat = .infinity

        @ContentBuilder
        var body: some View {
            Group {
                if width >= Self.stackedThreshold {
                    ZStack {
                        TransportButtons(adapter: adapter)

                        HStack {
                            Spacer(minLength: 0)
                            SettingsPills(adapter: adapter, openPanel: $openPanel)
                        }
                    }
                } else {
                    VStack(spacing: Tokens.Layout.timelineToRowSpacing) {
                        TransportButtons(adapter: adapter)
                        SettingsPills(adapter: adapter, openPanel: $openPanel)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        }
    }

    struct PillAnchorKey: PreferenceKey {

        static let defaultValue: [PanelKind: Anchor<CGRect>] = [:]

        static func reduce(value: inout [PanelKind: Anchor<CGRect>], nextValue: () -> [PanelKind: Anchor<CGRect>]) {
            value.merge(nextValue()) { $1 }
        }
    }
}
