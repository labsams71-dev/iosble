import Foundation
import CoreBluetooth

struct BLEDevice: Identifiable, Codable, Equatable {
    let id = UUID()
    let name: String
    let identifier: String
    let rssi: Int
    let advertisementData: [String: Any]
    let services: [CBUUID]
    let manufacturerData: Data?
    let timestamp: Date
    
    // Playback settings
    var isPlaying: Bool = false
    var playbackRange: Double = 10.0 // meters
    var playbackInterval: Double = 1.0 // seconds
    var playbackDuration: Double = 60.0 // seconds
    var customName: String = ""
    
    init(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        self.name = peripheral.name ?? "Unknown Device"
        self.identifier = peripheral.identifier.uuidString
        self.rssi = rssi.intValue
        self.advertisementData = advertisementData
        self.services = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        self.manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        self.timestamp = Date()
        self.customName = peripheral.name ?? "Unknown Device"
    }
    
    // Custom coding keys for advertisement data
    private enum CodingKeys: String, CodingKey {
        case id, name, identifier, rssi, services, manufacturerData, timestamp
        case isPlaying, playbackRange, playbackInterval, playbackDuration, customName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        identifier = try container.decode(String.self, forKey: .identifier)
        rssi = try container.decode(Int.self, forKey: .rssi)
        advertisementData = [:] // We can't encode/decode this properly
        services = try container.decode([CBUUID].self, forKey: .services)
        manufacturerData = try container.decodeIfPresent(Data.self, forKey: .manufacturerData)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        isPlaying = try container.decode(Bool.self, forKey: .isPlaying)
        playbackRange = try container.decode(Double.self, forKey: .playbackRange)
        playbackInterval = try container.decode(Double.self, forKey: .playbackInterval)
        playbackDuration = try container.decode(Double.self, forKey: .playbackDuration)
        customName = try container.decode(String.self, forKey: .customName)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(rssi, forKey: .rssi)
        try container.encode(services, forKey: .services)
        try container.encodeIfPresent(manufacturerData, forKey: .manufacturerData)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(isPlaying, forKey: .isPlaying)
        try container.encode(playbackRange, forKey: .playbackRange)
        try container.encode(playbackInterval, forKey: .playbackInterval)
        try container.encode(playbackDuration, forKey: .playbackDuration)
        try container.encode(customName, forKey: .customName)
    }
    
    static func == (lhs: BLEDevice, rhs: BLEDevice) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    // Helper computed properties
    var signalStrength: String {
        switch rssi {
        case -50...:
            return "Excellent"
        case -60...(-51):
            return "Good"
        case -70...(-61):
            return "Fair"
        case -80...(-71):
            return "Poor"
        default:
            return "Very Poor"
        }
    }
    
    var signalStrengthColor: String {
        switch rssi {
        case -50...:
            return "green"
        case -60...(-51):
            return "blue"
        case -70...(-61):
            return "yellow"
        case -80...(-71):
            return "orange"
        default:
            return "red"
        }
    }
} 