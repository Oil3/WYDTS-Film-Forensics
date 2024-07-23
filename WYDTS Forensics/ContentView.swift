//
//  ContentView.swift
//  WYDTS Forensics
//
//  Created by Almahdi Morris on 20/7/24.
//

import SwiftUI

struct ContentView: View {
  @State var preferredColumn = NavigationSplitViewColumn.content
  var body: some View {
    NavigationSplitView(preferredCompactColumn: $preferredColumn ) {
      LeftView()
    } content: {
      MainView()
    } detail: {
      RightView()
    }
    
}

  
}
//  What you don't see, forensics
//
//  Copyright Almahdi Morris Quet 2024
//
