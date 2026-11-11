//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

// REDESIGN: Thin adaptation layer between upstream player logic and the
// redesigned views. This is the ONLY place (with UpstreamActions.swift) that
// reads upstream player types. Every action forwards to the exact upstream
// call the original buttons use, so behaviour is unchanged.
//
// If an upstream update breaks the build, fix this file first.

extension PlayerRedesign {

    struct PanelOption: Identifiable {

        let id: String
        let title: String
        var detail: String?
        let isSelected: Bool
        let action: @MainActor () -> Void
    }

    struct PanelSection: Identifiable {

        let id: String
        var title: String?
        let options: [PanelOption]
    }

    struct PillValue {

        /// Short text shown in the pill, e.g. "EN".
        let short: String
        /// Long text read by VoiceOver, e.g. "English".
        let spoken: String
    }

    @MainActor
    struct Adapter {

        typealias ViewState = VideoPlayer.ViewState

        let viewState: ViewState
        let mediaSession: MediaSession

        /// Upstream uses `Interaction.menu` to pause auto-hide while a menu is open.
        private static let panelInteractionID = UUID()

        // MARK: - Metadata

        private var item: BaseItemDto {
            mediaSession.item
        }

        var title: String {
            if item.type == .episode, let parentTitle = item.parentTitle {
                return parentTitle
            }

            return item.displayTitle
        }

        var subtitle: String? {
            guard item.type == .episode,
                  let season = item.parentIndexNumber,
                  let episode = item.indexNumber
            else { return nil }

            return Strings.seasonEpisode(season: season, episode: episode)
        }

        // MARK: - Visibility (driven by upstream ViewState)

        /// Upstream hides everything but the progress bar while scrubbing.
        /// The redesign keeps the full overlay visible when scrubbing started
        /// from the controls (visual choice only, no state is changed).
        private var isScrubbingFromControls: Bool {
            viewState.isScrubbing && viewState.presentation == .controls
        }

        var showsTopBar: Bool {
            viewState.visibleElements.contains(.toolbar) || isScrubbingFromControls
        }

        var showsTimeline: Bool {
            viewState.isPresentingProgress
        }

        var showsControlsRow: Bool {
            viewState.visibleElements.contains(.playbackButtons) || isScrubbingFromControls
        }

        var showsScrim: Bool {
            (viewState.visibleElements.contains(.dimming) || isScrubbingFromControls)
                && !viewState.isPresentingSupplement
                && !viewState.isTabletop
        }

        var showsPauseDim: Bool {
            showsScrim && isPaused
        }

        var showsHiddenProgress: Bool {
            !viewState.isPresentingProgress
                && !viewState.isPresentingSupplement
                && !isLive
                && runtime > .zero
        }

        var isPresentingControls: Bool {
            viewState.isPresentingControls
        }

        var isPresentingSupplement: Bool {
            viewState.isPresentingSupplement
        }

        var isScrubbing: Bool {
            viewState.isScrubbing
        }

        // MARK: - Playback

        var isLive: Bool {
            item.isLiveStream
        }

        var isPaused: Bool {
            mediaSession.playbackRequestStatus == .paused
        }

        var isLoading: Bool {
            mediaSession.activity == .loading || mediaSession.playbackState.isBuffering
        }

        var canControlPlayback: Bool {
            mediaSession.canControlPlayback
        }

        var canSeek: Bool {
            mediaSession.canSeek
        }

        func togglePlayPause() {
            switch mediaSession.playbackRequestStatus {
            case .playing:
                mediaSession.setPlaybackRequestStatus(status: .paused)
            case .paused:
                mediaSession.setPlaybackRequestStatus(status: .playing)
            }
        }

        func close(dismiss: () -> Void) {
            if viewState.isPresentingSupplement {
                viewState.selectedSupplementID = nil
            } else {
                mediaSession.stop()
                dismiss()
            }
        }

        // MARK: - Time

        var runtime: Duration {
            item.runtime ?? .zero
        }

        /// Current position, or the finger position while scrubbing.
        var displayedSeconds: Duration {
            viewState.scrubbedSeconds
        }

        var progress: Double {
            let total = runtime.seconds
            guard total.isFinite, total > 0 else { return 0 }

            let value = displayedSeconds.seconds / total
            guard value.isFinite else { return 0 }

            return min(max(value, 0), 1)
        }

        var elapsedText: String {
            StreamFormatting.time(displayedSeconds)
        }

        var remainingText: String {
            StreamFormatting.remaining(max(.zero, runtime - displayedSeconds))
        }

        /// Live progress for the thin line shown while controls are hidden.
        /// Upstream freezes `scrubbedSeconds` when hidden, so read the session.
        var liveProgress: Double {
            let total = runtime.seconds
            guard total.isFinite, total > 0 else { return 0 }

            let value = mediaSession.seconds.seconds / total
            guard value.isFinite else { return 0 }

            return min(max(value, 0), 1)
        }

