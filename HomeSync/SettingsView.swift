//
//  SettingsView.swift
//  HomeSync
//
//  Created by Samarth Bhate on 18/03/26.
//

import SwiftUI
import CoreBluetooth

struct SettingsView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var showSettings: Bool
    var body: some View {
        NavigationStack {
            VStack {
                
                HStack {
                    Circle()
                        .fill(bleManager.connectedPeripheral != nil ? .green : .red)
                        .frame(width: 5, height: 5)
                    Text("\(bleManager.connectedPeripheral != nil ? "Connected to \(bleManager.connectedPeripheral!.name ?? "<unknown_device>")" : "Not Connected")")
                }
                    
                
                ScrollView {
                    ForEach(bleManager.peripherals, id: \.identifier) { d in
                        if let name = d.name {
                            HStack {
                                Image("Bluetooth logo")
                                    .resizable()
                                    .frame(width: 48, height: 72.5)
                                    .padding()
                                Text(name)
                                Spacer()
                                Button("Connect") {
                                    bleManager.connect(peripheral: d)
                                }
                                .padding()
                            }
                            
                        }
                    }
                }
                
            }
            
            .toolbar(content: {
                ToolbarItem {
                    Button {
                        bleManager.startScan()
                    } label: {
                        Text("Scan")
                    }
                    .disabled(!bleManager.finishedScan)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSettings.toggle()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundStyle(.red)
                }
            })
            .navigationTitle("Connect")
        }
        .onAppear {
            bleManager.startScan()
        }
    }
}

#Preview {
    SettingsView(showSettings: .constant(true))
        .environmentObject(BLEManager())
}

extension View {
    func Toolbar<Content: ToolbarContent>(@ToolbarContentBuilder content: () -> Content) -> some View {
        self.toolbar(content: content)
    }
}
