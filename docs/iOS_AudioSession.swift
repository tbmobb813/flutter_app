// Add to AppDelegate or a small Flutter plugin Swift file
import AVFAudio


func setupAudioSession() {
do {
let session = AVAudioSession.sharedInstance()
try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
try session.setActive(true)
} catch {
print("Audio session error: \(error)")
}
}