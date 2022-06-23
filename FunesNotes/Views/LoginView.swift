import SwiftUI

struct LoginView: View {
    @StateObject var viewModel = LoginViewModel()
    let appViewModel: AppViewModel
    @FocusState private var focusedField: LoginViewModel.Field?
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
    }
    
    fileprivate func validateAndConnect() {
        if self.viewModel.validateFields() {
            appViewModel.setupGraphStoreRequested(url: viewModel.urlAsURL,
                                                  key: viewModel.keyAsPatP)
        }
    }
    
    var body: some View {
        VStack {
            WelcomeText()
            
            TildeImage()
            
            DescriptionText()
            
            TextField("URL of Your Ship", text: $viewModel.url)
                .focused($focusedField, equals: .url)
                .submitLabel(.next)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .keyboardType(.URL)
                .padding()
                .background(Color("lightGrey"))
                .cornerRadius(5.0)
            
            ZStack {
                if viewModel.isPasswordSecure {
                    SecureField("Access Key", text: $viewModel.key)
                        .focused($focusedField, equals: .key)
                        .submitLabel(.done)
                        .onSubmit(validateAndConnect)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color("lightGrey"))
                        .cornerRadius(5.0)
                } else {
                    TextField("Access Key", text: $viewModel.key)
                        .focused($focusedField, equals: .key)
                        .submitLabel(.done)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .onSubmit(validateAndConnect)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color("lightGrey"))
                        .cornerRadius(5.0)                    
                }
                HStack {
                    Spacer()
                    Button {
                        viewModel.isPasswordSecure.toggle()
                    } label: {
                        Image(systemName: "eye")
                    }
                    .foregroundColor(viewModel.isPasswordSecure ?
                        .secondary :
                            .primary)
                }
                .padding(.trailing, 10)
            }
            .padding(.bottom, 20)
            
            
            Button(action: {
                validateAndConnect()
            }) {
                ConnectButtonContent()
            }
            .buttonStyle(.plain)
            
        }
        .padding()
        .onChange(of: self.viewModel.focusedField) { newValue in
            self.focusedField = newValue
        }
        .onChange(of: self.focusedField) { newValue in
            self.viewModel.focusedField = newValue
        }
        .alert(isPresented: self.$viewModel.showConnectError,
               error: self.viewModel.connectError,
               actions: {})
    }
}

struct LoginView_Previews: PreviewProvider {
    static let appViewModel = AppViewModel(fileConnector: FileConnector(),
                                           shipSession: PreviewShipSession())
    static var previews: some View {
        Group {
            LoginView(appViewModel: appViewModel)
            
            LoginView(appViewModel: appViewModel)
                .preferredColorScheme(.dark)
        }
    }
}

struct WelcomeText: View {
    var body: some View {
        Text("Funes Notes")
            .font(.largeTitle)
            .fontWeight(.semibold)
            .padding(.bottom, 20)
    }
}

struct TildeImage: View {
    var body: some View {
        Image("tilde")
            .resizable()
            .scaledToFit()
            .frame(width: 150, height: 50)
            .padding(.bottom, 50)
    }
}

struct ConnectButtonContent: View {
    var body: some View {
        Text("CONNECT")
            .font(.headline)
            .foregroundColor(Color(uiColor: .systemBackground))
            .padding()
            .frame(width:220, height: 60)
            .background(.primary)
            .cornerRadius(15)
    }
}

struct DescriptionText: View {
    var body: some View {
        Text("Funes Notes stores your notes on your Urbit ship.  Please enter the URL that you use to connect, and your access key.\n\nIf you aren't on Urbit, [tap here to find out how to get started](https://urbit.org/getting-started).")
            .multilineTextAlignment(.leading)
            .font(.caption)
            .padding(.horizontal)
            .padding(.bottom, 20)
    }
}
