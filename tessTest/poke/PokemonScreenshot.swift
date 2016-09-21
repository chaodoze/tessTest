//
//  ScreenshotOCR.swift
//  tessTest
//
//  Created by Chao Lam on 9/8/16.
//  Copyright © 2016 Next Small Things. All rights reserved.
//

import Foundation
import UIKit
import TesseractOCR
import Firebase
import PromiseKit

class ScreenshotOCR {
  let screenshot:UIImage
  let tesseract = G8Tesseract(language: "eng")
  
  init(screenshot:UIImage) {
    self.screenshot = screenshot
    tesseract?.image = screenshot
  }
  
  func extractText(_ rect: CGRect)->String {
    tesseract?.rect = rect
    tesseract?.recognize()
    return tesseract!.recognizedText
  }
}

class PokemonOCR {
  typealias BoundaryDict = [String:[CGFloat]]
  static var attrsLocs:BoundaryDict?
  let screenshot: UIImage
  let ocr: ScreenshotOCR
  static func getAttrsLocs() -> Promise<BoundaryDict> {
    return Promise {fulfill, reject in
      if let cachedAttrs = attrsLocs {
        fulfill(cachedAttrs)
        return
      }
      let ref = FIRDatabase.database().reference().child("screenshotMeta")
      ref.observeSingleEvent(of: FIRDataEventType.value, with: {(snapshot) in
        attrsLocs = (snapshot.value as! BoundaryDict)
        fulfill(attrsLocs!)
      })
    }
  }
  
  init(screenshot:UIImage) {
    self.screenshot = screenshot
    self.ocr = ScreenshotOCR(screenshot: screenshot)
  }
  
  func fetchData()->Promise<[String:String]> {
    print("in PokemonOCR")
    return PokemonOCR.getAttrsLocs().then {attrsRects->[String:String] in
      var attrs = [String:String]()
      for (attr,rect) in attrsRects {
        let (width, height) = (self.screenshot.size.width, self.screenshot.size.height)
        let cgRect = CGRect(x:rect[0]*width, y:rect[1]*height, width:rect[2]*width, height:rect[3]*height)
        attrs[attr] = self.ocr.extractText(cgRect)
      }
      return attrs
    }
  }
}

class PokemonScreenshot {
  let screenshot:Screenshot
  let pokemonOcr:PokemonOCR
  let levelGuesser:PokemonLevelGuesser
  let trainerLevel:Int
  init(screenshot:Screenshot, trainerLevel:Int) {
    let image = screenshot.image
    self.screenshot = screenshot
    self.trainerLevel = trainerLevel
    self.pokemonOcr = PokemonOCR(screenshot: image!)
    self.levelGuesser = PokemonLevelGuesser(screenshot: image!, trainerLevel: trainerLevel)
  }
  
  func fetchData()->Promise<[String:String]> {
    print("in PokemonScreenshot.fetchData")
    return pokemonOcr.fetchData().then {stats in
      var stats = stats // stats is a let parameter
      return Promise {fulfill, reject in
        stats["url"] = self.screenshot.url
        stats["trainerLevel"] = String(self.trainerLevel)
        stats["level"] = String(self.levelGuesser.guessLevel())
        fulfill(stats)
      }
    }
  }
}
