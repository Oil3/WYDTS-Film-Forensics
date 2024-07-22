import SwiftUI

@main
struct SensorApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

//import Foundation
//import IOKit.hid
//
//class SensorManager: ObservableObject {
//  @Published var deviceInfoText: String = ""
//
//  func readSensors() {
//    let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
//    IOHIDManagerSetDeviceMatching(manager, nil)
//
//    IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
//
//    guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
//      print("Failed to copy devices")
//      return
//    }
//
//    var deviceInfo = ""
//    for device in devices {
//      if let properties = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String {
//        deviceInfo += "Product: \(properties)\n"
//      } else {
//        deviceInfo += "Product: unknown\n"
//      }
//
//      if let vendorID = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int {
//        deviceInfo += "Vendor ID: \(vendorID)\n"
//      }
//
//      if let productID = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int {
//        deviceInfo += "Product ID: \(productID)\n"
//      }
//
//      deviceInfo += "\n"
//    }
//
//    deviceInfoText = deviceInfo
//    print(deviceInfo)
//  }
//}
//
//struct ContentView: View {
//  @ObservedObject var sensorManager = SensorManager()
//
//  var body: some View {
//    VStack {
//      Text("HID Devices")
//        .font(.headline)
//      ScrollView {
//        Text(sensorManager.deviceInfoText)
//          .padding()
//      }
//      Button("Read Sensor Values") {
//        sensorManager.readSensors()
//      }
//      .padding()
//    }
//    .padding()
//  }
//}
//


//import SwiftUI
//import Foundation
//import IOKit
//
//typealias IOHIDEventRef = OpaquePointer
//typealias IOHIDServiceClientRef = OpaquePointer
//typealias IOHIDEventSystemClientRef = OpaquePointer
//
//#if arch(arm64)
//typealias IOHIDFloat = Double
//#else
//typealias IOHIDFloat = Float
//#endif
//
//@_silgen_name("IOHIDEventSystemClientCreate")
//func IOHIDEventSystemClientCreate(_: CFAllocator?) -> IOHIDEventSystemClientRef?
//
//@_silgen_name("IOHIDEventSystemClientSetMatching")
//func IOHIDEventSystemClientSetMatching(_: IOHIDEventSystemClientRef, _: CFDictionary) -> Int32
//
//@_silgen_name("IOHIDEventSystemClientCopyServices")
//func IOHIDEventSystemClientCopyServices(_: IOHIDEventSystemClientRef) -> CFArray?
//
//@_silgen_name("IOHIDServiceClientCopyProperty")
//func IOHIDServiceClientCopyProperty(_: IOHIDServiceClientRef, _: CFString) -> CFTypeRef?
//
//@_silgen_name("IOHIDServiceClientCopyEvent")
//func IOHIDServiceClientCopyEvent(_: IOHIDServiceClientRef, _: Int64, _: Int32, _: Int64) -> IOHIDEventRef?
//
//@_silgen_name("IOHIDEventGetFloatValue")
//func IOHIDEventGetFloatValue(_: IOHIDEventRef, _: Int32) -> IOHIDFloat
//
//class SensorManager: ObservableObject {
//  @Published var sensorValuesText: String = ""
//  @Published var sensorNamesText: String = ""
//  
//  private var kIOHIDEventTypeTemperature = 15
//  private var kIOHIDEventTypePower = 25
//  
//  private func IOHIDEventFieldBase(type: Int) -> Int {
//    return type << 16
//  }
//  
//  func getProductNames() -> [String] {
//    guard let system = IOHIDEventSystemClientCreate(kCFAllocatorDefault) else {
//      print("Failed to create IOHIDEventSystemClient")
//      return []
//    }
//    
//    guard let matchingsrvs = IOHIDEventSystemClientCopyServices(system) as? [IOHIDServiceClientRef] else {
//      print("Failed to copy services")
//      return []
//    }
//    
//    var names: [String] = []
//    for service in matchingsrvs {
//      if let name = IOHIDServiceClientCopyProperty(service, "Product" as CFString) as? String {
//        names.append(name)
//      } else {
//        names.append("noname")
//      }
//    }
//    return names
//  }
//  
//  func getSensorValues() -> [Double] {
//    guard let system = IOHIDEventSystemClientCreate(kCFAllocatorDefault) else {
//      print("Failed to create IOHIDEventSystemClient")
//      return []
//    }
//    
//    guard let matchingsrvs = IOHIDEventSystemClientCopyServices(system) as? [IOHIDServiceClientRef] else {
//      print("Failed to copy services")
//      return []
//    }
//    
//    var values: [Double] = []
//    for service in matchingsrvs {
//      if let event = IOHIDServiceClientCopyEvent(service, Int64(kIOHIDEventTypeTemperature), 0, 0) {
//        let value = IOHIDEventGetFloatValue(event, Int32(IOHIDEventFieldBase(type: kIOHIDEventTypeTemperature)))
//        values.append(Double(value))
//      } else {
//        values.append(0.0)
//      }
//    }
//    return values
//  }
//  
//  func readSensors() {
//    let sensorNames = getProductNames()
//    let sensorValues = getSensorValues()
//    print("Sensor Names: \(sensorNames)")
//    print("Sensor Values: \(sensorValues)")
//    
//    sensorNamesText = sensorNames.joined(separator: "\n")
//    sensorValuesText = sensorValues.map { String(format: "%.2f", $0) }.joined(separator: "\n")
//  }
//}
//
//struct ContentView: View {
//  @ObservedObject var sensorManager = SensorManager()
//  
//  var body: some View {
//    VStack {
//      Text("Sensor Names")
//        .font(.headline)
//      Text(sensorManager.sensorNamesText)
//        .padding()
//      
//      Text("Sensor Values")
//        .font(.headline)
//      Text(sensorManager.sensorValuesText)
//        .padding()
//      
//      Button("Read Sensor Values") {
//        sensorManager.readSensors()
//      }
//      .padding()
//    }
//    .padding()
//  }
//}
//
//@main
//struct SensorApp: App {
//  var body: some Scene {
//    WindowGroup {
//      ContentView()
//    }
//  }
//}
//





//  What you don't see, forensics
//
//  Copyright Almahdi Morris Quet 2024
//
