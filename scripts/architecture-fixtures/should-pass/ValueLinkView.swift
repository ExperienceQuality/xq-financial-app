import SwiftUI

/// Positive control: NavigationLink(value:) is allowed (D6).
struct ValueLinkView: View {
    var body: some View {
        NavigationLink(value: "detail") {
            Text("Open")
        }
    }
}
