//
//  PauseScene.swift
//  Antivirus
//
//  Created by Adam Tan on 08/12/2020.
//  Copyright © 2020 TAN, ADAM (Student). All rights reserved.
//

import Foundation
import SpriteKit

class PauseScene : SKScene
{
    var buttonCancel: btn!
    
    override func didMove(to view: SKView)
    {
        //buttonCancel = self.childNode(withName: "buttonCancel") as! btn
        
        //buttonCancel.function = { self.resumeGame() }
    }
    
    func resumeGame()
    {
        //GameViewController.shared.resumeGame()
    }
}
