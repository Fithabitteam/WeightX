import FirebaseFirestore
import FirebaseAuth

class TagManager: ObservableObject {
    static let shared = TagManager()
    @Published var userTags: [String] = []
    private let maxTags = 15
    
    private init() {
        loadUserTags()
    }
    
    func loadUserTags() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let tags = data["customTags"] as? [String] else { return }
            
            DispatchQueue.main.async {
                self.userTags = tags
            }
        }
    }
    
    func addTag(_ tag: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let trimmedTag = tag.trimmingCharacters(in: .whitespaces)
        
        // Validate tag
        guard !trimmedTag.isEmpty,
              !userTags.contains(trimmedTag),
              userTags.count < maxTags else { return }
        
        // Update local state
        userTags.append(trimmedTag)
        
        // Update Firestore
        let db = Firestore.firestore()
        try await db.collection("users").document(userId).updateData([
            "customTags": FieldValue.arrayUnion([trimmedTag])
        ])
    }
} 
