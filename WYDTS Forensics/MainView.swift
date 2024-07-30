import SwiftUI
import AVFoundation
import CoreImage
import CoreML
import AVKit
import Vision

struct MainView: View {
  @State private var videoURL: URL? = Bundle.main.url(forResource: "matrix", withExtension: "mov")
  private let ciContext = CIContext()
  @State private var selectedFilter: CIFilter?
  @State private var mlModel: VNCoreMLModel?
  @State private var applyFilter = false
  @State private var applyMLModel = false
  @State private var applyPostMLFilters = false
  @State private var brightness: CGFloat = 0.0
  @State private var contrast: CGFloat = 1.0
  @State private var saturation: CGFloat = 1.0
  @State private var inputEV: CGFloat = 0.0
  @State private var gamma: CGFloat = 1.0
  @State private var hue: CGFloat = 0.0
  @State private var highlightAmount: CGFloat = 1.0
  @State private var shadowAmount: CGFloat = 0.0
  @State private var temperature: CGFloat = 6500.0
  @State private var tint: CGFloat = 0.0
  @State private var whitePoint: CGFloat = 1.0
  @State private var selectedFilterName: String = "Original"
  @State private var player: AVPlayer?
  @State private var playerView: AVPlayerView?
  @State private var invert = false
  @State private var posterize = false
  @State private var sharpenLuminance = false
  @State private var unsharpMask = false
  @State private var edges = false
  @State private var gaborGradients = false
  @State private var loop = false
  @State private var showOverlay = false
  @State private var colorClamp = false
  @State private var convolution3x3 = false
  @State private var gallery: [GalleryImage] = []
  @State private var putAsideFrame = false
  @State private var rotateAngle: CGFloat = 0.0
  @State private var selectedGalleryIndex: Int? = nil
  @State private var showFilteredGalleryImage = false
  @State private var isImageOverlayVisible = false
  @AppStorage("filterPreset") private var filterPresetData: Data?
  private var model = try? Image2redhue().model
  @State private var pixelBufferPool: CVPixelBufferPool?
  @State var selectedSize: CGSize = CGSize(width: 1024, height: 576)
  @State private var replacePlayerWithOverlay = false

  let filters = ["Original", "CIDocumentEnhancer", "CIColorHistogram"]
  
  var body: some View {
    NavigationSplitView(sidebar: {
      leftColumn
    }, content: {
      HStack {
        ScrollView {
          videoPlayerView
          controlButtons
        }
      }
    }, detail: {
      rightColumn
        .navigationSplitViewColumnWidth(210)
    })
    .navigationSplitViewStyle(.balanced)
    .onAppear(perform: loadGallery)
    .onAppear(perform: setupPlayer)

  }
  
  private var leftColumn: some View {
    VStack(alignment: .leading) {
      Button("Choose Video") {
        chooseVideo()
      }
      .keyboardShortcut("o", modifiers: .command)
      
      Button("Choose CoreML Model") {
        chooseModel()
      }
      HStack {
        Text("Enforce Video Size:")
        Menu("Select Size") {
          Button("640x640") { selectedSize = CGSize(width: 640, height: 640) }
          Button("1024x576") { selectedSize = CGSize(width: 1024, height: 576) }
          Button("576x1024") { selectedSize = CGSize(width: 540, height: 960) }
          Button("1280x720") { selectedSize = CGSize(width: 1280, height: 720) }
        }
      }
      Picker("Filter", selection: $selectedFilterName) {
        ForEach(filters, id: \.self) { filter in
          Text(filter).tag(filter as String?)
        }
      }
      .onChange(of: selectedFilterName) { newFilter in
        selectedFilter = CIFilter(name: newFilter)
        applyCurrentFilters()
      }
      Toggle("Apply Filter", isOn: $applyFilter)
      Toggle("Apply CoreML Model", isOn: $applyMLModel)
      Toggle("Apply Post-ML Filters", isOn: $applyPostMLFilters)
      let mlName = model?.modelDescription.metadata[.description] as? String ?? "None"
      Text("Model: \(mlName)")
      Spacer()
      GalleryView(gallery: $gallery, selectedGalleryIndex: $selectedGalleryIndex, showOverlay: $showOverlay, showFilteredGalleryImage: $showFilteredGalleryImage, isImageOverlayVisible: $isImageOverlayVisible)
    }
    .padding()
    .frame(width: 200)
  }
  
