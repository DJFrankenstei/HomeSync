//
//  ContentView.swift
//  HomeSync
//
//  Created by Samarth Bhate on 18/03/26.
//

import SwiftUI

struct ContentView: View {
    @State private var buttonsActivated = [false, false, false, false, false]
    @State private var systemNames = [
        "lightbulb",
        "lightbulb",
        "fan.ceiling"
        ]
    @State private var datalist = [
        "0",
        "2",
        "1"
    ]
    @EnvironmentObject var bleManager: BLEManager
    
    private var connectedColors: [Color] {
        [Color(red: 0, green: 3/255, blue: 1), Color(red: 69/255, green: 233/255, blue: 1)]
    }
    private var disconnectedColors: [Color] {
        [Color(red: 1, green: 0, blue: 0), Color(red: 134/255, green: 0, blue: 0)]
    }
    
   @State private var showSettings = false 
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: bleManager.connectedPeripheral != nil ? connectedColors : disconnectedColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                RoundedRectangle(cornerSize: CGSize(width: 10, height: 20))
                    .stroke(.white, lineWidth: 2)
                    .padding()
                VStack {
                    
                    HStack {
                        Spacer()
                        Button {
                            showSettings.toggle()
                            print(bleManager.connectedPeripheral ?? "not connected")
                        } label: {
                            Image(systemName: "gear")
                                .font(.system(size: 30))
                                .offset(x: -20, y: 20)
                                .foregroundStyle(.white)
                        }
                        .padding()
                    }
                    Spacer()
                }
                VStack {
                    if bleManager.connectedPeripheral == nil {
                         Text("Connect 2 bluetooth")
                    }
                    HStack {
                        ForEach(0..<systemNames.count, id: \.self) { i in
                            AutomateButton(systemName: systemNames[i], isActivated: $buttonsActivated[i], sends: datalist[i])
                                .padding()
                                .disabled(bleManager.connectedPeripheral == nil) 
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            
        }
    }
}

#Preview {
    ContentView()
}


