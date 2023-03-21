//
//  RecordedFilesview.swift
//  GpsPolling
//
//  Created by Kamil Kuczaj on 21/03/2023.
//

import SwiftUI

struct RecordedFilesView: View {
    @State private var recordedFiles: [URL] = []
    @State private var sortOldestFirst: Bool = false

    private func loadRecordedFiles() {
        let fileManager = FileManager.default
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
                recordedFiles = fileURLs.filter { $0.pathExtension == "csv" }
                
                recordedFiles.sort(by: {
                    let date1 = try? $0.resourceValues(forKeys: Set([.contentModificationDateKey])).contentModificationDate
                    let date2 = try? $1.resourceValues(forKeys: Set([.contentModificationDateKey])).contentModificationDate
                    
                    return sortOldestFirst ? date1 ?? Date() < date2 ?? Date() : date1 ?? Date() > date2 ?? Date()
                })
                
            } catch {
                print("Error loading recorded files: \(error)")
            }
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(recordedFiles, id: \.self) { file in
                    Text(file.lastPathComponent)
                }
                .onDelete(perform: deleteRecordedFile)
            }
            .navigationBarTitle("Recorded Files", displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                sortOldestFirst.toggle()
                loadRecordedFiles()
            }) {
                Text(sortOldestFirst ? "Sort by Newest" : "Sort by Oldest")
            }, trailing: EditButton())
            .onAppear(perform: loadRecordedFiles)
        }
    }
    
    func deleteRecordedFile(at offsets: IndexSet) {
        for index in offsets {
            let fileURL = recordedFiles[index]
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(at: fileURL)
                recordedFiles.remove(at: index)
            } catch {
                print("Error deleting recorded file: \(error)")
            }
        }
    }
}

struct RecordedFilesView_Previews: PreviewProvider {
    static var previews: some View {
        RecordedFilesView()
    }
}