  private var videoPlayerView: some View {
    ZStack {
      if replacePlayerWithOverlay {
        if isImageOverlayVisible, let selectedIndex = selectedGalleryIndex {
          let ciImage = CIImage(contentsOf: gallery[selectedIndex].url)!
          ResizableDraggableImageView(ciImage: ciImage, applyFilter: $applyFilter, selectedFilter: $selectedFilter, brightness: $brightness, contrast: $contrast, saturation: $saturation, inputEV: $inputEV, gamma: $gamma, hue: $hue, highlightAmount: $highlightAmount, shadowAmount: $shadowAmount, temperature: $temperature, tint: $tint, whitePoint: $whitePoint, invert: $invert, posterize: $posterize, sharpenLuminance: $sharpenLuminance, unsharpMask: $unsharpMask, edges: $edges, gaborGradients: $gaborGradients, colorClamp: $colorClamp, convolution3x3: $convolution3x3, showFilteredGalleryImage: $showFilteredGalleryImage, isImageOverlayVisible: $isImageOverlayVisible, replacePlayerWithOverlay: $replacePlayerWithOverlay)
        }
      } else {
        if let playerView = playerView {
          CoreVideoPlayerView(/*videoURL: $videoURL, */applyFilter: $applyFilter, selectedFilter: $selectedFilter, applyMLModel: $applyMLModel, applyPostMLFilters: $applyPostMLFilters, mlModel: $mlModel, brightness: $brightness, contrast: $contrast, saturation: $saturation, inputEV: $inputEV, gamma: $gamma, hue: $hue, highlightAmount: $highlightAmount, shadowAmount: $shadowAmount, temperature: $temperature, tint: $tint, whitePoint: $whitePoint, invert: $invert, posterize: $posterize, sharpenLuminance: $sharpenLuminance, unsharpMask: $unsharpMask, edges: $edges, gaborGradients: $gaborGradients, colorClamp: $colorClamp, convolution3x3: $convolution3x3, player: $player, playerView: $playerView, ciContext: .constant(ciContext), showOverlay: $showOverlay, putAsideFrame: $putAsideFrame, gallery: $gallery, selectedGalleryIndex: $selectedGalleryIndex, showFilteredGalleryImage: $showFilteredGalleryImage)
            .frame(minWidth: 480, idealWidth: selectedSize.width, minHeight: 480, idealHeight: selectedSize.height)
        } else {
          VStack {
            Rectangle()
              .stroke(Color.gray, lineWidth: 2)
              .frame(width: selectedSize.width, height: selectedSize.height)
              .background(Color.black)
              .overlay(
                Text("Load a video to start")
                  .foregroundColor(.white)
              )
              .padding()
              .contextMenu {
                Button("Copy Frame") {
                  copyCurrentFrame()
                }
                Button("Save Frame") {
                  saveCurrentFrame()
                }
                Button("Show Image") {
                  showImage()
                }
              }
          }
        }
      }
      
      if !replacePlayerWithOverlay && isImageOverlayVisible, let selectedIndex = selectedGalleryIndex {
        let ciImage = CIImage(contentsOf: gallery[selectedIndex].url)!
        ResizableDraggableImageView(ciImage: ciImage, applyFilter: $applyFilter, selectedFilter: $selectedFilter, brightness: $brightness, contrast: $contrast, saturation: $saturation, inputEV: $inputEV, gamma: $gamma, hue: $hue, highlightAmount: $highlightAmount, shadowAmount: $shadowAmount, temperature: $temperature, tint: $tint, whitePoint: $whitePoint, invert: $invert, posterize: $posterize, sharpenLuminance: $sharpenLuminance, unsharpMask: $unsharpMask, edges: $edges, gaborGradients: $gaborGradients, colorClamp: $colorClamp, convolution3x3: $convolution3x3, showFilteredGalleryImage: $showFilteredGalleryImage, isImageOverlayVisible: $isImageOverlayVisible, replacePlayerWithOverlay: $replacePlayerWithOverlay)
      }
    }
    .padding()
    .contextMenu {
      Button("Copy Frame") {
        copyCurrentFrame()
      }
      Button("Save Frame") {
        saveCurrentFrame()
      }
      Button("Show Image") {
        showImage()
      }
    }
  }
  
