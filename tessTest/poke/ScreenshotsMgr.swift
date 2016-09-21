//
//  FetchScreenshots.swift
//  tessTest
//
//  Created by Chao Lam on 9/7/16.
//  Copyright © 2016 Next Small Things. All rights reserved.
//

import Foundation
import UIKit
import Photos
import PromiseKit

class Screenshot {
  let url:String!
  let image:UIImage!
  init(image:UIImage, url:String) {
    self.url=url
    self.image=image
  }
}

struct ScreenshotsMgr {
  enum Err: Error {
    case imageNotFound
  }
  static let manager = PHImageManager.default()
  
  static func requestUrlForAsset(_ asset:PHAsset)->String {
    let options = PHImageRequestOptions()
    options.isSynchronous = true
    var result = "unknown"
    manager.requestImageData(for: asset, options: options, resultHandler: {(imagedata, dataUTI, orientation, info) in
      if let url = info?["PHImageFileURLKey"] as? URL {
        result = url.absoluteString
      }
    })
    return result
  }
  
  static func requestImageForAsset(_ asset:PHAsset)->UIImage {
    let options = PHImageRequestOptions()
    options.isSynchronous = true
    options.resizeMode = .exact
    var image = UIImage()
    manager.requestImage(for: asset, targetSize: CGSize(width:asset.pixelWidth, height:asset.pixelHeight), contentMode: .aspectFit, options: options, resultHandler: {(result,info) in
      if let img=result {
        image = img
      }
    })
    return image
  }
  
  static func fetch(_ after:Date)->[Screenshot] {
    let options = PHFetchOptions()
    let ssPredicate =  NSPredicate(format:"mediaSubtype == %ld", PHAssetMediaSubtype.photoScreenshot.rawValue)
    
    let datePredicate = NSPredicate(format:"creationDate > %@", after as CVarArg)
    options.predicate = NSCompoundPredicate(type:.and, subpredicates:[ssPredicate, datePredicate])
    let result = PHAsset.fetchAssets(with: .image, options: options)
    print("@@@", result.count)
    var screens = [Screenshot]()
    result.enumerateObjects({(asset, count, stop) in
      let url = requestUrlForAsset(asset)
      let image = requestImageForAsset(asset)
      screens.append(Screenshot(image:image, url:url))
    })
    return screens
  }
}
