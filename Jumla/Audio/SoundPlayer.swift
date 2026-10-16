import AVFoundation
import Foundation

/// Synthesized SFX via AVAudioEngine (no asset files).
@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()

    private var engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var unlocked = false
    var isMuted = false

    private init() {}

    func unlock() {
        guard !unlocked else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            _ = engine.mainMixerNode
            try engine.start()
            unlocked = true
        } catch {
            // UI still works without audio.
        }
    }

    func playSelect() { tone(freq: 720, duration: 0.06, volume: 0.12, wave: .sine) }
    func playMiss() { tone(freq: 160, duration: 0.12, volume: 0.14, wave: .triangle) }
    func playFall() { tone(freq: 360, duration: 0.22, volume: 0.08, wave: .saw, sweepTo: 140) }
    func playSuccess() {
        tone(freq: 523, duration: 0.12, volume: 0.12, wave: .sine, delay: 0)
        tone(freq: 659, duration: 0.12, volume: 0.12, wave: .sine, delay: 0.08)
        tone(freq: 784, duration: 0.18, volume: 0.12, wave: .sine, delay: 0.16)
    }

    func playExplode(index: Int = 0) {
        let delay = Double(index) * 0.05
        noise(duration: 0.16, volume: 0.22, delay: delay)
        tone(freq: 140, duration: 0.14, volume: 0.18, wave: .sine, sweepTo: 55, delay: delay)
    }

    func playSpawn(index: Int = 0) {
        let f = 520.0 + Double(index) * 40
        tone(freq: f, duration: 0.09, volume: 0.1, wave: .sine, sweepTo: f + 200, delay: Double(index) * 0.04)
    }

    private enum Wave { case sine, triangle, saw }

    private func tone(
        freq: Double,
        duration: Double,
        volume: Float,
        wave: Wave,
        sweepTo: Double? = nil,
        delay: Double = 0
    ) {
        guard !isMuted else { return }
        unlock()
        guard unlocked else { return }
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let sampleRate = format.sampleRate
        guard sampleRate > 0 else { return }
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        guard let data = buffer.floatChannelData else { return }
        let end = sweepTo ?? freq
        let channels = Int(format.channelCount)
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let progress = Double(i) / Double(max(frameCount - 1, 1))
            let f = freq + (end - freq) * progress
            let phase = 2 * Double.pi * f * t
            let raw: Double
            switch wave {
            case .sine: raw = sin(phase)
            case .triangle:
                raw = 2 * abs(2 * (t * f - floor(t * f + 0.5))) - 1
            case .saw:
                raw = 2 * (t * f - floor(t * f)) - 1
            }
            let sample = Float(raw) * volume * Float(exp(-progress * 4.5))
            for ch in 0..<channels { data[ch][i] = sample }
        }
        play(buffer: buffer, delay: delay)
    }

    private func noise(duration: Double, volume: Float, delay: Double) {
        guard !isMuted else { return }
        unlock()
        guard unlocked else { return }
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        guard let data = buffer.floatChannelData else { return }
        let channels = Int(format.channelCount)
        for i in 0..<Int(frameCount) {
            let progress = Double(i) / Double(max(frameCount - 1, 1))
            let sample = Float.random(in: -1...1) * volume * Float(pow(1 - progress, 2.2))
            for ch in 0..<channels { data[ch][i] = sample }
        }
        play(buffer: buffer, delay: delay)
    }

    private func play(buffer: AVAudioPCMBuffer, delay: Double) {
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: buffer.format)
        players.append(player)

        let start = {
            player.scheduleBuffer(buffer, at: nil, options: []) { [weak self, weak player] in
                Task { @MainActor in
                    guard let self, let player else { return }
                    self.engine.detach(player)
                    self.players.removeAll { $0 === player }
                }
            }
            player.play()
        }

        if delay <= 0 {
            start()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: start)
        }
    }
}
