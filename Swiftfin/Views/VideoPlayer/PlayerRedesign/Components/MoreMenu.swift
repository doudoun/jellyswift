//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// REDESIGN: "More" pill. Opens a native menu holding the upstream buttons that
// have no dedicated place in the redesign (PiP, gesture lock, auto play,
// offsets, chapters, playback destination). Behaviour stays 100% upstream.

extension PlayerRedesign {

    struct MoreMenu: View {

        @Environment(\.accessibilityReduceTransparency)
        private var reduceTransparency

        let adapter: Adapter

        @ContentBuilder
        var body: some View {
            let actions = adapter.moreActions

            if actions.isNotEmpty {
                Menu {
                    ForEach(actions, id: \.self) { action in
                        UpstreamAction(button: action)
                    }
                    .withViewContext(.isInMenu)
                } label: {
                    Image(systemName: Tokens.Icons.more)
                        .font(.system(size: Tokens.Size.pillIcon, weight: .semibold))
                        .foregroundStyle(Tokens.Colors.text)
                        .frame(width: Tokens.Size.pillHeight, height: Tokens.Size.pillHeight)
                        .background(
                            Capsule().fill(reduceTransparency ? Tokens.Colors.pillReducedTransparency : Tokens.Colors.pill)
                        )
                        .contentShape(Capsule())
                }
                .menuOrder(.fixed)
                .accessibilityLabel(Strings.more)
            }
        }
    }
}
