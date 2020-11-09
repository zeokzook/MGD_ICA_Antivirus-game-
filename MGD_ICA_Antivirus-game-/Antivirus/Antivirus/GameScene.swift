//
//  GameScene.swift
//  Antivirus
//
//  Created by TAN, ADAM (Student) on 06/11/2020.
//  Copyright © 2020 TAN, ADAM (Student). All rights reserved.
//

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

enum DimensionFace: UInt8
{
    case front = 0
    case back = 0b1
    case null = 0b11111111
}

struct PhysicsCategory
{
     static let none           : UInt32 = 0
     static let all            : UInt32 = UInt32.max
     static let playerFront    : UInt32 = 0b1   //1
     static let playerBack     : UInt32 = 0b10  //2
     static let monsterFront   : UInt32 = 0b11  //3
     static let projectileFront: UInt32 = 0b100 //4
     static let monsterBack    : UInt32 = 0b101 //5
     static let projectileBack : UInt32 = 0b110 //6
}

class GameScene: SKScene
{
    let player = SKSpriteNode(imageNamed: "BCell")
    var moveAmtY: CGFloat = 0
    var initPos: CGPoint = CGPoint.zero
    var initTouch: CGPoint = CGPoint.zero
    var currentDimension: DimensionFace = .front
    
    let fireRate: Double = 1.5
    let moveAmtthreshold: CGFloat = 100.0
    
    override func didMove(to view: SKView)
    {
        backgroundColor = SKColor.white
        
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width/2)
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = PhysicsCategory.playerFront

        addChild(player)
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run({
                    let i = self.random(min:0.0, max:5.0)
                    if(i <= 2.0)
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
        
        let actualY = random(min: enemy.size.height/2, max: size.height - enemy.size.height/2)
        
        enemy.position = CGPoint(x: size.width + enemy.size.width/2, y:actualY )
        
        addChild(enemy)
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemy.size.width/2)
        enemy.physicsBody?.isDynamic = true
        enemy.physicsBody?.affectedByGravity = false
        if(dimension == .front)
        {
            enemy.physicsBody?.categoryBitMask = PhysicsCategory.monsterFront
            enemy.physicsBody?.collisionBitMask = PhysicsCategory.playerFront
        }
        else if(dimension == .back)
        {
            enemy.physicsBody?.categoryBitMask = PhysicsCategory.monsterBack
            enemy.physicsBody?.collisionBitMask = PhysicsCategory.playerBack
        }
        
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
            print("Moving to back")
            switchDimension(toDimension: .back)
        }
        else if moveAmtY > moveAmtthreshold
        {
            print("Moving to front")
            switchDimension(toDimension: .front)
        }
        else
        {
            let projectile = SKSpriteNode(imageNamed:"Antibody")
            projectile.position = player.position
            
            addChild(projectile)
            
            let shootAmount = projectile.position.x * 10
            let realDest = CGPoint(x: shootAmount, y:0) + projectile.position
            let actionRotate = SKAction.rotate(byAngle: -(CGFloat.pi)/2, duration: 0)
            let actionMove = SKAction.move(to: realDest, duration: fireRate)
            let actionMoveDone = SKAction.removeFromParent()
            projectile.run(SKAction.sequence([actionRotate, actionMove, actionMoveDone]))
            
        }
    }
    
    func switchDimension(toDimension: DimensionFace)
    {
        currentDimension = toDimension
        
        //player.physicsBody?.collisionBitMask =
        //changing a global variable(?) to set image alphas?
    }
    
    func playerMovement()
    {
        //Player move up and down depending on gyroscope
    }
    
    func collided(NodeA: SKSpriteNode, NodeB: SKSpriteNode)
    {
        
    }
    
}

extension GameScene: SKPhysicsContactDelegate
{
    func didBegin(_ contact: SKPhysicsContact)
    {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask
        {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }
        else
        {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        
    }
}
