import SwiftUI
import AVFoundation
import CoreImage
import CoreML
import AVKit
import Vision

struct MainView: View {
  @State private var videoURL: URL?
  @State private var ciContext = CIContext()
  @State private var selectedFilter: CIFilter?
  @State private var mlModel: MLModel?
  @State private var applyFilter = false
  @State private var applyMLModel = false
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
  @State private var gallery: [NSImage] = []
  @State private var putAsideFrame = false
  @AppStorage("filterPreset") private var filterPresetData: Data?
  private var  model = try? Image2redhue().model

  let filters = ["Original", "CIDocumentEnhancer", "CIColorHistogram"]
  
  var body: some View {
    NavigationSplitView(sidebar: {
      leftColumn
    }, content: {
      HStack {
        VStack {
          videoPlayerView
          controlButtons
        }
      }
    }, detail: {
      rightColumn
        .navigationSplitViewColumnWidth(200)
    })
    .navigationSplitViewStyle(.balanced)
  }
  
  private var leftColumn: some View {
    VStack(alignment: .leading) {
      Button("Choose Video") {
        chooseVideo()
      }
      Button("Choose CoreML Model") {
        chooseModel()
      }
      Picker("Filter", selection: $selectedFilterName) {
        ForEach(filters, id: \.self) { filter in
          Text(filter).tag(filter as String?)
        }
      }
      .onChange(of: selectedFilterName) { newFilter in
        selectedFilter = CIFilter(name: newFilter ?? "")
        applyCurrentFilters()
      }
      Toggle("Apply Filter", isOn: $applyFilter)
      Toggle("Apply CoreML Model", isOn: $applyMLModel)
      let mlName = model?.modelDescription.metadata[.description] as? String ?? "None"
      Text("Model: \(mlName)")
      Spacer()
      Text("Gallery")
      ScrollView {
        ForEach(gallery.indices, id: \.self) { index in
          Image(nsImage: gallery[index])
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
        }
      }
    }
    .padding()
    .frame(width: 200)
  }
  
  private var videoPlayerView: some View {
    ZStack {
      if let playerView = playerView {
        CoreVideoPlayerView(videoURL: $videoURL, applyFilter: $applyFilter, selectedFilter: $selectedFilter, applyMLModel: $applyMLg, mlModel: $mlModel, brightness: $brightness, contrast: $contrast, saturation: $saturation, inputEV: $inputEV, gamma: $gamma, hue: $hue, highlightAmount: $highlightAmount, shadowAmount: $shadowAmount, temperature: $temperature, tint: $tint, whitePoint: $whitePoint, invert: $invert, posterize: $posterize, sharpenLuminance: $sharpenLuminance, unsharpMask: $unsharpMask, edges: $edges, gaborGradients: $gaborGradients, colorClamp: $colorClamp, convolution3x3: $convolution3x3, player: $player, playerView: $playerView, ciContext: $ciContext, showOverlay: $showOverlay, putAsideFrame: $putAsideFrame, gallery: $gallery)
          .frame(minWidth: 640, maxWidth: .infinity, minHeight: 480, maxHeight: .infinity)
      } else {
        VStack {
          Rectangle()
            .stroke(Color.gray, lineWidth: 2)
            .frame(minWidth: 640, maxWidth: .infinity, minHeight: 480, maxHeight: .infinity)
            .background(Color.black)
            .overlay(
              Text("Load a video to start")
                .foregroundColor(.white)
            )
            .padding()
        }
      }
    }
    .padding()
  }
  
