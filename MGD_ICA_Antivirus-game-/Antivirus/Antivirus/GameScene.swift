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
}
