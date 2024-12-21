import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct TagGridView: View {
    let tags: [String]
    let selectedTags: Set<String>
    let onTagTap: (String) -> Void
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                TagView(
                    tag: tag,
                    isSelected: selectedTags.contains(tag)
                ) {
                    onTagTap(tag)
                }
            }
        }
        .padding(.vertical, 4)
    }
} 
