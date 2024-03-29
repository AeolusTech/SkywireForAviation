//
//  RecordedFilesView.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 21/03/2023.
//

import SwiftUI

struct RecordedFilesView: View {
    @State private var recordedFiles: [URL] = []
    @State private var sortOldestFirst: Bool = false
    @State private var isSharingFile: Bool = false
    @State private var fileToShare: URL?
    @State private var isShowingAltitudeGraph: Bool = false
    @State private var selectedFile: URL?
    
    private func shareFile(fileURL: URL) {
        if let tempFileURL = createTemporaryFileCopy(fileURL: fileURL) {
            fileToShare = tempFileURL
            isSharingFile = true
        }
    }
    
    private func sharingFileActivityView() -> some View {
        VStack {
            if let fileURL = fileToShare {
                ActivityView(activityItems: [fileURL])
            }
        }
    }
    
    private func createTemporaryFileCopy(fileURL: URL) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent(fileURL.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: tempFileURL.path) {
                try FileManager.default.removeItem(at: tempFileURL)
            }
            
            try FileManager.default.copyItem(at: fileURL, to: tempFileURL)
            return tempFileURL
        } catch {
            print("Failed to create temporary file: \(error)")
        }
        
        return nil
    }
    
    
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
    
    private func deleteRecordedFile(at offsets: IndexSet) {
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
    
    var body: some View {
        NavigationView {
            List {
                ForEach(recordedFiles, id: \.self) { file in
                    Button(action: {
                        print("tapped on \(file)")
                        if file.pathExtension == "csv" {
                            
                            let altitudeGraphView = AltitudeGraphView(fileURL: file)
                            let navView = UINavigationController(rootViewController: UIHostingController(rootView: altitudeGraphView))
                            if let firstScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                if let rootViewController = firstScene.windows.first?.rootViewController {
                                    rootViewController.present(navView, animated: true, completion: nil)
                                }
                            }
                        } else {
                            print("Bad extension. Should be .csv but got \(file.pathExtension)")
                        }
                    }, label: {
                        Text(file.lastPathComponent)
                    })
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            shareFile(fileURL: file)
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
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
        .sheet(isPresented: $isSharingFile) {
            sharingFileActivityView()
        }
    }
}


struct RecordedFilesView_Previews: PreviewProvider {
    static var previews: some View {
        RecordedFilesView()
    }
}
