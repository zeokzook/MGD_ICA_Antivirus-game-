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
    case null  = 5
}

struct WallType : OptionSet
{
    let rawValue: UInt8
    init(rawValue: UInt8) {self.rawValue = rawValue}
    
    static let None            = WallType([])
    static let longThin        = WallType(rawValue: 0b001) //1
    static let shortWideBot    = WallType(rawValue: 0b010) //2
    static let shortWideTop    = WallType(rawValue: 0b011) //3
    static let shortWideMid    = WallType(rawValue: 0b100) //4
    static let shorterWideTop  = WallType(rawValue: 0b101) //5
    static let shorterWideBot  = WallType(rawValue: 0b110) //6
}

struct PhysicsCategory : OptionSet
{
    let rawValue: UInt32
    init(rawValue: UInt32) {self.rawValue = rawValue}
    
    static let None            = PhysicsCategory([])
    static let All             = PhysicsCategory(rawValue: UInt32.max)
    static let Enemy           = PhysicsCategory(rawValue: 0b00000001) //1
    static let EnemyTutorial   = PhysicsCategory(rawValue: 0b00000010) //2
    static let Projectile      = PhysicsCategory(rawValue: 0b00000100) //4
    static let Wall            = PhysicsCategory(rawValue: 0b00001000) //8
    static let WallTutorial    = PhysicsCategory(rawValue: 0b00010000) //16
    static let WallAll         = PhysicsCategory(rawValue: 0b00100000) //32
    static let WallAllTutorial = PhysicsCategory(rawValue: 0b01000000) //64
    static let Player          = PhysicsCategory(rawValue: 0b10000000) //128
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
    let wallColorAll = UIColor(red: 0.663, green: 0.055, blue: 0.110, alpha: 1.0)
    
    var motionManager: CMMotionManager!
    var calibrated: Double!
    
    var doneCalibrate = false
    var currentDimension: DimensionFace = .front
    var time = Date()
    var tutorialDone = false
    var hasPaused = false
    static var gameOver  = false
    
    let projectileSpeed: Double = 0.5 //smaller number is faster
    let moveAmtthreshold: CGFloat = 100.0
    let playerSpeed: CGFloat = 5.0
    let shootDelay: TimeInterval = 0.25
    
    let difficultyScoreCounterIncrement = 5000
    var difficultyScoreThreshold: Int = 1500
    var difficultyScoreDeathThreshold: Int = 3000
    var difficultyScoreCounter: Int = 0
    var difficultyDurModifier: CGFloat = 1.0
    var difficultyScoreModifier: CGFloat = 1.0
    var difficultyExpectedScore: Int = 0
    var difficultyEnemyScale: CGFloat = 1.0
    
    var score: Int = 0
    let enemyScore: Int = 100
    let wallScore: Int = 300
    
    let defaults = UserDefaults.standard
    