        var sliderTotal: Double {
            let total = runtime.seconds
            guard total.isFinite, total > 0 else { return 1 }

            return total
        }

        var scrubValue: Binding<Double> {
            Binding(
                get: { viewState.scrubbedSeconds.seconds },
                set: { viewState.scrubbedSeconds = .seconds($0) }
            )
        }

        func beginScrub() {
            viewState.beginScrub()
        }

        func commitScrub() {
            viewState.commitScrub()
        }

        func cancelScrub() {
            viewState.cancelScrub()
        }

        var previewImageProvider: PreviewImageProvider? {
            mediaSession.playbackItem?.previewImageProvider
        }

        var videoAspectRatio: CGFloat {
            guard let ratio = (mediaSession.player as? any VideoMediaPlayer)?.videoState.videoSize.aspectRatio,
                  ratio.isFinite,
                  ratio > 0
            else { return 16 / 9 }

            return min(max(ratio, 0.25), 4)
        }

        /// Frame of the visible picture inside the player, in player coordinates.
        func videoFrame(in size: CGSize) -> CGRect {
            let bounds = CGRect(origin: .zero, size: size)
            guard !viewState.isVideoEnlarged, size.width > 0, size.height > 0 else { return bounds }

            let ratio = videoAspectRatio
            var frame = bounds

            if size.width / size.height > ratio {
                frame.size.width = size.height * ratio
                frame.origin.x = (size.width - frame.width) / 2
            } else {
                frame.size.height = size.width / ratio
                frame.origin.y = (size.height - frame.height) / 2
            }

            return frame
        }

        // MARK: - Jump

        var jumpBackwardInterval: MediaJumpInterval {
            Defaults[.VideoPlayer.jumpBackwardInterval]
        }

        var jumpForwardInterval: MediaJumpInterval {
            Defaults[.VideoPlayer.jumpForwardInterval]
        }

        var jumpBackwardSystemImage: String {
            jumpBackwardInterval.secondarySystemImage
        }

        var jumpForwardSystemImage: String {
            jumpForwardInterval.systemImage
        }

        var jumpBackwardSeconds: Int {
            Int(jumpBackwardInterval.rawValue.seconds.rounded())
        }

        var jumpForwardSeconds: Int {
            Int(jumpForwardInterval.rawValue.seconds.rounded())
        }

        var showsJumpButtons: Bool {
            !isLive
        }

        func jumpBackward() {
            _ = mediaSession.seek(by: .zero - jumpBackwardInterval.rawValue)
        }

        func jumpForward() {
            _ = mediaSession.seek(by: jumpForwardInterval.rawValue)
        }

        // MARK: - Episodes (queue)

        var showsEpisodeButtons: Bool {
            mediaSession.queue != nil
        }

        var canPlayPrevious: Bool {
            mediaSession.queue?.previousItem != nil
        }

        var canPlayNext: Bool {
            mediaSession.queue?.nextItem != nil
        }

        func playPrevious() {
            guard let previous = mediaSession.queue?.previousItem else { return }

            _ = mediaSession.playNewItem(intent: previous)
        }

        func playNext() {
            guard let next = mediaSession.queue?.nextItem else { return }

            _ = mediaSession.playNewItem(intent: next)
        }

        // MARK: - Aspect fill

        var showsAspectFill: Bool {
            !mediaSession.isRemotePlayback
        }

        var isVideoEnlarged: Bool {
            viewState.isVideoEnlarged
        }

        var aspectFillSystemImage: String {
            isVideoEnlarged ? Tokens.Icons.fit : Tokens.Icons.fill
        }

        func toggleAspectFill() {
            viewState.toggleAspectFillBehavior()
        }

        // MARK: - Panels

        func setPanelOpen(_ isOpen: Bool) {
            viewState.setInteraction(.menu(Self.panelInteractionID), active: isOpen)
        }

        // MARK: - Audio

        var showsAudio: Bool {
            mediaSession.playbackItem?.audioStreams.isEmpty == false
        }

        var audioValue: PillValue {
            guard let playbackItem = mediaSession.playbackItem,
                  let stream = playbackItem.audioStreams.first(where: { $0.index == playbackItem.selectedAudioStreamIndex })
            else { return PillValue(short: "–", spoken: Strings.none) }

            return PillValue(short: StreamFormatting.shortLanguage(stream), spoken: StreamFormatting.languageName(stream))
        }

        var audioSections: [PanelSection] {
            guard let playbackItem = mediaSession.playbackItem else { return [] }

            let options = playbackItem.audioStreams.map { stream in
                PanelOption(
                    id: "audio-\(stream.index ?? -1)",
                    title: StreamFormatting.languageName(stream),
                    detail: StreamFormatting.audioDetail(stream),
                    isSelected: stream.index == playbackItem.selectedAudioStreamIndex,
                    action: { playbackItem.selectedAudioStreamIndex = stream.index }
                )
            }

            return [PanelSection(id: "audio", options: options)]
        }