  private var rightColumn: some View {

    VStack {
      Toggle("Apply Filters to Video", isOn: $applyFilter)
      Toggle("Apply Filters to Image", isOn: $showFilteredGalleryImage)
      Toggle("Show Overlay", isOn: $isImageOverlayVisible)
      Toggle("Replace Video Player with Overlay", isOn: $replacePlayerWithOverlay)

      Slider(value: $brightness, in: -1...1, step: 0.03) {
        Text("Brightness")
      }
      .onChange(of: brightness) {
        if player?.rate == 0 {
          applyCurrentFilters()
        }
//        if showFilteredGalleryImage {
//          applyCurrentFilters()
////
//        }
      }
      Slider(value: $contrast, in: 0...5, step: 0.03) {
        Text("Contrast")
      }
      .onChange(of: contrast) {
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Slider(value: $saturation, in: 0...4, step: 0.1) {
        Text("Saturation")
      }
      .onChange(of: saturation) {
        applyCurrentFilters()
      }
      Slider(value: $inputEV, in: -2...2, step: 0.1) {
        Text("Exposure")
      }
      .onChange(of: inputEV) {
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Slider(value: $gamma, in: 0.1...3.0, step: 0.1) {
        Text("Gamma")
      }
      .onChange(of: gamma) {
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Slider(value: $hue, in: 0...2 * .pi, step: 0.1) {
        Text("Hue")
      }
      .onChange(of: hue) {
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Slider(value: $highlightAmount, in: 0...1, step: 0.1) {
        Text("Highlight")
      }
      .onChange(of: highlightAmount) {
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Slider(value: $shadowAmount, in: -1...1, step: 0.1) {
        Text("Shadows")
      }
      .onChange(of: shadowAmount) {
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Slider(value: $temperature, in: 1000...10000, step: 100) {
        Text("Temperature")
      }
      .onChange(of: temperature) {
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Slider(value: $tint, in: -200...200, step: 1) {
        Text("Tint")
      }
      .onChange(of: tint) {
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Slider(value: $whitePoint, in: 0...2, step: 0.1) {
        Text("White Point")
      }
      .onChange(of: whitePoint) {
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Toggle("CIColorInvert", isOn: $invert)
        .onChange(of: invert) {
          if player?.rate == 0 {
            applyCurrentFilters()
          }
        }
      Toggle("CIColorPosterize", isOn: $posterize)
        .onChange(of: posterize) {
          if player?.rate == 0 {
            applyCurrentFilters()
          }
        }
      Toggle("CISharpenLuminance", isOn: $sharpenLuminance)
        .onChange(of: sharpenLuminance) {
          if player?.rate == 0 {
            applyCurrentFilters()
          }
        }
      Toggle("CIUnsharpMask", isOn: $unsharpMask)
        .onChange(of: unsharpMask) {
          if player?.rate == 0 {
            applyCurrentFilters()
          }
        }
      Toggle("CIEdges", isOn: $edges)
        .onChange(of: edges) {
          if player?.rate == 0 {
            applyCurrentFilters()
          }
        }
      Toggle("CIGaborGradients", isOn: $gaborGradients)
        .onChange(of: gaborGradients) {
          if player?.rate == 0 {
            applyCurrentFilters()
          }
        }
      Toggle("CIColorClamp", isOn: $colorClamp)
        .onChange(of: colorClamp) {
          if player?.rate == 0 {
            applyCurrentFilters()
          }
        }
      Toggle("CIConvolution3x3", isOn: $convolution3x3)
        .onChange(of: convolution3x3) {
          if player?.rate == 0 {
            applyCurrentFilters()
          }
        }
      Button("Put Aside Frame") {
        putAsideCurrentFrame()
      }
      Slider(value: $rotateAngle, in: 0...360, step: 1) {
        Text("Rotate")
      }
      .onChange(of: rotateAngle) {
        applyCurrentFilters()
      }
      Spacer()
    }
    .padding()
    .frame(width: 200)
  }
  
  private var controlButtons: some View {
    HStack {
      Button("Reset") {
        resetFilters()
      }
      Button("Save Preset") {
        savePreset()
      }
      Button("Restore Preset") {
        restorePreset()
      }
      Button("Play") {
        player?.play()
//        showOverlay = false
      }
      Button("Pause") {
        player?.pause()
//        showOverlay = true
      }
      Toggle("Loop", isOn: $loop)
        .onChange(of: loop) { newValue in
          player?.actionAtItemEnd = newValue ? .none : .pause
          if newValue {
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { _ in
              player?.seek(to: .zero)
              player?.play()
            }
          } else {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
          }
        }
    }
    .padding()
  }
  
  private func chooseVideo() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.movie]
    if panel.runModal() == .OK {
      videoURL = panel.url
      setupPlayer()
    }
  }
  
  private func chooseModel() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = []
    if panel.runModal() == .OK {
      do {
        let url = panel.url
        let compiledModelURL = try? MLModel.compileModel(at: url!)
      let model = try? MLModel(contentsOf: compiledModelURL!)
        let coreMLModel = try? VNCoreMLModel(for: model!)
          mlModel = coreMLModel
          //            createPixelBufferPool()
          
          applyCurrentFilters()
        
        
      }
    }
  }
  private func setupVideoComposition(for asset: AVAsset, playerItem: AVPlayerItem) {
    Task {
      do {
        let videoComposition = try await AVVideoComposition.videoComposition(with: asset) { request in
          let ciImage = request.sourceImage.clampedToExtent()
          var filteredImage = self.applyFilters(to: ciImage)
          
          // Apply additional filters if needed
          filteredImage = self.applyAdditionalFilters(to: filteredImage)
          
          request.finish(with: filteredImage, context: self.ciContext)
        }
        playerItem.videoComposition = videoComposition
      } catch {
        print("Error setting up video composition: \(error)")
      }
    }
  }

  fileprivate func showImage() {
    guard let player = player, let playerItem = player.currentItem else { return }
    let currentTime = player.currentTime()
    let asset = playerItem.asset
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    if let cgImage = try? generator.copyCGImage(at: currentTime, actualTime: nil) {
      let ciImage = CIImage(cgImage: cgImage)
      let filters = FilterPreset(
        brightness: brightness,
        contrast: contrast,
        saturation: saturation,
        inputEV: inputEV,
        gamma: gamma,
        hue: hue,
        highlightAmount: highlightAmount,
        shadowAmount: shadowAmount,
        temperature: temperature,
        tint: tint,
        whitePoint: whitePoint,
        invert: invert,
        posterize: posterize,
        sharpenLuminance: sharpenLuminance,
        unsharpMask: unsharpMask,
        edges: edges,
        gaborGradients: gaborGradients,
        colorClamp: colorClamp,
        convolution3x3: convolution3x3,
        rotateAngle: rotateAngle
      )
      gallery.append(GalleryImage(url: saveImageToDisk(nsImage: convertCIImageToNSImage(ciImage: ciImage)), index: gallery.count, filters: filters))
      saveGallery()
      selectedGalleryIndex = gallery.count - 1
      isImageOverlayVisible = true
      showOverlay = true
      showFilteredGalleryImage = false
    }
  }
  private func createPixelBufferPool() {
    let attributes: [String: Any] = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
      kCVPixelBufferWidthKey as String: playerView?.player?.currentItem?.presentationSize.width,
      kCVPixelBufferHeightKey as String: playerView?.player?.currentItem?.presentationSize.height,
      kCVPixelBufferIOSurfacePropertiesKey as String: [:]
    ]
    
    CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, attributes as CFDictionary, &pixelBufferPool)
  }
  private func applyCurrentFilters() {
    guard let player = player, let playerItem = player.currentItem else { return }
    
    Task {
      do {
        let videoComposition = try await AVVideoComposition.videoComposition(with: playerItem.asset) { request in
          let ciImage = request.sourceImage.clampedToExtent()
          let filteredImage = self.applyFilters(to: ciImage)
          
          request.finish(with: filteredImage, context: self.ciContext)
        }
        playerItem.videoComposition = videoComposition
      } catch {
        print("Error applying current filters: \(error)")
      }
      
//      // Apply filters to the selected gallery image if showFilteredGalleryImage is true
//      if showFilteredGalleryImage, let selectedIndex = selectedGalleryIndex {
//        let galleryImage = gallery[selectedIndex]
//        if let nsImage = NSImage(contentsOf: galleryImage.url), let ciImage = convertNSImageToCIImage(nsImage: nsImage) {
//          let filteredImage = self.applyFilters(to: ciImage)
//          // Replace the existing gallery image with the filtered one
//          gallery[selectedIndex] = GalleryImage(url: saveImageToDisk(nsImage: convertCIImageToNSImage(ciImage: filteredImage)), index: selectedIndex, filters: galleryImage.filters)
//        }
//      }
    }
  }
  private func convertNSImageToCIImage(nsImage: NSImage) -> CIImage? {
    guard let tiffData = nsImage.tiffRepresentation else { return nil }
    guard let bitmapImage = NSBitmapImageRep(data: tiffData) else { return nil }
    return CIImage(bitmapImageRep: bitmapImage)
  }
  
  private func applyFilters(to image: CIImage) -> CIImage {
    var ciImage = image
    
    if applyMLModel {
      ciImage = applyCoreMLModel(to: ciImage)
    }
    
    if applyFilter || applyPostMLFilters {
      if let selectedFilter = selectedFilter {
        selectedFilter.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = selectedFilter.outputImage ?? ciImage
      }
      ciImage = applyAdditionalFilters(to: ciImage)
    }
    
    return ciImage
  }

  private func applyAdditionalFilters(to image: CIImage) -> CIImage {
    var ciImage = image
    
    if invert {
      let filter = CIFilter(name: "CIColorInvert")
      filter?.setValue(ciImage, forKey: kCIInputImageKey)
      ciImage = filter?.outputImage ?? ciImage
    }
    
    if posterize {
      let filter = CIFilter(name: "CIColorPosterize")
      filter?.setValue(ciImage, forKey: kCIInputImageKey)
      ciImage = filter?.outputImage ?? ciImage
    }
    
    if sharpenLuminance {
      let filter = CIFilter(name: "CISharpenLuminance")
      filter?.setValue(ciImage, forKey: kCIInputImageKey)
      ciImage = filter?.outputImage ?? ciImage
    }
    
    if unsharpMask {
      let filter = CIFilter(name: "CIUnsharpMask")
      filter?.setValue(ciImage, forKey: kCIInputImageKey)
      ciImage = filter?.outputImage ?? ciImage
    }
    
    if edges {
      let filter = CIFilter(name: "CIEdges")
      filter?.setValue(ciImage, forKey: kCIInputImageKey)
      ciImage = filter?.outputImage ?? ciImage
    }
    
    if gaborGradients {
      let filter = CIFilter(name: "CIGaborGradients")
      filter?.setValue(ciImage, forKey: kCIInputImageKey)
      ciImage = filter?.outputImage ?? ciImage
    }
    
    if colorClamp {
      let filter = CIFilter(name: "CIColorClamp")
      filter?.setValue(ciImage, forKey: kCIInputImageKey)
      ciImage = filter?.outputImage ?? ciImage
    }
    
    if convolution3x3 {
      let filter = CIFilter(name: "CIConvolution3X3")
      filter?.setValue(ciImage, forKey: kCIInputImageKey)
      ciImage = filter?.outputImage ?? ciImage
    }
    
    let colorControlsFilter = CIFilter(name: "CIColorControls")
    colorControlsFilter?.setValue(ciImage, forKey: kCIInputImageKey)
    colorControlsFilter?.setValue(brightness, forKey: kCIInputBrightnessKey)
    colorControlsFilter?.setValue(contrast, forKey: kCIInputContrastKey)
    colorControlsFilter?.setValue(saturation, forKey: kCIInputSaturationKey)
    ciImage = colorControlsFilter?.outputImage ?? ciImage
    
    let gammaFilter = CIFilter(name: "CIGammaAdjust")
    gammaFilter?.setValue(ciImage, forKey: kCIInputImageKey)
    gammaFilter?.setValue(gamma, forKey: "inputPower")
    ciImage = gammaFilter?.outputImage ?? ciImage
    
    let hueFilter = CIFilter(name: "CIHueAdjust")
    hueFilter?.setValue(ciImage, forKey: kCIInputImageKey)
    hueFilter?.setValue(hue, forKey: kCIInputAngleKey)
    ciImage = hueFilter?.outputImage ?? ciImage
    
    let highlightShadowFilter = CIFilter(name: "CIHighlightShadowAdjust")
    highlightShadowFilter?.setValue(ciImage, forKey: kCIInputImageKey)
    highlightShadowFilter?.setValue(highlightAmount, forKey: "inputHighlightAmount")
    highlightShadowFilter?.setValue(shadowAmount, forKey: "inputShadowAmount")
    ciImage = highlightShadowFilter?.outputImage ?? ciImage
    
    let temperatureAndTintFilter = CIFilter(name: "CITemperatureAndTint")
    temperatureAndTintFilter?.setValue(ciImage, forKey: kCIInputImageKey)
    temperatureAndTintFilter?.setValue(CIVector(x: temperature, y: tint), forKey: "inputNeutral")
    ciImage = temperatureAndTintFilter?.outputImage ?? ciImage
    
    let whitePointAdjustFilter = CIFilter(name: "CIWhitePointAdjust")
    whitePointAdjustFilter?.setValue(ciImage, forKey: kCIInputImageKey)
    whitePointAdjustFilter?.setValue(CIColor(red: whitePoint, green: whitePoint, blue: whitePoint), forKey: kCIInputColorKey)
    ciImage = whitePointAdjustFilter?.outputImage ?? ciImage
    
    // Apply rotation if needed
    if rotateAngle != 0 {
      ciImage = ciImage.transformed(by: CGAffineTransform(rotationAngle: rotateAngle * (.pi / 180)))
    }
    
    return ciImage
  }
  
  private func applyCoreMLModel(to ciImage: CIImage) -> CIImage {
    guard let mlModel = mlModel, let pixelBufferPool = pixelBufferPool else { return ciImage }

    var outputCIImage: CIImage?
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
    guard status == kCVReturnSuccess, var pixelBuffer = pixelBuffer else { return ciImage }
    ciContext.render(ciImage, to: pixelBuffer)

  let vnRequest = VNCoreMLRequest(model: mlModel) { vnRequest, error in
    if let results = vnRequest.results as? [VNPixelBufferObservation],
       let observation = results.first {
      outputCIImage = CIImage(cvPixelBuffer: observation.pixelBuffer)
    }
  }
  vnRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.scaleFit
  let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
  try? handler.perform([vnRequest])
  
  return outputCIImage ?? ciImage.clampedToExtent()
}

private func pixelBufferFromImage(ciImage: CIImage) -> CVPixelBuffer {
  let width = Int((playerView?.player?.currentItem?.presentationSize.width)!)//Int((playerView?.videoBounds.width)!)
  let height = Int((playerView?.player?.currentItem?.presentationSize.height)!)//Int((playerView?.videoBounds.height)!)
  
  var pixelBuffer: CVPixelBuffer?
  let attrs = [
    kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
    kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
  ] as CFDictionary
  CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
  
  ciContext.render(ciImage, to: pixelBuffer!)
  
  return pixelBuffer!
}  
  
//  private func pixelBufferFromImage(ciImage: CIImage, size: CGSize) -> CVPixelBuffer {
//    let width = Int(size.width)
//    let height = Int(size.height)
//    
//    var pixelBuffer: CVPixelBuffer?
//    let attrs = [
//      kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
//      kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
//    ] as CFDictionary
//    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
//    
//    ciContext.render(ciImage, to: pixelBuffer!)
//    
//    return pixelBuffer!
//  }
  
  private func resetFilters() {
    brightness = 0.0
    contrast = 1.0
    saturation = 1.0
    inputEV = 0.0
    gamma = 1.0
    hue = 0.0
    highlightAmount = 1.0
    shadowAmount = 0.0
    temperature = 6500.0
    tint = 0.0
    whitePoint = 1.0
    invert = false
    posterize = false
    sharpenLuminance = false
    unsharpMask = false
    edges = false
    gaborGradients = false
    colorClamp = false
    convolution3x3 = false
    rotateAngle = 0.0
    applyCurrentFilters()
  }
  
  private func savePreset() {
    
    let preset = FilterPreset(
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      inputEV: inputEV,
      gamma: gamma,
      hue: hue,
      highlightAmount: highlightAmount,
      shadowAmount: shadowAmount,
      temperature: temperature,
      tint: tint,
      whitePoint: whitePoint,
      invert: invert,
      posterize: posterize,
      sharpenLuminance: sharpenLuminance,
      unsharpMask: unsharpMask,
      edges: edges,
      gaborGradients: gaborGradients,
      colorClamp: colorClamp,
      convolution3x3: convolution3x3,
      rotateAngle: rotateAngle
    )
    if let data = try? JSONEncoder().encode(preset) {
      filterPresetData = data
    }
  }
  
  private func restorePreset() {
    guard let data = filterPresetData, let preset = try? JSONDecoder().decode(FilterPreset.self, from: data) else { return }
    brightness = preset.brightness
    contrast = preset.contrast
    saturation = preset.saturation
    inputEV = preset.inputEV
    gamma = preset.gamma
    hue = preset.hue
    highlightAmount = preset.highlightAmount
    shadowAmount = preset.shadowAmount
    temperature = preset.temperature
    tint = preset.tint
    whitePoint = preset.whitePoint
    invert = preset.invert
    posterize = preset.posterize
    sharpenLuminance = preset.sharpenLuminance
    unsharpMask = preset.unsharpMask
    edges = preset.edges
    gaborGradients = preset.gaborGradients
    colorClamp = preset.colorClamp
    convolution3x3 = preset.convolution3x3
    rotateAngle = preset.rotateAngle
    applyCurrentFilters()
  }
  
  private func setupPlayer() {
    createPixelBufferPool()

    guard let videoURL = videoURL else { return }
    let asset = AVAsset(url: videoURL)
    let playerItem = AVPlayerItem(asset: asset)
    player = AVPlayer(playerItem: playerItem)
    playerView = AVPlayerView()
    playerView?.player = player
    playerView?.allowsMagnification = false
    playerView?.allowsVideoFrameAnalysis = false
    playerView?.videoGravity = .resizeAspect
    playerView?.allowsPictureInPicturePlayback = true
    playerView?.showsFullScreenToggleButton = true
    playerView?.showsFrameSteppingButtons = true
    playerView?.controlsStyle = .floating
    
    setupVideoComposition(for: asset, playerItem: playerItem)
  }
  
  private func putAsideCurrentFrame() {
    guard let player = player, let playerItem = player.currentItem else { return }
    let currentTime = player.currentTime()
    let asset = playerItem.asset
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    if let cgImage = try? generator.copyCGImage(at: currentTime, actualTime: nil) {
      let ciImage = CIImage(cgImage: cgImage)
      let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
      let url = saveImageToDisk(nsImage: nsImage)
      let filters = FilterPreset(
        brightness: brightness,
        contrast: contrast,
        saturation: saturation,
        inputEV: inputEV,
        gamma: gamma,
        hue: hue,
        highlightAmount: highlightAmount,
        shadowAmount: shadowAmount,
        temperature: temperature,
        tint: tint,
        whitePoint: whitePoint,
        invert: invert,
        posterize: posterize,
        sharpenLuminance: sharpenLuminance,
        unsharpMask: unsharpMask,
        edges: edges,
        gaborGradients: gaborGradients,
        colorClamp: colorClamp,
        convolution3x3: convolution3x3,
        rotateAngle: rotateAngle
      )
      let galleryImage = GalleryImage(url: url, index: gallery.count, filters: filters)
      gallery.append(galleryImage)
      saveGallery()
    }
  }

  private func saveImageToDisk(nsImage: NSImage) -> URL {
    let fileManager = FileManager.default
    let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
    let picturesDirectory = urls[0]
    let fileName = UUID().uuidString + ".tiff"
    let fileURL = picturesDirectory.appendingPathComponent(fileName)
    guard let tiffData = nsImage.tiffRepresentation else { return fileURL }
    do {
      try tiffData.write(to: fileURL)
    } catch {
      print("Error saving image: \(error)")
    }
    return fileURL
  }
  
  private func galleryURL() -> URL {
    let fileManager = FileManager.default
    let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    return urls[0].appendingPathComponent("gallery.json")
  }
  
  fileprivate func copyCurrentFrame() {
    if let selectedIndex = selectedGalleryIndex {
      let ciImage = CIImage(contentsOf: gallery[selectedIndex].url)!
      let nsImage = convertCIImageToNSImage(ciImage: ciImage)
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      pasteboard.writeObjects([nsImage])
    } else if let player = player, let currentItem = player.currentItem {
      let currentTime = player.currentTime()
      let asset = currentItem.asset
      let generator = AVAssetImageGenerator(asset: asset)
      generator.appliesPreferredTrackTransform = true
      if let cgImage = try? generator.copyCGImage(at: currentTime, actualTime: nil) {
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([nsImage])
      }
    }
  }
  
  fileprivate func saveCurrentFrame() {
    guard let player = player, let playerItem = player.currentItem else { return }
    let currentTime = player.currentTime()
    let asset = playerItem.asset
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    if let cgImage = try? generator.copyCGImage(at: currentTime, actualTime: nil) {
      let ciImage = CIImage(cgImage: cgImage)
      guard let colorSpace = ciImage.colorSpace else { return }
      
      let panel = NSSavePanel()
      panel.allowedContentTypes = [.jpeg]
      if panel.runModal() == .OK, let url = panel.url {
        do {
          let jpegData = ciContext.jpegRepresentation(of: ciImage, colorSpace: colorSpace)
          try jpegData?.write(to: url)
        } catch {
          print("Error saving frame: \(error)")
        }
      }
    }
  }
  
  private func convertCIImageToNSImage(ciImage: CIImage) -> NSImage {
    let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)!
    let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    return nsImage
  }
  
  private func previousImage() {
    guard let selectedIndex = selectedGalleryIndex else { return }
    if selectedIndex > 0 {
      selectedGalleryIndex = selectedIndex - 1
    }
  }
  
  private func nextImage() {
    guard let selectedIndex = selectedGalleryIndex else { return }
    if selectedIndex < gallery.count - 1 {
      selectedGalleryIndex = selectedIndex + 1
    }
  }
  
  private func loadGallery() {
    // Load gallery images from persistent storage
    if let data = try? Data(contentsOf: galleryURL()), let savedGallery = try? JSONDecoder().decode([GalleryImage].self, from: data) {
      gallery = savedGallery
    }
  }
  
  private func saveGallery() {
    guard let data = try? JSONEncoder().encode(gallery) else { return }
    try? data.write(to: galleryURL())
  }
}

struct CoreVideoPlayerView: NSViewRepresentable {
  @State private var videoURL: URL? = Bundle.main.url(forResource: "matrix", withExtension: "mov")
  @Binding var applyFilter: Bool
  @Binding var selectedFilter: CIFilter?
  @Binding var applyMLModel: Bool
  @Binding var applyPostMLFilters: Bool
  @Binding var mlModel: VNCoreMLModel?
  @Binding var brightness: CGFloat
  @Binding var contrast: CGFloat
  @Binding var saturation: CGFloat
  @Binding var inputEV: CGFloat
  @Binding var gamma: CGFloat
  @Binding var hue: CGFloat
  @Binding var highlightAmount: CGFloat
  @Binding var shadowAmount: CGFloat
  @Binding var temperature: CGFloat
  @Binding var tint: CGFloat
  @Binding var whitePoint: CGFloat
  @Binding var invert: Bool
  @Binding var posterize: Bool
  @Binding var sharpenLuminance: Bool
  @Binding var unsharpMask: Bool
  @Binding var edges: Bool
  @Binding var gaborGradients: Bool
  @Binding var colorClamp: Bool
  @Binding var convolution3x3: Bool
  @Binding var player: AVPlayer?
  @Binding var playerView: AVPlayerView?
  @Binding var ciContext: CIContext
  @Binding var showOverlay: Bool
  @Binding var putAsideFrame: Bool
  @Binding var gallery: [GalleryImage]
  @Binding var selectedGalleryIndex: Int?
  @Binding var showFilteredGalleryImage: Bool
  
  func makeNSView(context: Context) -> NSView {
    let view = NSView()
    view.wantsLayer = true
    return view
    
  }
  
  func updateNSView(_ nsView: NSView, context: Context) {
    guard let playerView = playerView else { return }
    
    playerView.translatesAutoresizingMaskIntoConstraints = false
    nsView.addSubview(playerView)
    
    NSLayoutConstraint.activate([
      playerView.leadingAnchor.constraint(equalTo: nsView.leadingAnchor),
      playerView.trailingAnchor.constraint(equalTo: nsView.trailingAnchor),
      playerView.topAnchor.constraint(equalTo: nsView.topAnchor),
      playerView.bottomAnchor.constraint(equalTo: nsView.bottomAnchor)
    ])
    
    if showOverlay, let player = player, player.rate == 0, let selectedIndex = selectedGalleryIndex {
      let ciImage = CIImage(contentsOf: gallery[selectedIndex].url)!
      Image(nsImage: convertCIImageToNSImage(ciImage: ciImage))
        .resizable()
        .overlay(
          HStack {
            Button(action: previousImage) {
              Image(systemName: "arrow.left.circle.fill")
                .font(.largeTitle)
                .padding()
            }
              .keyboardShortcut(.leftArrow)

            Spacer()
            Button(action: nextImage) {
              Image(systemName: "arrow.right.circle.fill")
                .font(.largeTitle)
                .padding()
            }
          }
            .padding()
            .background(Color.black.opacity(0.5))
        )
    }
  }

  private func convertCIImageToNSImage(ciImage: CIImage) -> NSImage {
    let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)
    return NSImage(cgImage: cgImage!, size: NSSize(width: ciImage.extent.width, height: ciImage.extent.height))
  }
  
  private func previousImage() {
    guard let selectedIndex = selectedGalleryIndex else { return }
    let newIndex = (selectedIndex - 1 + gallery.count) % gallery.count
    selectedGalleryIndex = newIndex
  }
  
  private func nextImage() {
    guard let selectedIndex = selectedGalleryIndex else { return }
    let newIndex = (selectedIndex + 1) % gallery.count
    selectedGalleryIndex = newIndex
  }
}

struct FilterPreset: Codable {
  let brightness: CGFloat
  let contrast: CGFloat
  let saturation: CGFloat
  let inputEV: CGFloat
  let gamma: CGFloat
  let hue: CGFloat
  let highlightAmount: CGFloat
  let shadowAmount: CGFloat
  let temperature: CGFloat
  let tint: CGFloat
  let whitePoint: CGFloat
  let invert: Bool
  let posterize: Bool
  let sharpenLuminance: Bool
  let unsharpMask: Bool
  let edges: Bool
  let gaborGradients: Bool
  let colorClamp: Bool
  let convolution3x3: Bool
  let rotateAngle: CGFloat
}

struct GalleryImage: Codable, Identifiable {
  var id = UUID()
  let url: URL
  let index: Int
  let filters: FilterPreset
}

struct GalleryView: View {
  @Binding var gallery: [GalleryImage]
  @Binding var selectedGalleryIndex: Int?
  @Binding var showOverlay: Bool
  @Binding var showFilteredGalleryImage: Bool
  @Binding var isImageOverlayVisible: Bool //= false

  var body: some View {
    VStack {
      Text("Gallery")
      ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
          if gallery.isEmpty {
            Text("No images")
            //              .foregroundColor(.gray)
//              .frame(maxWidth: .infinity, maxHeight: .infinity)
          } else {
                ForEach(gallery.indices, id: \.self) { index in
                  if let ciImage = CIImage(contentsOf: gallery[index].url) {
                    Image(nsImage: convertCIImageToNSImage(ciImage: ciImage))
                      .resizable()
                      .scaledToFit()
                      .frame(width: 100, height: 58)
                      .onTapGesture(count: 2) {
                        selectedGalleryIndex = index
                        showOverlay = true
                        showFilteredGalleryImage = false
                        isImageOverlayVisible = true

                      }
                      .contextMenu {
                        Button("Copy Frame") {
                          MainView().copyCurrentFrame()
                        }
                        Button("Save Frame") {
                          MainView().saveCurrentFrame()
                        }
                        Button("Show Image") {
                          MainView().showImage()
                        }
                        Button("Remove Picture") {
                          removePicture(at: index)
                        }
                        Button("Clear All") {
                          clearAllPictures()
                        }
                      }
                  }
                }
          }

        }
        .padding()
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
          for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (urlData, error) in
              DispatchQueue.main.async {
                if let data = urlData as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                  addImage(from: url)
                }
              }
            }
          }
          return true
        }
      }
}
 }
  private func convertCIImageToNSImage(ciImage: CIImage) -> NSImage {
    let ciContext = CIContext()
    let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)!
    let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    return nsImage
  }
  
  private func addImage(from url: URL) {
    if let _ = CIImage(contentsOf: url) {
      let filters = FilterPreset(
        brightness: 0.0,
        contrast: 1.0,
        saturation: 1.0,
        inputEV: 0.0,
        gamma: 1.0,
        hue: 0.0,
        highlightAmount: 1.0,
        shadowAmount: 0.0,
        temperature: 6500.0,
        tint: 0.0,
        whitePoint: 1.0,
        invert: false,
        posterize: false,
        sharpenLuminance: false,
        unsharpMask: false,
        edges: false,
        gaborGradients: false,
        colorClamp: false,
        convolution3x3: false,
        rotateAngle: 0.0
      )
      gallery.append(GalleryImage(url: url, index: gallery.count, filters: filters))
      saveGallery()
    }
  }
  
  private func saveGallery() {
    guard let data = try? JSONEncoder().encode(gallery) else { return }
    try? data.write(to: galleryURL())
  }
  
  private func galleryURL() -> URL {
    let fileManager = FileManager.default
    let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    return urls[0].appendingPathComponent("gallery.json")
  }
  private func removePicture(at index: Int) {
    gallery.remove(at: index)
    saveGallery()
  }
  
  private func clearAllPictures() {
    gallery.removeAll()
    saveGallery()
  }
}

