import Foundation
import SwiftData

/// Seeds deterministic sample projects for previews and UI tests only.
enum SampleDataSeeder {
    static func seed(into context: ModelContext, now: Date) {
        let project = RTProject(
            title: "TV Setup",
            category: .electronics,
            status: .disassembled,
            createdAt: now,
            updatedAt: now
        )
        context.insert(project)

        let stepSpecs: [(String, RTStepType)] = [
            ("Original Setup", .reference),
            ("HDMI cable removed from HDMI 2", .disconnect),
            ("Power cable removed", .unplug),
            ("Soundbar optical cable removed", .disconnect),
        ]
        for (index, spec) in stepSpecs.enumerated() {
            let step = RTStep(orderIndex: index, title: spec.0, createdAt: now, stepType: spec.1)
            step.project = project
            context.insert(step)
        }

        let part = RTPart(name: "HDMI Cable", quantity: 1, storageLabel: "Bag A", createdAt: now)
        part.project = project
        context.insert(part)

        try? context.save()
    }
}
