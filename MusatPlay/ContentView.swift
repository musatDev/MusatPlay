import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []

        let js = """
        (function() {
            let lastTrack = "";
            let lastPlaying = null;
            let lastModes = null;

            function readRepeat(bar) {
                const r = (bar.getAttribute('repeat-mode') || 'NONE').toUpperCase();
                if (r === 'ALL' || r === 'ONE') return r;
                return 'NONE';
            }

            function readShuffle(bar) {
                return bar.hasAttribute('shuffle-on');
            }

            setInterval(function() {
                const m = navigator.mediaSession && navigator.mediaSession.metadata;
                if (m && m.title) {
                    const key = m.title + "|" + m.artist;
                    if (key !== lastTrack) {
                        lastTrack = key;
                        const art = (m.artwork && m.artwork.length) ? m.artwork[m.artwork.length - 1].src : "";
                        window.webkit.messageHandlers.trackChanged.postMessage({
                            title: m.title,
                            artist: m.artist,
                            artwork: art
                        });
                    }
                }

                const v = document.querySelector('video');
                if (v) {
                    const playing = !v.paused;
                    if (playing !== lastPlaying) {
                        lastPlaying = playing;
                        window.webkit.messageHandlers.playbackChanged.postMessage(playing);
                    }
                }

                const bar = document.querySelector('ytmusic-player-bar');
                if (bar) {
                    const repeat = readRepeat(bar);
                    const shuffle = readShuffle(bar);
                    const modes = repeat + "|" + shuffle;
                    if (modes !== lastModes) {
                        lastModes = modes;
                        window.webkit.messageHandlers.modesChanged.postMessage({ repeat: repeat, shuffle: shuffle });
                    }
                }
            }, 500);
        })();
        """
        let script = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(script)
        config.userContentController.add(context.coordinator, name: "trackChanged")
        config.userContentController.add(context.coordinator, name: "playbackChanged")
        config.userContentController.add(context.coordinator, name: "modesChanged")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15"
        PlayerController.shared.webView = webView
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKScriptMessageHandler {
        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            switch message.name {
            case "trackChanged":
                guard let body = message.body as? [String: Any] else { return }
                let title = body["title"] as? String ?? ""
                let artist = body["artist"] as? String ?? ""
                let artwork = body["artwork"] as? String ?? ""
                TrackNotifier.shared.show(title: title, artist: artist, artwork: artwork)
            case "playbackChanged":
                let playing = (message.body as? NSNumber)?.boolValue ?? true
                TrackNotifier.shared.model.isPlaying = playing
            case "modesChanged":
                guard let body = message.body as? [String: Any] else { return }
                TrackNotifier.shared.model.repeatMode = body["repeat"] as? String ?? "NONE"
                TrackNotifier.shared.model.isShuffle = body["shuffle"] as? Bool ?? false
            default:
                break
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        WebView(url: URL(string: "https://music.youtube.com")!)
            .frame(minWidth: 900, minHeight: 600)
    }
}
