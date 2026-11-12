//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// REDESIGN: The redesign is iOS-only (Swiftfin/Views/VideoPlayer/PlayerRedesign).
// This shim gives tvOS the same names so the shared upstream hooks stay
// one-liners, and tvOS keeps its original overlay.

#if os(tvOS)
enum PlayerRedesign {

    static let isActive = false
    static let subtitleScale: CGFloat = 1

    struct Controls: View {

        @ContentBuilder
        var body: some View {
            VideoPlayer.PlaybackControls()
        }
    }
}
#endif
