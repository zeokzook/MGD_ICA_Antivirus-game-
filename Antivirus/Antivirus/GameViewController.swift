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
    static var shared: GameViewController!
    
    var mainMenu: MainMenu?
    var gameScene: GameScene?
    var pauseScene: PauseScene?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        GameViewController.shared = self
        
        let skView = self.view as! SKView
        
        /*mainMenu = MainMenu(fileNamed:"MainMenu")
        mainMenu!.scaleMode = .aspectFill

        skView.presentScene(mainMenu)*/
        
        gameScene = GameScene(size: view.bounds.size)
        gameScene!.scaleMode = .resizeFill
        
        skView.presentScene(gameScene)
        
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsPhysics = true
        
    }
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    
    func startNewGame()
    {
        gameScene = GameScene(size: view.bounds.size)
        gameScene!.scaleMode = .resizeFill
        let skView = self.view as! SKView
        
        let transition = SKTransition.push(with: .down, duration: 0.4)
        skView.presentScene(gameScene!, transition: transition)
    }
}
