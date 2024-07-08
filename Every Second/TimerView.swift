import SwiftUI
import Combine

struct TimerView: View {
    @State private var isTaskRunning = [Bool](repeating: false, count: 12)  // Array to track if each task is running
    @State private var taskElapsedTimes = [TimeInterval](repeating: 0, count: 12)  // Array to track elapsed time for each task
    @State private var taskNames = ["Sleep", "Beats", "Family", "Friends", "Sport", "We Have Sun", "Luarikot", "Tokinoki", "You", "Human Maintenance", "Transport", "Nothing"]  // Task names
    @State private var otherElapsedTime: TimeInterval = 0  // Elapsed time for "Other" category
    @State private var weekTimer = Timer.publish(every: 0.001, on: .main, in: .common)  // Timer to update elapsed times
    @State private var weekCancellable: Cancellable?  // Cancellable for the timer
    @State private var timeSinceStartOfWeek: TimeInterval = 0  // Time since the start of the week
    @State private var timeSinceStartOfYear: TimeInterval = 0  // Time since the start of the year
    @State private var timeSinceBirth: TimeInterval = 0  // Time since birth date
    @State private var currentWeekNumber: Int = 0  // Current week number
    @State private var showPreviousWeeks = false  // State to show the PreviousWeeksView
    
    // Array of colors for the task buttons
    private let buttonColors: [Color] = [
        .blue, .red, .green, .orange, .purple, .pink,
        .yellow, .gray, .teal, .indigo, .mint, .cyan
    ]
    
