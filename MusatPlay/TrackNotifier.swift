import SwiftUI
import AppKit
import WebKit
import Combine

final class PlayerController {
    static let shared = PlayerController()
    weak var webView: WKWebView?

    private func click(_ selector: String) {
        let js = "document.querySelector('ytmusic-player-bar \(selector)')?.click();"
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    func previous() { click(".previous-button") }
    func playPause() { click(".play-pause-button") }
    func next() { click(".next-button") }
    func shuffle() { click(".shuffle") }
    func cycleRepeat() { click(".repeat") }
}

final class NotificationModel: ObservableObject {
    @Published var title = ""
    @Published var artist = ""
    @Published var artworkURL: URL?
    @Published var isPlaying = true
    @Published var isShuffle = false
    @Published var repeatMode = "NONE"
}

struct NotificationView: View {
    @ObservedObject var model: NotificationModel

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                AsyncImage(url: model.artworkURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text(model.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Text(model.artist)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 18) {
                shuffleButton()
                controlButton("backward.fill") { PlayerController.shared.previous() }
                controlButton(model.isPlaying ? "pause.fill" : "play.fill") { PlayerController.shared.playPause() }
                controlButton("forward.fill") { PlayerController.shared.next() }
                repeatButton()
            }
        }
        .padding(12)
        .frame(width: 320, height: 116)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onHover { TrackNotifier.shared.hoverChanged($0) }
    }

    private func controlButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .frame(width: 32, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func shuffleButton() -> some View {
        Button(action: { PlayerController.shared.shuffle() }) {
            Image(systemName: "shuffle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(model.isShuffle ? .red : .secondary)
                .frame(width: 32, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func repeatButton() -> some View {
        let mode = model.repeatMode
        let active = mode != "NONE"
        return Button(action: { PlayerController.shared.cycleRepeat() }) {
            ZStack {
                Image(systemName: "repeat")
                    .font(.system(size: 14, weight: .semibold))
                if mode == "ONE" {
                    Text("1")
                        .font(.system(size: 7, weight: .heavy))
                } else if mode == "ALL" {
                    Circle()
                        .frame(width: 3.5, height: 3.5)
                }
            }
            .foregroundColor(active ? .red : .secondary)
            .frame(width: 32, height: 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

final class TrackNotifier {
    static let shared = TrackNotifier()

    let model = NotificationModel()

    private var panel: NSPanel?
    private var hideTimer: Timer?
    private var finalFrame = NSRect.zero
    private var isVisible = false
    private var isHovering = false
    private var generation = 0

    private let size = NSSize(width: 320, height: 116)
    private let slide: CGFloat = 20
    private let fadeInDuration: TimeInterval = 0.75
    private let fadeOutDuration: TimeInterval = 0.75
    private let stayDuration: TimeInterval = 3.5
    private let afterHoverDelay: TimeInterval = 5

    private func isOtherAppFullscreen() -> Bool {
        guard let screen = NSScreen.main else { return false }
        let myPID = ProcessInfo.processInfo.processIdentifier

        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }

        for window in list {
            guard let layer = window[kCGWindowLayer as String] as? Int, layer == 0,
                  let pid = window[kCGWindowOwnerPID as String] as? Int32, pid != myPID,
                  let boundsDict = window[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsDict) else { continue }

            if abs(bounds.width - screen.frame.width) < 1 &&
               abs(bounds.height - screen.frame.height) < 1 {
                return true
            }
        }
        return false
    }

    private func makePanelIfNeeded() -> NSPanel {
        if let panel = panel { return panel }

        let hosting = NSHostingView(rootView: NotificationView(model: model))
        hosting.frame = NSRect(origin: .zero, size: size)

        let p = NSPanel(
            contentRect: hosting.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.contentView = hosting
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.level = .statusBar
        p.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel = p
        return p
    }

    func show(title: String, artist: String, artwork: String) {
        model.title = title
        model.artist = artist
        model.artworkURL = URL(string: artwork)

        if isOtherAppFullscreen() { return }

        let panel = makePanelIfNeeded()
        generation += 1
        hideTimer?.invalidate()

        if isVisible {
            if panel.alphaValue < 1 {
                animate(panel, alpha: 1, frame: finalFrame, duration: 0.3, curve: .easeOut)
            }
            if !isHovering {
                scheduleHide(after: stayDuration)
            }
            return
        }

        guard let screen = NSScreen.main else { return }
        let f = screen.visibleFrame
        finalFrame = NSRect(x: f.maxX - size.width - 16,
                            y: f.maxY - size.height - 12,
                            width: size.width,
                            height: size.height)

        var startFrame = finalFrame
        startFrame.origin.x += slide
        panel.setFrame(startFrame, display: false)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        isVisible = true

        animate(panel, alpha: 1, frame: finalFrame, duration: fadeInDuration, curve: .easeInEaseOut)

        scheduleHide(after: fadeInDuration + stayDuration)
    }

    func hoverChanged(_ hovering: Bool) {
        isHovering = hovering
        guard isVisible, let panel = panel else { return }

        if hovering {
            generation += 1
            hideTimer?.invalidate()
            if panel.alphaValue < 1 {
                animate(panel, alpha: 1, frame: finalFrame, duration: 0.3, curve: .easeOut)
            }
        } else {
            scheduleHide(after: afterHoverDelay)
        }
    }

    private func scheduleHide(after seconds: TimeInterval) {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }

    private func hide() {
        guard let panel = panel, isVisible, !isHovering else { return }
        generation += 1
        let gen = generation

        var target = finalFrame
        target.origin.x += slide

        animate(panel, alpha: 0, frame: target, duration: fadeOutDuration, curve: .easeInEaseOut) { [weak self] in
            guard let self = self, self.generation == gen else { return }
            panel.orderOut(nil)
            self.isVisible = false
        }
    }

    private func animate(_ panel: NSPanel,
                         alpha: CGFloat,
                         frame: NSRect,
                         duration: TimeInterval,
                         curve: CAMediaTimingFunctionName,
                         completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: curve)
            panel.animator().alphaValue = alpha
            panel.animator().setFrame(frame, display: true)
        }, completionHandler: completion)
    }
}
