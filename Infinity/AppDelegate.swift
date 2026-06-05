import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let store = TimerStore()
    private var escMonitor: Any?

    // MARK: Lifecycle

    func applicationDidFinishLaunching(_ note: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupPopover()
        installEscMonitor()
        NotificationCenter.default.addObserver(
            self, selector: #selector(alarmStarted),
            name: .infinityAlarmStarted, object: nil)
        // Close the popover whenever the app loses focus (click any other app / the desktop).
        NotificationCenter.default.addObserver(
            self, selector: #selector(appResignedActive),
            name: NSApplication.didResignActiveNotification, object: nil)
    }

    @objc private func appResignedActive() {
        if popover?.isShown == true { popover?.performClose(nil) }
    }

    func applicationWillTerminate(_ note: Notification) { store.save() }

    // MARK: Status item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else { return }

        let cfg = NSImage.SymbolConfiguration(pointSize: 15, weight: .light)
        if let img = NSImage(systemSymbolName: "infinity", accessibilityDescription: "Infinity")?
            .withSymbolConfiguration(cfg) {
            img.isTemplate = true
            button.image = img
        }
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.target = self
    }

    // MARK: Popover (auto-sizes to its SwiftUI content)

    private func setupPopover() {
        let pop = NSPopover()
        pop.behavior = .transient
        pop.animates = true

        let hosting = NSHostingController(rootView: ContentView().environmentObject(store))
        hosting.sizingOptions = .preferredContentSize
        pop.contentViewController = hosting
        popover = pop
    }

    // MARK: Alarm → focus app + allow Esc to stop

    @objc private func alarmStarted() {
        NSApp.activate(ignoringOtherApps: true)
        if let button = statusItem?.button, !(popover?.isShown ?? false) {
            showPopover(button)
        }
    }

    /// Esc stops a ringing alarm (works because the app is brought to front).
    private func installEscMonitor() {
        escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53, SoundManager.shared.isAlarming {   // 53 = Escape
                self?.store.stopAlarm()
                return nil                                             // consume the key
            }
            return event
        }
    }

    // MARK: Click handling

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        store.stopAlarm()                                              // any interaction silences alarm
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp { showMenu(sender) }
        else                           { toggle(sender)   }
    }

    private func toggle(_ button: NSStatusBarButton) {
        guard let popover else { return }
        popover.isShown ? popover.performClose(nil) : showPopover(button)
    }

    private func showPopover(_ button: NSStatusBarButton) {
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover?.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showMenu(_ button: NSStatusBarButton) {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Infinity", action: #selector(open), keyEquivalent: "o"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Infinity", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
        button.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func open() {
        if let button = statusItem?.button { toggle(button) }
    }
}