    // Hardcoded birth date
    private let birthDateString = "1992-05-04"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) { // Increased spacing between sections
                    // Padding at the top
                    Spacer().frame(height: 20)
                    
                    // Display time since start of the week
                    VStack(spacing: 10) {
                        Text("Time since start of the week:")
                            .font(.system(size: 24, weight: .bold))
                        Text(timeString(from: timeSinceStartOfWeek))
                            .font(.system(size: 20, weight: .medium, design: .monospaced))
                    }

                    // Display time since start of the year
                    VStack(spacing: 10) {
                        Text("Time since start of the year:")
                            .font(.system(size: 24, weight: .bold))
                        Text(timeStringWithDays(from: timeSinceStartOfYear))
                            .font(.system(size: 20, weight: .medium, design: .monospaced))
                    }

                    // Display time since birth date
                    VStack(spacing: 10) {
                        Text("Time since birth date:")
                            .font(.system(size: 24, weight: .bold))
                        Text(timeStringWithMonthsDays(from: timeSinceBirth))
                            .font(.system(size: 20, weight: .medium, design: .monospaced))
                    }
                    
                    .onReceive(weekTimer) { _ in
                        // Update times and handle week change
                        timeSinceStartOfYear = calculateTimeSinceStartOfYear()
                        timeSinceStartOfWeek = calculateTimeSinceStartOfWeek()
                        timeSinceBirth = calculateTimeSinceBirth()
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
                        // Display "Other" task
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
                            .disabled(isTaskRunning.contains(true))  // Disable if any task is running
                        }
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .navigationBarItems(trailing: Button(action: {
                showPreviousWeeks.toggle()
            }) {
                Text("Previous Weeks")
            })
            .sheet(isPresented: $showPreviousWeeks) {
                PreviousWeeksView()
            }
            .onAppear {
                // Start the timer
                weekTimer = Timer.publish(every: 0.001, on: .main, in: .common)
                weekCancellable = weekTimer.connect()
                loadState()  // Load saved state
            }
            .onDisappear {
                weekCancellable?.cancel()  // Cancel the timer
            }
        }
    }

    // Function to start a task
    private func startTask(index: Int) {
        for i in 0..<isTaskRunning.count {
            isTaskRunning[i] = false
        }
        isTaskRunning[index] = true
        saveState()
    }

    // Function to start the "Other" task
    private func startOther() {
        for i in 0..<isTaskRunning.count {
            isTaskRunning[i] = false
        }
        saveState()
    }

    // Function to update elapsed times for tasks
    private func updateElapsedTimes() {
        let runningTaskIndex = isTaskRunning.firstIndex(of: true)

        if let index = runningTaskIndex {
            // Update the elapsed time for the running task
            taskElapsedTimes[index] = timeSinceStartOfWeek - (otherElapsedTime + taskElapsedTimes.filter { $0 != taskElapsedTimes[index] }.reduce(0, +))
        } else {
            // Update the elapsed time for "Other"
            otherElapsedTime = timeSinceStartOfWeek - taskElapsedTimes.reduce(0, +)
        }
    }

    // Function to handle week change
    private func handleWeekChange() {
        let calendar = Calendar.current
        let now = Date()
        let weekNumber = calendar.component(.weekOfYear, from: now)
        let yearNumber = calendar.component(.year, from: now)
        
        if weekNumber != currentWeekNumber {
            // Save the overflow time from the previous week
            let overflowTime = timeSinceStartOfWeek
            savePreviousWeekData(weekNumber: currentWeekNumber, year: yearNumber - 1)
            resetData()
            
            // Add the overflow time to the current running task
            if let runningTaskIndex = isTaskRunning.firstIndex(of: true) {
                taskElapsedTimes[runningTaskIndex] += overflowTime
            }
            
            // Update the current week number
            currentWeekNumber = weekNumber
        }
    }

    // Function to reset data at the start of a new week
    private func resetData() {
        isTaskRunning = [Bool](repeating: false, count: 12)
        taskElapsedTimes = [TimeInterval](repeating: 0, count: 12)
        otherElapsedTime = 0
    }

    // Function to save the previous week's data
    private func savePreviousWeekData(weekNumber: Int, year: Int) {
        let defaults = UserDefaults.standard
        var previousWeeksData = defaults.dictionary(forKey: "previousWeeksData") as? [String: [String: TimeInterval]] ?? [:]

        // Create a unique key for the week and year
        let weekKey = "\(year)-\(weekNumber)"
        
        // Save task elapsed times for the week
        var weekData: [String: TimeInterval] = [:]
        for (index, elapsedTime) in taskElapsedTimes.enumerated() {
            weekData[taskNames[index]] = elapsedTime
        }
        weekData["Other"] = otherElapsedTime
        
        previousWeeksData[weekKey] = weekData
        defaults.set(previousWeeksData, forKey: "previousWeeksData")
    }

    // Function to save the current state
    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(isTaskRunning, forKey: "isTaskRunning")
        defaults.set(taskElapsedTimes, forKey: "taskElapsedTimes")
        defaults.set(taskNames, forKey: "taskNames")
        defaults.set(otherElapsedTime, forKey: "otherElapsedTime")
        defaults.set(currentWeekNumber, forKey: "currentWeekNumber")
        defaults.set(Date().timeIntervalSinceReferenceDate, forKey: "lastSavedTime")
    }

    // Function to load the saved state
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
            // Adjust the elapsed time for the running task
            taskElapsedTimes[index] += timeDifference
        } else {
            // Adjust the elapsed time for "Other"
            otherElapsedTime += timeDifference
        }
    }

    // Function to convert time interval to a formatted string
    private func timeString(from interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        let milliseconds = Int((interval - floor(interval)) * 1000)

        return String(format: "%02i:%02i:%02i:%03i", hours, minutes, seconds, milliseconds)
    }
    
    // Function to convert time interval to a formatted string with days
    private func timeStringWithDays(from interval: TimeInterval) -> String {
        let days = Int(interval) / (3600 * 24)
        let hours = (Int(interval) % (3600 * 24)) / 3600
        let minutes = (Int(interval) / 60) % 60
        let seconds = Int(interval) % 60
        let milliseconds = Int((interval - floor(interval)) * 1000)

        return String(format: "%02i days %02i:%02i:%02i:%03i", days, hours, minutes, seconds, milliseconds)
    }
    
    // Function to convert time interval to a formatted string with months and days
    private func timeStringWithMonthsDays(from interval: TimeInterval) -> String {
        let calendar = Calendar.current
        let now = Date()
        let birthDate = getDate(from: birthDateString)
        let components = calendar.dateComponents([.month, .day, .hour, .minute, .second, .nanosecond], from: birthDate, to: now)
        
        let months = components.month ?? 0
        let days = components.day ?? 0
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        let seconds = components.second ?? 0
        let milliseconds = (components.nanosecond ?? 0) / 1_000_000

        return String(format: "%02im %02id %02i:%02i:%02i:%03i", months, days, hours, minutes, seconds, milliseconds)
    }

    // Function to calculate time since the start of the week
    private func calculateTimeSinceStartOfWeek() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        return now.timeIntervalSince(startOfWeek)
    }

    // Function to calculate time since the start of the year
    private func calculateTimeSinceStartOfYear() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
        return now.timeIntervalSince(startOfYear)
    }
    
    // Function to calculate time since birth date
    private func calculateTimeSinceBirth() -> TimeInterval {
        let now = Date()
        let birthDate = getDate(from: birthDateString)
        return now.timeIntervalSince(birthDate)
    }
    
    // Function to get date from string
    private func getDate(from dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: dateString) ?? Date()
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView()
    }
}
