import SwiftUI
import UniformTypeIdentifiers
import FirebaseFirestore
import FirebaseAuth
import CoreXLSX

// First, let's define a custom UTType for xlsx files
extension UTType {
    static var xlsx: UTType {
        UTType(tag: "xlsx",
               tagClass: .filenameExtension,
               conformingTo: nil) ?? UTType(importedAs: "com.microsoft.excel.xlsx")
    }
}

struct ImportView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingFilePicker = false
    @State private var isImporting = false
    @State private var importError: String?
    @State private var showError = false
    @State private var importedCount = 0
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: ExcelImportView()) {
                        HStack {
                            Image(systemName: "tablecells")
                                .foregroundColor(.green)
                            Text("Custom Excel")
                        }
                    }
                } header: {
                    Text("Import Options")
                }
                
                // Add more import options here in future
            }
            .navigationTitle("Import Data")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ExcelImportView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingFilePicker = false
    @State private var isImporting = false
    @State private var importError: String?
    @State private var showError = false
    @State private var importedCount = 0
    @State private var showingSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Import from Excel")
                    .font(.title)
                    .padding(.top)
                
                Text("File Format Requirements:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("1. Excel file (.xlsx)")
                        .font(.subheadline)
                    Text("2. Two columns only:")
                        .font(.subheadline)
                    Text("   • Column A: Weight (e.g., 70.5)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("   • Column B: Date (e.g., 2024-01-30)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("3. First row should be headers")
                        .font(.subheadline)
                }
                
                Text("Date Format Instructions:")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Select date column")
                    Text("2. Right-click > Format Cells")
                    Text("3. Choose 'Date' category")
                    Text("4. Select 'yyyy-mm-dd' format")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                Button(action: {
                    showingFilePicker = true
                }) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Import Excel File")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.top, 20)
                
                if isImporting {
                    ProgressView("Importing data...")
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Excel Import")
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.xlsx],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Error", isPresented: $showError, presenting: importError) { _ in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error)
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Successfully imported \(importedCount) weight entries")
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        do {
            guard let selectedFile = try result.get().first else { return }
            
            guard selectedFile.startAccessingSecurityScopedResource() else {
                throw ImportError.accessDenied
            }
            defer { selectedFile.stopAccessingSecurityScopedResource() }
            
            isImporting = true
            try importExcelFile(from: selectedFile)
            
        } catch {
            importError = error.localizedDescription
            showError = true
        }
    }
    
    private func parseDate(_ dateStr: String) -> Date? {
        // First try parsing as formatted date
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        // For format like '28/07/2023 6:33:14 AM'
        formatter.dateFormat = "dd/MM/yyyy h:mm:ss a"
        
        if let date = formatter.date(from: dateStr) {
            print("Successfully parsed formatted date: \(dateStr) to \(date)")
            return date
        }
        
        // If formatted date parsing fails, try Excel numeric date
        if let excelDate = Double(dateStr) {
            // Excel dates start from January 0, 1900 and have a bug treating 1900 as leap year
            // We need to adjust for these Excel quirks
            let adjustedExcelDate = excelDate - 2  // Subtract 2 days to account for Excel's quirks
            
            // Convert to Unix timestamp
            let secondsSinceUnixEpoch = (adjustedExcelDate - 25569) * 86400  // 25569 is days between 1/1/1900 and 1/1/1970
            let date = Date(timeIntervalSince1970: secondsSinceUnixEpoch)
            
            print("Converting Excel date:")
            print("Original Excel date: \(excelDate)")
            print("Adjusted Excel date: \(adjustedExcelDate)")
            print("Converted to: \(date)")
            
            return date
        }
        
        print("Failed to parse date: \(dateStr)")
        return nil
    }
    
    private func importExcelFile(from file: URL) throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw ImportError.notAuthenticated
        }
        
        print("Starting Excel import process...")
        
        let bufferSize = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard let xlsxFile = try XLSXFile(filepath: file.path, bufferSize: UInt32(bufferSize)) else {
            throw ImportError.invalidFormat
        }
        
        guard let worksheetPath = try xlsxFile.parseWorksheetPaths().first else {
            throw ImportError.noWorksheet
        }
        
        let worksheet = try xlsxFile.parseWorksheet(at: worksheetPath)
        
        let db = Firestore.firestore()
        var importCount = 0
        var errorCount = 0
        
        // Skip header row
        var isFirstRow = true
        
        if let rows = worksheet.data?.rows {
            for rowReference in rows {
                if isFirstRow {
                    isFirstRow = false
                    print("Skipping header row")
                    continue
                }
                
                let rowCells = rowReference.cells
                
                // Get weight from first column
                guard let weightStr = rowCells[0].value,
                      let weight = Double(weightStr) else {
                    print("Invalid weight format: \(rowCells[0].value ?? "nil")")
                    errorCount += 1
                    continue
                }
                
                // Get date from second column
                guard let dateStr = rowCells[1].value else {
                    print("No date value found")
                    errorCount += 1
                    continue
                }
                
                print("Processing row - Weight: \(weight), Date string: \(dateStr)")
                guard let date = parseDate(dateStr) else {
                    print("Failed to parse date string: \(dateStr)")
                    errorCount += 1
                    continue
                }
                
                // Create weight entry
                let data: [String: Any] = [
                    "userId": userId,
                    "weight": weight,
                    "date": Timestamp(date: date),
                    "createdAt": Timestamp()
                ]
                
                // Add to Firestore
                do {
                    try db.collection("weights").addDocument(data: data)
                    importCount += 1
                    print("Successfully imported: Weight=\(weight), Date=\(date)")
                } catch {
                    print("Error adding entry: \(error.localizedDescription)")
                    errorCount += 1
                }
            }
        }
        
        print("Import completed - Successful: \(importCount), Errors: \(errorCount)")
        
        DispatchQueue.main.async {
            self.importedCount = importCount
            self.isImporting = false
            
            if importCount > 0 {
                self.showingSuccess = true
            } else {
                self.importError = "No valid entries found. Please check the file format."
                self.showError = true
            }
        }
    }
}

enum ImportError: LocalizedError {
    case accessDenied
    case notAuthenticated
    case noWorksheet
    case invalidFormat
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Cannot access the selected file"
        case .notAuthenticated:
            return "Please sign in to import data"
        case .noWorksheet:
            return "Invalid Excel file format"
        case .invalidFormat:
            return "Invalid data format in Excel file"
        }
    }
} 