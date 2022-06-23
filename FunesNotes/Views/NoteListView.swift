import SwiftUI
import UrsusHTTP

struct NoteListView: View {
    @ObservedObject var viewModel: NoteListViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(isActive: $viewModel.showEditNoteView,
                               destination: {
                    NoteEditView(viewModel: viewModel.editViewModel)
                }, label: { EmptyView() })
                
                List {
                    ForEach($viewModel.noteMetas) { $noteMeta in
                        NoteListRowButton(noteMeta: noteMeta,
                                          listViewModel: viewModel)
                    }
                }
                .alert("Are you sure you want to delete this?",
                       isPresented: $viewModel.showDeleteConfirmation,
                       actions: {
                    Button("Yes", role: .destructive) {
                        viewModel.delete()
                    }
                })
                .alert("Would you like to logout?",
                       isPresented: $viewModel.showLogoutConfirmation,
                       actions: {
                    Button("Yes", role: .destructive) {
                        Task {
                            await self.viewModel.logout()
                        }
                    }
                })
                
                NoteListViewFooter(viewModel: viewModel)
                
            }
            .navigationTitle(viewModel.navigationTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.viewModel.sigilTapped()
                    }) {
                        SigilImage(url: self.viewModel.sigilURL)
                    }
                }
            }
            .onAppear {
                viewModel.loadLastSelectedNote()
            }
            .task {
                await viewModel.loadNoteMetas()
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct NoteListView_Previews: PreviewProvider {
    static var previews: some View {
        NoteListView(viewModel: NoteListViewModel.makePreviewVM())
    }
}
