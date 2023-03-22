//
//  SettingsView.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 21/03/2023.
//

import SwiftUI

struct SettingsView: View {
    @Binding var pollingRate: String
    
    @State private var initialPollingRate: String = ""
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Polling Rate")) {
                    TextField("Enter polling rate", text: $pollingRate)
                        .keyboardType(.decimalPad)
                }
            }
            
            HStack {
                Spacer()
                
                Button(action: {
                    saveButtonTapped()
                }) {
                    Text("Save")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                
                Button(action: {
                    cancelButtonTapped()
                }) {
                    Text("Cancel")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                
                Spacer()
            }
            .padding(.bottom, keyboardHeight)
        }
        .onAppear {
            initialPollingRate = pollingRate
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { (notification) in
                let value = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
                let height = value.height
                keyboardHeight = height
            }
            
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { (notification) in
                keyboardHeight = 0
            }
        }
    }
    
    func saveButtonTapped() {
        // Dismiss the keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func cancelButtonTapped() {
        // Restore the initial polling rate
        pollingRate = initialPollingRate
        
        // Dismiss the keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

