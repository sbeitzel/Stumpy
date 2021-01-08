//
//  DataController.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/7/21.
//

import Foundation
import CoreData

/// An environment singleton for managing the Core Data stack and dealing with sample data
class DataController: ObservableObject {
    /// The container for CloudKit, in which all the data gets stored
    let container: NSPersistentCloudKitContainer

    /// Initializer, creating a DataController backed by a file or in memory (for testing).
    ///
    /// Defaults to permanent storage
    /// - Parameter inMemory: Whether data should be memory-only or not
    init(inMemory: Bool = false, container: NSPersistentCloudKitContainer) {
        self.container = container

        // For testing and previewing purposes, we create a
        // temporary, in-memory database by writing to /dev/null
        // so our data is destroyed after the app finishes running.
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Fatal error loading store: \(error.localizedDescription)")
            }
        }
    }

    static var preview: DataController = {
        let container = NSPersistentCloudKitContainer(name: "Stumpy")
        let dataController = DataController(inMemory: true, container: container)

        do {
            try dataController.createSampleData()
        } catch {
            fatalError("Fatal error creating sample data: \(error.localizedDescription)")
        }

        return dataController
    }()

    func createNewSpec(capacity: Int32 = 100, smtpPort: Int16 = 1080, popPort: Int16 = 9090) -> ServerSpec {
        let spec = ServerSpec(context: container.viewContext)
        spec.specID = UUID()
        spec.mailSlots = capacity
        spec.smtpPort = smtpPort
        spec.popPort = popPort
        return spec
    }

    /// Create sample ServerSpec for testing
    ///
    /// - Throws: an NSError from calling save() on the NSManagedObjectContext
    func createSampleData() throws {
        let viewContext = container.viewContext

        let spec = ServerSpec(context: viewContext)
        spec.mailSlots = 10
        spec.smtpPort = 4000
        spec.popPort = 4001
        try viewContext.save()
    }

    /// Saves our Core Data context iff there are changes. This silently ignores any errors caused by
    /// saving, but this should be fine because all our attributes are optional.
    func save() {
        if container.viewContext.hasChanges {
            try? container.viewContext.save()
        }
    }

    /// Delete a single managed object
    /// - Parameter object: the object to delete
    func delete(_ object: NSManagedObject) {
        container.viewContext.delete(object)
    }

    /// Deletes everything from our Core Data context.
    func deleteAll() {
        let fetchRequest1: NSFetchRequest<NSFetchRequestResult> = ServerSpec.fetchRequest()
        let batchDeleteRequest1 = NSBatchDeleteRequest(fetchRequest: fetchRequest1)
        _ = try? container.viewContext.execute(batchDeleteRequest1)
    }

}
