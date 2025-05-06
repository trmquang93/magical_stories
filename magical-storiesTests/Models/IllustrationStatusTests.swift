import Foundation
import Testing

@testable import magical_stories

@Suite("IllustrationStatus Tests")
struct IllustrationStatusTests {

    @Test("IllustrationStatus initialization and equality")
    func testStatusInitializationAndEquality() {
        // Test basic equality
        let pending1 = IllustrationStatus.pending
        let pending2 = IllustrationStatus.pending
        let generating = IllustrationStatus.generating
        let scheduled = IllustrationStatus.scheduled

        #expect(pending1 == pending2)
        #expect(pending1 != generating)
        #expect(pending1 != scheduled)
        #expect(scheduled != generating)

        // Test raw values
        #expect(pending1.rawValue == "pending")
        #expect(generating.rawValue == "generating")
        #expect(IllustrationStatus.ready.rawValue == "ready")
        #expect(IllustrationStatus.failed.rawValue == "failed")
        #expect(scheduled.rawValue == "scheduled")
    }

    @Test("IllustrationStatus case iteration")
    func testStatusCaseIteration() {
        // Test that we can iterate through all cases
        let allCases = IllustrationStatus.allCases

        #expect(allCases.count == 5)
        #expect(allCases.contains(.pending))
        #expect(allCases.contains(.scheduled))
        #expect(allCases.contains(.generating))
        #expect(allCases.contains(.ready))
        #expect(allCases.contains(.failed))
    }
    
    @Test("IllustrationStatus scheduled state behavior")
    func testScheduledStateBehavior() {
        // The scheduled state is used to track tasks in the queue
        let scheduledStatus = IllustrationStatus.scheduled
        
        // Verify it's a distinct state
        #expect(scheduledStatus != .pending)
        #expect(scheduledStatus != .generating)
        #expect(scheduledStatus != .ready)
        #expect(scheduledStatus != .failed)
        
        // Test state transitions - in a real scenario, these transitions would
        // be handled by the IllustrationTaskManager
        // Transitions: pending -> scheduled -> generating -> ready/failed
        let transitions: [(from: IllustrationStatus, to: IllustrationStatus, valid: Bool)] = [
            (.pending, .scheduled, true),     // Valid: Task is initially scheduled
            (.scheduled, .generating, true),  // Valid: Scheduled task starts processing
            (.scheduled, .ready, false),      // Invalid: Task must be generated first
            (.scheduled, .failed, false),     // Invalid: Task hasn't attempted generation
            (.generating, .scheduled, false), // Invalid: Can't go back to scheduled
            (.ready, .scheduled, false),      // Invalid: Already completed
            (.failed, .scheduled, true),      // Valid: Failed task can be rescheduled
        ]
        
        // Validate state transition logic
        // Note: These expectations are based on the intended state machine
        // The actual enforcement would be in the IllustrationTaskManager
        for transition in transitions {
            let transitionDescription = "\(transition.from) -> \(transition.to)"
            if transition.valid {
                print("Valid transition: \(transitionDescription)")
            } else {
                print("Invalid transition: \(transitionDescription)")
            }
        }
    }
}
