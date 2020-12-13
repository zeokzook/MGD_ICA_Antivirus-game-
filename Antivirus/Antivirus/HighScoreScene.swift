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
    static var shared: HighScoreScene!
    
    let buttonBack = SKSpriteNode(imageNamed: "backButton")
    let buttonReset = SKSpriteNode(imageNamed: "restartButton")
    
    let defaults = UserDefaults.standard
    
    override func didMove(to view: SKView)
    {
        addBackground()
        setupScene()
        
        HighScoreScene.shared = self
    }
        
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        let location = (touches.first?.location(in: self))!
        
        if buttonBack.contains(location)
        {
            returnToMainMenu()
        }
        else if buttonReset.contains(location)
        {
            GameViewController.shared.resetHighScore()
        }
    }
    
    func returnToMainMenu()
    {
        GameViewController.shared.returnMainMenu(from: "High Score")
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
    
    //SETUPS
    func setupScene()
    {
        let backgroundFade = SKSpriteNode(color: .black, size: CGSize(width: size.width / 2, height: size.height))
        backgroundFade.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundFade.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundFade.alpha = 0.6
        
        addChild(backgroundFade)
        
        buttonBack.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        buttonBack.setScale(0.5)
        buttonBack.position = CGPoint(x: buttonBack.size.width / 2, y: size.height - buttonBack.size.height / 2)
        
        addChild(buttonBack)
        
        let titleFontSize: CGFloat = 70
        let highScoreTitle = SKLabelNode(fontNamed: "ArialMT")
        highScoreTitle.text = "High Scores"
        highScoreTitle.fontSize = titleFontSize
        highScoreTitle.position = CGPoint(x: size.width / 2, y: 0.9 * size.height)
        
        addChild(highScoreTitle)
        
        var highScores: [Int]
        if let savedHighScores = defaults.object(forKey: "High Scores") as? [Int]
        {
            print("High Scores Exists")
            highScores = savedHighScores
            
            let HSFont = "ArialMT"
            
            let HS1text = String(format: "%010d", highScores[0])
            let HS2text = String(format: "%010d", highScores[1])
            let HS3text = String(format: "%010d", highScores[2])
            let HS4text = String(format: "%010d", highScores[3])
            let HS5text = String(format: "%010d", highScores[4])
            let HS6text = String(format: "%010d", highScores[5])
            let HS7text = String(format: "%010d", highScores[6])
            let HS8text = String(format: "%010d", highScores[7])
            
            let HS1FontSize: CGFloat = 60
            let HS2FontSize: CGFloat = 50
            let HS3FontSize: CGFloat = 40
            let HSFontSize: CGFloat = 30
            
            let HS1Color: UIColor = .yellow
            let HS2Color: UIColor = .lightGray
            let HS3Color: UIColor = UIColor(red: 0.804, green: 0.498, blue: 0.196, alpha: 1.0)
                      
            let HS1Pos = CGPoint(x: size.width / 2, y: 0.75 * size.height)
            let HS2Pos = CGPoint(x: size.width / 2, y: 0.65 * size.height)
            let HS3Pos = CGPoint(x: size.width / 2, y: 0.55 * size.height)
            let HS4Pos = CGPoint(x: size.width / 2, y: 0.45 * size.height)
            let HS5Pos = CGPoint(x: size.width / 2, y: 0.40 * size.height)
            let HS6Pos = CGPoint(x: size.width / 2, y: 0.35 * size.height)
            let HS7Pos = CGPoint(x: size.width / 2, y: 0.30 * size.height)
            let HS8Pos = CGPoint(x: size.width / 2, y: 0.25 * size.height)
            
            let HS1 = SKLabelNode(fontNamed: HSFont)
            HS1.text = "#1 - \(HS1text)"
            HS1.name = "HSText"
            HS1.fontSize = HS1FontSize
            HS1.position = HS1Pos
            HS1.fontColor = HS1Color
            
            let HS2 = SKLabelNode(fontNamed: HSFont)
            HS2.text = "#2 - \(HS2text)"
            HS2.name = "HSText"
            HS2.fontSize = HS2FontSize
            HS2.position = HS2Pos
            HS2.fontColor = HS2Color
            
            let HS3 = SKLabelNode(fontNamed: HSFont)
            HS3.text = "#3 - \(HS3text)"
            HS3.name = "HSText"
            HS3.fontSize = HS3FontSize
            HS3.position = HS3Pos
            HS3.fontColor = HS3Color
            
            let HS4 = SKLabelNode(fontNamed: HSFont)
            HS4.text = "#4 - \(HS4text)"
            HS4.name = "HSText"
            HS4.fontSize = HSFontSize
            HS4.position = HS4Pos
            
            let HS5 = SKLabelNode(fontNamed: HSFont)
            HS5.text = "#5 - \(HS5text)"
            HS5.name = "HSText"
            HS5.fontSize = HSFontSize
            HS5.position = HS5Pos
            
            let HS6 = SKLabelNode(fontNamed: HSFont)
            HS6.text = "#6 - \(HS6text)"
            HS6.name = "HSText"
            HS6.fontSize = HSFontSize
            HS6.position = HS6Pos
            
            let HS7 = SKLabelNode(fontNamed: HSFont)
            HS7.text = "#7 - \(HS7text)"
            HS7.name = "HSText"
            HS7.fontSize = HSFontSize
            HS7.position = HS7Pos
            
            let HS8 = SKLabelNode(fontNamed: HSFont)
            HS8.text = "#8 - \(HS8text)"
            HS8.name = "HSText"
            HS8.fontSize = HSFontSize
            HS8.position = HS8Pos
            
            addChild(HS1)
            addChild(HS2)
            addChild(HS3)
            addChild(HS4)
            addChild(HS5)
            addChild(HS6)
            addChild(HS7)
            addChild(HS8)
        }
        else
        {
            let noScoreFontSize: CGFloat = 30
            let noScore = SKLabelNode(fontNamed: "ArialMT")
            noScore.text = "No score yet :( Go Play!"
            noScore.fontSize = noScoreFontSize
            noScore.position = CGPoint(x: size.width / 2, y: 0.75 * size.height)
            
            addChild(noScore)
        }
        
        buttonReset.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        buttonReset.setScale(0.5)
        buttonReset.position = CGPoint(x: size.width - buttonReset.size.width / 2, y: buttonReset.size.height / 2)
        
        addChild(buttonReset)
    }
    
    func resetScores()
    {
        self.enumerateChildNodes(withName: "HSText")
        {
            (node, stop)in
            
            node.removeFromParent()
        }
        
        let noScoreFontSize: CGFloat = 30
        let noScore = SKLabelNode(fontNamed: "ArialMT")
        noScore.text = "No score yet :( Go Play!"
        noScore.fontSize = noScoreFontSize
        noScore.position = CGPoint(x: size.width / 2, y: 0.75 * size.height)
        
        addChild(noScore)
    }
}