        // MARK: - Subtitles

        var showsSubtitles: Bool {
            mediaSession.playbackItem?.subtitleStreams.isEmpty == false
        }

        var canSelectSubtitles: Bool {
            mediaSession.canControlPlayback
        }

        var subtitleValue: PillValue {
            guard let playbackItem = mediaSession.playbackItem, playbackItem.subtitlesEnabled else {
                return PillValue(short: Strings.subtitlesOffShort, spoken: Strings.none)
            }

            let index = playbackItem.subtitleTrackIndex(secondary: false)

            guard let stream = playbackItem.subtitleStreams.first(where: { $0.index == index }) else {
                return PillValue(short: Strings.subtitlesOffShort, spoken: Strings.none)
            }

            return PillValue(short: StreamFormatting.shortLanguage(stream), spoken: StreamFormatting.subtitleTitle(stream))
        }

        var subtitleSections: [PanelSection] {
            guard let playbackItem = mediaSession.playbackItem else { return [] }

            let isEnabled = playbackItem.subtitlesEnabled
            let primaryIndex = playbackItem.subtitleTrackIndex(secondary: false)

            var primary = [
                PanelOption(
                    id: "subtitle-none",
                    title: Strings.none,
                    isSelected: !isEnabled || primaryIndex < 0,
                    action: { playbackItem.setSubtitlesEnabled(false) }
                ),
            ]

            primary += playbackItem.subtitleStreams
                .filter { ($0.index ?? -1) >= 0 }
                .map { stream in
                    let index = stream.index ?? -1

                    return PanelOption(
                        id: "subtitle-\(index)",
                        title: StreamFormatting.subtitleTitle(stream),
                        detail: StreamFormatting.subtitleDetail(stream),
                        isSelected: isEnabled && index == primaryIndex,
                        action: {
                            // Same two calls as the upstream subtitle menu (track, then on).
                            playbackItem.setSubtitleTrack(index: index, secondary: false)
                            playbackItem.setSubtitlesEnabled(true)
                        }
                    )
                }

            var sections = [PanelSection(id: "subtitle-primary", options: primary)]

            if playbackItem.supportsSecondarySubtitles {
                let secondaryIndex = playbackItem.subtitleTrackIndex(secondary: true)

                var secondary = [
                    PanelOption(
                        id: "subtitle-secondary-none",
                        title: Strings.none,
                        isSelected: secondaryIndex < 0,
                        action: { playbackItem.setSubtitleTrack(index: -1, secondary: true) }
                    ),
                ]

                secondary += playbackItem.secondarySubtitleStreams
                    .filter { ($0.index ?? -1) >= 0 && $0.index != primaryIndex }
                    .map { stream in
                        let index = stream.index ?? -1

                        return PanelOption(
                            id: "subtitle-secondary-\(index)",
                            title: StreamFormatting.subtitleTitle(stream),
                            detail: StreamFormatting.subtitleDetail(stream),
                            isSelected: index == secondaryIndex,
                            action: { playbackItem.setSubtitleTrack(index: index, secondary: true) }
                        )
                    }

                sections[0].title = Strings.primaryTrack
                sections.append(PanelSection(id: "subtitle-secondary", title: Strings.secondaryTrack, options: secondary))
            }

            return sections
        }

        // MARK: - Speed

        var showsSpeed: Bool {
            !isLive
        }

        var speedValue: PillValue {
            let text = StreamFormatting.rate(mediaSession.effectiveRate)
            return PillValue(short: text, spoken: text)
        }

        var speedSections: [PanelSection] {
            let supportedRates = mediaSession.player?.supportedRates ?? 0.1 ... 5
            let current = mediaSession.effectiveRate
            var rates = Defaults[.VideoPlayer.Playback.rates].filter { supportedRates.contains($0) }

            if !rates.contains(current) {
                rates.append(current)
                rates.sort()
            }

            let options = rates.map { rate in
                PanelOption(
                    id: "rate-\(rate)",
                    title: StreamFormatting.rate(rate),
                    isSelected: rate == current,
                    action: { mediaSession.rate = rate }
                )
            }

            let custom = PanelOption(
                id: "rate-custom",
                title: L10n.custom,
                isSelected: false,
                action: {
                    viewState.presentGuestSupplement(PlaybackAdjustmentSupplement.playbackSpeed(range: supportedRates))
                }
            )

            return [
                PanelSection(id: "rates", options: options),
                PanelSection(id: "rates-custom", options: [custom]),
            ]
        }

        // MARK: - Quality

