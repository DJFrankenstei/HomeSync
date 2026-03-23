//
//  ContentView.swift
//  HomeSync
//
//  Created by Samarth Bhate on 18/03/26.
//

import SwiftUI

@main
struct HomeSyncApp: App {
    @StateObject var blemanager = BLEManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(blemanager)
        }
    }
}



