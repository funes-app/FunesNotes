import SwiftUI

struct SigilImage: View {
    let url: URL
    var body: some View {
            AsyncImage(url: url,
                       content: { image in
                image.resizable()
            }, placeholder: {
                Color.black
            })
            .scaledToFit()
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
}

struct SigilImage_Previews: PreviewProvider {
    static var previews: some View {
        SigilImage(url: URL(string: "https://api.urbit.live/images/~sampel-palnet_black.png")!)
            .previewLayout(.sizeThatFits)
    }
}
