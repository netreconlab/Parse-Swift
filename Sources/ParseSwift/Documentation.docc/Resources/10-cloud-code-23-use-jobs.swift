import Foundation
import ParseSwift

// Good: Use a job for long-running tasks
struct GenerateMonthlyReport: ParseCloudable {
    typealias ReturnType = String
    var functionJobName: String = "generateMonthlyReport"
    var month: Int
    var year: Int
}

let reportJob = GenerateMonthlyReport(month: 12, year: 2023)

do {
    // Start the job and return immediately
    let jobId = try await reportJob.startJob()
    print("Report generation started: \(jobId)")
    
    // The user can continue using the app
    // The report will be ready later and can be accessed via another query
} catch {
    print("Failed to start report generation: \(error)")
}

// Don't make users wait for tasks that can be completed in the background
