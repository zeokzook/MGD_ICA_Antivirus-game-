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
    case back = 1
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
    
    let fireRate: Double = 1.5
    let moveAmtthreshold: CGFloat = 100.0
    
    override func didMove(to view: SKView)
    {
        backgroundColor = UIColor(displayP3Red: 0.545, green: 0, blue: 0, alpha: 1.0)
        
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        
        addChild(player)
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
        
        addChild(enemy)
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody?.isDynamic = true
        if(dimension == .front)
        {
            enemy.physicsBody?.categoryBitMask = PhysicsCategory.monsterFront
        }
        else if(dimension == .back)
        {
            enemy.physicsBody?.categoryBitMask = PhysicsCategory.monsterBack
        }
        
        
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        let actionMove = SKAction.move(to: CGPoint(x: -enemy.size.width/2, y: actualY), duration: TimeInterval(actualDuration))
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
            print("up")
        }
        else if moveAmtY > moveAmtthreshold
        {
            print("down")
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
    
    func switchDimension()
    {
        //switch player dimension
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
