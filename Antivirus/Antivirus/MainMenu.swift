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
        
        buttonPlay.function = { self.startGame() }
    }
    
    func startGame()
    {
        print("Loading Game")
        //self.GameView
        GameViewController.shared.startNewGame()
    }
}
