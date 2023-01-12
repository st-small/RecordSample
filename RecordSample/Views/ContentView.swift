//
//  ContentView.swift
//  RecordSample
//
//  Created by Stanly Shiyanovskiy on 28.12.2022.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                NavigationLink {
                    ConversationScreenConnector()
                        .environmentObject(store)
                } label: {
                    Text("Open conversation screen")
                        .foregroundColor(.primary)
                }

            }
            .padding()
            .frame(height: 150)
            .navigationTitle("Main screen")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
