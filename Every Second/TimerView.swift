import SwiftUI
import Combine

struct TimerView: View {
    @State private var isTaskRunning = [Bool](repeating: false, count: 12)
    @State private var taskElapsedTimes = [TimeInterval](repeating: 0, count: 12)
    @State private var taskNames = ["Sleep", "Beats", "Family", "Friends", "Sport", "We Have Sun", "Luarikot", "Tokinoki", "You", "Human Maintenance", "Transport", "Nothing"]
    @State private var otherElapsedTime: TimeInterval = 0
    @State private var weekTimer = Timer.publish(every: 0.001, on: .main, in: .common)
    @State private var weekCancellable: Cancellable?
    @State private var timeSinceStartOfWeek: TimeInterval = 0
    @State private var timeSinceStartOfYear: TimeInterval = 0
    @State private var currentWeekNumber: Int = 0
    
    private let buttonColors: [Color] = [
        .blue, .red, .green, .orange, .purple, .pink,
        .yellow, .gray, .teal, .indigo, .mint, .cyan
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Padding at the top
                Spacer().frame(height: 20)
                
                // Display time since start of the week and year at the top
                Text("Time since start of the week:")
                    .font(.system(size: 24, weight: .bold))
                Text(timeString(from: timeSinceStartOfWeek))
                    .font(.system(size: 20, weight: .medium, design: .monospaced))

                Text("Time since start of the year:")
                    .font(.system(size: 24, weight: .bold))
                Text(timeStringWithDays(from: timeSinceStartOfYear))
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .onReceive(weekTimer) { _ in
                        timeSinceStartOfYear = calculateTimeSinceStartOfYear()
                        timeSinceStartOfWeek = calculateTimeSinceStartOfWeek()
                        updateElapsedTimes()
                        handleWeekChange()
                        saveState()
                    }
                
                // Add space between the time section and the first task
                Spacer().frame(height: 20)

                // Display currently running task at the top
                if let runningTaskIndex = isTaskRunning.firstIndex(of: true) {
                    TaskView(
                        index: runningTaskIndex,
                        taskName: taskNames[runningTaskIndex],
                        elapsedTime: taskElapsedTimes[runningTaskIndex],
                        buttonColor: buttonColors[runningTaskIndex % buttonColors.count],
                        isRunning: true,
                        startTask: startTask(index:)
                    )
                }

                // Display all other tasks
                ForEach(0..<12) { index in
                    if !isTaskRunning[index] {
                        TaskView(
                            index: index,
                            taskName: taskNames[index],
                            elapsedTime: taskElapsedTimes[index],
                            buttonColor: buttonColors[index % buttonColors.count],
                            isRunning: false,
                            startTask: startTask(index:)
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Other")
                        .font(.title2)
                        .frame(width: 150, alignment: .leading)

                    HStack {
                        Text(timeString(from: otherElapsedTime))
                            .font(.system(size: 20, weight: .medium, design: .monospaced))
                            .frame(minWidth: 100, alignment: .leading)
                        Spacer()
                        Button(action: startOther) {
                            Text("Start")
                                .padding()
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(isTaskRunning.contains(true))
                    }
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .onAppear {
            weekTimer = Timer.publish(every: 0.001, on: .main, in: .common)
            weekCancellable = weekTimer.connect()
            loadState()
        }
        .onDisappear {
            weekCancellable?.cancel()
        }
    }

    private func startTask(index: Int) {
        for i in 0..<isTaskRunning.count {
            isTaskRunning[i] = false
        }
        isTaskRunning[index] = true
        saveState()
    }

    private func startOther() {
        for i in 0..<isTaskRunning.count {
            isTaskRunning[i] = false
        }
        saveState()
    }

    private func updateElapsedTimes() {
        let runningTaskIndex = isTaskRunning.firstIndex(of: true)

        if let index = runningTaskIndex {
            taskElapsedTimes[index] = timeSinceStartOfWeek - (otherElapsedTime + taskElapsedTimes.filter { $0 != taskElapsedTimes[index] }.reduce(0, +))
        } else {
            otherElapsedTime = timeSinceStartOfWeek - taskElapsedTimes.reduce(0, +)
        }
    }

    private func handleWeekChange() {
        let calendar = Calendar.current
        let now = Date()
        let weekNumber = calendar.component(.weekOfYear, from: now)
        
        if weekNumber != currentWeekNumber {
            // Save the overflow time from the previous week
            let overflowTime = timeSinceStartOfWeek
            resetData()
            
            // Add the overflow time to the current running task
            if let runningTaskIndex = isTaskRunning.firstIndex(of: true) {
                taskElapsedTimes[runningTaskIndex] += overflowTime
            }
            
            // Update the current week number
            currentWeekNumber = weekNumber
        }
    }

    private func resetData() {
        isTaskRunning = [Bool](repeating: false, count: 12)
        taskElapsedTimes = [TimeInterval](repeating: 0, count: 12)
        otherElapsedTime = 0
    }

    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(isTaskRunning, forKey: "isTaskRunning")
        defaults.set(taskElapsedTimes, forKey: "taskElapsedTimes")
        defaults.set(taskNames, forKey: "taskNames")
        defaults.set(otherElapsedTime, forKey: "otherElapsedTime")
        defaults.set(currentWeekNumber, forKey: "currentWeekNumber")
        defaults.set(Date().timeIntervalSinceReferenceDate, forKey: "lastSavedTime")
    }

    private func loadState() {
        let defaults = UserDefaults.standard
        let lastSavedTime = defaults.double(forKey: "lastSavedTime")
        let timeDifference = Date().timeIntervalSinceReferenceDate - lastSavedTime

        isTaskRunning = defaults.array(forKey: "isTaskRunning") as? [Bool] ?? [Bool](repeating: false, count: 12)
        taskElapsedTimes = defaults.array(forKey: "taskElapsedTimes") as? [TimeInterval] ?? [TimeInterval](repeating: 0, count: 12)
        taskNames = defaults.stringArray(forKey: "taskNames") ?? ["Sleep", "Beats", "Family", "Friends", "Sport", "We Have Sun", "Luarikot", "Tokinoki", "You", "Human Maintenance", "Transport", "Nothing"]
        otherElapsedTime = defaults.double(forKey: "otherElapsedTime")
        currentWeekNumber = defaults.integer(forKey: "currentWeekNumber")

        if let index = isTaskRunning.firstIndex(of: true) {
            taskElapsedTimes[index] += timeDifference
        } else {
            otherElapsedTime += timeDifference
        }
    }

    private func timeString(from interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        let milliseconds = Int((interval - floor(interval)) * 1000)

        return String(format: "%02i:%02i:%02i:%03i", hours, minutes, seconds, milliseconds)
    }
    
    private func timeStringWithDays(from interval: TimeInterval) -> String {
        let days = Int(interval) / (3600 * 24)
        let hours = (Int(interval) % (3600 * 24)) / 3600
        let minutes = (Int(interval) / 60) % 60
        let seconds = Int(interval) % 60
        let milliseconds = Int((interval - floor(interval)) * 1000)

        return String(format: "%02i days %02i:%02i:%02i:%03i", days, hours, minutes, seconds, milliseconds)
    }

    private func calculateTimeSinceStartOfWeek() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        return now.timeIntervalSince(startOfWeek)
    }

    private func calculateTimeSinceStartOfYear() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
        return now.timeIntervalSince(startOfYear)
    }
}

struct TaskView: View {
    let index: Int
    let taskName: String
    let elapsedTime: TimeInterval
    let buttonColor: Color
    let isRunning: Bool
    let startTask: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(taskName)
                .font(.title2)
                .frame(width: 150, alignment: .leading)

            HStack {
                Text(timeString(from: elapsedTime))
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .frame(minWidth: 100, alignment: .leading)
                Spacer()
                Button(action: { startTask(index) }) {
                    Text("Start")
                        .padding()
                        .background(buttonColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isRunning)
            }
        }
    }

    private func timeString(from interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        let milliseconds = Int((interval - floor(interval)) * 1000)

        return String(format: "%02i:%02i:%02i:%03i", hours, minutes, seconds, milliseconds)
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView()
    }
}
