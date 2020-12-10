//
//  HighScoreScene.swift
//  Antivirus
//
//  Created by Adam Tan on 10/12/2020.
//  Copyright © 2020 TAN, ADAM (Student). All rights reserved.
//

import Foundation
import SpriteKit

class HighScoreScene: SKScene
{
    let buttonBack = SKSpriteNode(imageNamed: "backButton")
    
    override func didMove(to view: SKView)
    {
        addBackground()
        
        let titleFontSize: CGFloat = 30
        let highScoreTitle = SKLabelNode(fontNamed: "ArialMT")
        highScoreTitle.text = "High Scores"
        highScoreTitle.fontSize = titleFontSize
        highScoreTitle.position = CGPoint(x: size.width / 2, y: 0.9 * size.height)
        
        addChild(highScoreTitle)
        
        buttonBack.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        buttonBack.setScale(0.5)
        buttonBack.position = CGPoint(x: buttonBack.size.width / 2, y: size.height - buttonBack.size.height / 2)
        
        addChild(buttonBack)
    }
        
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        let location = (touches.first?.location(in: self))!
        
        if buttonBack.contains(location)
        {
            returnToMainMenu()
        }
    }
    
    func returnToMainMenu()
    {
        GameViewController.shared.returnMainMenu()
    }
    
    func random() -> CGFloat
    {
        return CGFloat(Float(arc4random()) / Float(0xFFFFFFFF))
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat
    {
        return random() * (max - min) + min
    }
    
    //BACKGROUND
    func addBackground()
    {
        //adding background images
        let topBG = SKSpriteNode(imageNamed: "topBG")
        let background = SKSpriteNode(imageNamed: "background")
        let botBG = SKSpriteNode(imageNamed: "botBG")
        
        topBG.position = CGPoint(x: size.width / 2, y: size.height - topBG.size.height / 2)
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        botBG.position = CGPoint(x: size.width / 2, y: 0 + botBG.size.height / 2)
        
        topBG.zPosition = -9
        background.zPosition = -10
        botBG.zPosition = -9
        
        addChild(background)
        addChild(topBG)
        addChild(botBG)
        
        //adding strings
        let strings = SKSpriteNode(imageNamed: "strings")
        
        strings.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        strings.zPosition = -9
        
        addChild(strings)
        
        //adding background blood cells
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run({
                    self.addBloodCells()
                }),
                SKAction.wait(forDuration: 1.0)
            ])))
    }
    
    func addBloodCells()
    {
        let bloodCell = SKSpriteNode(imageNamed: "bloodCell")
        
        let y = random(min: 0 + bloodCell.size.height / 2, max: size.height - bloodCell.size.height / 2)
        bloodCell.position = CGPoint(x: size.width + bloodCell.size.width/2, y: y)
        
        bloodCell.zPosition = -8
        
        bloodCell.alpha = 0.5
        
        addChild(bloodCell)
        
        let duration = random(min: 3.0, max: 5.0)
        let actionMove = SKAction.move(to: CGPoint(x: bloodCell.position.x - (size.width + bloodCell.size.width), y: y), duration: TimeInterval(duration))
        let actionDone = SKAction.removeFromParent()
        
        bloodCell.run(SKAction.sequence([actionMove, actionDone]))
    }
    //BACKGROUND END
}
