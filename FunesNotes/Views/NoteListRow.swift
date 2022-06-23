import SwiftUI

struct NoteListRow: View {
    let noteMeta: NoteMeta
    
    let viewModel = NoteListRowViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(viewModel.title(noteMeta: noteMeta))
                .fontWeight(.bold)
                .lineLimit(1)
                .font(.headline)
            HStack {
                Text(viewModel.lastModifiedDescription(noteMeta: noteMeta))
                    .italic()
                Text(viewModel.subtitle(noteMeta: noteMeta))
                    .lineLimit(1)
            }
        }
    }
}

struct NoteListRow_Previews: PreviewProvider {
    static var noteMeta: NoteMeta {
        NoteMeta(NoteContents(text: "This is my rifle\nThere are many like it but this one is mine"),
                 contentsLastModified: Date.now,
                 metadataLastModified: Date.now)
    }
    static var previews: some View {
        NoteListRow(noteMeta: noteMeta)
            .previewLayout(.fixed(width: 300, height: 70))
    }
}
