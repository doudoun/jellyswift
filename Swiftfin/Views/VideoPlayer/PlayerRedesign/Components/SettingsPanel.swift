//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// REDESIGN: Custom panel replacing the native Menu for Audio, Subtitles,
// Speed and Quality. Options come from the adapter; selecting one runs the
// upstream action immediately, then closes the panel.

extension PlayerRedesign {

    struct SettingsPanel: View {

        @Environment(\.accessibilityReduceTransparency)
        private var reduceTransparency

        let title: String
        let sections: [PanelSection]
        let maxHeight: CGFloat
        let onSelect: () -> Void

        @State
        private var contentHeight: CGFloat = 0

        private typealias Colors = Tokens.Colors

        @ContentBuilder
        private var content: some View {
            VStack(alignment: .leading, spacing: 0) {
                Text(title.uppercased())
                    .font(Tokens.Typography.panelHeader)
                    .tracking(Tokens.Typography.panelHeaderTracking)
                    .foregroundStyle(Colors.accent)
                    .padding(Tokens.Padding.panelHeader)
                    .accessibilityAddTraits(.isHeader)

                ForEach(Array(sections.enumerated()), id: \.element.id) { offset, section in
                    if offset > 0 {
                        Divider()
                            .overlay(Colors.panelBorder)
                            .padding(.horizontal, Tokens.Padding.panelRowHorizontal)
                            .padding(.vertical, 6)
                    }

                    if let sectionTitle = section.title {
                        Text(sectionTitle)
                            .font(Tokens.Typography.panelRowDetail.weight(.semibold))
                            .foregroundStyle(Colors.textSecondary)
                            .padding(.horizontal, Tokens.Padding.panelRowHorizontal)
                            .padding(.top, 4)
                            .padding(.bottom, 2)
                            .accessibilityAddTraits(.isHeader)
                    }

                    ForEach(section.options) { option in
                        PanelRow(option: option) {
                            option.action()
                            onSelect()
                        }
                    }
                }
            }
            .padding(Tokens.Padding.panel)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        }

        @ContentBuilder
        var body: some View {
            ScrollView(.vertical) {
                content
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.automatic)
            .frame(height: min(max(contentHeight, 1), maxHeight))
            .background {
                RoundedRectangle(cornerRadius: Tokens.Radius.panel)
                    .fill(reduceTransparency ? Colors.panelReducedTransparency : Colors.panel)
            }
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.panel))
            .overlay {
                RoundedRectangle(cornerRadius: Tokens.Radius.panel)
                    .strokeBorder(Colors.panelBorder, lineWidth: 1)
            }
            .shadow(color: Colors.panelShadow, radius: Tokens.Shadow.panelRadius, y: Tokens.Shadow.panelY)
            .environment(\.colorScheme, .dark)
        }
    }

    struct PanelRow: View {

        let option: PanelOption
        let action: () -> Void

        private typealias Colors = Tokens.Colors

        @ContentBuilder
        var body: some View {
            Button(action: action) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(option.title)
                            .font(option.isSelected ? Tokens.Typography.panelRowSelected : Tokens.Typography.panelRow)
                            .foregroundStyle(Colors.text)

                        if let detail = option.detail {
                            Text(detail)
                                .font(Tokens.Typography.panelRowDetail)
                                .foregroundStyle(option.isSelected ? Colors.textSelectedDetail : Colors.textSecondary)
                        }
                    }
                    .lineLimit(1)

                    Spacer(minLength: 0)

                    if option.isSelected {
                        Image(systemName: Tokens.Icons.checkmark)
                            .font(.system(size: Tokens.Size.panelCheck, weight: .bold))
                            .foregroundStyle(Colors.accent)
                    }
                }
                .padding(.horizontal, Tokens.Padding.panelRowHorizontal)
                .frame(height: option.detail == nil ? Tokens.Size.panelRowSingle : Tokens.Size.panelRowDouble)
                .background {
                    RoundedRectangle(cornerRadius: Tokens.Radius.panelRow)
                        .fill(option.isSelected ? Colors.accentFill : .clear)
                }
                .contentShape(RoundedRectangle(cornerRadius: Tokens.Radius.panelRow))
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityAddTraits(option.isSelected ? .isSelected : [])
        }
    }
}
