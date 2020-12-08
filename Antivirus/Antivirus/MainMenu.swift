//
//  MainMenu.swift
//  Antivirus
//
//  Created by Adam Tan on 07/12/2020.
//  Copyright © 2020 TAN, ADAM (Student). All rights reserved.
//

import Foundation
import SpriteKit

class MainMenu: SKScene
{
    var buttonPlay: btn!
    
    override func didMove(to view: SKView)
    {
        buttonPlay = self.childNode(withName: "buttonPlay") as! btn
        
        buttonPlay.function = { self.loadGame() }
    }
    
    func loadGame()
    {
        guard let view = self.view as SKView? else
        {
            print("Failed to get SKView")
            return
        }
        
        let scene = GameScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        
        view.showsDrawCount = true
        view.showsFPS = true
        
        let transition = SKTransition.reveal(with: .up, duration: 1.0)
        
        view.presentScene(scene, transition: transition)
    }
}
