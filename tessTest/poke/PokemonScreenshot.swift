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
  let width: CGFloat
  let height: CGFloat
  let tesseract = G8Tesseract(language: "eng")
  
  init(screenshot:UIImage) {
    self.screenshot = screenshot
    self.width = screenshot.size.width
    self.height = screenshot.size.height
    tesseract?.image = screenshot.g8_blackAndWhite()
  }
  
  func extractText(_ spec: OCRSpec)->String {
    if let blackList = spec.blackList {
      tesseract?.charBlacklist = blackList
    }
    else {
      tesseract?.charBlacklist = ""
    }
    if let whiteList = spec.whiteList {
      tesseract?.charWhitelist = whiteList
      print("got whitelist", whiteList)
    }
    else {
      tesseract?.charWhitelist = ""
    }
    let rect = spec.rect
    tesseract?.rect = CGRect(x:rect[0]*width, y:rect[1]*height, width:rect[2]*width, height:rect[3]*height)
    tesseract?.recognize()
    return tesseract!.recognizedText
  }
}

class OCRSpec {
  let rect: [CGFloat]
  var whiteList: String? = nil
  var blackList: String? = nil
  let name: String
  
  init(_ name:String, specs:[String:Any]) {
    self.name = name
    self.rect = specs["rect"] as! [CGFloat]
    if let whiteList = specs["whiteList"] {
      self.whiteList = whiteList as? String
    }
    if let blackList = specs["blackList"] {
      self.blackList = blackList as? String
    }
  }
}
class PokemonOCR {
  typealias AttrsDict = [String:OCRSpec]
  static var attrsLocs:AttrsDict?
  let screenshot: UIImage
  let ocr: ScreenshotOCR
  static func getAttrsLocs() -> Promise<AttrsDict> {
    return Promise {fulfill, reject in
      if let cachedAttrs = attrsLocs {
        fulfill(cachedAttrs)
        return
      }
      let ref = FIRDatabase.database().reference().child("ssMetaNew")
      ref.observeSingleEvent(of: FIRDataEventType.value, with: {(snapshot) in
        let attributes = snapshot.value as! [String:[String:Any]]
        attrsLocs = [:]
        for (name, specs) in attributes {
          attrsLocs?[name] = OCRSpec(name, specs: specs)
        }
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
    return PokemonOCR.getAttrsLocs().then {attrsSpecs->[String:String] in
      var attrs = [String:String]()
      for (attr,spec) in attrsSpecs {
        attrs[attr] = self.ocr.extractText(spec)
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
