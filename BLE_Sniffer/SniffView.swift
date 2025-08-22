import SwiftUI

struct SniffView: View {
    @StateObject private var bleManager = BLEManager.shared
    @State private var showingAddAlert = false
    @State private var selectedDevice: BLEDevice?
    
    var body: some View {
        VStack(spacing: 0) {
            // Scan Control Section
            VStack(spacing: 16) {
                // Status and Control
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bluetooth Status:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Circle()
                                .fill(bluetoothStatusColor)
                                .frame(width: 8, height: 8)
                            Text(bluetoothStatusText)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if bleManager.isScanning {
                            bleManager.stopScanning()
                        } else {
                            bleManager.startScanning()
                        }
                    }) {
                        HStack {
                            Image(systemName: bleManager.isScanning ? "stop.circle.fill" : "play.circle.fill")
                            Text(bleManager.isScanning ? "Stop Scan" : "Start Scan")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(bleManager.isScanning ? Color.red : Color.blue)
                        .cornerRadius(25)
                    }
                }
                
                // Scan Progress
                if bleManager.isScanning {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Scanning for BLE devices...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            
            // Device List
            if bleManager.discoveredDevices.isEmpty && !bleManager.isScanning {
                VStack(spacing: 16) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("No BLE devices found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Tap 'Start Scan' to search for BLE devices nearby")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(bleManager.discoveredDevices) { device in
                        DeviceRowView(device: device) {
                            selectedDevice = device
                            showingAddAlert = true
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .alert("Add Device to Library", isPresented: $showingAddAlert) {
            Button("Add") {
                if let device = selectedDevice {
                    bleManager.addDeviceToLibrary(device)
                    selectedDevice = nil
                }
            }
            Button("Cancel", role: .cancel) {
                selectedDevice = nil
            }
        } message: {
            if let device = selectedDevice {
                Text("Do you want to add '\(device.name)' to the library?")
            }
        }
    }
    
    private var bluetoothStatusColor: Color {
        switch bleManager.bluetoothState {
        case .poweredOn:
            return .green
        case .poweredOff:
            return .red
        case .unauthorized, .unsupported:
            return .orange
        default:
            return .gray
        }
    }
    
    private var bluetoothStatusText: String {
        switch bleManager.bluetoothState {
        case .poweredOn:
            return "Active"
        case .poweredOff:
            return "Turned Off"
        case .unauthorized:
            return "Unauthorized"
        case .unsupported:
            return "Not Supported"
        case .resetting:
            return "Resetting"
        case .unknown:
            return "Unknown"
        @unknown default:
            return "Unknown"
        }
    }
}

struct DeviceRowView: View {
    let device: BLEDevice
    let onAddToLibrary: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Signal Strength Indicator
            VStack(spacing: 4) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundColor(signalStrengthColor)
                
                Text("\(device.rssi)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            // Device Info
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("ID: \(String(device.identifier.prefix(8)))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Signal: \(device.signalStrength)")
                        .font(.caption)
                        .foregroundColor(signalStrengthColor)
                    
                    Spacer()
                    
                    Text(device.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Add Button
            Button(action: onAddToLibrary) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var signalStrengthColor: Color {
        switch device.signalStrength {
        case "Excellent":
            return .green
        case "Good":
            return .blue
        case "Fair":
            return .yellow
        case "Poor":
            return .orange
        default:
            return .red
        }
    }
}

struct SniffView_Previews: PreviewProvider {
    static var previews: some View {
        SniffView()
            .preferredColorScheme(.dark)
    }
} 