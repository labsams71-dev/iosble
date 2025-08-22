import Foundation
import CoreBluetooth
import Combine

class BLEManager: NSObject, ObservableObject {
    static let shared = BLEManager()
    
    @Published var isScanning = false
    @Published var discoveredDevices: [BLEDevice] = []
    @Published var savedDevices: [BLEDevice] = []
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var errorMessage: String?
    
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    private var scanTimer: Timer?
    private var advertisingTimer: Timer?
    private let userDefaults = UserDefaults.standard
    private let savedDevicesKey = "SavedBLEDevices"
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        loadSavedDevices()
    }
    
    // MARK: - Bluetooth Management
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            errorMessage = "Bluetooth is not available"
            return
        }
        
        isScanning = true
        discoveredDevices.removeAll()
        
        // Start scanning with high power for maximum range
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true,
            CBCentralManagerScanOptionSolicitedServiceUUIDsKey: nil
        ])
        
        // Stop scanning after 30 seconds
        scanTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { _ in
            self.stopScanning()
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil
    }
    
    // MARK: - Device Management
    
    func addDeviceToLibrary(_ device: BLEDevice) {
        if !savedDevices.contains(where: { $0.identifier == device.identifier }) {
            var newDevice = device
            newDevice.customName = device.name
            savedDevices.append(newDevice)
            saveDevices()
        }
    }
    
    func removeDeviceFromLibrary(_ device: BLEDevice) {
        savedDevices.removeAll { $0.identifier == device.identifier }
        saveDevices()
    }
    
    func updateDevice(_ device: BLEDevice) {
        if let index = savedDevices.firstIndex(where: { $0.identifier == device.identifier }) {
            savedDevices[index] = device
            saveDevices()
        }
    }
    
    // MARK: - Real BLE Advertising
    
    func startPlayback(for device: BLEDevice) {
        guard let index = savedDevices.firstIndex(where: { $0.identifier == device.identifier }) else { return }
        guard peripheralManager.state == .poweredOn else {
            errorMessage = "Peripheral manager not ready"
            return
        }
        
        var updatedDevice = device
        updatedDevice.isPlaying = true
        savedDevices[index] = updatedDevice
        
        // Start real BLE advertising
        startBLEAdvertising(for: updatedDevice)
        
        saveDevices()
    }
    
    func stopPlayback(for device: BLEDevice) {
        guard let index = savedDevices.firstIndex(where: { $0.identifier == device.identifier }) else { return }
        
        var updatedDevice = device
        updatedDevice.isPlaying = false
        savedDevices[index] = updatedDevice
        
        // Stop BLE advertising
        stopBLEAdvertising()
        
        saveDevices()
    }
    
    private func startBLEAdvertising(for device: BLEDevice) {
        // Create a custom service UUID for this device
        let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABC")
        
        // Create advertisement data
        var advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: device.customName.isEmpty ? device.name : device.customName
        ]
        
        // Add manufacturer data if available
        if let manufacturerData = device.manufacturerData {
            advertisementData[CBAdvertisementDataManufacturerDataKey] = manufacturerData
        }
        
        // Start advertising
        peripheralManager.startAdvertising(advertisementData)
        
        // Schedule stop after duration
        advertisingTimer = Timer.scheduledTimer(withTimeInterval: device.playbackDuration, repeats: false) { _ in
            self.stopBLEAdvertising()
            // Find and update the device
            if let index = self.savedDevices.firstIndex(where: { $0.identifier == device.identifier }) {
                var updatedDevice = self.savedDevices[index]
                updatedDevice.isPlaying = false
                self.savedDevices[index] = updatedDevice
                self.saveDevices()
            }
        }
    }
    
    private func stopBLEAdvertising() {
        peripheralManager.stopAdvertising()
        advertisingTimer?.invalidate()
        advertisingTimer = nil
    }
    
    // MARK: - Persistence
    
    private func saveDevices() {
        do {
            let data = try JSONEncoder().encode(savedDevices)
            userDefaults.set(data, forKey: savedDevicesKey)
        } catch {
            print("Error saving devices: \(error)")
        }
    }
    
    private func loadSavedDevices() {
        guard let data = userDefaults.data(forKey: savedDevicesKey) else { return }
        
        do {
            savedDevices = try JSONDecoder().decode([BLEDevice].self, from: data)
        } catch {
            print("Error loading devices: \(error)")
        }
    }
    
    // MARK: - Utility
    
    func clearDiscoveredDevices() {
        discoveredDevices.removeAll()
    }
    
    func getDeviceByIdentifier(_ identifier: String) -> BLEDevice? {
        return savedDevices.first { $0.identifier == identifier }
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            self.bluetoothState = central.state
            
            switch central.state {
            case .poweredOn:
                self.errorMessage = nil
            case .poweredOff:
                self.errorMessage = "Bluetooth is turned off"
                self.stopScanning()
            case .unauthorized:
                self.errorMessage = "Bluetooth access denied"
            case .unsupported:
                self.errorMessage = "Bluetooth not supported"
            case .resetting:
                self.errorMessage = "Bluetooth is resetting"
            case .unknown:
                self.errorMessage = "Bluetooth status unknown"
            @unknown default:
                self.errorMessage = "Unknown Bluetooth status"
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let device = BLEDevice(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
        
        DispatchQueue.main.async {
            // Check if device already exists
            if let existingIndex = self.discoveredDevices.firstIndex(where: { $0.identifier == device.identifier }) {
                // Update existing device with new RSSI
                var updatedDevice = device
                updatedDevice.rssi = RSSI.intValue
                self.discoveredDevices[existingIndex] = updatedDevice
            } else {
                // Add new device
                self.discoveredDevices.append(device)
            }
            
            // Sort by RSSI (strongest signal first)
            self.discoveredDevices.sort { $0.rssi > $1.rssi }
        }
    }
}

// MARK: - CBPeripheralManagerDelegate

extension BLEManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        DispatchQueue.main.async {
            switch peripheral.state {
            case .poweredOn:
                print("Peripheral manager powered on")
            case .poweredOff:
                print("Peripheral manager powered off")
            case .unauthorized:
                print("Peripheral manager unauthorized")
            case .unsupported:
                print("Peripheral manager unsupported")
            case .resetting:
                print("Peripheral manager resetting")
            case .unknown:
                print("Peripheral manager unknown")
            @unknown default:
                print("Peripheral manager unknown state")
            }
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("Error starting advertising: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to start BLE advertising: \(error.localizedDescription)"
            }
        } else {
            print("BLE advertising started successfully")
        }
    }
} 