struct ResizableDraggableImageView: View {
  @State var position: CGSize = .zero
  @State var size: CGSize = CGSize(width: 800, height: 600)
  var ciImage: CIImage
  @Binding var applyFilter: Bool
  @Binding var selectedFilter: CIFilter?
  @Binding var brightness: CGFloat
  @Binding var contrast: CGFloat
  @Binding var saturation: CGFloat
  @Binding var inputEV: CGFloat
  @Binding var gamma: CGFloat
  @Binding var hue: CGFloat
  @Binding var highlightAmount: CGFloat
  @Binding var shadowAmount: CGFloat
  @Binding var temperature: CGFloat
  @Binding var tint: CGFloat
  @Binding var whitePoint: CGFloat
  @Binding var invert: Bool
  @Binding var posterize: Bool
  @Binding var sharpenLuminance: Bool
  @Binding var unsharpMask: Bool
  @Binding var edges: Bool
  @Binding var gaborGradients: Bool
  @Binding var colorClamp: Bool
  @Binding var convolution3x3: Bool
  @Binding var showFilteredGalleryImage: Bool
  @GestureState private var magnifyBy = 1.0
  @State private var rotateBy = Angle(degrees: 0.0)
  @Binding var isImageOverlayVisible: Bool
  @Binding var replacePlayerWithOverlay: Bool

