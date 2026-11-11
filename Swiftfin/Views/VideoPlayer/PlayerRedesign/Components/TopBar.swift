//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// REDESIGN: Top bar: round close button, title, season/episode line.

extension PlayerRedesign {

    struct TopBar: View {

        @Router
        private var router

        let adapter: Adapter

        private typealias Colors = Tokens.Colors
        private typealias Size = Tokens.Size

        @ContentBuilder
        private var closeButton: some View {
            Button {
                adapter.close { router.dismiss() }
            } label: {
                Image(systemName: adapter.isPresentingSupplement ? Tokens.Icons.closeSupplement : Tokens.Icons.close)
                    .font(.system(size: Size.closeIcon, weight: .semibold))
                    .foregroundStyle(Colors.text)
                    .frame(width: Size.closeButton, height: Size.closeButton)
                    .overlay(Circle().strokeBorder(Colors.closeBorder, lineWidth: 1))
                    .contentShape(Circle())
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel(Strings.close)
            .accessibilityIdentifier("closePlayerButton")
        }

        @ContentBuilder
        var body: some View {
            HStack(spacing: Tokens.Layout.topBarSpacing) {
                closeButton

                VStack(alignment: .leading, spacing: 2) {
                    Text(adapter.title)
                        .font(Tokens.Typography.title)
                        .foregroundStyle(Colors.text)

                    if let subtitle = adapter.subtitle {
                        Text(subtitle)
                            .font(Tokens.Typography.subtitle)
                            .foregroundStyle(Colors.textSecondary)
                    }
                }
                .lineLimit(1)
                .accessibilityElement(children: .combine)

                Spacer(minLength: 0)
            }
            .frame(height: Tokens.Layout.topBarHeight)
        }
    }
}
