import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BLEManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("BLE Sniffer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Bluetooth Low Energy Scanner & Library")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                
                // Main Content
                TabView(selection: $selectedTab) {
                    SniffView()
                        .tabItem {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Text("Sniff")
                        }
                        .tag(0)
                    
                    LibraryView()
                        .tabItem {
                            Image(systemName: "folder")
                            Text("Library")
                        }
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.dark)
        .alert("Bluetooth Error", isPresented: .constant(bleManager.errorMessage != nil)) {
            Button("OK") {
                bleManager.errorMessage = nil
            }
        } message: {
            if let errorMessage = bleManager.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
} 