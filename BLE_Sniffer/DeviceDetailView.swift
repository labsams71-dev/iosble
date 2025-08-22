import SwiftUI

struct DeviceDetailView: View {
    @StateObject private var bleManager = BLEManager.shared
    @State private var device: BLEDevice
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    init(device: BLEDevice) {
        self._device = State(initialValue: device)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Device Header
                VStack(spacing: 16) {
                    Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(device.isPlaying ? .green : .blue)
                    
                    VStack(spacing: 8) {
                        Text(device.customName.isEmpty ? device.name : device.customName)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        if device.customName != device.name {
                            Text("Original: \(device.name)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Playback Status
                    if device.isPlaying {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .foregroundColor(.green)
                            Text("BLE Signal Broadcasting")
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
                .padding(.top, 20)
                
                // Device Information
                VStack(alignment: .leading, spacing: 16) {
                    Text("Device Information")
                        .font(.headline)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        InfoRow(title: "Device ID", value: device.identifier)
                        InfoRow(title: "Signal Strength", value: "\(device.rssi) dBm (\(device.signalStrength))")
                        InfoRow(title: "Discovered", value: device.timestamp, style: .date)
                        InfoRow(title: "Time", value: device.timestamp, style: .time)
                        
                        if !device.services.isEmpty {
                            InfoRow(title: "Services", value: "\(device.services.count) found")
                        }
                        
                        if device.manufacturerData != nil {
                            InfoRow(title: "Manufacturer Data", value: "Available")
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Playback Controls
                VStack(spacing: 16) {
                    Text("BLE Signal Broadcasting")
                        .font(.headline)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        // Play/Stop Button
                        Button(action: {
                            if device.isPlaying {
                                bleManager.stopPlayback(for: device)
                            } else {
                                bleManager.startPlayback(for: device)
                            }
                            updateDevice()
                        }) {
                            HStack {
                                Image(systemName: device.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                Text(device.isPlaying ? "Stop Signal" : "Broadcast Signal")
                            }
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(device.isPlaying ? Color.red : Color.green)
                            .cornerRadius(12)
                        }
                        
                        // Playback Settings
                        VStack(spacing: 12) {
                            PlaybackSettingRow(
                                title: "Range",
                                value: device.playbackRange,
                                unit: "m",
                                range: 1...100
                            ) { newValue in
                                device.playbackRange = newValue
                                updateDevice()
                            }
                            
                            PlaybackSettingRow(
                                title: "Interval",
                                value: device.playbackInterval,
                                unit: "s",
                                range: 0.1...10.0
                            ) { newValue in
                                device.playbackInterval = newValue
                                updateDevice()
                            }
                            
                            PlaybackSettingRow(
                                title: "Duration",
                                value: device.playbackDuration,
                                unit: "s",
                                range: 10...3600
                            ) { newValue in
                                device.playbackDuration = newValue
                                updateDevice()
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Device")
                        }
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Device")
                        }
                        .font(.title3)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Device Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            EditDeviceView(device: $device) {
                updateDevice()
            }
        }
        .alert("Delete Device", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                bleManager.removeDeviceFromLibrary(device)
                // Navigate back
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Do you really want to delete '\(device.customName.isEmpty ? device.name : device.customName)'?")
        }
    }
    
    private func updateDevice() {
        bleManager.updateDevice(device)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let style: DateFormatter.Style?
    
    init(title: String, value: String) {
        self.title = title
        self.value = value
        self.style = nil
    }
    
    init(title: String, value: Date, style: DateFormatter.Style) {
        self.title = title
        self.value = DateFormatter.localizedString(from: value, dateStyle: style, timeStyle: .none)
        self.style = nil
    }
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct PlaybackSettingRow: View {
    let title: String
    let value: Double
    let unit: String
    let range: ClosedRange<Double>
    let onValueChanged: (Double) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .fontWeight(.medium)
                Spacer()
                Text("\(value, specifier: "%.1f") \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Slider(value: Binding(
                get: { value },
                set: { onValueChanged($0) }
            ), in: range, step: range.lowerBound < 1 ? 0.1 : 1.0)
            .accentColor(.blue)
        }
    }
}

struct EditDeviceView: View {
    @Binding var device: BLEDevice
    let onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var customName: String
    @State private var playbackRange: Double
    @State private var playbackInterval: Double
    @State private var playbackDuration: Double
    
    init(device: Binding<BLEDevice>, onSave: @escaping () -> Void) {
        self._device = device
        self.onSave = onSave
        self._customName = State(initialValue: device.wrappedValue.customName)
        self._playbackRange = State(initialValue: device.wrappedValue.playbackRange)
        self._playbackInterval = State(initialValue: device.wrappedValue.playbackInterval)
        self._playbackDuration = State(initialValue: device.wrappedValue.playbackDuration)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Device Settings")) {
                    HStack {
                        Text("Custom Name")
                        Spacer()
                        TextField("Enter name", text: $customName)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Broadcasting Settings")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Range: \(playbackRange, specifier: "%.1f") m")
                        Slider(value: $playbackRange, in: 1...100, step: 1.0)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interval: \(playbackInterval, specifier: "%.1f") s")
                        Slider(value: $playbackInterval, in: 0.1...10.0, step: 0.1)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration: \(playbackDuration, specifier: "%.0f") s")
                        Slider(value: $playbackDuration, in: 10...3600, step: 10.0)
                    }
                }
            }
            .navigationTitle("Edit Device")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    device.customName = customName
                    device.playbackRange = playbackRange
                    device.playbackInterval = playbackInterval
                    device.playbackDuration = playbackDuration
                    onSave()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .preferredColorScheme(.dark)
    }
}

struct DeviceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DeviceDetailView(device: BLEDevice(
                peripheral: CBPeripheral(),
                advertisementData: [:],
                rssi: NSNumber(value: -65)
            ))
        }
        .preferredColorScheme(.dark)
    }
} 