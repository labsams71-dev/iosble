import SwiftUI

struct LibraryView: View {
    @StateObject private var bleManager = BLEManager.shared
    @State private var showingDeleteAlert = false
    @State private var deviceToDelete: BLEDevice?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("BLE Library")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(bleManager.savedDevices.count) saved devices")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Device List
            if bleManager.savedDevices.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("No saved devices")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Scan for BLE devices and add them to the library")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(bleManager.savedDevices) { device in
                        NavigationLink(destination: DeviceDetailView(device: device)) {
                            LibraryDeviceRowView(device: device)
                        }
                    }
                    .onDelete(perform: deleteDevices)
                }
                .listStyle(PlainListStyle())
            }
        }
        .alert("Delete Device", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let device = deviceToDelete {
                    bleManager.removeDeviceFromLibrary(device)
                    deviceToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                deviceToDelete = nil
            }
        } message: {
            if let device = deviceToDelete {
                Text("Do you really want to delete '\(device.customName)'?")
            }
        }
    }
    
    private func deleteDevices(offsets: IndexSet) {
        for index in offsets {
            deviceToDelete = bleManager.savedDevices[index]
            showingDeleteAlert = true
        }
    }
}

struct LibraryDeviceRowView: View {
    let device: BLEDevice
    
    var body: some View {
        HStack(spacing: 12) {
            // Device Icon and Status
            VStack(spacing: 4) {
                Image(systemName: device.isPlaying ? "antenna.radiowaves.left.and.right.circle.fill" : "antenna.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundColor(device.isPlaying ? .green : .blue)
                
                if device.isPlaying {
                    Text("PLAY")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                }
            }
            .frame(width: 50)
            
            // Device Info
            VStack(alignment: .leading, spacing: 4) {
                Text(device.customName.isEmpty ? device.name : device.customName)
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
                    
                    Text("Added: \(device.timestamp, style: .date)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Quick Actions
            HStack(spacing: 8) {
                Button(action: {
                    if device.isPlaying {
                        BLEManager.shared.stopPlayback(for: device)
                    } else {
                        BLEManager.shared.startPlayback(for: device)
                    }
                }) {
                    Image(systemName: device.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(device.isPlaying ? .red : .green)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
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

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
            .preferredColorScheme(.dark)
    }
} 