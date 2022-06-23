import SwiftUI

struct IconButton: View {
    let iconName: String
    let role: ButtonRole?
    let action: () -> Void
    
    init(_ iconName: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.iconName = iconName
        self.role = role
        self.action = action
    }
    
    var body: some View {
        Button(role: role, action: action) {
            Image(systemName: iconName)
                .font(Font.system(.title))
                .foregroundColor(.primary)
        }
    }
}

struct IconButton_Previews: PreviewProvider {
    static var previews: some View {
        IconButton("trash") {}
        .previewLayout(.fixed(width: 50, height: 50))

    }
}
