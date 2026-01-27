import Foundation
import ParseSwift

// Create an instance of the job
let job = MyBackgroundJob(batchSize: 100)

Task {
    do {
        // Start the Cloud Job (runs asynchronously on the server)
        let response = try await job.startJob()

        print("Job started: \(response)")
        // The job continues running on the server even after this returns
    } catch {
        print("Error starting job: \(error)")
    }
}
