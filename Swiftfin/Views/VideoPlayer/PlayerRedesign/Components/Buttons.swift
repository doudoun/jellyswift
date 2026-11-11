//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// REDESIGN: Reusable button visuals (pill, round icon button, press feedback).

extension PlayerRedesign {

    /// Press feedback shared by every redesigned button.
    struct PressableButtonStyle: ButtonStyle {

        @Environment(\.isEnabled)
        private var isEnabled

        @ContentBuilder
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.94 : 1)
                .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.35)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }

    /// Settings pill: icon + short value, "active" when its panel is open.
    struct Pill: View {

        @Environment(\.accessibilityReduceTransparency)
        private var reduceTransparency

        let systemImage: String
        var text: String?
        let accessibilityLabel: String
        var isActive: Bool = false
        /// Crosses the icon out, e.g. subtitles off.
        var isSlashed: Bool = false
        let action: () -> Void

        private typealias Colors = Tokens.Colors
        private typealias Size = Tokens.Size

        private var background: Color {
            if isActive {
                return Colors.accentFillStrong
            }

            return reduceTransparency ? Colors.pillReducedTransparency : Colors.pill
        }

        @ContentBuilder
        var body: some View {
            Button(action: action) {
                HStack(spacing: Tokens.Layout.groupSpacing) {
                    Image(systemName: systemImage)
                        .font(.system(size: Size.pillIcon, weight: .medium))
                        .foregroundStyle(isActive ? Colors.accent : Colors.text)
                        .overlay {
                            if isSlashed {
                                Capsule()
                                    .fill(isActive ? Colors.accent : Colors.text)
                                    .frame(width: Size.pillSlashWidth, height: Size.pillIcon * 1.35)
                                    .rotationEffect(.degrees(-45))
                                    .shadow(color: Colors.background, radius: 0, x: 1, y: 1)
                            }
                        }

                    if let text {
                        Text(text)
                            .font(Tokens.Typography.pill)
                            .foregroundStyle(Colors.text)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
                .padding(.leading, text == nil ? 0 : Size.pillLeadingPadding)
                .padding(.trailing, text == nil ? 0 : Size.pillTrailingPadding)
                .frame(minWidth: Size.pillHeight, minHeight: Size.pillHeight)
                .background(Capsule().fill(background))
                .overlay {
                    if isActive {
                        Capsule().strokeBorder(Colors.accent, lineWidth: 1)
                    }
                }
                .contentShape(Capsule())
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(isActive ? .isSelected : [])
        }
    }

    /// Borderless icon button (episode skip, jump).
    struct IconButton: View {

        let systemImage: String
        let size: CGFloat
        let iconSize: CGFloat
        let accessibilityLabel: String
        let action: () -> Void

        @ContentBuilder
        var body: some View {
            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.system(size: iconSize, weight: .regular))
                    .foregroundStyle(Tokens.Colors.text)
                    .frame(
                        width: max(size, Tokens.Size.minimumHitTarget),
                        height: max(size, Tokens.Size.minimumHitTarget)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel(accessibilityLabel)
        }
    }
}
