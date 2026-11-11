//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// REDESIGN: Upstream views reused as-is by the redesign. No logic is
// duplicated: upstream keeps owning behaviour. If an upstream update
// renames one of these types, fix it here only.

extension PlayerRedesign {

    enum Upstream {

        typealias ActionButtons = VideoPlayer.PlaybackControls.Toolbar.ActionButtons
    }

    /// Upstream action button views, shown untouched in the "more" menu.
    /// Mirrors the switch in upstream `ActionButtons.view(for:)`.
    struct UpstreamAction: View {

        private typealias Buttons = Upstream.ActionButtons

        let button: VideoPlayerActionButton

        @ContentBuilder
        var body: some View {
            switch button {
            case .aspectFill:
                Buttons.AspectFill()
            case .audio:
                Buttons.Audio()
            case .audioOffset:
                Buttons.AudioOffset()
            case .autoPlay:
                Buttons.AutoPlay()
            case .pictureInPicture:
                Buttons.PictureInPicture()
            case .playbackSpeed:
                Buttons.PlaybackRateMenu()
            case .playbackSettings:
                Buttons.PlaybackSettings()
            case .playNextItem:
                Buttons.PlayNextItem()
            case .playPreviousItem:
                Buttons.PlayPreviousItem()
            case .nextChapter:
                Buttons.NextChapter()
            case .previousChapter:
                Buttons.PreviousChapter()
            case .subtitles:
                Buttons.Subtitles()
            case .gestureLock:
                Buttons.GestureLock()
            case .playbackDestination:
                Buttons.PlaybackDestination()
            case .subtitleOffset:
                Buttons.SubtitleOffset()
            }
        }
    }

    /// Upstream Info / Episodes / ... drawer, kept exactly as upstream shows it.
    struct UpstreamSupplements: View {

        @Environment(VideoPlayer.ViewState.self)
        private var viewState

        @ContentBuilder
        var body: some View {
            VideoPlayer.UIContainerViewController.SupplementContainerView()
                .frame(height: viewState.supplementHeight)
                .frame(
                    height: max(0, viewState.supplementVisibleHeight - viewState.systemInsets.bottom),
                    alignment: .top
                )
                .allowsHitTesting(viewState.visibleElements.contains(.supplements))
        }
    }

    /// Upstream "skip intro"-style overlay actions.
    struct UpstreamOverlayActions: View {

        @ContentBuilder
        var body: some View {
            VideoPlayer.OverlayActions()
        }
    }

    /// Upstream toast (errors, notices).
    struct UpstreamToast: View {

        @Environment(VideoPlayer.ViewState.self)
        private var viewState

        @ContentBuilder
        var body: some View {
            if viewState.toastProxy.isPresenting {
                OverlayToastContent()
                    .environmentObject(viewState.toastProxy)
                    .transition(.offset(y: -20).combined(with: .opacity))
            }
        }
    }

    /// Upstream trickplay thumbnail for the scrub position.
    struct UpstreamPreviewImage: View {

        let provider: PreviewImageProvider

        @ContentBuilder
        var body: some View {
            VideoPlayer.PlaybackControls.PreviewImageView(previewImageProvider: provider)
        }
    }

    /// Upstream keyboard shortcuts (space, arrows...).
    struct UpstreamKeyCommands: ViewModifier {

        @ContentBuilder
        func body(content: Content) -> some View {
            content.modifier(VideoPlayer.KeyCommandsModifier())
        }
    }
}
