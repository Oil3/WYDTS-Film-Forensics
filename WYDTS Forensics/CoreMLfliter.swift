//
//  CoreMLfliter.swift
//  WYDTS Forensics
//
//  Created by Almahdi Morris on 23/7/24.
//

import Vision
import SwiftUI

class CoreMLfliter {
  static func createCoreMLFilterer() -> VNCoreMLModel {
    
    let defaultMLConfig = MLModelConfiguration()
    
    let mlFiltererWrapper = try? img2imgCheckFlexibleShape(configuration: defaultMLConfig)
    
    let mlFiltererModel = (mlFiltererWrapper?.model)!
    
    guard let mlFiltererVisionModel = try? VNCoreMLModel(for: mlFiltererModel) else {
      fatalError("VNCoreMLModel bug")
    }
    return mlFiltererVisionModel
  }
  
}
