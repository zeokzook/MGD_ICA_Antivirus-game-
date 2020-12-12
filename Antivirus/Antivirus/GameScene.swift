//
//  GameScene.swift
//  Antivirus
//
//  Created by TAN, ADAM (Student) on 06/11/2020.
//  Copyright © 2020 TAN, ADAM (Student). All rights reserved.
//

import CoreMotion
import SpriteKit
import GameplayKit

func +(left: CGPoint, right:CGPoint) -> CGPoint
{
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right:CGPoint) -> CGPoint
{
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint
{
  return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint
{
  return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
  func sqrt(a: CGFloat) -> CGFloat
  {
    return CGFloat(sqrtf(Float(a)))
  }
#endif

extension CGPoint
{
  func length() -> CGFloat
  {
    return sqrt(x * x + y * y)
  }
  
  func normalized() -> CGPoint
  {
    return self / length()
  }
}

enum DimensionFace: CGFloat
{
    case front = 0
    case back  = -1
    case null  = 10
}

struct WallType : OptionSet
{
    let rawValue: UInt8
    init(rawValue: UInt8) {self.rawValue = rawValue}
    
    static let longThin     = WallType(rawValue: 0b01)
    static let shortWideBot = WallType(rawValue: 0b10)
    static let shortWideTop = WallType(rawValue: 0b11)
}

struct PhysicsCategory : OptionSet
{
    let rawValue: UInt32
    init(rawValue: UInt32) {self.rawValue = rawValue}
    
    static let None            = PhysicsCategory(rawValue: 0b0000)
    static let All             = PhysicsCategory(rawValue: UInt32.max)
    static let Enemy           = PhysicsCategory(rawValue: 0b0001) //1
    static let Projectile      = PhysicsCategory(rawValue: 0b0010) //2
    static let Wall            = PhysicsCategory(rawValue: 0b0100) //4
    static let Player          = PhysicsCategory(rawValue: 0b1000) //8
}

extension Notification.Name
{
    static let notifPause = Notification.Name("notifPause")
}

class GameScene: SKScene
{
    let player = SKSpriteNode(imageNamed: "whiteCell")
    let scoreText = SKLabelNode(fontNamed: "ArialMT")
    let buttonPause = SKSpriteNode(imageNamed: "pauseButton")
    var playerAimGuide: SKShapeNode?
    
    let wallColorFront = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    let wallColorBack = UIColor(red: 1.0, green: 0.612, blue: 0, alpha: 1.0)
    
    var motionManager: CMMotionManager!
    var calibrated: Double!
    var doneCalibrate = false
    var moveAmtY: CGFloat = 0
    var initPos: CGPoint = CGPoint.zero
    var initTouch: CGPoint = CGPoint.zero
    var currentDimension: DimensionFace = .front
    var time = Date()
    var tutorialDone : Bool = false
    var rotate = false
    var score: Int = 0
    var hasPaused: Bool = false
    static var gameOver: Bool = false
    
    let projectileSpeed: Double = 0.5 //smaller number is faster
    let moveAmtthreshold: CGFloat = 100.0
    let playerSpeed: CGFloat = 7.5
    let shootDelay: TimeInterval = 0.25
    
    var collidedCounter = 0
    
    let enemyScore = 100
    let wallScore = 300
    
    override func didMove(to view: SKView)
    {
        NotificationCenter.default.addObserver(self, selector: #selector(notifPause), name: .notifPause , object: nil)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeUp.direction = .up
        self.view?.addGestureRecognizer(swipeUp)
        
        addBackground()
        setupPauseMenu()
        setupGameOver()
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        //Setting up player
        player.scale(to: CGSize(width: 50, height: 50))
        player.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        player.name = "player"
        player.color = UIColor(red: 1.0, green: 0.612, blue: 0, alpha: 1.0)
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width/2)
        player.physicsBody!.category = .Player
        player.physicsBody!.collision = .None
        player.Dimension = currentDimension
        
        addChild(player)
        
        //Setting up playerAimGuide
        let rect = CGRect(x: 0, y: 0, width: size.width - (player.position.x + (player.size.width / 2)), height: 4)
        playerAimGuide = SKShapeNode(rect: rect)
        playerAimGuide?.position = CGPoint(x: player.position.x + (player.size.width / 2), y: player.position.y - rect.height)
        playerAimGuide?.name = "player"
        playerAimGuide?.fillColor = .white
        playerAimGuide?.alpha = 0.6
        playerAimGuide?.strokeColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        
        //addChild(playerAimGuide!)
        
        //Setting up score text
        scoreText.position = CGPoint(x: size.width/2, y: size.height - 25)
        scoreText.fontSize = 25
        scoreText.fontColor = SKColor.white
        scoreText.text = "Score: \(String(format: "%010d", score))"
        
        addChild(scoreText)
        
        //Setting up pause button
        buttonPause.setScale(0.5)
        buttonPause.position = CGPoint(x: size.width - buttonPause.size.width / 2, y: size.height - buttonPause.size.height / 2)
        
        addChild(buttonPause)
        
        //Setting up CMMotion
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        
        /*run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run({
                    let i = self.random(min:0.0, max:5.0)
                    
                    if(i == 0.0)
                    {
                        self.addWall(dimension: self.currentDimension, wallType: .shortWideBot, wallDuration: 2.0)
                    }
                    else if(i <= 2.0)
                    {
                        self.addEnemy(dimension: .front)
                    }
                    else if(i >= 3.0)
                    {
                        self.addEnemy(dimension: .back)
                    }
                    
                }),
                SKAction.wait(forDuration: 1.0)
            ])
        ))*/
    }
    
    var sentWave: Bool = false
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer)
    {
        if currentDimension == .front
        {
            switchDimension(toDimension: .back)
        }
        else if currentDimension == .back
        {
            switchDimension(toDimension: .front)
        }
    }
    
    override func update(_ currentTime: TimeInterval)
    {
        #if targetEnvironment(simulator)
        #else
        
        if hasPaused
        {
            pausing()
        }
        else if GameScene.gameOver
        {
            didGameOver()
        }
        else
        {
            playerMovement()
            
            /*if(!tutorialDone)
            {
                tutorial()
            }*/
            
            if !sentWave
            {
                waveType1()
                sentWave = true
            }
            
            updateScore()
            //print(player.position)
        }
        #endif
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        let location = (touches.first?.location(in: self))!
        if hasPaused
        {
            if buttonCancel.contains(location)
            {
                print("unpausing")
                unpause()
            }
            else if buttonRecalibrate.contains(location)
            {
                print("recalibrated")
                recalibrate()
            }
            else if buttonExitPause.contains(location)
            {
                GameViewController.shared.returnMainMenu(from: "Game")
            }
        }
        else if GameScene.gameOver
        {
            if buttonRestart.contains(location)
            {
                restartGame()
            }
            else if buttonExitGameOver.contains(location)
            {
                GameScene.gameOver = false
                GameViewController.shared.returnMainMenu(from: "Game")
            }
        }
        else
        {
            if buttonPause.contains(location)
            {
                print("pausing")
                pausing()
            }
            else
            {
                shoot(dimension: currentDimension, after: shootDelay)
            }
        }
    }
    
    //PAUSE MENU
    let buttonCancel = SKSpriteNode(imageNamed: "cancelButton")
    let buttonRecalibrate = SKSpriteNode(color: UIColor(red: 0.937254, green: 0.0, blue: 0.0, alpha: 1.0), size: CGSize(width: 320, height: 60))
    let buttonExitPause = SKSpriteNode(imageNamed: "exitButton")
    let textRecalibrateDone = SKLabelNode(fontNamed: "ArialMT")
    
    func setupPauseMenu()
    {
        let zPos: CGFloat = -20
        
        let backgroundFade = SKSpriteNode(color: .black, size: CGSize(width: size.width, height: size.height))
        backgroundFade.name = "pauseMenu"
        backgroundFade.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundFade.zPosition = zPos
        backgroundFade.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundFade.alpha = 0.6
        
        addChild(backgroundFade)
        
        let pauseTextFontSize: CGFloat = 50
        let pauseTextMargin: CGFloat = 0.05 * size.height
        let pauseText = SKLabelNode(fontNamed: "ArialMT")
        pauseText.name = "pauseMenu"
        pauseText.text = "Paused"
        pauseText.zPosition = zPos
        pauseText.fontSize = pauseTextFontSize
        pauseText.position = CGPoint(x: size.width / 2, y: size.height - pauseTextFontSize - pauseTextMargin)

        addChild(pauseText)
        
        buttonCancel.name = "pauseMenu"
        buttonCancel.anchorPoint = CGPoint(x: 1.0, y: 1.0)
        buttonCancel.zPosition = zPos
        buttonCancel.position = CGPoint(x: size.width, y: size.height)
        buttonCancel.setScale(0.5)
        
        addChild(buttonCancel)
        
        let buttonRecalibrateMargin: CGFloat = 0.15 * size.height
        buttonRecalibrate.name = "pauseMenu"
        buttonRecalibrate.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        buttonRecalibrate.zPosition = zPos
        buttonRecalibrate.position = CGPoint(x: size.width / 2, y: size.height / 2 + buttonRecalibrateMargin)
        
        addChild(buttonRecalibrate)
        
        let textRecalibrateFontSize: CGFloat = 30
        let textRecalibrate = SKLabelNode(fontNamed: "ArialMT")
        textRecalibrate.name = "pauseMenu"
        textRecalibrate.text = "Recalibrate Movement"
        textRecalibrate.zPosition = zPos
        textRecalibrate.fontSize = textRecalibrateFontSize
        textRecalibrate.position = CGPoint(x: buttonRecalibrate.position.x, y: buttonRecalibrate.position.y - textRecalibrateFontSize / 2)

        addChild(textRecalibrate)
        
        textRecalibrateDone.text = "Recalibration Done"
        textRecalibrateDone.zPosition = zPos
        textRecalibrateDone.fontSize = textRecalibrateFontSize
        textRecalibrateDone.position = CGPoint(x: buttonRecalibrate.position.x, y: buttonRecalibrate.position.y + buttonRecalibrate.size.height)
        
        addChild(textRecalibrateDone)
        
        let buttonExitMargin: CGFloat = 0.15 * size.height
        buttonExitPause.name = "pauseMenu"
        buttonExitPause.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        buttonExitPause.zPosition = zPos
        buttonExitPause.position = CGPoint(x: size.width / 2, y: size.height / 2 - buttonExitMargin)
        buttonExitPause.setScale(0.5)
        
        addChild(buttonExitPause)
    }

    func recalibrate()
    {
        doneCalibrate = false
        showDoneText()
    }
    
    func showDoneText()
    {
        textRecalibrateDone.zPosition = 5
    }
    
    func hideDoneText()
    {
        textRecalibrateDone.zPosition = -20
    }
    
    @objc func notifPause()
    {
        pausing()
    }
    
    func pausing()
    {
        self.isPaused = true
        physicsWorld.speed = 0
        hasPaused = true
        
        self.enumerateChildNodes(withName: "pauseMenu")
        {
            (node, stop)in
            
            node.zPosition = 5
        }
    }
    
    func unpause()
    {
        self.isPaused = false
        physicsWorld.speed = 1
        hasPaused = false
        
        hideDoneText()
        
        self.enumerateChildNodes(withName: "pauseMenu")
        {
            (node, stop)in
            
            node.zPosition = -20
        }
    }
    //PAUSE MENU END
    
    //GAME OVER MENU
    let buttonExitGameOver = SKSpriteNode(imageNamed: "exitButton")
    let buttonRestart = SKSpriteNode(imageNamed: "restartButton")
    let endScoreText = SKLabelNode(fontNamed: "ArialMT")
    
    func setupGameOver()
    {
        let zPos: CGFloat = -20
        
        let backgroundFade = SKSpriteNode(color: .black, size: CGSize(width: size.width, height: size.height))
        backgroundFade.name = "loseMenu"
        backgroundFade.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundFade.zPosition = zPos
        backgroundFade.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundFade.alpha = 0.6
        
        addChild(backgroundFade)
        
        let gameOverTextFontSize: CGFloat = 50
        let gameOverTextMargin: CGFloat = 0.05 * size.height
        let gameOverText = SKLabelNode(fontNamed: "ArialMT")
        gameOverText.name = "loseMenu"
        gameOverText.text = "Game Over!"
        gameOverText.zPosition = zPos
        gameOverText.fontSize = gameOverTextFontSize
        gameOverText.position = CGPoint(x: size.width / 2, y: size.height - gameOverTextFontSize - gameOverTextMargin)

        addChild(gameOverText)
        
        let endScoreTextFontSize: CGFloat = 40
        let endScoreTextMargin: CGFloat = 0.15 * size.height
        endScoreText.name = "loseMenu"
        endScoreText.text = "Score: \(score)"
        endScoreText.zPosition = zPos
        endScoreText.fontSize = endScoreTextFontSize
        endScoreText.position = CGPoint(x: size.width / 2, y: size.height / 2 + endScoreTextMargin)
        
        addChild(endScoreText)
        
        let buttonExitMargin: CGFloat = 0.15 * size.height
        buttonExitGameOver.name = "loseMenu"
        buttonExitGameOver.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        buttonExitGameOver.zPosition = zPos
        buttonExitGameOver.position = CGPoint(x: size.width / 2 - buttonExitMargin, y: size.height / 2 - buttonExitMargin)
        buttonExitGameOver.setScale(0.5)
        
        addChild(buttonExitGameOver)
        
        let buttonRestartMargin: CGFloat = 0.15 * size.height
        buttonRestart.name = "loseMenu"
        buttonRestart.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        buttonRestart.zPosition = zPos
        buttonRestart.position = CGPoint(x: size.width / 2 + buttonRestartMargin, y: size.height / 2 - buttonRestartMargin)
        buttonRestart.setScale(0.5)
        
        addChild(buttonRestart)
    }
    
    func didGameOver()
    {
        print("Game Over!")
        
        self.isPaused = true
        physicsWorld.speed = 0
        GameScene.gameOver = true
        endScoreText.text = "Score: \(score)"
        
        player.removeFromParent()
        scoreText.removeFromParent()
        
        self.enumerateChildNodes(withName: "loseMenu")
        {
            (node, stop)in
            
            node.zPosition = 5
        }
        
        sortHighScore()
    }
    
    func restartGame()
    {
        print("Restarting")
        
        self.isPaused = false
        physicsWorld.speed = 1
        GameScene.gameOver = false
        sentWave = false
        currentDimension = .front
        
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        player.Dimension = currentDimension
        player.colorBlendFactor = 0.0
        
        addChild(player)
        addChild(scoreText)
        
        removeAllActions()
        
        self.enumerateChildNodes(withName: "*")
        {
            (node, _)in
            
            if node.name == "enemy" || node.name == "wall" || node.name == "bullet"
            {
                node.removeFromParent()
            }
            else if node.name == "loseMenu"
            {
                node.zPosition = -20
            }
        }
    }
    
    func sortHighScore()
    {
        let defaults = UserDefaults.standard
        
        var highScores : [Int]
        
        if let savedHighScores = defaults.object(forKey: "High Scores") as? [Int]
        {
            print("High Score exists")
            
            highScores = savedHighScores
            
            if highScores.count == 8
            {
                highScores.removeLast()
                highScores.append(score)
                highScores.sort(by: >)
            }
            else
            {
                highScores.append(score)
                highScores.sort(by: >)
            }
            
            defaults.set(highScores, forKey: "High Scores")
        }
        else
        {
            print("High Score doesnt exists")
            
            highScores = [score,0,0,0,0,0,0,0]
            highScores.reserveCapacity(8)
            
            defaults.set(highScores, forKey: "High Scores")
        }
        
        score = 0
        print(highScores)
    }
    //GAME OVER END
    
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
        
        bloodCells()
    }
    
    func bloodCells()
    {
        //adding background blood cells
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run({
                    self.addBloodCell()
                }),
                SKAction.wait(forDuration: 1.0)
            ])
        ))
    }
    
    func addBloodCell()
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
    
    //TUTORIAL
    var movementDone: Bool = false
    var shootDone: Bool = false
    var changeDimen: Bool = false
    var setCurrPlayerPos: Bool = false
    var currentPlayerPos: CGFloat = 0
    
    func tutorial()
    {
        if(!movementDone)
        {
            if(!setCurrPlayerPos)
            {
                currentPlayerPos = player.position.y
                setCurrPlayerPos = true
            }
            
            print("movement tutorial")
            let moveText = SKLabelNode(fontNamed: "Chalkduster")
            moveText.text = "Tilt up and down to move up"
            moveText.fontSize = 65
            moveText.fontColor = SKColor.white
            moveText.position = CGPoint(x: frame.midX + 100, y: frame.midY)
            
            addChild(moveText)
            
            if(player.position.y >= currentPlayerPos - 150)
            {
                movementDone = true
                print("move up done")
            }
            
        }
    }
    //TUTORIAL END
    
    //PLAYER MOVEMENT
    func playerMovement()
    {
        if let accelerometerData = motionManager.accelerometerData
        {
            if doneCalibrate != true
            {
                calibrated = accelerometerData.acceleration.x
                doneCalibrate = true
            }
        
            if accelerometerData.acceleration.x > calibrated + 0.035
            {
                player.position.y += playerSpeed
                playerAimGuide?.position.y += playerSpeed
            }
            
            if accelerometerData.acceleration.x < calibrated - 0.02
            {
                player.position.y -= playerSpeed
                playerAimGuide?.position.y -= playerSpeed
            }
        }
        
        if player.position.y <= player.size.height / 2
        {
            player.position.y = player.size.height / 2
            playerAimGuide?.position.y = player.size.height / 2
        }
        
        if player.position.y >= size.height - player.size.height / 2
        {
            player.position.y = size.height - player.size.height / 2
            playerAimGuide?.position.y = size.height - player.size.height / 2
        }
    }
    //PLAYER MOVEMENT END
    
    func random() -> CGFloat
    {
        return CGFloat(Float(arc4random()) / Float(0xFFFFFFFF))
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat
    {
        return random() * (max - min) + min
    }
    
    //ADD ENEMY
    var enemyScale = CGSize(width: 40, height: 40)
    
    func addEnemy(dimension: DimensionFace,x: CGFloat = 0, y: CGFloat = 0, duration: CGFloat = 0)
    {
        var enemy = SKSpriteNode()
        if dimension == .front
        {
            enemy = SKSpriteNode(imageNamed: "virus")
        }
        else if dimension == .back
        {
            enemy = SKSpriteNode(imageNamed: "infectedCell")
        }
        
        enemy.name = "enemy"
        
        enemy.scale(to: enemyScale)
        enemy.position = CGPoint(x: size.width + enemy.size.width/2 + x, y: y)
        enemy.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        enemy.Dimension = dimension
        
        addChild(enemy)
        
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemy.size.width/2)
        enemy.physicsBody!.isDynamic = true
        enemy.physicsBody!.affectedByGravity = false
        enemy.physicsBody!.category = .Enemy
        enemy.physicsBody!.collision = .None
        enemy.physicsBody!.contact = .Player
        
        if(currentDimension == dimension)
        {
            enemy.alpha = 1.0
        }
        else
        {
            enemy.alpha = 0.5
        }

        let actionMove = SKAction.move(to: CGPoint(x: -enemy.size.width/2, y: y), duration: TimeInterval(duration))
        let removeScore = SKAction.run { self.score -= self.enemyScore }
        let actionMoveDone = SKAction.removeFromParent()
        
        enemy.run(SKAction.sequence([actionMove, removeScore, actionMoveDone]))
        
        //add slow down and go to player
    }
    //ADD ENEMY END
    
    func addWall(dimension: DimensionFace, wallType: WallType, wallDuration: CGFloat)
    {
        var wallRect: CGRect = CGRect(x:0, y:0, width:0, height:0)
        var y: CGFloat = 0
        if wallType == .longThin
        {
            wallRect = CGRect(x:0, y:0, width: 100, height: size.height)
            y = 0
        }
        else if wallType == .shortWideBot
        {
            wallRect = CGRect(x:0, y:0, width: 1000, height: size.height/2)
            y = size.height/2
        }
        else if wallType == .shortWideTop
        {
            wallRect = CGRect(x:0, y:0, width: 1000, height: size.height/2)
            y = 0
        }
        
        let wall = SKShapeNode(rect: wallRect)
    
        wall.name = "wall"
        wall.position = CGPoint(x: size.width + wallRect.size.width, y: y)
        
        if(dimension == .front)
        {
            wall.fillColor = wallColorFront
        }
        else
        {
            wall.fillColor = wallColorBack
        }
        
        wall.Dimension = dimension
        
        addChild(wall)
        
        wall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: wallRect.width, height: wallRect.height), center: CGPoint(x: wallRect.width / 2, y: wallRect.height / 2))
        wall.physicsBody!.affectedByGravity = false
        wall.physicsBody!.category = .Wall
        wall.physicsBody!.collision = .None
        wall.physicsBody!.contact = .Player
        
        if(currentDimension == dimension)
        {
            wall.alpha = 1.0
        }
        else
        {
            wall.alpha = 0.5
        }
        
        let actionMove = SKAction.move(to: CGPoint(x: -wallRect.width, y: y), duration: TimeInterval(wallDuration))
        let actionMoveDone = SKAction.removeFromParent()
        let actionAddScore = SKAction.run { self.score += self.wallScore }
        
        wall.run(SKAction.sequence([actionMove, actionAddScore ,actionMoveDone]))
    }
    
    func shoot(dimension: DimensionFace, after timeInterval: Double)
    {
        guard Date() - timeInterval > time else {
            return
        }

        let projectile = SKSpriteNode(imageNamed: "antibody")
        
        projectile.position = player.position
        projectile.name = "bullet"
        
        projectile.Dimension = dimension
        
        addChild(projectile)
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2 - 2)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody!.affectedByGravity = false
        projectile.physicsBody?.usesPreciseCollisionDetection = true
        projectile.physicsBody!.category = .Projectile
        projectile.physicsBody!.collision = .None
        projectile.physicsBody!.contact = .Enemy
        
        let shootAmount = projectile.position.x * 10
        let realDest = CGPoint(x: shootAmount, y:0) + projectile.position
        let actionRotate = SKAction.rotate(byAngle: -(CGFloat.pi)/2, duration: 0)
        let actionMove = SKAction.move(to: realDest, duration: projectileSpeed)
        let actionMoveDone = SKAction.removeFromParent()
        
        projectile.run(SKAction.sequence([actionRotate, actionMove, actionMoveDone]))
        time = Date()
    }
    
    func switchDimension(toDimension: DimensionFace)
    {
        currentDimension = toDimension
        player.Dimension = toDimension
        
        if(toDimension == .front)
        {
            player.colorBlendFactor = 0.0
            playerAimGuide?.fillColor = .white
        }
        else if(toDimension == .back)
        {
            player.colorBlendFactor = 0.8
            playerAimGuide?.fillColor = UIColor(red: 1.0, green: 0.612, blue: 0.0, alpha: 0.6)
        }
        
        self.enumerateChildNodes(withName: "*")
        {
            (node, _)in
            
            if(node.name == "enemy" || node.name == "wall" || node.name == "bullet")
            {
                if(toDimension == .front)
                {
                    if node.Dimension == .front
                    {
                        node.alpha = 1.0
                    }
                    else
                    {
                        node.alpha = 0.5
                    }
                }
                else if(toDimension == .back)
                {
                    if node.Dimension == .front
                    {
                        node.alpha = 0.5
                    }
                    else
                    {
                        node.alpha = 1.0
                    }
                }
            }
        }
    }
    
    func updateScore()
    {
        scoreText.text = "Score: \(String(format: "%010d", score))"
    }
    
    //WAVES
    func tutorialWave()
    {
        run(SKAction.sequence([
            SKAction.run({self.addEnemy(dimension: self.currentDimension, y: self.player.position.y, duration: 2.0)}),
            SKAction.run({self.addEnemy(dimension: self.currentDimension, y: self.player.position.y + 100, duration: 2.0)}),
            SKAction.run({self.addEnemy(dimension: self.currentDimension, y: self.player.position.y + 200, duration: 2.0)}),
            SKAction.run({self.addEnemy(dimension: self.currentDimension, y: self.player.position.y + 300, duration: 2.0)}),
            SKAction.wait(forDuration: 2.0),
            SKAction.run({self.addEnemy(dimension: self.currentDimension, y: self.player.position.y, duration: 3.0)}),
            SKAction.wait(forDuration: 3.0),
            SKAction.run({self.addWall(dimension: self.currentDimension, wallType: .shortWideTop, wallDuration: 4.0)}),
            SKAction.wait(forDuration: 2.0),
            SKAction.run({self.addWall(dimension: self.currentDimension, wallType: .shortWideBot, wallDuration: 4.0)}),
            SKAction.wait(forDuration: 2.0),
            SKAction.run({self.addWall(dimension: self.currentDimension, wallType: .longThin, wallDuration: 4.0)}),
            SKAction.wait(forDuration: 2.0),
            SKAction.run({self.sentWave = false})
        ]))
    }
    
    func waveType1()
    {
        let dur: CGFloat = 2.5
        let screenHeight = size.height
        let screenYCenter = size.height / 2
        
        var oppositeDimension: DimensionFace
        var curDimension: DimensionFace
        if currentDimension == .front
        {
            curDimension = .front
            oppositeDimension = .back
        }
        else
        {
            curDimension = .back
            oppositeDimension = .front
        }
        
        run(SKAction.sequence([
            /* e = enemy, w = wall
             *                e4                 ||      e7
             *        e2                         ||              e9
             *                                   ||          e8
             *    e1                    e6       w1                       e11
             *                                   ||                  e10                      |=========================|
             *            e3                     ||                                 e13       ||                       ||
             *                      e5           ||                            e12            ||                       ||
             * <---------curDimension------------><--------------------oppositeDimension-----------------------------------
             */
            SKAction.run({self.addEnemy(dimension: curDimension, y: screenYCenter, duration: dur )}),                             //e1
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: curDimension, y: screenYCenter + (0.15 * screenHeight), duration: dur )}),     //e2
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: curDimension, y: screenYCenter - (0.15 * screenHeight), duration: dur )}),     //e3
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: curDimension, y: screenYCenter + (0.30 * screenHeight), duration: dur )}),     //e4
            SKAction.wait(forDuration: 2),
            SKAction.run({self.addEnemy(dimension: curDimension, y: screenYCenter - (0.30 * screenHeight), duration: dur )}),     //e5
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: curDimension, y: screenYCenter, duration: dur )}),                             //e6
            SKAction.wait(forDuration: 2.0),
            SKAction.run({self.addWall(dimension: curDimension, wallType: .longThin, wallDuration: dur)}),                        //w1
            SKAction.wait(forDuration: 2.5),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter + (0.40 * screenHeight), duration: dur)}), //e7
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter + (0.15 * screenHeight), duration: dur)}), //e8
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter + (0.30 * screenHeight), duration: dur)}), //e9
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter - (0.15 * screenHeight), duration: dur)}), //e10
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter, duration: dur)}),                         //e11
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter - (0.40 * screenHeight), duration: dur)}), //e12
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter - (0.30 * screenHeight), duration: dur)}), //e13
            //for testing purposes only
            SKAction.wait(forDuration: 2.0),
            SKAction.run({self.sentWave = false})
            
        ]))
        
        
        
    }
    
    func waveType2()
    {
        
    }
    
    func waveType3()
    {
        
    }
    
    func waveType4()
    {
        
    }
    //WAVES END
    
    func collidedEnemyWithPlayer(Enemy: SKSpriteNode, Player: SKSpriteNode)
    {
        didGameOver()
    }
    
    func collidedEnemyWithProjectile(Enemy: SKSpriteNode, Projectile: SKSpriteNode)
    {
        Enemy.removeFromParent()
        Projectile.removeFromParent()
        
        score += enemyScore
    }
    
}

