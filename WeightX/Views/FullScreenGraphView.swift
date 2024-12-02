import SwiftUI
import Charts

struct FullScreenGraphView<Content: View>: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                content
                    .frame(width: geometry.size.height * 0.9, height: geometry.size.width * 0.8)
                    .rotationEffect(.degrees(-90))
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Extension for chart interaction
extension View {
    func chartInteraction(isFullScreen: Bool = false, 
                         plotted points: [Date],
                         onValueChanged: @escaping (Date, Double) -> Void) -> some View {
        self.chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        isFullScreen ? DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let currentX = value.location.x - geometry.frame(in: .local).origin.x
                                guard currentX >= 0, currentX < geometry.size.width else { return }
                                
                                // Convert screen coordinate to chart coordinate
                                let xScale = geometry.size.width / CGFloat(points.count - 1)
                                let index = Int((currentX / xScale).rounded())
                                
                                guard index >= 0 && index < points.count else { return }
                                
                                let date = points[index]
                                if let yValue = proxy.value(atY: value.location.y) as Double? {
                                    onValueChanged(date, yValue)
                                }
                            }
                            .onEnded { _ in
                                onValueChanged(Date(), 0) // Clear selection
                            } : nil
                    )
            }
        }
    }
} 