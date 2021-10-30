//
//  LoadingLabel.swift
//  workout-map
//
//  Created by Josh Lalonde on 2021-10-30.
//

import SwiftUI

struct LoadingView<Content: View>: View {
    var isLoading = false
    @ViewBuilder var content: Content
    
    var body: some View {
        if isLoading {
            ProgressView().progressViewStyle(.circular)
        } else {
            content
        }
    }
}

struct LoadingLabel_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            LoadingView(isLoading: true) {
                Text("Example")
            }
            LoadingView(isLoading: false) {
                Text("Example")
            }
        }
    }
}
