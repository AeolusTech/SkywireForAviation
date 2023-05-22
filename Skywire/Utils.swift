//
//  Utils.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 14/05/2023.
//

import Foundation
import SwiftUI


class AlertUtility {
    static func showDisappearingAlert(title: String, message: String) {
        DispatchQueue.main.async {
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            if let firstScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                if let rootViewController = firstScene.windows.first?.rootViewController {
                    rootViewController.present(alert, animated: true, completion: {
                        let timeToRead25Chars = 1.0
                        let howManySecondsToDisplay = Double(message.count / 25)  * timeToRead25Chars
                        DispatchQueue.main.asyncAfter(deadline: .now() + howManySecondsToDisplay	) {
                            alert.dismiss(animated: true, completion: nil)
                        }
                    })
                }
            }
        }
    }
}
