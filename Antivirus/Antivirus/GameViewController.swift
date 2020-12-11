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
    var highScoreScene: HighScoreScene?
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        GameViewController.shared = self
        
        let skView = self.view as! SKView
        
        mainMenu = MainMenu(size: view.bounds.size)
        mainMenu!.scaleMode = .resizeFill

        skView.presentScene(mainMenu)
        /*
        gameScene = GameScene(size: view.bounds.size)
        gameScene!.scaleMode = .resizeFill
        
        skView.presentScene(gameScene)*/
        
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
    
    func returnMainMenu(from: String)
    {
        mainMenu = MainMenu(size: view.bounds.size)
        mainMenu!.scaleMode = .resizeFill
        let skView = self.view as! SKView
        
        var transitionDir: SKTransitionDirection = .up
        if(from == "High Score")
        {
            transitionDir = .right
        }
        else if(from == "Game")
        {
            transitionDir = .up
        }
        
        let transition = SKTransition.push(with: transitionDir, duration: 0.4)
        skView.presentScene(mainMenu!, transition: transition)
    }
    
    func toHighScoreScene()
    {
        highScoreScene = HighScoreScene(size: view.bounds.size)
        highScoreScene!.scaleMode = .resizeFill
        let skView = self.view as! SKView
        
        let transition = SKTransition.push(with: .left, duration: 0.4)
        skView.presentScene(highScoreScene!, transition: transition)
    }
}
