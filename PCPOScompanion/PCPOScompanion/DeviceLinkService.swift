import Foundation
import MultipeerConnectivity
import Combine

class DeviceLinkService: NSObject, ObservableObject {
    static let shared = DeviceLinkService()
    
    private let serviceType = "pcpos-link"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser
    
    @Published var connectedPeers: [MCPeerID] = []
    @Published var isConnected = false
    
    // Data Callbacks
    var onCameraFrameReceived: ((Data) -> Void)?
    
    private lazy var session: MCSession = {
        let session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()
    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceBrowser.delegate = self
    }
    
    func start() {
        #if os(iOS)
        // iPhone Advertises (Broadcaster)
        print("DeviceLink: Starting Advertiser...")
        serviceAdvertiser.startAdvertisingPeer()
        #else
        // Vision Pro Browses (Receiver)
        print("DeviceLink: Starting Browser...")
        serviceBrowser.startBrowsingForPeers()
        #endif
    }
    
    func stop() {
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
        session.disconnect()
    }
    
    func send(data: Data) {
        guard !session.connectedPeers.isEmpty else { return }
        
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .unreliable)
        } catch {
            print("DeviceLink Error sending data: \(error)")
        }
    }
}

extension DeviceLinkService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
            self.isConnected = !session.connectedPeers.isEmpty
            print("DeviceLink: Peer \(peerID.displayName) changed state to \(state.rawValue)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Handle received data (Camera Frames)
        onCameraFrameReceived?(data)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension DeviceLinkService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("DeviceLink: Received invitation from \(peerID.displayName). Accepting.")
        invitationHandler(true, session)
    }
}

extension DeviceLinkService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("DeviceLink: Found peer \(peerID.displayName). Inviting.")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("DeviceLink: Lost peer \(peerID.displayName)")
    }
}