  var magnification: some Gesture {
    MagnifyGesture()
      .updating($magnifyBy) { value, gestureState, transaction in
        gestureState = value.magnification
      }
      .onEnded { value in
        size.width *= value.magnification
        size.height = size.width * (ciImage.extent.height / ciImage.extent.width)
      }

  }
  var rotation: some Gesture {
    RotateGesture()
      .onChanged { value in
        rotateBy = value.rotation
      }
      .onEnded { value in
        rotateBy = value.rotation
      }
  }
  var body: some View {
    VStack {
      if showFilteredGalleryImage {
        Image(nsImage: convertCIImageToNSImage(ciImage: applyFilters(to: ciImage)))
          .resizable()
        
          .scaledToFit()
          .scaleEffect(magnifyBy)
          .gesture(magnification)
          .rotationEffect(rotateBy)
          .gesture(rotation)
        .frame(width: size.width, height: size.height)
          .offset(x: position.width, y: position.height)
          .gesture(
            DragGesture()
              .onChanged { value in
                self.position = value.translation
              }
          )

      } else {
      //      if showFilteredGalleryImage {
      //        Image(nsImage: convertCIImageToNSImage(ciImage: applyFilters(to: ciImage)))

        Image(nsImage: convertCIImageToNSImage(ciImage: ciImage))
          .resizable()
          .scaledToFit()
          .scaleEffect(magnifyBy)
          .gesture(magnification)
          .rotationEffect(rotateBy)
          .gesture(rotation)

          .frame(width: size.width, height: size.height)
          .offset(x: position.width, y: position.height)
          .gesture(
            DragGesture()
              .onChanged { value in
                self.position = value.translation
              }
          )
      }
    }
    .frame(width: (MainView().selectedSize.width), height: MainView().selectedSize.height)
    .contextMenu {
      Button("Close Overlay") {
        isImageOverlayVisible = false
      }
      .keyboardShortcut(.escape)
      

    }

  }
  