    override func didMove(to view: SKView)
    {
        NotificationCenter.default.addObserver(self, selector: #selector(notifPause), name: .notifPause , object: nil)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeUp.direction = .up
        self.view?.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeDown.direction = .down
        self.view?.addGestureRecognizer(swipeDown)
        
        if(!defaults.bool(forKey: "Start Tutorial") || defaults.bool(forKey: "Skip Tutorial"))
        {
            setAllTutorialTrue()
        }
        
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
        scoreText.zPosition = 10
        scoreText.text = "Score: \(String(format: "%010d", score))"
        
        addChild(scoreText)
        
        let backgroundFade = SKSpriteNode(color: .black, size: CGSize(width: 340, height: 45))
        backgroundFade.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundFade.zPosition = 9
        backgroundFade.position = CGPoint(x: scoreText.position.x, y: scoreText.position.y + 10)
        backgroundFade.alpha = 0.6
        
        addChild(backgroundFade)
        
        //Setting up pause button
        buttonPause.setScale(0.5)
        buttonPause.zPosition = 10
        buttonPause.position = CGPoint(x: size.width - buttonPause.size.width / 2, y: size.height - buttonPause.size.height / 2)
        
        addChild(buttonPause)
        
        //Setting up CMMotion
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
    }
    
    var sentWave: Bool = false
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer)
    {
        if setupChangeDimenWall
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
            
            if(!tutorialDone && defaults.bool(forKey: "Start Tutorial") && !defaults.bool(forKey: "Skip Tutorial"))
            {
                tutorial()
            }
            else
            {
                if !sentWave
                {
                    /*waveType3()
                    sentWave = true*/
                    let i = random(min: 0.0, max: 6.0)
                    
                    if i < 2.0
                    {
                        waveType1()
                        sentWave = true
                    }
                    else if i > 2.0 && i < 4.0
                    {
                        waveType2()
                        sentWave = true
                    }
                    else if i > 4.0 && i < 6.0
                    {
                        waveType3()
                        sentWave = true
                    }
                }
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
            else if setupShoot
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
        textRecalibrateDone.zPosition = 10
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
            
            node.zPosition = 10
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
    
    var sorted = false
    
    func didGameOver()
    {
        print("Game Over!")
        
        self.isPaused = true
        physicsWorld.speed = 0
        GameScene.gameOver = true
        endScoreText.text = "Score: \(score)"
        
        player.removeFromParent()
        scoreText.removeFromParent()
        buttonPause.removeFromParent()
        
        self.enumerateChildNodes(withName: "loseMenu")
        {
            (node, stop)in
            
            node.zPosition = 20
        }
        
        if !sorted
        {
            sortHighScore()
        }
        
    }
    
    func restartGame()
    {
        print("Restarting")
        
        self.isPaused = false
        physicsWorld.speed = 1
        GameScene.gameOver = false
        sentWave = false
        currentDimension = .front
        sorted = false
        score = 0
        difficultyScoreCounter = 0
        difficultyDurModifier = 1.0
        difficultyScoreModifier = 1.0
        difficultyExpectedScore = 0
        
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        player.Dimension = currentDimension
        player.colorBlendFactor = 0.0
        
        addChild(player)
        addChild(scoreText)
        addChild(buttonPause)
        
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
        
        sorted = true
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
    var setupMovement: Bool = false
    var shootDone: Bool = false
    var setupShoot: Bool = false
    var changeDimenWallDone: Bool = false
    var setupChangeDimenWall: Bool = false
    var changeDimenEnemyDone: Bool = false
    var setupChangeDimenEnemy: Bool = false
    var avoidRedWallsDone: Bool = false
    var setupRedWalls: Bool = false
    var currentPlayerPos: CGFloat = 0
    let tutorialText = SKLabelNode(fontNamed: "ArialMT")
    
    func setAllTutorialTrue()
    {
        movementDone = true
        setupMovement = true
        shootDone = true
        setupShoot = true
        changeDimenWallDone = true
        setupChangeDimenWall = true
        changeDimenEnemyDone = true
        setupChangeDimenEnemy = true
        avoidRedWallsDone = true
        setupRedWalls = true
        tutorialDone = true
    }
    
    let enemyTutorialShoot = SKSpriteNode(imageNamed: "virus")
    func setupEnemyTutorialShoot()
    {
        enemyTutorialShoot.name = "Tutorial"
        
        enemyTutorialShoot.scale(to: CGSize(width: 40, height: 40))
        enemyTutorialShoot.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        enemyTutorialShoot.Dimension = .front
        
        addChild(enemyTutorialShoot)
        
        enemyTutorialShoot.physicsBody = SKPhysicsBody(circleOfRadius: enemyTutorialShoot.size.width/2)
        enemyTutorialShoot.physicsBody!.isDynamic = true
        enemyTutorialShoot.physicsBody!.affectedByGravity = false
        enemyTutorialShoot.physicsBody!.category = .EnemyTutorial
        enemyTutorialShoot.physicsBody!.collision = .None
        enemyTutorialShoot.physicsBody!.contact = .Player
    }
    
    func moveEnemyTutorialShoot(duration: CGFloat)
    {
        let y = 0.8 * size.height
        
        enemyTutorialShoot.position = CGPoint(x: size.width + enemyTutorialShoot.size.width / 2, y: y)
        
        let actionMove = SKAction.move(to: CGPoint(x: -enemyTutorialShoot.size.width/2, y: y), duration: TimeInterval(duration))
        let actionMoveDone = SKAction.move(to: CGPoint(x: size.width + enemyTutorialShoot.size.width / 2, y: y), duration: TimeInterval(0.0))
        
        enemyTutorialShoot.run(SKAction.repeatForever(SKAction.sequence([actionMove, actionMoveDone])))
    }
    
    var wallTutorial: SKShapeNode?
    func setupTutorialChangeWall()
    {
        let wallTutorialRect = CGRect(x:0, y:0, width: 100, height: size.height)
        wallTutorial = SKShapeNode(rect: wallTutorialRect)
        
        wallTutorial?.name = "wall"
        wallTutorial?.Dimension = currentDimension
        
        addChild(wallTutorial!)
        
        wallTutorial?.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: wallTutorialRect.width, height: wallTutorialRect.height), center: CGPoint(x: wallTutorialRect.width / 2, y: wallTutorialRect.height / 2))
        wallTutorial?.physicsBody!.affectedByGravity = false
        wallTutorial?.physicsBody!.collision = .None
        wallTutorial?.physicsBody!.contact = .Player
        wallTutorial?.physicsBody!.category = .WallTutorial
        
        wallTutorial?.fillColor = wallColorFront
        wallTutorial?.strokeColor = wallColorFront
    }
    
    func moveTutorialChangeWall(duration: CGFloat)
    {
        wallTutorial?.position = CGPoint(x: size.width, y: 0)
        
        let actionMove = SKAction.move(to: CGPoint(x: -wallTutorial!.frame.width, y: 0), duration: TimeInterval((duration)))
        let actionMoveDone = SKAction.run({
            SKAction.removeFromParent()
            self.changeDimenWallDone = true
        })
        
        wallTutorial?.run(SKAction.sequence([actionMove ,actionMoveDone]))
    }
    
    let enemyTutorialChange = SKSpriteNode(imageNamed: "virus")
    func setupTutorialChangeEnemy()
    {
        enemyTutorialChange.name = "Tutorial"
        
        enemyTutorialChange.scale(to: CGSize(width: 40, height: 40))
        enemyTutorialChange.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        enemyTutorialChange.Dimension = .front
        
        addChild(enemyTutorialChange)
        
        enemyTutorialChange.alpha = 0.5
        
        enemyTutorialChange.physicsBody = SKPhysicsBody(circleOfRadius: enemyTutorialShoot.size.width/2)
        enemyTutorialChange.physicsBody!.isDynamic = true
        enemyTutorialChange.physicsBody!.affectedByGravity = false
        enemyTutorialChange.physicsBody!.category = .EnemyTutorial
        enemyTutorialChange.physicsBody!.collision = .None
        enemyTutorialChange.physicsBody!.contact = .Player
    }
    
    func moveTutorialChangeEnemy(duration: CGFloat)
    {
        let y = 0.8 * size.height
        
        enemyTutorialChange.position = CGPoint(x: size.width + enemyTutorialChange.size.width / 2, y: y)
        
        let actionMove = SKAction.move(to: CGPoint(x: -enemyTutorialChange.size.width/2, y: y), duration: TimeInterval(duration))
        let actionMoveDone = SKAction.move(to: CGPoint(x: size.width + enemyTutorialChange.size.width / 2, y: y), duration: TimeInterval(0.0))
        
        enemyTutorialChange.run(SKAction.repeatForever(SKAction.sequence([actionMove, actionMoveDone])))
    }
    
    var redWallTutorial: SKShapeNode?
    func setupRedWallTutorial()
    {
        let wallTutorialRect = CGRect(x:0, y:0, width: 1000, height: size.height/3)
        redWallTutorial = SKShapeNode(rect: wallTutorialRect)
        
        redWallTutorial?.name = "wall"
        redWallTutorial?.Dimension = currentDimension
        
        addChild(redWallTutorial!)
        
        redWallTutorial?.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: wallTutorialRect.width, height: wallTutorialRect.height), center: CGPoint(x: wallTutorialRect.width / 2, y: wallTutorialRect.height / 2))
        redWallTutorial?.physicsBody!.affectedByGravity = false
        redWallTutorial?.physicsBody!.collision = .None
        redWallTutorial?.physicsBody!.contact = .Player
        redWallTutorial?.physicsBody!.category = .WallAllTutorial
        
