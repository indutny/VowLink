//
//  LinkRequestController.swift
//  VowLink
//
//  Created by Indutnyy, Fedor on 7/30/19.
//  Copyright © 2019 Indutnyy, Fedor. All rights reserved.
//

import UIKit
import Sodium

class LinkRequestController : UIViewController, LinkNotificationDelegate {
    @IBOutlet weak var imageView: UIImageView!
    var sodium: Sodium!
    var boxPublicKey: Bytes?
    var boxSecretKey: Bytes?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let app = UIApplication.shared.delegate as! AppDelegate
        let identity = app.identity!
        
        sodium = app.context.sodium
        
        let keyPair = sodium.box.keyPair()!
        
        boxPublicKey = keyPair.publicKey
        boxSecretKey = keyPair.secretKey
        
        let req = Proto_LinkRequest.with { (req) in
            req.peerID = app.p2p.peer.displayName
            req.trusteePubKey = Data(identity.publicKey)
            req.desiredDisplayName = identity.name

            req.boxPubKey = Data(keyPair.publicKey)
        }
        let binary = try! req.serializedData()
        let b64 = app.context.sodium.utils.bin2base64(Bytes(binary))!
        let uri = "vow-link://link-request/\(b64)"
        
        let filter = CIFilter(name: "CIQRCodeGenerator")
        
        filter?.setValue(Data(uri.bytes), forKey: "inputMessage")
        filter?.setValue("Q", forKey: "inputCorrectionLevel")
        
        guard let image = filter?.outputImage else {
            debugPrint("Could not generate image")
            return;
        }
        
        let scale = view.frame.size.width / image.extent.width

        let transform = CGAffineTransform(scaleX: scale, y: scale)
        
        let qr = image.transformed(by: transform)
        imageView.image = UIImage(ciImage: qr)
        
        app.linkDelegate = self
    }
    
    deinit {
        if var secretKey = boxSecretKey {
            sodium.utils.zero(&secretKey)
        }
    }
    
    func link(received link: Link) {
        let alert = UIAlertController(title: "Got Link",
                                      message: "Link received",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true) {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
