import SwiftUI

struct ErrorText: View {
  let error: Error

  init(_ error: Error) {
    self.error = error
  }

  var body: some View {
    Text(String(describing: error))
      .foregroundColor(.red)
      .font(.footnote)
  }
}

#Preview {
  ErrorText(NSError())
}