extension SKNode
{
    var Dimension: DimensionFace
    {
        get
        {
            if self.zPosition == DimensionFace.front.rawValue
            {
                return DimensionFace.front
            }
            else if self.zPosition == DimensionFace.back.rawValue
            {
                return DimensionFace.back
            }
            else
            {
                return DimensionFace.null
            }
        }
        set(newValue)
        {
            self.zPosition = newValue.rawValue
        }
    }
}

extension SKPhysicsBody
{
    var category: PhysicsCategory
    {
        get
        {
            return PhysicsCategory(rawValue: self.categoryBitMask)
        }
        set(newValue)
        {
            self.categoryBitMask = newValue.rawValue
        }
    }
    
    var collision: PhysicsCategory
    {
        get
        {
            return PhysicsCategory(rawValue: self.collisionBitMask)
        }
        set(newValue)
        {
            self.collisionBitMask = newValue.rawValue
        }
    }
    
    var contact: PhysicsCategory
    {
        get
        {
            return PhysicsCategory(rawValue: self.contactTestBitMask)
        }
        set(newValue)
        {
            self.contactTestBitMask = newValue.rawValue
        }
    }
}

extension GameScene: SKPhysicsContactDelegate
{
    func didBegin(_ contact: SKPhysicsContact)
    {
        if contact.bodyA.node?.Dimension == contact.bodyB.node?.Dimension
        {
            let contactCategory: PhysicsCategory = [contact.bodyA.category, contact.bodyB.category]
            
            if contactCategory.contains([.Player, .Enemy])
            {
                if contact.bodyA.category == .Player
                {
                    if let player = contact.bodyA.node as? SKSpriteNode, let enemy = contact.bodyB.node as? SKSpriteNode
                    {
                        collidedEnemyWithPlayer(Enemy: enemy, Player: player)
                    }
                }
                else
                {
                    if let enemy = contact.bodyA.node as? SKSpriteNode, let player = contact.bodyB.node as? SKSpriteNode
                    {
                        collidedEnemyWithPlayer(Enemy: enemy, Player: player)
                    }
                }
            }
            
            if contactCategory.contains([.Projectile, .Enemy])
            {
                if contact.bodyA.category == .Projectile
                {
                    if let projectile = contact.bodyA.node as? SKSpriteNode, let enemy = contact.bodyB.node as? SKSpriteNode
                    {
                        collidedEnemyWithProjectile(Enemy: enemy, Projectile: projectile)
                    }
                }
                else
                {
                    if let enemy = contact.bodyA.node as? SKSpriteNode, let projectile = contact.bodyB.node as? SKSpriteNode
                    {
                        collidedEnemyWithProjectile(Enemy: enemy, Projectile: projectile)
                    }
                }
            }
            
            
            if contactCategory.contains([.Player, .Wall])
            {
                didGameOver()
            }
        }
    }
}
