import SwiftUI

/// Positive control: nested NavigationStack as editor/sheet toolbar chrome is allowed.
struct EditorChromeView: View {
    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: .constant(""))
            }
            .navigationTitle("Editor")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {}
                }
            }
        }
    }
}

#Preview {
    // Ignored by the architecture scanner.
    EditorChromeView()
        .navigationDestination(for: String.self) { _ in Text("preview-only") }
}
