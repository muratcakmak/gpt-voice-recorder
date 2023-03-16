//
//  ContentView.swift
//  voice-recorder
//
//  Created by Oguzhan Cakmak on 16.03.2023.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var isRecording = false
    @State private var audioRecorder: AudioRecorder?
    @State private var recordings: [URL] = []
    
    var body: some View {
        NavigationView{
            VStack {
                List(recordings, id: \.self) { recording in
                    NavigationLink(destination: RecordingDetail(recording: recording)) {
                        Text(recording.lastPathComponent)
                    }
                }
                
                Text("Voice Recorder")
                    .font(.largeTitle)
                    .padding(.bottom, 40)
                
                Circle()
                    .fill(isRecording ? Color.gray : Color.red)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                    )
                    .onTapGesture {
                        if isRecording {
                            audioRecorder?.stopRecording()
                        } else {
                            audioRecorder = AudioRecorder {
                                loadRecordings()
                            }
                            audioRecorder?.startRecording()
                        }
                        isRecording.toggle()
                    }
            }
            .onAppear {
                loadRecordings()
            }
        }
    }
    
    func loadRecordings() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directoryContents = try? FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
        recordings = directoryContents?.filter { $0.pathExtension == "m4a" } ?? []
    }
}

struct RecordingDetail: View {
    let recording: URL
    @State private var audioPlayer: AVAudioPlayer?
    @State private var playbackProgress: Double = 0
    
    var body: some View {
        VStack {
            Text("Duration: \(formattedDuration())")
            Text("Location: \(recording.path)")
            
            Slider(value: $playbackProgress, in: 0...1, step: 0.01, onEditingChanged: { _ in
                if let player = audioPlayer {
                    player.currentTime = player.duration * playbackProgress
                }
            })
            .padding(.horizontal)
            
            Button(action: {
                if audioPlayer?.isPlaying == true {
                    audioPlayer?.pause()
                } else {
                    playRecording()
                }
            }) {
                Image(systemName: audioPlayer?.isPlaying == true ? "pause.fill" : "play.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .navigationTitle("Recording Details")
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            updatePlaybackProgress()
        }
    }
    
    func getDuration() -> TimeInterval {
        let audioAsset = AVURLAsset(url: recording)
        return CMTimeGetSeconds(audioAsset.duration)
    }
    
    func formattedDuration() -> String {
        let duration = getDuration()
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func playRecording() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording)
            audioPlayer?.play()
        } catch {
            print("Failed to play the recording: \(error)")
        }
    }
    func updatePlaybackProgress() {
        if let player = audioPlayer, player.isPlaying {
            playbackProgress = player.currentTime / player.duration
        }
    }
}

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    var audioRecorder: AVAudioRecorder!
    var isRecording = false
    var onRecordingStateChanged: () -> Void
    
    init(onRecordingStateChanged: @escaping () -> Void) {
        self.onRecordingStateChanged = onRecordingStateChanged
    }
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .default)
        try? audioSession.setActive(true)
        
        let fileName = "recording-\(UUID().uuidString).m4a"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFileURL = documentsPath.appendingPathComponent(fileName)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try? AVAudioRecorder(url: audioFileURL, settings: settings)
        audioRecorder.delegate = self
        
        
        if let recorder = audioRecorder {
            isRecording = true
            recorder.record()
            onRecordingStateChanged()
        }
    }
    
    func stopRecording() {
        if isRecording {
            audioRecorder.stop()
            isRecording = false
            onRecordingStateChanged()
        }
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