  private func applyFilters(to image: CIImage) -> CIImage {
    var ciImage = image
    
    if applyFilter {
      if let selectedFilter = selectedFilter {
        selectedFilter.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = selectedFilter.outputImage ?? ciImage
      }
      
      if invert {
        let filter = CIFilter(name: "CIColorInvert")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = filter?.outputImage ?? ciImage
      }
      
      if posterize {
        let filter = CIFilter(name: "CIColorPosterize")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = filter?.outputImage ?? ciImage
      }
      
      if sharpenLuminance {
        let filter = CIFilter(name: "CISharpenLuminance")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = filter?.outputImage ?? ciImage
      }
      
      if unsharpMask {
        let filter = CIFilter(name: "CIUnsharpMask")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = filter?.outputImage ?? ciImage
      }
      
      if edges {
        let filter = CIFilter(name: "CIEdges")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = filter?.outputImage ?? ciImage
      }
      
      if gaborGradients {
        let filter = CIFilter(name: "CIGaborGradients")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = filter?.outputImage ?? ciImage
      }
      
      if colorClamp {
        let filter = CIFilter(name: "CIColorClamp")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = filter?.outputImage ?? ciImage
      }
      
      if convolution3x3 {
        let filter = CIFilter(name: "CIConvolution3X3")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = filter?.outputImage ?? ciImage
      }
      
      let colorControlsFilter = CIFilter(name: "CIColorControls")
      colorControlsFilter?.setValue(ciImage, forKey: kCIInputImageKey)
      colorControlsFilter?.setValue(brightness, forKey: kCIInputBrightnessKey)
      colorControlsFilter?.setValue(contrast, forKey: kCIInputContrastKey)
      colorControlsFilter?.setValue(saturation, forKey: kCIInputSaturationKey)
      ciImage = colorControlsFilter?.outputImage ?? ciImage
      
      let gammaFilter = CIFilter(name: "CIGammaAdjust")
      gammaFilter?.setValue(ciImage, forKey: kCIInputImageKey)
      gammaFilter?.setValue(gamma, forKey: "inputPower")
      ciImage = gammaFilter?.outputImage ?? ciImage
      
      let hueFilter = CIFilter(name: "CIHueAdjust")
      hueFilter?.setValue(ciImage, forKey: kCIInputImageKey)
      hueFilter?.setValue(hue, forKey: kCIInputAngleKey)
      ciImage = hueFilter?.outputImage ?? ciImage
      
      let highlightShadowFilter = CIFilter(name: "CIHighlightShadowAdjust")
      highlightShadowFilter?.setValue(ciImage, forKey: kCIInputImageKey)
      highlightShadowFilter?.setValue(highlightAmount, forKey: "inputHighlightAmount")
      highlightShadowFilter?.setValue(shadowAmount, forKey: "inputShadowAmount")
      ciImage = highlightShadowFilter?.outputImage ?? ciImage
      
      let temperatureAndTintFilter = CIFilter(name: "CITemperatureAndTint")
      temperatureAndTintFilter?.setValue(ciImage, forKey: kCIInputImageKey)
      temperatureAndTintFilter?.setValue(CIVector(x: temperature, y: tint), forKey: "inputNeutral")
      ciImage = temperatureAndTintFilter?.outputImage ?? ciImage
      
      let whitePointAdjustFilter = CIFilter(name: "CIWhitePointAdjust")
      whitePointAdjustFilter?.setValue(ciImage, forKey: kCIInputImageKey)
      whitePointAdjustFilter?.setValue(CIColor(red: whitePoint, green: whitePoint, blue: whitePoint), forKey: kCIInputColorKey)
      ciImage = whitePointAdjustFilter?.outputImage ?? ciImage
      
      // Apply rotation if needed
      //            if rotateAngle != 0 {
      //                ciImage = ciImage.transformed(by: CGAffineTransform(rotationAngle: rotateAngle * (.pi / 180)))
      //            }
    }
    
    return ciImage
  }
  
  private func convertCIImageToNSImage(ciImage: CIImage) -> NSImage {
    let ciContext = CIContext()
    let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)!
    let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    return nsImage
  }
}
//
//  What you don't see, forensics
//  Copyright Almahdi Morris Quet 2024
