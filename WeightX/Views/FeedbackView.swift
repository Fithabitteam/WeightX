import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FeedbackView: View {
    @Environment(\.dismiss) var dismiss
    @State private var overallExperience = ""
    @State private var improvementFeedback = ""
    @State private var otherFeedback = ""
    @State private var preferredTime = ""
    @State private var isSubmitting = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    
    let experienceOptions = [
        "Excellent",
        "Good",
        "Satisfactory",
        "Needs Improvement",
        "Unsatisfactory"
    ]
    
    let timeSlotOptions = [
        "Anytime is fine for me",
        "Morning(9am - 12pm )",
        "Afternoon(12pm - 4pm)",
        "Evening(4pm - 8pm)"
    ]
    
    var isFormValid: Bool {
        !overallExperience.isEmpty && !preferredTime.isEmpty
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("How is your overall experience?")
                        Text("*")
                            .foregroundColor(.red)
                    }
                    
                    Picker("Select experience", selection: $overallExperience) {
                        Text("Please select...").tag("")
                        ForEach(experienceOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How can we improve your experience?")
                    TextEditor(text: $improvementFeedback)
                        .frame(height: 100)
                        .overlay(
                            Text(improvementFeedback.isEmpty ? "Enter your feedback" : "")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8),
                            alignment: .topLeading
                        )
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Any other feedback?")
                    TextEditor(text: $otherFeedback)
                        .frame(height: 100)
                        .overlay(
                            Text(otherFeedback.isEmpty ? "Enter your feedback" : "")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8),
                            alignment: .topLeading
                        )
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("In case required, what is a convenient time for our customer care executive to get in touch with you?")
                        Text("*")
                            .foregroundColor(.red)
                    }
                    
                    Picker("Select time slot", selection: $preferredTime) {
                        Text("Please select...").tag("")
                        ForEach(timeSlotOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }
            }
            
            Section {
                Button(action: submitFeedback) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Submit")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.blue : Color.gray)
                .cornerRadius(10)
                .disabled(!isFormValid || isSubmitting)
            }
        }
        .navigationTitle("Feedback")
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Thank you for your feedback!")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Failed to submit feedback. Please try again.")
        }
    }
    
    private func submitFeedback() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isSubmitting = true
        
        let feedback: [String: Any] = [
            "userId": userId,
            "overallExperience": overallExperience,
            "improvementFeedback": improvementFeedback,
            "otherFeedback": otherFeedback,
            "preferredTime": preferredTime,
            "submittedAt": Timestamp(date: Date()),
            "userEmail": Auth.auth().currentUser?.email ?? "No email"
        ]
        
        let db = Firestore.firestore()
        db.collection("feedback").addDocument(data: feedback) { error in
            isSubmitting = false
            if let error = error {
                print("Error submitting feedback: \(error)")
                showingErrorAlert = true
            } else {
                showingSuccessAlert = true
            }
        }
    }
} 