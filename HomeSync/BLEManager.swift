//
//  BLEManager.swift
//  HomeSync
//
//  Created by Samarth Bhate on 23/03/26.
//


import SwiftUI
import Foundation
import Combine
import CoreBluetooth

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager!
    
    @Published var peripherals: [CBPeripheral] = [] {
        didSet {
            
        }
    }
    @Published var connectedPeripheral: CBPeripheral?
    
    @Published var finishedScan = true {
        didSet {
            print("b")
        }
    }
    
    var targetCharacteristic: CBCharacteristic?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Scan
    func startScan() {
        defer {
            finishedScan = true
        }
        finishedScan = false
        peripherals.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    // MARK: - Connect
    func connect(peripheral: CBPeripheral) {
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }
    
    // MARK: - Send Data
    func send(data: String) {
        guard let characteristic = targetCharacteristic,
              let peripheral = connectedPeripheral else { return }
        
        let dataToSend = Data(data.utf8)
        peripheral.writeValue(dataToSend, for: characteristic, type: .withResponse)
    }
    
    // MARK: - Central Delegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth ON")
        } else {
            print("Bluetooth not available")
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        
        if !peripherals.contains(peripheral) {
            peripherals.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        
        connectedPeripheral = peripheral
        peripheral.delegate = self
        
        peripheral.discoverServices(nil)
    }
    
    // MARK: - Peripheral Delegate
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        
        service.characteristics?.forEach { characteristic in
            
            print("Found characteristic: \(characteristic.uuid)")
            
            // Example: HM-10 uses FFE1
            if characteristic.uuid.uuidString == "FFE1" {
                targetCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        
        if let data = characteristic.value,
           let string = String(data: data, encoding: .utf8) {
            print("Received:", string)
        }
    }
}