        var showsQuality: Bool {
            !isLive && VideoPlayer.PlaybackControls.Toolbar.ActionButtons.PlaybackSettings.isAvailable(for: mediaSession.playbackItem)
        }

        var qualityValue: PillValue {
            let bitrate = mediaSession.playbackItem?.configuration.requestedBitrate ?? .auto

            switch bitrate {
            case .auto:
                return PillValue(short: Strings.automaticShort, spoken: Strings.automatic)
            case .max:
                return PillValue(short: Strings.maximumShort, spoken: bitrate.displayTitle)
            default:
                return PillValue(short: bitrate.displayTitle, spoken: bitrate.displayTitle)
            }
        }

        var qualitySections: [PanelSection] {
            guard let playbackItem = mediaSession.playbackItem else { return [] }

            var sections: [PanelSection] = []

            let bitrates = playbackItem.mediaSource.supportedBitrates
            let currentBitrate = playbackItem.configuration.requestedBitrate

            if bitrates.isNotEmpty {
                sections.append(PanelSection(
                    id: "bitrate",
                    title: Strings.bitrate,
                    options: bitrates.map { bitrate in
                        PanelOption(
                            id: "bitrate-\(bitrate.rawValue)",
                            title: bitrate == .auto ? Strings.automatic : bitrate.displayTitle,
                            isSelected: bitrate == currentBitrate,
                            action: {
                                guard bitrate != playbackItem.configuration.requestedBitrate else { return }

                                mediaSession.setBitrate(bitrate: bitrate)
                            }
                        )
                    }
                ))
            }

            if playbackItem.baseItem.mediaType == .video {
                let currentResolution = playbackItem.configuration.maxResolution

                sections.append(PanelSection(
                    id: "resolution",
                    title: Strings.resolution,
                    options: PlaybackResolution.allCases.map { resolution in
                        PanelOption(
                            id: "resolution-\(resolution.rawValue)",
                            title: resolution.displayTitle,
                            isSelected: resolution == currentResolution,
                            action: {
                                guard resolution != playbackItem.configuration.maxResolution else { return }

                                mediaSession.setResolution(resolution: resolution)
                            }
                        )
                    }
                ))
            }

            let versions = playbackItem.baseItem.mediaSources ?? []

            if versions.count > 1 {
                let currentID = playbackItem.mediaSource.id

                sections.append(PanelSection(
                    id: "version",
                    title: Strings.version,
                    options: versions.map { version in
                        PanelOption(
                            id: "version-\(version.id ?? "")",
                            title: version.displayTitle,
                            isSelected: version.id == currentID,
                            action: {
                                guard let id = version.id, id != playbackItem.mediaSource.id else { return }

                                var intent = playbackItem.resumingIntent(at: mediaSession.seconds)
                                intent.configuration.selectMediaSource(id: id)
                                _ = mediaSession.playNewItem(intent: intent)
                            }
                        )
                    }
                ))
            }

            if sections.count == 1 {
                sections[0].title = nil
            }

            return sections
        }

        // MARK: - More menu

        /// Upstream action buttons that have no dedicated place in the redesign.
        /// They are shown, untouched, in the "more" menu. The user's own
        /// bar/menu button configuration is respected.
        var moreActions: [VideoPlayerActionButton] {
            let configured = Defaults[.VideoPlayer.barActionButtons] + Defaults[.VideoPlayer.menuActionButtons]
            let handledByRedesign: Set<VideoPlayerActionButton> = [
                .audio,
                .subtitles,
                .playbackSpeed,
                .playbackSettings,
                .playNextItem,
                .playPreviousItem,
                .aspectFill,
            ]

            var seen = Set<VideoPlayerActionButton>()

            return configured.filter { button in
                guard !handledByRedesign.contains(button), seen.insert(button).inserted else { return false }

                return isMoreActionAvailable(button)
            }
        }

        /// Mirrors the filters of upstream `ActionButtons.resolvedActionButtons`.
        /// Re-check this list against upstream after each update.
        private func isMoreActionAvailable(_ button: VideoPlayerActionButton) -> Bool {
            switch button {
            case .playbackDestination:
                return Defaults[.Experimental.chromecast]

            case .pictureInPicture:
                return !mediaSession.isRemotePlayback

            case .audioOffset:
                return showsAudio && mediaSession.player is MediaPlayerOffsetProviding

            case .subtitleOffset:
                return showsSubtitles && mediaSession.player is MediaPlayerOffsetProviding

            case .autoPlay:
                return mediaSession.queue != nil && !isLive

            case .nextChapter, .previousChapter:
                let chapterCount = viewState.supplements
                    .compactMap { $0 as? MediaChaptersSupplement }
                    .first?
                    .chapters
                    .count ?? 0
                return chapterCount >= 2

            default:
                return true
            }
        }
    }
}
