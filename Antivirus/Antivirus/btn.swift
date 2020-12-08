//
//  btn.swift
//  Antivirus
//
//  Created by Adam Tan on 07/12/2020.
//  Copyright © 2020 TAN, ADAM (Student). All rights reserved.
//

import Foundation
import SpriteKit

class btn: SKSpriteNode
{
    var function: () -> Void = { print("Null") }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        self.isUserInteractionEnabled = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.isUserInteractionEnabled = true
        print("button pressed")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.isUserInteractionEnabled = true
        function()
    }
    
}
