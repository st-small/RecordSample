import AVFAudio
import Foundation

final class AudioRecorderService {
    
    static let shared = AudioRecorderService()
    
    private let audioSession = AVAudioSession.sharedInstance()
    private var recorder: AVAudioRecorder!
    private let recFormat = AVAudioFormat(
        commonFormat: AVAudioCommonFormat.pcmFormatFloat32,
        sampleRate: 22050,
        channels: 1,
        interleaved: true)!
    
    private init() {
        setCatecoryDefault()
    }
    
    func startRecord(id: String) {
        let recordingURL = getUrl(id: id)
        print("recordingURL \(recordingURL)")
        
        do {
            try audioSession.setCategory(.record, mode: .default, options: .allowBluetooth)
            try audioSession.setActive(true)
            
            enableBuiltInMic()
            start(recordingURL: recordingURL)
            
        } catch {
            preconditionFailure(error.localizedDescription)
        }
    }
    
    func stopRecord() {
        recorder.stop()
        recorder = nil
    }
    
    func cancelRecord(id: String) {
        print("*** Record cancelled ...")
        recorder.stop()
        recorder = nil
        
        do {
            try FileManager.default.removeItem(at: getUrl(id: id))
        } catch {
            preconditionFailure(error.localizedDescription)
        }
    }
    
    private func setCatecoryDefault() {
        do {
            try audioSession.setCategory(.ambient, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Can't set audio category to default")
        }
    }
    
    private func getUrl(id: String) -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory().appending("\(id).wav"))
    }
    
    private func enableBuiltInMic() {
        // Find the built-in microphone input
        guard let availableInputs = audioSession.availableInputs,
              let builtInMicInput = availableInputs.first(where: { $0.portType == .builtInMic }) else {
            preconditionFailure("The device must have a built-in microphone.")
        }
        
        // Make the built-in microphone input the preffered input
        do {
            try audioSession.setPreferredInput(builtInMicInput)
        } catch {
            preconditionFailure("Unable to set the built-in microphone as the preffered input")
        }
    }
    
    private func start(recordingURL: URL) {
        do {
            recorder = try AVAudioRecorder(url: recordingURL, settings: recFormat.settings)
            recorder.record()
            recorder.isMeteringEnabled = true // may be add animation to button like an indicator of sound strenght
        } catch {}
    }
}
