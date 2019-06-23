//
//  GameViewController.swift
//  gengo-puyo
//
//  Created by motoki-shun on 2019/04/03.
//  Copyright © 2019 motoki-shun. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import GoogleMobileAds

class GameViewController: UIViewController, GADInterstitialDelegate {

    private let AdUnitID = "ca-app-pub-8182413336410310/6041903904"
    private let AdUnitIDTest = "ca-app-pub-3940256099942544/4411468910"
    private var interstitial: GADInterstitial!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") as! GameScene? {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFit // .fill, .aspectFill, .aspectFit, .resizeFill
                print("size: \(scene.size)")
                print("frame: \(scene.frame)")

                // Present the scene
                view.presentScene(scene)

                self.interstitial = self.createAndLoadInterstitial()
                scene.onShowAd = {
                    if self.interstitial.isReady {
                        self.interstitial.present(fromRootViewController: self)
                    } else {
                        print("Ad wasn't ready")
                    }
                }
            }

            view.preferredFramesPerSecond = 30 // FPS
            view.ignoresSiblingOrder = true

            #if DEBUG
                view.showsFPS = true
                view.showsNodeCount = true
                view.showsDrawCount = true
                view.showsQuadCount = true
                // view.showsPhysics = true
                // view.showsFields = true
            #endif
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    internal func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        self.interstitial = self.createAndLoadInterstitial()
    }

    private func createAndLoadInterstitial() -> GADInterstitial {
        let request = GADRequest()
        #if DEBUG
            request.testDevices = [ "06141913762d75a35715ba8ee8532969" ]
        #endif
        #if DEBUG
            let interstitial = GADInterstitial(adUnitID: AdUnitIDTest)
        #else
            let interstitial = GADInterstitial(adUnitID: AdUnitID)
        #endif
        interstitial.delegate = self
        interstitial.load(request)
        return interstitial
    }
}
