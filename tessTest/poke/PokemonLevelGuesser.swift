//
//  PokemonLevelGuesser.swift
//  tessTest
//
//  Created by Chao Lam on 9/6/16.
//  Copyright © 2016 Next Small Things. All rights reserved.
//

import Foundation
import UIKit

class PokemonLevelGuesser {
  static let cpMultiplier = [0.0939999967813492, 0.135137432089339, 0.166397869586945, 0.192650913155325, 0.215732470154762,
                             0.236572651424822, 0.255720049142838, 0.273530372106572, 0.290249884128571, 0.306057381389863,
                             0.321087598800659, 0.335445031996451, 0.349212676286697, 0.362457736609939, 0.375235587358475,
                             0.387592407713878, 0.399567276239395, 0.4111935532161, 0.422500014305115, 0.432926420512509,
                             0.443107545375824, 0.453059948165049, 0.46279838681221, 0.472336085311278, 0.481684952974319,
                             0.490855807179549, 0.499858438968658, 0.5087017489616, 0.517393946647644, 0.525942516110322,
                             0.534354329109192, 0.542635753803599, 0.550792694091797, 0.558830584490385, 0.566754519939423,
                             0.57456912814537, 0.582278907299042, 0.589887907888945, 0.597400009632111, 0.604823648665171,
                             0.61215728521347, 0.619404107958234, 0.626567125320435, 0.633649178748576, 0.6406529545784,
                             0.647580971386554, 0.654435634613037, 0.661219265805859, 0.667934000492096, 0.674581885647492,
                             0.681164920330048, 0.687684901255373, 0.694143652915955, 0.700542901033063, 0.706884205341339,
                             0.713169074873823, 0.719399094581604, 0.725575586915154, 0.731700003147125, 0.734741038550429,
                             0.737769484519958, 0.740785579737136, 0.743789434432983, 0.746781197247765, 0.749761044979095,
                             0.752729099732281, 0.75568550825119, 0.758630370209851, 0.761563837528229, 0.76448604959218,
                             0.767397165298462, 0.770297293677362, 0.773186504840851, 0.776064947064992, 0.778932750225067,
                             0.781790050767666, 0.784636974334717, 0.787473608513275, 0.790300011634827]
  
  let screenshot: UIImage
  let width, height, centerX, centerY: Int
  let radius: Double
  let trainerLevel: Int
  var arcX = [Int]()
  var arcY = [Int]()
  var context: CGContext? = nil
  
  static func levelToLevelIndex(_ level:Double)->Int {
    return Int((level-1)*2)
  }
  
  static func levelIndexToLevel(_ index:Int)->Double {
    return Double(index)*0.5+1
  }
  
  init(screenshot:UIImage, trainerLevel:Int) {
    self.screenshot = screenshot
    self.width = Int(screenshot.size.width)
    self.height = Int(screenshot.size.height)
    self.trainerLevel = trainerLevel
    centerX =  Int(screenshot.size.width*0.5)
    centerY = Int(screenshot.size.height/2.803943)
    radius = Double(screenshot.size.height)/4.3760683
    
    let cpM = PokemonLevelGuesser.cpMultiplier
    let maxLevelIndex = maxMonLevelIndex()
    let baseCpM = cpM[0]
    let maxCpMDelta = cpM[min(maxLevelIndex+1, cpM.count-1)] - baseCpM
    for index in 0...maxLevelIndex {
      let delta = cpM[index]-baseCpM
      let arcRatio = delta/maxCpMDelta
      let angleInRadians = (arcRatio+1)*M_PI //@@@ use CGFloat.pi in Swift 3
      arcX.append(Int(Double(centerX)+radius*cos(angleInRadians)))
      arcY.append(Int(Double(centerY)+radius*sin(angleInRadians)))
    }
  }
  
  func maxMonLevel()->Double {
    return min(Double(trainerLevel)+1.5, 40)
  }
  
  func maxMonLevelIndex()->Int {
    return PokemonLevelGuesser.levelToLevelIndex(maxMonLevel())
  }
  
  func getScreenshotContext()->CGContext {
    if let context = self.context {
      return context
    }
    else {
      let cgImage = screenshot.cgImage
      let width = Int(screenshot.size.width)
      let height = Int(screenshot.size.height)
      let colorSpace = CGColorSpaceCreateDeviceRGB()
      let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4, space: colorSpace, bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)!
      context.draw(cgImage!, in:CGRect(x:0,y:0,width:width, height:height))
      return context
    }
  }
  
  func getPixelValue(x:Int, y:Int)-> (red:Int, green:Int, blue:Int)? {
    let context = getScreenshotContext()
    let rawData = context.data
    let data = rawData!.bindMemory(to: UInt8.self, capacity: width*height*4)
    let pixelData = ((width * y) + x) * 4
    return (red:Int(data[pixelData+0]), green:Int(data[pixelData+1]), blue:Int(data[pixelData+2]))
  }
  
  func guessLevel()->Double {
    var estLevel = maxMonLevel()
    repeat {
      let index = PokemonLevelGuesser.levelToLevelIndex(estLevel)
      let (x,y) = (arcX[index], arcY[index])
      if let pixelValue = getPixelValue(x: x, y: y) {
        print("pixelValue", x, y, pixelValue.red, pixelValue.green, pixelValue.blue, estLevel)
//        if pixelValue.red==255 && pixelValue.green==255 && pixelValue.blue==255 {
//          return estLevel
//        }
      }
      estLevel -= 0.5
    } while estLevel >= 1.0
    return 1.0
  }
  
}

