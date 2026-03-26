import FluidAudio
import Foundation
import os

private let diarizationLog = Logger(subsystem: "com.openoats.app", category: "Diarization")

/// Manages speaker diarization for system audio.
/// Wraps FluidAudio's DiarizerManager and exposes a stable interface used by
/// OpenOats for speaker attribution.
actor DiarizationManager {
    private nonisolated(unsafe) let diarizer = DiarizerManager()
    private var isInitialized = false
    private var allSegments: [TimedSpeakerSegment] = []
    private var speakerIndexByID: [String: Int] = [:]
    private var nextSpeakerIndex = 1
    private var nextChunkStartTime: TimeInterval = 0

    /// Load diarization models. Variant is retained for app compatibility.
    func load(variant: DiarizationVariant = .dihard3) async throws {
        diarizationLog.info("Loading diarization model (variant: \(variant.rawValue))")
        let models = try await DiarizerModels.downloadIfNeeded()
        diarizer.initialize(models: models)
        isInitialized = true
        allSegments.removeAll()
        speakerIndexByID.removeAll()
        nextSpeakerIndex = 1
        nextChunkStartTime = 0
        diarizationLog.info("Diarization model loaded")
    }

    /// Feed audio samples to the diarizer. Samples should be at 16kHz mono Float32.
    func feedAudio(_ samples: [Float]) throws {
        guard isInitialized else { return }
        let result = try diarizer.performCompleteDiarization(
            samples,
            sampleRate: 16000,
            atTime: nextChunkStartTime
        )
        allSegments.append(contentsOf: result.segments)
        nextChunkStartTime += Double(samples.count) / 16000.0
    }

    /// Returns the dominant speaker for a given time range in seconds.
    /// Finds which speaker has the most overlap with [startTime, endTime].
    func dominantSpeaker(from startTime: TimeInterval, to endTime: TimeInterval) -> Speaker {
        guard !allSegments.isEmpty else { return .them }
        var bestOverlap: Float = 0
        var bestSpeakerID: String?

        let queryStart = Float(startTime)
        let queryEnd = Float(endTime)

        for segment in allSegments {
            let overlapStart = max(segment.startTimeSeconds, queryStart)
            let overlapEnd = min(segment.endTimeSeconds, queryEnd)
            guard overlapEnd > overlapStart else { continue }
            let overlap = overlapEnd - overlapStart
            if overlap > bestOverlap {
                bestOverlap = overlap
                bestSpeakerID = segment.speakerId
            }
        }
        guard bestOverlap > 0, let bestSpeakerID else { return .them }

        // If only one speaker was detected overall, preserve existing .them behavior.
        let uniqueSpeakerCount = Set(allSegments.map(\.speakerId)).count
        guard uniqueSpeakerCount > 1 else { return .them }

        if let existingIndex = speakerIndexByID[bestSpeakerID] {
            return .remote(existingIndex)
        }

        let index = nextSpeakerIndex
        speakerIndexByID[bestSpeakerID] = index
        nextSpeakerIndex += 1
        return .remote(index)
    }

    /// Finalize the diarization session.
    func finalize() {
        // No-op for current FluidAudio diarizer API.
    }

    /// Reset the diarizer state for a new session.
    func reset() {
        allSegments.removeAll()
        speakerIndexByID.removeAll()
        nextSpeakerIndex = 1
        nextChunkStartTime = 0
        diarizer.speakerManager.reset()
    }
}
