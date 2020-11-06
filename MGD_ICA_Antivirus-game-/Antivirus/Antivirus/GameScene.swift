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
    let player = SKSpriteNode()
    
    override func didMove(to view: SKView)
    {
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
