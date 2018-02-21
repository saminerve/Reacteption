//
//  AppDelegate.swift
//  Currency
//
//  Created by Nuno Coelho Santos on 11/02/2016.
//  Copyright © 2016 Nuno Coelho Santos. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Print user language.
        print("Device locale:", Locale.preferredLanguages[0])
        
        // Make audio not interupt music playback.
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print("Error setting audio category:", error)
        }
        
        // Set default preferences.
        let defaults = UserDefaults.standard
        if defaults.value(forKey: "sounds_preference") == nil {
            defaults.set(true, forKey: "sounds_preference")
        }
        if defaults.value(forKey: "activity_indicators_preference") == nil {
            defaults.set(true, forKey: "activity_indicators_preference")
        }
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.nunocoelhosantos.Test" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Currency", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("CurrencyDatabase.sqlite")
        let prefs = UserDefaults.standard
        let userDatabaseVersion: Int
        let latestDatabaseVersion: Int = 19 // Match build number.
        let deleteExisting: Bool = FileManager.default.fileExists(atPath: url.path)
        
        if let version = prefs.string(forKey: "databaseVersion") {
            userDatabaseVersion = Int(version)!
        } else {
            userDatabaseVersion = 0
        }
        
        print("Device local database version:", userDatabaseVersion)
        print("Latest database version:", latestDatabaseVersion)
        print("Database URL: ", url)

        if userDatabaseVersion != latestDatabaseVersion {
            print("Device local database is out of date. Updating database files...")
            let sourceSqliteURLs = [Bundle.main.url(forResource: "InitialCurrencyDatabase", withExtension: "sqlite")!, Bundle.main.url(forResource: "InitialCurrencyDatabase", withExtension: "sqlite-wal")!, Bundle.main.url(forResource: "InitialCurrencyDatabase", withExtension: "sqlite-shm")!]
            let destSqliteURLs = [self.applicationDocumentsDirectory.appendingPathComponent("CurrencyDatabase.sqlite"), self.applicationDocumentsDirectory.appendingPathComponent("CurrencyDatabase.sqlite-wal"), self.applicationDocumentsDirectory.appendingPathComponent("CurrencyDatabase.sqlite-shm")]

            for index in 0..<sourceSqliteURLs.count {
                do {
                    if deleteExisting {
                        try FileManager.default.removeItem(at: destSqliteURLs[index])
                    }
                    try FileManager.default.copyItem(at: sourceSqliteURLs[index], to: destSqliteURLs[index])
                    print("Updated database file \(index) of \(sourceSqliteURLs.count)")
                } catch {
                    print(error)
                }
            }

            prefs.set(latestDatabaseVersion, forKey: "databaseVersion")
            print("Finished updating local database files.")
        }

        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

}
