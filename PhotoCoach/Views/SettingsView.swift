import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var showKey = false
    @State private var saveStatus: SaveStatus = .idle

    enum SaveStatus {
        case idle
        case saved
        case error
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OpenAI API Key")
                            .font(.headline)

                        HStack {
                            Group {
                                if showKey {
                                    TextField("sk-...", text: $apiKey)
                                } else {
                                    SecureField("sk-...", text: $apiKey)
                                }
                            }
                            .textContentType(.password)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                            Button {
                                showKey.toggle()
                            } label: {
                                Image(systemName: showKey ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text("Your API key is stored securely in the device Keychain.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("API Configuration")
                }

                Section {
                    Button {
                        saveAPIKey()
                    } label: {
                        HStack {
                            Text("Save API Key")
                            Spacer()
                            switch saveStatus {
                            case .idle:
                                EmptyView()
                            case .saved:
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            case .error:
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .disabled(apiKey.isEmpty)

                    if KeychainHelper.hasAPIKey() {
                        Button(role: .destructive) {
                            deleteAPIKey()
                        } label: {
                            Text("Delete API Key")
                        }
                    }
                }

                Section {
                    Link(destination: URL(string: "https://platform.openai.com/api-keys")!) {
                        HStack {
                            Text("Get an API Key")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("You need an OpenAI API key with access to GPT-4 Vision to use PhotoCoach.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadExistingKey()
            }
        }
    }

    private func loadExistingKey() {
        if let existingKey = KeychainHelper.getAPIKey() {
            apiKey = existingKey
        }
    }

    private func saveAPIKey() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKey.isEmpty else {
            saveStatus = .error
            return
        }

        if KeychainHelper.saveAPIKey(trimmedKey) {
            saveStatus = .saved
            // Reset status after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                saveStatus = .idle
            }
        } else {
            saveStatus = .error
        }
    }

    private func deleteAPIKey() {
        KeychainHelper.deleteAPIKey()
        apiKey = ""
        saveStatus = .idle
    }
}

#Preview {
    SettingsView()
}
