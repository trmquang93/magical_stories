//
//  AppDelegate.swift
//  magical-stories
//
//  Created by Quang Tran Minh on 5/7/25.
//

import UIKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}
