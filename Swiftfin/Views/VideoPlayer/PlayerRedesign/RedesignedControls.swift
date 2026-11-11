//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// REDESIGN: Assembles the redesigned overlay.
//
// It reuses the upstream `VideoPlayerControlsLayout` so safe areas, the
// Info / Episodes drawer, "skip intro" actions and toasts keep working
// exactly as upstream. Only the toolbar, the centre buttons and the progress
// area are replaced by redesigned components.

extension PlayerRedesign {

    struct RedesignedControls: View {

        @Environment(VideoPlayer.ViewState.self)
        private var viewState
        @Environment(MediaSession.self)
        private var mediaSession

        @State
        private var openPanel: PanelKind?

        private var adapter: Adapter {
            Adapter(viewState: viewState, mediaSession: mediaSession)
        }

        private var horizontalMargin: EdgeInsets {
            EdgeInsets(
                top: viewState.systemInsets.top,
                leading: max(viewState.systemInsets.leading, Tokens.Layout.edgeMargin),
                bottom: 0,
                trailing: max(viewState.systemInsets.trailing, Tokens.Layout.edgeMargin)
            )
        }

        // MARK: - Bottom bar (timeline + controls row)

        @ContentBuilder
        private func bottomBar(_ adapter: Adapter) -> some View {
            VStack(spacing: Tokens.Layout.timelineToRowSpacing) {
                if !adapter.isLive {
                    Timeline(adapter: adapter)
                        .isVisible(adapter.showsTimeline)
                        .enabled(adapter.showsTimeline)
                }

                ControlsRow(adapter: adapter, openPanel: $openPanel)
                    .isVisible(adapter.showsControlsRow)
                    .enabled(adapter.showsControlsRow)
            }
            .padding(.bottom, Tokens.Layout.bottomPadding)
            .frame(maxWidth: .infinity)
            .background {
                if adapter.showsTimeline || adapter.showsControlsRow {
                    // Stops taps on the bar from toggling the overlay underneath.
                    EmptyHitTestView()
                }
            }
        }

        // MARK: - Panels

        private func panelTitle(_ kind: PanelKind) -> String {
            switch kind {
            case .audio: Strings.audio
            case .subtitles: Strings.subtitles
            case .speed: Strings.speed
            case .quality: Strings.quality
            }
        }

        private func panelSections(_ kind: PanelKind, adapter: Adapter) -> [PanelSection] {
            switch kind {
            case .audio: adapter.audioSections
            case .subtitles: adapter.subtitleSections
            case .speed: adapter.speedSections
            case .quality: adapter.qualitySections
            }
        }

        private func panelWidth(_ kind: PanelKind) -> CGFloat {
            switch kind {
            case .audio: Tokens.PanelWidth.audio
            case .subtitles: Tokens.PanelWidth.subtitles
            case .speed: Tokens.PanelWidth.speed
            case .quality: Tokens.PanelWidth.quality
            }
        }

        @ContentBuilder
        private func panelOverlay(anchors: [PanelKind: Anchor<CGRect>], adapter: Adapter) -> some View {
            if let kind = openPanel, let anchor = anchors[kind] {
                GeometryReader { proxy in
                    let pill = proxy[anchor]
                    let width = panelWidth(kind)
                    let margin = Tokens.Size.panelScreenMargin
                    let x = min(max(pill.minX, margin), max(margin, proxy.size.width - width - margin))
                    let bottom = pill.minY - Tokens.Size.panelGap
                    let top = Tokens.Layout.topBarHeight + viewState.systemInsets.top

                    ZStack(alignment: .topLeading) {
                        // Tap outside closes the panel.
                        Color.black
                            .opacity(0.001)
                            .contentShape(Rectangle())
                            .onTapGesture { openPanel = nil }
                            .accessibilityHidden(true)

                        VStack {
                            Spacer(minLength: 0)

                            SettingsPanel(
                                title: panelTitle(kind),
                                sections: panelSections(kind, adapter: adapter),
                                maxHeight: max(Tokens.Size.panelRowDouble * 2, bottom - top)
                            ) {
                                openPanel = nil
                            }
                            .frame(width: width)
                        }
                        .frame(height: max(0, bottom))
                        .offset(x: x)
                        .transition(.opacity.combined(with: .offset(y: 8)))
                    }
                }
                .accessibilityAction(.escape) { openPanel = nil }
            }
        }

        // MARK: - Body

        @ContentBuilder
        var body: some View {
            let adapter = adapter

            ZStack(alignment: .top) {
                VideoBackdrop(adapter: adapter)

                VideoPlayerControlsLayout(
                    systemInsets: viewState.systemInsets,
                    edgePadding: Tokens.Layout.edgeMargin,
                    showsProgress: adapter.showsTimeline || adapter.showsControlsRow,
                    showsSupplements: viewState.visibleElements.contains(.supplements),
                    buttonsInsets: viewState.playbackButtonsInsets
                ) {
                    EmptyView()
                } buttons: {
                    EmptyView()
                } progress: {
                    bottomBar(adapter)
                } progressBackground: {
                    EmptyView()
                } actions: {
                    UpstreamOverlayActions()
                } supplements: {
                    UpstreamSupplements()
                } toast: {
                    UpstreamToast()
                }

                TopBar(adapter: adapter)
                    .padding(horizontalMargin)
                    .background(alignment: .top) {
                        if adapter.showsTopBar {
                            EmptyHitTestView()
                                .frame(height: Tokens.Layout.topBarHeight + viewState.systemInsets.top)
                        }
                    }
                    .isVisible(adapter.showsTopBar)
                    .enabled(adapter.showsTopBar)
            }
            .overlayPreferenceValue(PillAnchorKey.self) { anchors in
                panelOverlay(anchors: anchors, adapter: adapter)
            }
            .modifier(UpstreamKeyCommands())
            .environmentObject(viewState.toastProxy)
            .foregroundStyle(Tokens.Colors.text)
            .animation(Tokens.Motion.controls, value: viewState.presentation)
            .animation(Tokens.Motion.controls, value: adapter.isPaused)
            .animation(Tokens.Motion.panel, value: openPanel)
            .animation(.easeInOut(duration: 0.2), value: viewState.toastProxy.isPresenting)
            .onChange(of: openPanel) { _, newValue in
                adapter.setPanelOpen(newValue != nil)
            }
            .onChange(of: adapter.isPresentingControls) { _, isPresenting in
                if !isPresenting {
                    openPanel = nil
                }
            }
            .onDisappear {
                adapter.setPanelOpen(false)
            }
            .disabled(mediaSession.state == .error)
        }
    }
}
