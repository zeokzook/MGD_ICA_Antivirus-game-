//
//  GameViewController.swift
//  Antivirus
//
//  Created by TAN, ADAM (Student) on 06/11/2020.
//  Copyright © 2020 TAN, ADAM (Student). All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let scene = GameScene(size: view.bounds.size)
        let skView = view as! SKView
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }
    
    override var prefersStatusBarHidden: Bool
    {
      return true
    }
}
