import SwiftUI

struct PreviousWeeksView: View {
    @State private var previousWeeksData: [String: [String: TimeInterval]] = [:]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(previousWeeksData.keys).sorted(), id: \.self) { weekKey in
                    Section(header: Text(weekKey)) {
                        if let weekData = previousWeeksData[weekKey] {
                            ForEach(Array(weekData.keys), id: \.self) { taskName in
                                HStack {
                                    Text(taskName)
                                    Spacer()
                                    Text(timeString(from: weekData[taskName] ?? 0))
                                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Previous Weeks")
            .onAppear {
                loadPreviousWeeksData()
            }
        }
    }
    
    // Function to load previous weeks data from UserDefaults
    private func loadPreviousWeeksData() {
        let defaults = UserDefaults.standard
        previousWeeksData = defaults.dictionary(forKey: "previousWeeksData") as? [String: [String: TimeInterval]] ?? [:]
    }
    
    // Function to convert time interval to a formatted string
    private func timeString(from interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }
}

struct PreviousWeeksView_Previews: PreviewProvider {
    static var previews: some View {
        PreviousWeeksView()
    }
}
