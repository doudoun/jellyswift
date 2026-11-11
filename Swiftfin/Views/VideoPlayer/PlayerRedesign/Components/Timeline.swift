//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// REDESIGN: Timeline: elapsed time, track, remaining time, scrub preview.
// The drag behaviour is upstream's `SliderContainer` (same gesture padding,
// slow scrubbing and commit/cancel as the original progress bar). Only the
// drawing is new, through `TrackStyle`.

extension PlayerRedesign {

    struct Timeline: View {

        let adapter: Adapter

        @State
        private var translation: CGPoint = .zero
        @State
        private var trackWidth: CGFloat = 0

        private typealias Colors = Tokens.Colors
        private typealias Size = Tokens.Size

        /// Same threshold as upstream `PlaybackProgress.isSlowScrubbing`.
        private var isSlowScrubbing: Bool {
            adapter.isScrubbing && translation.y >= 60
        }

        @ContentBuilder
        private var slider: some View {
            SliderContainer(
                value: adapter.scrubValue,
                total: adapter.sliderTotal,
                isScrollingEnabled: adapter.canSeek
            )
            .translation($translation)
            .valueDamping(isSlowScrubbing ? 0.1 : 1)
            .gesturePadding(30)
            .onEditingChanged { isEditing in
                if isEditing {
                    adapter.beginScrub()
                } else {
                    adapter.commitScrub()
                }
            }
            .onEditingCancelled { adapter.cancelScrub() }
            .sliderContainerStyle(TrackStyle())
            .frame(height: Size.knobScrubbing)
            .disabled(!adapter.canSeek)
        }

        @ContentBuilder
        var body: some View {
            HStack(spacing: Tokens.Layout.timelineSpacing) {
                Text(adapter.elapsedText)
                    .font(Tokens.Typography.elapsed)
                    .foregroundStyle(Colors.text)
                    .frame(minWidth: Tokens.Layout.elapsedWidth, alignment: .leading)
                    .fixedSize()

                slider
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { trackWidth = $0 }
                    .overlay(alignment: .bottomLeading) {
                        if adapter.isScrubbing {
                            ScrubPreview(adapter: adapter, isSlowScrubbing: isSlowScrubbing)
                                .offset(x: previewX, y: -(Size.knobScrubbing / 2 + Size.trackHeight / 2 + Size.previewOffset))
                                .transition(.opacity)
                                .allowsHitTesting(false)
                        }
                    }

                Text(adapter.remainingText)
                    .font(Tokens.Typography.remaining)
                    .foregroundStyle(Colors.textSecondary)
                    .frame(minWidth: Tokens.Layout.remainingWidth, alignment: .trailing)
                    .fixedSize()
            }
            .animation(Tokens.Motion.scrub, value: adapter.isScrubbing)
            .onChange(of: isSlowScrubbing) {
                guard adapter.isScrubbing else { return }

                UIDevice.impact(.soft)
            }
            .accessibilityElement(children: .contain)
        }

        /// Keeps the preview centred on the knob, inside the track bounds.
        private var previewX: CGFloat {
            let width = Size.previewSize.width
            let x = trackWidth * adapter.progress - width / 2

            return min(max(x, -Tokens.Layout.elapsedWidth), max(0, trackWidth - width + Tokens.Layout.remainingWidth))
        }
    }

    /// Visual style of the timeline track, plugged into upstream `SliderContainer`.
    struct TrackStyle: SliderContainerStyle {

        @ContentBuilder
        func makeBody(configuration: SliderContainerStyleConfiguration) -> some View {
            let knob = configuration.isEditing ? Tokens.Size.knobScrubbing : Tokens.Size.knob

            GeometryReader { proxy in
                let width = proxy.size.width
                let progress = configuration.progress

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Tokens.Colors.trackBackground)
                        .frame(height: Tokens.Size.trackHeight)

                    Capsule()
                        .fill(Tokens.Colors.accent)
                        .frame(width: max(Tokens.Size.trackHeight, width * progress), height: Tokens.Size.trackHeight)

                    Circle()
                        .fill(Tokens.Colors.knob)
                        .frame(width: knob, height: knob)
                        .shadow(color: Tokens.Colors.knobShadow, radius: Tokens.Shadow.knobRadius, y: Tokens.Shadow.knobY)
                        .offset(x: width * progress - knob / 2)
                }
                .frame(maxHeight: .infinity)
            }
            .animation(Tokens.Motion.scrub, value: configuration.isEditing)
        }
    }

    /// Thumbnail above the knob while scrubbing (trickplay if available,
    /// otherwise the time chip alone).
    struct ScrubPreview: View {

        let adapter: Adapter
        let isSlowScrubbing: Bool

        private typealias Size = Tokens.Size

        @ContentBuilder
        private var timeChip: some View {
            Text(adapter.elapsedText)
                .font(Tokens.Typography.previewChip)
                .foregroundStyle(Tokens.Colors.text)
                .padding(Tokens.Padding.previewChip)
                .background(Capsule().fill(Tokens.Colors.previewChip))
        }

        @ContentBuilder
        var body: some View {
            VStack(spacing: 6) {
                if isSlowScrubbing {
                    Text(L10n.slowScrubbing.localizedCapitalized)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Tokens.Colors.text)
                        .padding(Tokens.Padding.previewChip)
                        .background(Capsule().fill(Tokens.Colors.previewChip))
                }

                if let provider = adapter.previewImageProvider {
                    UpstreamPreviewImage(provider: provider)
                        .frame(width: Size.previewSize.width, height: Size.previewSize.height)
                        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.preview))
                        .overlay {
                            RoundedRectangle(cornerRadius: Tokens.Radius.preview)
                                .strokeBorder(Tokens.Colors.previewBorder, lineWidth: Size.previewBorder)
                        }
                        .overlay(alignment: .bottom) {
                            timeChip.padding(.bottom, 8)
                        }
                        .shadow(color: .black.opacity(0.5), radius: Tokens.Shadow.previewRadius, y: Tokens.Shadow.previewY)
                } else {
                    timeChip
                }
            }
            .frame(width: Size.previewSize.width)
        }
    }
}
