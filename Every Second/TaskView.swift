//
//  TaskView.swift
//  Every Second
//
//  Created by Natalia Terlecka on 06/07/2024.
//

import Foundation
import SwiftUI

struct TaskView: View {
    let index: Int
    let taskName: String
    let elapsedTime: TimeInterval
    let buttonColor: Color
    let isRunning: Bool
    let startTask: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Display the task name
            Text(taskName)
                .font(.title2)
                .frame(width: 150, alignment: .leading)

            HStack {
                // Display the elapsed time for the task
                Text(timeString(from: elapsedTime))
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .frame(minWidth: 100, alignment: .leading)
                Spacer()
                // Button to start the task
                Button(action: { startTask(index) }) {
                    Text("Start")
                        .padding()
                        .background(buttonColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isRunning)  // Disable button if the task is already running
            }
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
}

struct TaskView_Previews: PreviewProvider {
    static var previews: some View {
        TaskView(index: 0, taskName: "Sample Task", elapsedTime: 3600, buttonColor: .blue, isRunning: false, startTask: { _ in })
    }
}
