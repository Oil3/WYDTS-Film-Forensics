//
//  RightView.swift
//  WYDTS Forensics
//
//  Created by Almahdi Morris on 20/7/24.
//

import SwiftUI

struct RightView: View {
    @State private var cliOutput: String = "Waiting for command..."
    @State private var isRunning: Bool = false
    
  
  var body: some View {
    Text("RightView")
//      VStack {  //can run command-line tools within the app and display output, however has to add bunch of value because the idea is a GUI app
//        Text(cliOutput)
//          .padding()
//          .frame(maxWidth: .infinity, alignment: .leading)
//        
//        HStack {
//          Button("Run Command") {
//            runCLICommand()
//          }
//          .disabled(isRunning)
//          
//          if isRunning {
//            ProgressView()
//              .progressViewStyle(CircularProgressViewStyle())
//              .padding(.leading, 10)
//          }
//        }
//        .padding()
//      }
//      .padding()
//      .frame(width: 400, height: 200)
//    }
//    
//    func runCLICommand() {
//      isRunning = true
//      cliOutput = "Running..."
//      
//      DispatchQueue.global(qos: .userInitiated).async {
//        let process = Process()
//        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
//        process.arguments = ["yolo" "predit" "detect"]  // Replace with your command
//        
//        let pipe = Pipe()
//        process.standardOutput = pipe
//        process.standardError = pipe
//        
//        do {
//          try process.run()
//          process.waitUntilExit()
//          
//          let data = pipe.fileHandleForReading.readDataToEndOfFile()
//          let output = String(data: data, encoding: .utf8) ?? "Unknown error"
//          
//          DispatchQueue.main.async {
//            cliOutput = output
//            isRunning = false
//          }
//        } catch {
//          DispatchQueue.main.async {
//            cliOutput = "Failed to run command: \(error.localizedDescription)"
//            isRunning = false
//          }
//        }
//      }
    }
  }

//  What you don't see, forensics
//
//  Copyright Almahdi Morris Quet 2024
//
