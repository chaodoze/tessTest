//
//  ViewController.swift
//  tessTest
//
//  Created by Chao Lam on 8/30/16.
//  Copyright © 2016 Next Small Things. All rights reserved.
//

import UIKit
import TesseractOCR
import Photos
import Firebase

class ViewController: UIViewController {

  @IBOutlet weak var textLabel: UILabel!
  @IBOutlet weak var imageView: UIImageView!
  var ref: FIRDatabaseReference!
  
  func getAssetThumbnail(_ asset: PHAsset) -> UIImage {
    let manager = PHImageManager.default()
    let option = PHImageRequestOptions()
    var thumbnail = UIImage()
    option.isSynchronous = true
    manager.requestImage(for: asset, targetSize: CGSize(width: 100.0, height: 100.0), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
      thumbnail = result!
    })
    manager.requestImageData(for: asset, options: nil, resultHandler: {
      (imageData, dataUTI, orientation, info) in
      if info?.keys.contains("PHImageFileURLKey") != nil {
        print("@@@ file URL", info!["PHImageFileURLKey"])
      }
    })
    return thumbnail
  }
  
  func fetchPhotos() -> Void {
    let options = PHFetchOptions()
    options.predicate = NSPredicate(format:"mediaSubtype == %ld", PHAssetMediaSubtype.photoScreenshot.rawValue)
    let result = PHAsset.fetchAssets(with: .image, options: options)
    NSLog("result: %d", result.count)
    result.enumerateObjects({(object: AnyObject!, count:Int, stop:UnsafeMutablePointer<ObjCBool>) in
      if object is PHAsset {
        let asset  = object as! PHAsset
        NSLog("image: %@", asset.localIdentifier)
        self.imageView.image = self.getAssetThumbnail(asset)
      }
    })
  }
  
  func fetchFBData() {
    ref = FIRDatabase.database().reference().child("screenshotMeta")
    ref.observe(FIRDataEventType.value, with: { (snapshot) in
      let dict = snapshot.value as! [String: [CGFloat]]
      for (_, value) in dict {
        let r = CGRect(x: value[0], y: value[1], width: value[2], height: value[3])
        print("@@@rect", r)
      }
    })
  }
  
  override func viewDidLoad() {
    let RFC3339DateFormatter = DateFormatter()
    RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
    RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    if let date = RFC3339DateFormatter.date(from: "2016-09-16T21:53:23+00:00") {
      
      let screenshots = ScreenshotsMgr.fetch(date)
      for ss in screenshots {
        print("got screenshot", ss.image, ss.url)
        let pokemon = PokemonScreenshot(screenshot: ss, trainerLevel: 21)
        _ = pokemon.fetchData().then {stats in
          print("pstats", stats)
        }
        self.imageView.image = ss.image
      }
    }
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

