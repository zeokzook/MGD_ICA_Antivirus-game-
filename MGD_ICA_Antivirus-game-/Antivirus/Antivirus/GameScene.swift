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

struct PhysicsCategory : OptionSet
{
    let rawValue: UInt32
    init(rawValue: UInt32) {self.rawValue = rawValue}
    
    static let None            = PhysicsCategory(rawValue: 0b000000)
    static let All             = PhysicsCategory(rawValue: UInt32.max)
    static let Enemy           = PhysicsCategory(rawValue: 0b0001)
    static let Projectile      = PhysicsCategory(rawValue: 0b0010)
    static let Wall            = PhysicsCategory(rawValue: 0b0100)
    static let Player          = PhysicsCategory(rawValue: 0b1000)
}

class GameScene: SKScene
{
    let player = SKSpriteNode(imageNamed: "BCell")
    var moveAmtY: CGFloat = 0
    var initPos: CGPoint = CGPoint.zero
    var initTouch: CGPoint = CGPoint.zero
    var currentDimension: DimensionFace = .front
    
    let projectileSpeed: Double = 0.5 //smaller number is faster
    let moveAmtthreshold: CGFloat = 100.0

    let bgColor = SKColor(red: 0.23, green: 0.0, blue: 0.0, alpha: 1.0)
    let wallColor = UIColor(red: 0.90, green: 0.0, blue: 0.0, alpha: 1.0)
    
    var wallTimer = 0
    
    var motionManager: CMMotionManager!
    
    var collidedCounter = 0
    
    override func didMove(to view: SKView)
    {
        backgroundColor = bgColor
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width/2)
        player.physicsBody!.category = .Player
        player.physicsBody!.collision = .None
        player.Dimension = currentDimension
        
        addChild(player)
        
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run({
                    let i = self.random(min:0.0, max:5.0)
                    
                    self.wallTimer += 1
                    
                    if(self.wallTimer == 10)
                    {
                        self.addWall(dimension: self.currentDimension)
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
        ))
        
        //run(SKAction.run({self.addWall(dimension: .front)}))
    }
    
    override func update(_ currentTime: TimeInterval)
    {
        #if targetEnvironment(simulator)
        #else
        if let accelerometerData = motionManager.accelerometerData
        {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y * -50, dy: accelerometerData.acceleration.x * -50)
        }
        #endif
    }
    
    func random() -> CGFloat
    {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat
    {
        return random() * (max - min) + min
    }
    
    func addEnemy(dimension: DimensionFace)
    {
        let enemy = SKSpriteNode(imageNamed: "RedVirus")
        
        enemy.name = "editable"
        
        let actualY = random(min: enemy.size.height/2, max: size.height - enemy.size.height/2)
        //let actualY = player.position.y
        
        enemy.position = CGPoint(x: size.width + enemy.size.width/2, y:actualY )
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

        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        let actionMove = SKAction.move(to: CGPoint(x: -enemy.size.width/2, y:actualY), duration: TimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        
        enemy.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    func addWall(dimension: DimensionFace)
    {
        let wallRect = CGRect(x:0, y:0, width: 100, height: size.height)
        let wall = SKShapeNode(rect: wallRect)
        
        wall.name = "editable"
        
        wall.position = CGPoint(x: size.width + 1000, y: 0)
        wall.fillColor = wallColor
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
        
        let actualDuration = 4.0
        let actionMove = SKAction.move(to: CGPoint(x: -1000, y:0), duration: TimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        let actionResetTimer = SKAction.run {
            self.wallTimer = 0
        }
        
        wall.run(SKAction.sequence([actionMove, actionMoveDone, actionResetTimer]))
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if let touch = touches.first as UITouch?
        {
            initTouch = touch.location(in: self.scene!.view)
            moveAmtY = 0
            initPos = self.position
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if let touch = touches.first as UITouch?
        {
            let movingPoint: CGPoint = touch.location(in: self.scene!.view)
            
            moveAmtY = movingPoint.y - initTouch.y
        }
        
    }

    //Shooting
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if moveAmtY < -moveAmtthreshold
        {
            if(currentDimension != .back)
            {
                print("Moving to back")
                switchDimension(toDimension: .back)
            }
        }
        else if moveAmtY > moveAmtthreshold
        {
            if(currentDimension != .front)
            {
                print("Moving to front")
                switchDimension(toDimension: .front)
            }
            
        }
        else
        {
            shoot(dimension: currentDimension)
        }
    }
    
    func shoot(dimension: DimensionFace)
    {
        let projectile = SKSpriteNode(imageNamed:"Antibody")
        projectile.position = player.position
        projectile.name = "editable"
        
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
    }
    
    func switchDimension(toDimension: DimensionFace)
    {
        currentDimension = toDimension
        player.Dimension = toDimension
        
        self.enumerateChildNodes(withName: "editable")
        {
            (node, stop)in
            
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
    
    func PlayerDied()
    {
        print("Oh no you dead!")
        
        let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
        let gameOverScene = GameOverScene(size: self.size, won: false)
        self.view?.presentScene(gameOverScene, transition: reveal)
    }
    
    func collidedEnemyWithPlayer(Enemy: SKSpriteNode, Player: SKSpriteNode)
    {
        collidedCounter += 1
        print("Player Collided #\(collidedCounter)")
        PlayerDied()
    }
    
    func collidedEnemyWithProjectile(Enemy: SKSpriteNode, Projectile: SKSpriteNode)
    {
        Enemy.removeFromParent()
        Projectile.removeFromParent()
        
        collidedCounter += 1
        print("Projectile Collided #\(collidedCounter)")
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
            
            
            if contactCategory.contains([.Wall, .Player])
            {
                PlayerDied()
            }
        }
        
    }
}