        redWallTutorial?.fillColor = wallColorAll
        redWallTutorial?.strokeColor = wallColorAll
    }
    
    func moveRedWallTutorial(duration: CGFloat)
    {
        redWallTutorial?.position = CGPoint(x: size.width, y: size.height/3)
        
        let actionMove = SKAction.move(to: CGPoint(x: -redWallTutorial!.frame.width, y: size.height/3), duration: TimeInterval((duration)))
        let actionMoveDone = SKAction.run({
            SKAction.removeFromParent()
            self.avoidRedWallsDone = true
        })
        
        redWallTutorial?.run(SKAction.sequence([actionMove ,actionMoveDone]))
    }
    
    func tutorial()
    {
        tutorialText.preferredMaxLayoutWidth = 0.6 * size.width
        tutorialText.lineBreakMode = .byWordWrapping
        tutorialText.numberOfLines = 3
        tutorialText.fontSize = 55
        tutorialText.fontColor = SKColor.white
        tutorialText.position = CGPoint(x: frame.midX + 100, y: frame.midY)
        
        if !movementDone
        {
            if !setupMovement
            {
                tutorialText.text = "Tilt up or down to move up or down"
                currentPlayerPos = player.position.y
                setupMovement = true
                addChild(tutorialText)
            }
            
            print("movement tutorial")
            
            if player.position.y >= currentPlayerPos + 150 || player.position.y <= currentPlayerPos - 150
            {
                movementDone = true
                print("movement done")
            }
        }
        else if !shootDone
        {
            if !setupShoot
            {
                tutorialText.text = "Move up to the enemy to shoot"
                setupEnemyTutorialShoot()
                moveEnemyTutorialShoot(duration: 4.0)
                setupShoot = true
            }
            
            print("shooting tutorial")
        }
        else if !changeDimenWallDone
        {
            if !setupChangeDimenWall
            {
                tutorialText.text = "Swipe up or down to change colors and to avoid walls of the same color"
                setupTutorialChangeWall()
                moveTutorialChangeWall(duration: 4.0)
                setupChangeDimenWall = true
            }
            
            print("changing dimension tutorial (wall)")
        }
        else if !changeDimenEnemyDone
        {
            if !setupChangeDimenEnemy
            {
                tutorialText.text = "Swipe up or down to attack enemies of the same color!"
                setupTutorialChangeEnemy()
                moveTutorialChangeEnemy(duration: 4.0)
                setupChangeDimenEnemy = true
            }
            
            print("changing dimension tutorial (shoot)")
        }
        else if !avoidRedWallsDone
        {
            print("Avoid Red Walls tutorial")
            if !setupRedWalls
            {
                tutorialText.text = "Avoid red walls!"
                setupRedWallTutorial()
                moveRedWallTutorial(duration: 4.0)
                setupRedWalls = true
            }
            
        }
        else if movementDone && shootDone && changeDimenWallDone && changeDimenEnemyDone && avoidRedWallsDone
        {
            run(SKAction.sequence([
                SKAction.run({self.tutorialText.text = "Tutorial Complete! Have fun!"}),
                SKAction.wait(forDuration: 1.5),
                SKAction.run({
                    self.tutorialText.removeFromParent()
                    self.tutorialDone = true
                })
            ]))
            setAllTutorialTrue()
            score = 0
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
            
            if(accelerometerData.acceleration.x <= 0)
            {
                if accelerometerData.acceleration.x > calibrated + 0.035
                {
                    let x = (calibrated + 0.085) / accelerometerData.acceleration.x //0.585       0.1
                    let playerSpeedChanged = playerSpeed * CGFloat(x)
                    player.position.y += playerSpeedChanged
                    playerAimGuide?.position.y += playerSpeed * CGFloat(x)
                }
                
                if accelerometerData.acceleration.x < calibrated - 0.02
                {
                    var x = accelerometerData.acceleration.x / (calibrated - 0.07)
                    if(accelerometerData.acceleration.x < -0.9)
                    {
                        x = accelerometerData.acceleration.x * 1.4 / (calibrated - 0.07)
                    }
                    let playerSpeedChanged = playerSpeed * CGFloat(x)
                    player.position.y -= playerSpeedChanged
                    playerAimGuide?.position.y -= playerSpeed * CGFloat(x)
                }
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
    
    func addEnemy(dimension: DimensionFace, y: CGFloat = 0, duration: CGFloat = 0, name: String = "enemy")
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
        
        enemy.name = name
        
        let actualScale = CGSize(width: enemyScale.width * difficultyEnemyScale, height: enemyScale.height * difficultyEnemyScale)
        
        enemy.scale(to: actualScale)
        enemy.position = CGPoint(x: size.width + enemy.size.width/2, y: y)
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

        let actionMove = SKAction.move(to: CGPoint(x: -enemy.size.width/2, y: y), duration: TimeInterval(duration * difficultyDurModifier))
        let removeScore = SKAction.run { self.score -= self.enemyScore }
        let actionMoveDone = SKAction.removeFromParent()
        
        let actualScore = CGFloat(enemyScore) * difficultyScoreModifier
        difficultyExpectedScore += Int(actualScore)
        enemy.run(SKAction.sequence([actionMove, removeScore, actionMoveDone]))
    }
    //ADD ENEMY END
    
    //ADD WALL
    func addWall(dimension: DimensionFace, wallType: WallType, wallDuration: CGFloat, affectAll: Bool = false)
    {
        var wallRect: CGRect = CGRect(x:0, y:0, width:0, height:0)
        var y: CGFloat = 0
        if wallType == .longThin
        {
            wallRect = CGRect(x:0, y:0, width: 100, height: size.height)
            y = 0
        }
        else if wallType == .shortWideTop
        {
            wallRect = CGRect(x:0, y:0, width: 1000, height: size.height/2)
            y = size.height/2
        }
        else if wallType == .shortWideBot
        {
            wallRect = CGRect(x:0, y:0, width: 1000, height: size.height/2)
            y = 0
        }
        else if wallType == .shortWideMid
        {
            wallRect = CGRect(x:0, y:0, width: 1000, height: size.height/3)
            y = size.height/3
        }
        else if wallType == .shorterWideTop
        {
            wallRect = CGRect(x:0, y:0, width: 1000, height: size.height/3)
            y = 0
        }
        else if wallType == .shorterWideBot
        {
            wallRect = CGRect(x:0, y:0, width: 1000, height: size.height/3)
            y = size.height/3 * 2
        }
        
        let wall = SKShapeNode(rect: wallRect)
    
        wall.name = "wall"
        wall.position = CGPoint(x: size.width, y: y)
        wall.Dimension = dimension
        
        addChild(wall)
        
        wall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: wallRect.width, height: wallRect.height), center: CGPoint(x: wallRect.width / 2, y: wallRect.height / 2))
        wall.physicsBody!.affectedByGravity = false
        wall.physicsBody!.collision = .None
        wall.physicsBody!.contact = .Player
        
        if affectAll
        {
            wall.fillColor = wallColorAll
            wall.strokeColor = wallColorAll
            wall.physicsBody!.category = .WallAll
        }
        else
        {
            wall.physicsBody!.category = .Wall
            
            if dimension == .front
            {
                wall.fillColor = wallColorFront
                wall.strokeColor = wallColorFront
            }
            else if dimension == .back
            {
                wall.fillColor = wallColorBack
                wall.strokeColor = wallColorBack
            }
        }
        
        if currentDimension == dimension || affectAll
        {
            wall.alpha = 1.0
        }
        else
        {
            wall.alpha = 0.5
        }
        
        let actualDuration = wallDuration * difficultyDurModifier
        let actionMove = SKAction.move(to: CGPoint(x: -wallRect.width, y: y), duration: TimeInterval((actualDuration)))
        let actionMoveDone = SKAction.removeFromParent()
        let actionAddScore = SKAction.run { self.score += self.wallScore }
        
        difficultyExpectedScore += wallScore
        wall.run(SKAction.sequence([actionMove, actionAddScore ,actionMoveDone]))
    }
    //ADD WALL END
    
    func shoot(dimension: DimensionFace, after timeInterval: Double)
    {
        guard Date() - timeInterval > time else {
            return
        }

        let projectile = SKSpriteNode(imageNamed: "antibody")
        
        projectile.position = player.position
        projectile.name = "bullet"
        projectile.setScale(1.5)
        projectile.Dimension = dimension
        
        addChild(projectile)
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2 - 2)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody!.affectedByGravity = false
        projectile.physicsBody?.usesPreciseCollisionDetection = true
        projectile.physicsBody!.category = .Projectile
        projectile.physicsBody!.collision = .None
        
        if tutorialDone
        {
            projectile.physicsBody!.contact = .Enemy
        }
        else
        {
            projectile.physicsBody!.contact = .EnemyTutorial
        }
        
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
        
        if toDimension == .front
        {
            player.colorBlendFactor = 0.0
            playerAimGuide?.fillColor = .white
        }
        else if toDimension == .back
        {
            player.colorBlendFactor = 0.8
            playerAimGuide?.fillColor = UIColor(red: 1.0, green: 0.612, blue: 0.0, alpha: 0.6)
        }
        
        self.enumerateChildNodes(withName: "*")
        {
            (node, _)in
            
            if node.name == "enemy" || node.name == "wall" || node.name == "bullet" || node.name == "Tutorial"
            {
                if node.physicsBody?.category != .WallAll
                {
                    if toDimension == .front
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
                    else if toDimension == .back
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
    }
    
    func updateScore()
    {
        scoreText.text = "Score: \(String(format: "%010d", score))"
    }
    
    func difficultyModifier()
    {
        if difficultyExpectedScore > difficultyScoreCounter + difficultyScoreCounterIncrement
        {
            print("duration decreased!")
            difficultyDurModifier -= 0.05
            difficultyScoreCounter += difficultyScoreCounterIncrement
        }
        
        if score < difficultyExpectedScore - difficultyScoreThreshold
        {
            print("smaller enemies, more score!")
            difficultyEnemyScale = 0.5
            difficultyScoreModifier = 1.5
        }
        
        if score < difficultyExpectedScore - difficultyScoreDeathThreshold
        {
            print("Too low from expected score!")
            addWall(dimension: .null, wallType: .longThin, wallDuration: 0.5, affectAll: true)
        }
    }
    
    //WAVES
    func waveType1()
    {
        print("Wave Type 1")
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
            SKAction.run({self.addEnemy(dimension: curDimension, y: screenYCenter, duration: dur )}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: curDimension, y: screenYCenter + (0.15 * screenHeight), duration: dur )}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: curDimension, y: screenYCenter - (0.15 * screenHeight), duration: dur )}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: curDimension, y: screenYCenter + (0.30 * screenHeight), duration: dur )}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: curDimension, y: screenYCenter - (0.30 * screenHeight), duration: dur )}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: curDimension, y: screenYCenter, duration: dur )}),
            SKAction.wait(forDuration: 2.0),
            SKAction.run({self.addWall(dimension: curDimension, wallType: .longThin, wallDuration: dur)}),
            SKAction.wait(forDuration: 1.5),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter + (0.40 * screenHeight), duration: dur)}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter + (0.15 * screenHeight), duration: dur)}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter + (0.30 * screenHeight), duration: dur)}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter - (0.15 * screenHeight), duration: dur)}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter, duration: dur)}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter - (0.40 * screenHeight), duration: dur)}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter - (0.30 * screenHeight), duration: dur)}),
            SKAction.wait(forDuration: 1.8),
            SKAction.run({self.addWall(dimension: .null, wallType: .shortWideBot, wallDuration: 5.0, affectAll: true)}),
            SKAction.wait(forDuration: 0.3),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter + (0.10 * screenHeight), duration: dur)}),
            SKAction.wait(forDuration: 0.5),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter + (0.25 * screenHeight), duration: dur)}),
            SKAction.wait(forDuration: 0.5),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter + (0.10 * screenHeight), duration: dur)}),
            SKAction.wait(forDuration: 0.5),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter + (0.40 * screenHeight), duration: dur)}),
            SKAction.wait(forDuration: 0.5),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter + (0.25 * screenHeight), duration: dur)}),
            SKAction.wait(forDuration: 0.5),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: screenYCenter + (0.45 * screenHeight), duration: dur)}),
            SKAction.wait(forDuration: 1.5),
            SKAction.run({self.addWall(dimension: .null, wallType: .shortWideTop, wallDuration: 4.5, affectAll: true)}),
            SKAction.wait(forDuration: 4.0),
            SKAction.run({
                self.sentWave = false
                self.difficultyModifier()
            })
        ]))
    }
    
    func waveType2()
    {
        print("Wave Type 2")
        let dur: CGFloat = 3.5
        
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
            SKAction.run({self.addWall(dimension: .null, wallType: .shortWideBot, wallDuration: dur, affectAll: true)}),
            SKAction.wait(forDuration: 2.5),
            SKAction.run({self.addWall(dimension: .null, wallType: .shortWideTop, wallDuration: dur, affectAll: true)}),
            SKAction.wait(forDuration: 2.5),
            SKAction.run({self.addWall(dimension: curDimension, wallType: .longThin, wallDuration: 2.0)}),
            SKAction.wait(forDuration: 1.5),
            SKAction.run({self.addWall(dimension: .null, wallType: .shorterWideTop, wallDuration: dur, affectAll: true)}),
            SKAction.run({self.addWall(dimension: .null, wallType: .shorterWideBot, wallDuration: dur, affectAll: true)}),
            SKAction.wait(forDuration: 2.5),
            SKAction.run({self.addWall(dimension: .null, wallType: .shortWideTop, wallDuration: dur, affectAll: true)}),
            SKAction.wait(forDuration: 2.5),
            SKAction.run({self.addWall(dimension: .null, wallType: .shortWideBot, wallDuration: dur, affectAll: true)}),
            SKAction.wait(forDuration: 2.5),
            SKAction.run({self.addWall(dimension: .null, wallType: .shortWideMid, wallDuration: dur, affectAll: true)}),
            SKAction.wait(forDuration: 2.5),
            SKAction.run({self.addWall(dimension: oppositeDimension, wallType: .longThin, wallDuration: 2.0)}),
            SKAction.wait(forDuration: 1.5),
            SKAction.run({
                self.sentWave = false
                self.difficultyModifier()
            })
        ]))
    }
    
    func waveType3()
    {
        print("Wave Type 3")
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
            SKAction.run({self.addEnemy(dimension: curDimension, y: 0.80 * screenHeight, duration: dur)}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: curDimension, y: 0.60 * screenHeight, duration: dur)}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: curDimension, y: 0.40 * screenHeight, duration: dur)}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: curDimension, y: 0.20 * screenHeight, duration: dur)}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: curDimension, y: 0.40 * screenHeight, duration: dur)}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: curDimension, y: 0.60 * screenHeight, duration: dur)}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: curDimension, y: 0.80 * screenHeight, duration: dur)}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: curDimension, y: 0.60 * screenHeight, duration: dur)}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: curDimension, y: 0.40 * screenHeight, duration: dur)}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: curDimension, y: 0.20 * screenHeight, duration: dur)}),
            SKAction.wait(forDuration: 2.0),
            SKAction.run({self.addWall(dimension: .null, wallType: .shorterWideTop, wallDuration: 3.0, affectAll: true)}),
            SKAction.run({self.addWall(dimension: .null, wallType: .shorterWideBot, wallDuration: 3.0, affectAll: true)}),
            SKAction.run({self.addEnemy(dimension: curDimension, y: screenYCenter, duration: dur)}),
            SKAction.wait(forDuration: 0.5),
            SKAction.run({self.addEnemy(dimension: curDimension, y: screenYCenter, duration: dur)}),
            SKAction.wait(forDuration: 0.5),
            SKAction.run({self.addEnemy(dimension: curDimension, y: screenYCenter, duration: dur)}),
            SKAction.wait(forDuration: 0.5),
            SKAction.run({self.addEnemy(dimension: curDimension, y: screenYCenter, duration: dur)}),
            SKAction.wait(forDuration: 1.5),
            SKAction.run({self.addWall(dimension: curDimension, wallType: .longThin, wallDuration: 2.0)}),
            SKAction.wait(forDuration: 0.5),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: 0.20 * screenHeight, duration: dur)}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: 0.40 * screenHeight, duration: dur)}),
            SKAction.wait(forDuration: 0.5),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: 0.60 * screenHeight, duration: dur)}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: 0.80 * screenHeight, duration: dur)}),
            SKAction.wait(forDuration: 0.5),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: 0.60 * screenHeight, duration: dur)}),
            SKAction.wait(forDuration: 1),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: 0.40 * screenHeight, duration: dur)}),
            SKAction.wait(forDuration: 0.5),
            SKAction.run({self.addEnemy(dimension: oppositeDimension, y: 0.20 * screenHeight, duration: dur)}),
            SKAction.wait(forDuration: 1.5),
            SKAction.run({
                self.sentWave = false
                self.difficultyModifier()
            })
        ]))
    }
    //WAVES END
    
    func tutorialCollidedEnemyWithPlayer(EnemyTutorial: SKSpriteNode, Player: SKSpriteNode)
    {
        EnemyTutorial.removeAllActions()
        EnemyTutorial.removeFromParent()
        
        if EnemyTutorial == enemyTutorialShoot
        {
            moveEnemyTutorialShoot(duration: 4.0)
            addChild(EnemyTutorial)
        }
        else if EnemyTutorial == enemyTutorialChange
        {
            moveTutorialChangeEnemy(duration: 4.0)
            addChild(EnemyTutorial)
        }
    }
    
    func tutorialCollidedEnemyWithProjectile(EnemyTutorial: SKSpriteNode, Projectile: SKSpriteNode)
    {
        EnemyTutorial.removeFromParent()
        Projectile.removeFromParent()
        
        if EnemyTutorial == enemyTutorialShoot
        {
            shootDone = true
        }
        else if EnemyTutorial == enemyTutorialChange
        {
            changeDimenEnemyDone = true
        }
    }
    
    func tutorialCollidedWallWithPlayer()
    {
        if !changeDimenWallDone
        {
            wallTutorial!.removeFromParent()
            wallTutorial!.removeAllActions()
            addChild(wallTutorial!)
            wallTutorial?.run(SKAction.move(to: CGPoint(x: size.width, y: 0), duration: TimeInterval(0.0)))
            moveTutorialChangeWall(duration: 4.0)
        }
        else if !avoidRedWallsDone && changeDimenWallDone
        {
            redWallTutorial!.removeFromParent()
            redWallTutorial!.removeAllActions()
            addChild(redWallTutorial!)
            redWallTutorial?.run(SKAction.move(to: CGPoint(x: size.width, y: 0), duration: TimeInterval(0.0)))
            moveRedWallTutorial(duration: 4.0)
        }
    }
    
    func collidedEnemyWithProjectile(Enemy: SKSpriteNode, Projectile: SKSpriteNode)
    {
        Enemy.removeFromParent()
        Projectile.removeFromParent()
        
        let actualEarnedScore = CGFloat(enemyScore) * difficultyScoreModifier
        score += Int(actualEarnedScore)
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
        let contactCategory: PhysicsCategory = [contact.bodyA.category, contact.bodyB.category]
        
        if contact.bodyA.node?.Dimension == contact.bodyB.node?.Dimension
        {
            if contactCategory.contains([.Player, .Enemy])
            {
                didGameOver()
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
            
            if !tutorialDone
            {
                if contactCategory.contains([.Player, .EnemyTutorial])
                {
                    if contact.bodyA.category == .Player
                    {
                        if let player = contact.bodyA.node as? SKSpriteNode, let enemyTutorial = contact.bodyB.node as? SKSpriteNode
                        {
                            tutorialCollidedEnemyWithPlayer(EnemyTutorial: enemyTutorial, Player: player)
                        }
                    }
                    else
                    {
                        if let enemyTutorial = contact.bodyA.node as? SKSpriteNode, let player = contact.bodyB.node as? SKSpriteNode
                        {
                            tutorialCollidedEnemyWithPlayer(EnemyTutorial: enemyTutorial, Player: player)
                        }
                    }
                }
                
                if contactCategory.contains([.Projectile, .EnemyTutorial])
                {
                    if contact.bodyA.category == .Projectile
                    {
                        if let projectile = contact.bodyA.node as? SKSpriteNode, let enemyTutorial = contact.bodyB.node as? SKSpriteNode
                        {
                            tutorialCollidedEnemyWithProjectile(EnemyTutorial: enemyTutorial, Projectile: projectile)
                        }
                    }
                    else
                    {
                        if let enemyTutorial = contact.bodyA.node as? SKSpriteNode, let projectile = contact.bodyB.node as? SKSpriteNode
                        {
                            tutorialCollidedEnemyWithProjectile(EnemyTutorial: enemyTutorial, Projectile: projectile)
                        }
                    }
                }
                
                if contactCategory.contains([.Player, .WallTutorial])
                {
                    tutorialCollidedWallWithPlayer()
                }
            }
        }
        else if contactCategory.contains([.WallAll, .Player])
        {
            didGameOver()
        }
        else if contactCategory.contains([.WallAllTutorial, .Player])
        {
            
        }
    }
}