  private var rightColumn: some View {
    VStack {
      Slider(value: $brightness, in: -1...1, step: 0.1) {
        Text("Brightness")
      }
      .onChange(of: brightness) { newValue in
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Slider(value: $contrast, in: 0...4, step: 0.1) {
        Text("Contrast")
      }
      .onChange(of: contrast) { newValue in
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Slider(value: $saturation, in: 0...4, step: 0.1) {
        Text("Saturation")
      }
      .onChange(of: saturation) { newValue in
        applyCurrentFilters()
      }
      Slider(value: $inputEV, in: -2...2, step: 0.1) {
        Text("Exposure")
      }
      .onChange(of: inputEV) { newValue in
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Slider(value: $gamma, in: 0.1...3.0, step: 0.1) {
        Text("Gamma")
      }
      .onChange(of: gamma) { newValue in
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Slider(value: $hue, in: 0...2 * .pi, step: 0.1) {
        Text("Hue")
      }
      .onChange(of: hue) { newValue in
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Slider(value: $highlightAmount, in: 0...1, step: 0.1) {
        Text("Highlight")
      }
      .onChange(of: highlightAmount) { newValue in
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Slider(value: $shadowAmount, in: -1...1, step: 0.1) {
        Text("Shadows")
      }
      .onChange(of: shadowAmount) { newValue in
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Slider(value: $temperature, in: 1000...10000, step: 100) {
        Text("Temperature")
      }
      .onChange(of: temperature) { newValue in
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Slider(value: $tint, in: -200...200, step: 1) {
        Text("Tint")
      }
      .onChange(of: tint) { newValue in
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Slider(value: $whitePoint, in: 0...2, step: 0.1) {
        Text("White Point")
      }
      .onChange(of: whitePoint) { newValue in
        if player?.rate == 0 {
          applyCurrentFilters()
        }
      }
      Toggle("CIColorInvert", isOn: $invert)
        .onChange(of: invert) { newValue in
          if player?.rate == 0 {
            applyCurrentFilters()
          }
        }
      Toggle("CIColorPosterize", isOn: $posterize)
        .onChange(of: posterize) { newValue in
          if player?.rate == 0 {
            applyCurrentFilters()
          }
        }
      Toggle("CISharpenLuminance", isOn: $sharpenLuminance)
        .onChange(of: sharpenLuminance) { newValue in
          if player?.rate == 0 {
            applyCurrentFilters()
          }
        }
      Toggle("CIUnsharpMask", isOn: $unsharpMask)
        .onChange(of: unsharpMask) { newValue in
          if player?.rate == 0 {
            applyCurrentFilters()
          }
        }
      Toggle("CIEdges", isOn: $edges)
        .onChange(of: edges) { newValue in
          if player?.rate == 0 {
            applyCurrentFilters()
          }
        }
      Toggle("CIGaborGradients", isOn: $gaborGradients)
        .onChange(of: gaborGradients) { newValue in
          if player?.rate == 0 {
            applyCurrentFilters()
          }
        }
      Toggle("CIColorClamp", isOn: $colorClamp)
        .onChange(of: colorClamp) { newValue in
          if player?.rate == 0 {
            applyCurrentFilters()
          }
        }
      Toggle("CIConvolution3x3", isOn: $convolution3x3)
        .onChange(of: convolution3x3) { newValue in
          if player?.rate == 0 {
            applyCurrentFilters()
          }
        }
      Button("Put Aside Frame") {
        putAsideCurrentFrame()
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
        showOverlay = false
      }
      Button("Pause") {
        player?.pause()
        showOverlay = true
      }
      Toggle("Loop", isOn: $loop)
    }
    .padding()
  }
  
  private func chooseVideo() {
    let panel = NSOpenPanel()
    panel.allowedFileTypes = ["mp4", "mov"]
    if panel.runModal() == .OK {
      videoURL = panel.url
      setupPlayer()
    }
  }
  
  private func chooseModel() {
    let panel = NSOpenPanel()
    panel.allowedFileTypes = ["mlmodel"]
    if panel.runModal() == .OK {
      do {
        let url = panel.url
        let compiledModelURL = try? MLModel.compileModel(at: url!)
        mlModel = try MLModel(contentsOf: compiledModelURL!)
      } catch {
        print("Error loading CoreML model: \(error)")
      }
    }
    applyCurrentFilters()
  }
  
  private func applyCurrentFilters() {
    guard let player = player, let playerItem = player.currentItem else { return }
    
    playerItem.videoComposition = AVVideoComposition(asset: playerItem.asset) { request in
      var ciImage = request.sourceImage.clampedToExtent()
      ciImage = self.applyFilters(to: ciImage)
      request.finish(with: ciImage, context: self.ciContext)
    }
    
    // Explicitly reset the video composition if the player is paused
    if player.rate == 0 {
      playerItem.videoComposition = playerItem.videoComposition
    }
  }
  
  private func applyFilters(to image: CIImage) -> CIImage {
    var ciImage = image
    
    if applyMLModel {
        let modelDescription = model!.modelDescription
//        guard let inputDescription = modelDescription.inputDescriptionsByName["image"],
//              let inputConstraint = inputDescription.imageConstraint else {
//          return ciImage
//        }
      let mlFilter = CIFilter(name: "CICoreMLModelFilter")!
        mlFilter.setValue(model, forKey: "inputModel")
        mlFilter.setValue(ciImage, forKey: kCIInputImageKey)
        ciImage = mlFilter.outputImage!        
        // Apply affine transform to adjust the plane
    }

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
    }
    
    return ciImage
  }
  
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
      convolution3x3: convolution3x3
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
    applyCurrentFilters()
  }
  
  private func setupPlayer() {
    guard let videoURL = videoURL else { return }
    let asset = AVAsset(url: videoURL)
    let playerItem = AVPlayerItem(asset: asset)
    player = AVPlayer(playerItem: playerItem)
    playerView = AVPlayerView()
    playerView?.player = player
    playerView?.allowsMagnification = true
    playerView?.allowsVideoFrameAnalysis = false
    
    let videoComposition = AVVideoComposition(asset: asset) { request in
      var ciImage = request.sourceImage.clampedToExtent()
      ciImage = self.applyFilters(to: ciImage)
      request.finish(with: ciImage, context: self.ciContext)
    }
    
    playerItem.videoComposition = videoComposition
  }
  
  private func putAsideCurrentFrame() {
    guard let player = player, let playerItem = player.currentItem else { return }
    let currentTime = player.currentTime()
    let asset = playerItem.asset
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    if let cgImage = try? generator.copyCGImage(at: currentTime, actualTime: nil) {
      let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
      gallery.append(nsImage)
    }
  }
}

struct CoreVideoPlayerView: NSViewRepresentable {
  @Binding var videoURL: URL?
  @Binding var applyFilter: Bool
  @Binding var selectedFilter: CIFilter?
  @Binding var applyMLModel: Bool
  @Binding var mlModel: MLModel?
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
  @Binding var gallery: [NSImage]
  
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
    
    if showOverlay, let player = player, player.rate == 0 {
      // Add overlay logic here
    }
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
}
// What you don't see, forensics
// Copyright Almahdi Morris Quet 2024
