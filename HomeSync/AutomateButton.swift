//
//  AutomateButton.swift
//  ArduinoAutomate
//
//  Created by Samarth Bhate on 18/03/26.
//

import SwiftUI

struct AutomateButton: View {
    var systemName: String
    @Binding var isActivated: Bool
    var label: String?
    var sends: String
    var callback: (() -> ())?
    
    @Environment(\.isEnabled) var isEnabled
    @EnvironmentObject var bleManager: BLEManager
    
    var body: some View {
        VStack {
            Button {
                isActivated.toggle()
                bleManager.send(data: "\(sends)\r\n")
                if let callback = callback {
                    callback()
                }
            } label: {
                if isEnabled {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 3)
                            .frame(width: 100, height: 100)
                            .foregroundStyle(isActivated ? .yellow : .white)
                        Image(systemName: systemName)
                            .font(.system(size: 60, weight: .light))
                            .foregroundStyle(isActivated ? .yellow : .white)
                    }
                } else {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 3)
                            .frame(width: 100, height: 100)
                            .foregroundStyle(.white)
                        Image(systemName: systemName)
                            .font(.system(size: 60, weight: .light))
                            .foregroundStyle(.red)
                    }
                }
                    
            }
            
            .disabled(!isEnabled)
            if let label = label {
                Text(label)
                    .foregroundStyle(.white)
            }
        
            
        }
    }
}

#Preview {
    @Previewable @State var isActivated = false
    AutomateButton(systemName: "lightbulb", isActivated: $isActivated, label: "Light 1", sends: "")
        .environmentObject(BLEManager())
}
