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
    
    @State private var detected = false
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        switch horizontalSizeClass {
        case .regular:
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
                            Text("Connect to Bluetooth!")
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                        } else {
                            HStack {
                                ForEach(0..<systemNames.count, id: \.self) { i in
                                    AutomateButton(systemName: systemNames[i], isActivated: $buttonsActivated[i], sends: datalist[i])
                                        .padding()
                                        .disabled(bleManager.connectedPeripheral == nil)
                                }
                            }
                        }
                    }
                }
                .ignoresSafeArea()
                .sheet(isPresented: $showSettings) {
                    SettingsView(showSettings: $showSettings)
                }
                .onAppear {
                    showSettings.toggle()
                }
                .onChange(of: bleManager.received) { _, newValue in
                    
                    guard let data = newValue else { return }
                    
                    let byteArray = Array(data)
                    
                    
                    
                    print()
                    
                    
                    
                    if String(byteArray.first!) == "1" || String(byteArray.first!) == "0" {
                        detected = true
                        
                    } else {
                        
                    }
                }
                .alert("Someone at yo door", isPresented: $detected) {
                    Button("Alr") {
                        detected = false
                    }
                }
                
            }
            
        default:
            ZStack {
                LinearGradient(colors: bleManager.connectedPeripheral != nil ? connectedColors : disconnectedColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                RoundedRectangle(cornerSize: CGSize(width: 10, height: 20))
                    .stroke(.white, lineWidth: 2)
                    .padding()
                VStack {
                    
                    Text("Unsupported Size Class!")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                }
            }
            
        
        }
    }
}

#Preview {
    ContentView()
}


extension String {
    func literalized() -> String {
        return self
            .replacingOccurrences(of: "\\", with: "\\\\") // Escape backslashes first
            .replacingOccurrences(of: "\n", with: "\\n")  // Replace newline with literal \n
            .replacingOccurrences(of: "\r", with: "\\r")  // Replace carriage return with literal \r
            .replacingOccurrences(of: "\t", with: "\\t")  // Optionally replace tab
             // Optionally replace quotes
    }
}
