//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// REDESIGN: Layers drawn over the picture, under the controls:
// bottom scrim, pause dim, and the thin progress line when controls are hidden.
// Never hit-testable: gestures keep going to upstream.

extension PlayerRedesign {

    struct VideoBackdrop: View {

        let adapter: Adapter

        @ContentBuilder
        var body: some View {
            GeometryReader { proxy in
                let videoFrame = adapter.videoFrame(in: proxy.size)
                let belowVideo = max(0, proxy.size.height - videoFrame.maxY)

                ZStack(alignment: .topLeading) {
                    Tokens.Colors.pauseDim
                        .frame(width: videoFrame.width, height: videoFrame.height)
                        .offset(x: videoFrame.minX, y: videoFrame.minY)
                        .opacity(adapter.showsPauseDim ? 1 : 0)

                    LinearGradient(
                        colors: [Tokens.Colors.scrim.opacity(0), Tokens.Colors.scrim],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: proxy.size.width, height: Tokens.Layout.scrimHeight + belowVideo)
                    .offset(y: proxy.size.height - Tokens.Layout.scrimHeight - belowVideo)
                    .opacity(adapter.showsScrim ? 1 : 0)

                    if Tokens.Options.showsProgressLineWhenHidden, adapter.showsHiddenProgress {
                        HiddenProgressLine(adapter: adapter)
                            .frame(width: videoFrame.width, height: Tokens.Size.hiddenTrackHeight)
                            .offset(
                                x: videoFrame.minX,
                                y: min(videoFrame.maxY, proxy.size.height) - Tokens.Size.hiddenTrackHeight
                            )
                            .transition(.opacity)
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    /// Kept in its own view: it observes the live position, so only this
    /// small view re-renders on every time update.
    struct HiddenProgressLine: View {

        let adapter: Adapter

        @ContentBuilder
        var body: some View {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Tokens.Colors.hiddenTrackBackground

                    Tokens.Colors.accent
                        .opacity(Tokens.Colors.hiddenTrackOpacity)
                        .frame(width: proxy.size.width * adapter.liveProgress)
                }
            }
        }
    }
}
