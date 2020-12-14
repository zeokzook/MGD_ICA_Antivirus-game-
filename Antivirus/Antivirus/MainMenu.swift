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
    let buttonPlay = SKSpriteNode(imageNamed: "playButton")
    let buttonHighScore = SKSpriteNode(imageNamed: "highScoreButton")
    let titleAntivirus = SKLabelNode(fontNamed: "ArialMT")
    
    let defaults = UserDefaults.standard
    
    override func didMove(to view: SKView)
    {
        addBackground()
        setupTutorialCheck()
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        titleAntivirus.text = "ANTIVIRUS"
        titleAntivirus.fontSize = 100
        titleAntivirus.position = CGPoint(x: center.x , y: center.y + 0.2 * size.height)
        
        addChild(titleAntivirus)
        
        buttonPlay.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        //buttonPlay.setScale(0.75)
        buttonPlay.position = CGPoint(x: center.x - 0.15 * size.width, y: center.y - 0.15 * size.height)
        
        addChild(buttonPlay)
        
        buttonHighScore.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        //buttonHighScore.setScale(0.75)
        buttonHighScore.position = CGPoint(x: center.x + 0.15 * size.width, y: center.y - 0.15 * size.height)
        
        addChild(buttonHighScore)
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        var location = (touches.first?.location(in: self))!
        
        if tutorialChecking
        {
            if buttonBack.contains(location)
            {
                removeTutorialCheck()
                tutorialChecking = false
            }
            
            if skipTutorialText.contains(location) || checkBox.contains(location)
            {
                if skipTutorial
                {
                    skipTutorial = false
                    defaults.set(skipTutorial, forKey: "Skip Tutorial")
                    checkBox.texture = SKTexture(imageNamed: "uncheckedBox")
                }
                else
                {
                    skipTutorial = true
                    defaults.set(skipTutorial, forKey: "Skip Tutorial")
                    checkBox.texture = SKTexture(imageNamed: "checkedBox")
                }
            }
            
            if buttonCancel.contains(location)
            {
                print("creating new Game!")
                defaults.set(false, forKey: "Start Tutorial")
                GameViewController.shared.startNewGame()
            }
            
            if buttonConfirm.contains(location)
            {
                print("creating new Game!")
                defaults.set(true, forKey: "Start Tutorial")
                GameViewController.shared.startNewGame()
            }
        }
        else
        {
            if buttonPlay.contains(location)
            {
                startGame()
                location = CGPoint(x: 0, y: 0)
            }
            
            if buttonHighScore.contains(location)
            {
                highScore()
            }
        }
    }
    
    func startGame()
    {
        if !defaults.bool(forKey: "Skip Tutorial")
        {
            tutorialCheck()
        }
        else if !tutorialChecking
        {
            print("creating new Game!")
            GameViewController.shared.startNewGame()
        }
    }
    
    func highScore()
    {
        GameViewController.shared.toHighScoreScene()
    }
    
    func random() -> CGFloat
    {
        return CGFloat(Float(arc4random()) / Float(0xFFFFFFFF))
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat
    {
        return random() * (max - min) + min
    }
    
    //TUTORIAL PROMPT
    var box: SKSpriteNode?
    let tutorialText = SKLabelNode(fontNamed: "ArialMT")
    let tutorialHelpText = SKLabelNode(fontNamed: "ArialMT")
    let skipTutorialText = SKLabelNode(fontNamed: "ArialMT")
    var checkBox: SKSpriteNode = SKSpriteNode(imageNamed: "uncheckedBox")
    let buttonCancel = SKSpriteNode(imageNamed: "cancelButton")
    let buttonConfirm = SKSpriteNode(imageNamed: "confirmButton")
    let buttonBack = SKSpriteNode(imageNamed: "backButton")
    
    var tutorialChecking: Bool = false
    var skipTutorial: Bool = false
    
    func setupTutorialCheck()
    {
        let zPos: CGFloat = 20
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        let boxColor = UIColor(red: 0.663, green: 0.055, blue: 0.110, alpha: 1.0)
        box = SKSpriteNode(color: boxColor, size: CGSize(width: 0.7 * size.width, height: 0.6 * size.height))
        
        box?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        box?.zPosition = zPos
        box?.position = center
        
        let tutorialTextFontSize: CGFloat = 25
        tutorialText.text = "Tutorial"
        tutorialText.fontSize = tutorialTextFontSize
        tutorialText.zPosition = zPos
        tutorialText.position = CGPoint(x: center.x, y: center.y + (0.8 * ((box?.size.height)! / 2)))
        
        let tutorialHelpTextFontSize: CGFloat = 20
        tutorialHelpText.text = "Do you want to start the tutorial?"
        tutorialHelpText.fontSize = tutorialHelpTextFontSize
        tutorialHelpText.zPosition = zPos
        tutorialHelpText.position = CGPoint(x: center.x, y: center.y + 0.1 * center.y)
        
        let skipTutorialTextFontSize: CGFloat = 20
        skipTutorialText.text = "Always skip the tutorial"
        skipTutorialText.fontSize = skipTutorialTextFontSize
        skipTutorialText.zPosition = zPos
        skipTutorialText.position = CGPoint(x: center.x, y: tutorialHelpText.position.y - 0.05 * size.height)
        
        checkBox.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        checkBox.zPosition = zPos
        checkBox.setScale(3.0)
        checkBox.position = CGPoint(x: skipTutorialText.frame.minX - 0.02 * size.width, y: skipTutorialText.frame.midY)
        
        let x = box?.frame.minX
        let y = box?.frame.maxY
        buttonBack.anchorPoint = CGPoint(x: 0.0, y: 1.0)
        buttonBack.zPosition = zPos
        buttonBack.setScale(0.5)
        buttonBack.position = CGPoint(x: x!, y: y!)
        
        buttonCancel.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        buttonCancel.zPosition = zPos
        buttonCancel.setScale(0.5)
        buttonCancel.position = CGPoint(x: center.x - 0.1 * size.width, y: center.y - 0.15 * size.height)
        
        buttonConfirm.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        buttonConfirm.zPosition = zPos
        buttonConfirm.setScale(0.5)
        buttonConfirm.position = CGPoint(x: center.x + 0.1 * size.width, y: center.y - 0.15 * size.height)
    }
    
    func addTutorialCheck()
    {
        addChild(box!)
        addChild(tutorialText)
        addChild(tutorialHelpText)
        addChild(skipTutorialText)
        addChild(checkBox)
        addChild(buttonBack)
        addChild(buttonCancel)
        addChild(buttonConfirm)
    }
    
    func removeTutorialCheck()
    {
        box!.removeFromParent()
        tutorialText.removeFromParent()
        tutorialHelpText.removeFromParent()
        skipTutorialText.removeFromParent()
        checkBox.removeFromParent()
        buttonBack.removeFromParent()
        buttonCancel.removeFromParent()
        buttonConfirm.removeFromParent()
    }
    
    func tutorialCheck()
    {
        addTutorialCheck()
        
        tutorialChecking = true
    }
    
    //TUTORIAL PROMPT END
    
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
