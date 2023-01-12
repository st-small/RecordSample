//
//  ConversationScreen.swift
//  RecordSample
//
//  Created by Stanly Shiyanovskiy on 28.12.2022.
//

import PopupView
import SwiftUI

struct ErrorMessage {
    var error: String
    
    var isNotEmpty: Bool {
        get { !error.isEmpty }
        set { error = "" }
    }
}

enum ConversationPanelState {
    case main, recordAudio
}

struct ConversationScreenConnector: Connector {
    func map(store: Store<AppState, AppAction>) -> some View {
        var errorMessage = ErrorMessage(error: "")
        var isRecording = false
        
        switch store.state.recordAudioState {
        case .pending, .recordingCompete, .recordingCancel:
            break
        case .startRecord:
            isRecording = true
        case .error(let errorText):
            errorMessage.error = errorText
        }

        return ConversationScreen(
            textFieldValue: Binding(
                get: { "" },
                set: { _ in }
            ),
            errorMessage: Binding(
                get: { errorMessage },
                set: { _ in store.dispatch(.errorDismiss) }
            ),
            showRecordPanel: isRecording,
            showAttachmentButton: !isRecording,
            showTextField: !isRecording,
            showEmojiIcon: !isRecording,
            onOpenRecordAudioPanel: {
                store.dispatch(.startRecordSession)
            },
            onCancelRecordAudio: {
                store.dispatch(.cancelRecordSession)
            },
            onCloseRecordAudioPanel: {
                store.dispatch(.endRecordSession)
            }
        )
    }
}

struct ConversationScreen: View {
    
    // MARK: - Props
    @Binding var textFieldValue: String
    @Binding var errorMessage: ErrorMessage
    
    var showRecordPanel: Bool
    var showAttachmentButton: Bool = false
    var showTextField: Bool = false
    var showEmojiIcon: Bool = false
    
    @State private var timerLabel = "00:00"
    @State private var timerCounter = 0
    @State private var isRecordLocked: Bool = false
    
    private let timer = Timer
        .publish(every: 1, on: .main, in: .common)
        .autoconnect()
    
    // MARK: - Commands
    var onOpenRecordAudioPanel: () -> Void
    var onCancelRecordAudio: () -> Void
    var onCloseRecordAudioPanel: () -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                messagesContainer
                
                bottomPanel
            }
        }
        .onReceive(timer) { _ in
            if showRecordPanel {
                timerCounter += 1
                timerLabel = timerCounter.toMinutesAndSeconds()
            } else {
                timerCounter = 0
                timerLabel = "00:00"
            }
        }
    }
    
    var messagesContainer: some View {
        ScrollView {
            // Messages list here ...
        }
        .popup(isPresented: $errorMessage.isNotEmpty) {
            Text(errorMessage.error)
                .frame(width: 150, height: 50)
                .foregroundColor(.red)
                .background(Color.black.opacity(0.1))
                .cornerRadius(25)
                .overlay {
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(.black, lineWidth: 1)
                }
        } customize: {
            $0
                .type(.floater())
                .position(.top)
                .animation(.spring())
                .closeOnTapOutside(true)
        }
    }
    
    var bottomPanel: some View {
        VStack(spacing: 0) {
            
            if showRecordPanel {
                HStack {
                    Spacer()
                    
                    Image(systemName: isRecordLocked ? "lock.fill" : "lock")
                        .background {
                            Circle()
                                .fill(Color.black.opacity(0.2))
                                .frame(width: 36, height: 36)
                                
                        }
                        .padding()
                }
            }
            
            Divider()
                .frame(height: 1)
                .background(Color.gray)
            
            HStack(alignment: .center, spacing: 10) {
                
                if showAttachmentButton {
                    Button {
                        print("Show attachments panel")
                    } label: {
                        Image(systemName: "paperclip")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                } else {
                    Text(timerLabel)
                }
                
                if showTextField {
                    TextField("Send a message", text: $textFieldValue)
                } else {
                    Spacer()
                }
                
                if showEmojiIcon {
                    Button {
                        print("Emoji tapped")
                    } label: {
                        Image(systemName: "face.smiling.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                } else {
                    Button {
                        onCancelRecordAudio()
                        isRecordLocked = false
                    } label: {
                        Text("Cancel")
                    }
                }
                
                if isRecordLocked {
                    Button {
                        onCloseRecordAudioPanel()
                    } label: {
                        Image(systemName: "paperplane.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                } else {
                    Button {
                        
                    } label: {
                        Image(systemName: "mic")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                    .pressAction {
                        onOpenRecordAudioPanel()
                    } onTrash: {
                        onCancelRecordAudio()
                    } onLock: {
                        isRecordLocked = true
                    } onRelease: {
                        onCloseRecordAudioPanel()
                    }
                }
            }
            .padding(.vertical, textFieldValue.isEmpty ? 8 : 6)
            .padding(.horizontal, 10)
            .frame(height: 48)
            .background(Color.black.opacity(0.1))
        }
    }
}

struct ConversationScreen_Previews: PreviewProvider {
    static var previews: some View {
        ConversationScreen(
            textFieldValue: .constant(""),
            errorMessage: .constant(ErrorMessage(error: "")),
            showRecordPanel: true,
            showAttachmentButton: false,
            showTextField: false,
            onOpenRecordAudioPanel: { },
            onCancelRecordAudio: { },
            onCloseRecordAudioPanel: { }
        )
    }
}
