import SwiftUI
import ServiceManagement

struct SettingsView: View {
    var onDismiss: () -> Void = {}

    @State private var launchAtLogin = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Theme.divider)

            row {
                Text("Launch at Login").font(.onePlus(15)).foregroundColor(.white)
                Spacer()
                Toggle("", isOn: $launchAtLogin)
                    .toggleStyle(.switch).controlSize(.small)
                    .onChange(of: launchAtLogin) { setLogin($0) }
            }
            Divider().background(Theme.divider).padding(.leading, 20)

            row {
                Text("Alarm Sound").font(.onePlus(15)).foregroundColor(.white)
                Spacer()
                Button { SoundManager.shared.preview() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill").font(.system(size: 10))
                        Text("Preview").font(.onePlus(13))
                    }
                    .foregroundColor(Theme.accentSolid)
                }
                .buttonStyle(.plain)
            }
            Divider().background(Theme.divider)

            row {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Infinity").font(.onePlus(15)).foregroundColor(.white)
                    HStack(spacing: 0) {
                        Text("Made by ")
                            .foregroundColor(.white.opacity(0.35))
                        Link("Kalyan", destination: URL(string: "mailto:kalyanaslog1@gmail.com")!)
                            .foregroundColor(Theme.accentSolid)
                        Text(" · Version 1.0")
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .font(.onePlus(10, .light))
                }
                Spacer()
            }
            Divider().background(Theme.divider)

            Button { NSApp.terminate(nil) } label: {
                Text("Quit Infinity").font(.onePlus(13)).foregroundColor(Theme.danger)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
            }
            .buttonStyle(.plain)
        }
        .background(Theme.bg)
        .frame(width: 360)
        .onAppear { launchAtLogin = SMAppService.mainApp.status == .enabled }
    }

    private var header: some View {
        ZStack {
            Text("Settings").font(.onePlus(14)).foregroundColor(.white)
            HStack {
                Button(action: onDismiss) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back").font(.onePlus(13))
                    }
                    .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
    }

    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        HStack { content() }.padding(.horizontal, 20).padding(.vertical, 14)
    }

    private func setLogin(_ on: Bool) {
        try? on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
    }
}
