//
//  Legend.swift
//  workout-map
//
//  Created by Josh Lalonde on 2021-11-09.
//

import SwiftUI

struct Legend<Content: View>: View {
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                VStack(alignment: .leading) {
                    content
                        .padding()
                        .frame(
                            maxWidth: .infinity,
                            alignment: .bottom
                        )
                }
                .foregroundColor(.white)
                .background(
                    Color
                        .black
                        .opacity(0.5)
                        .edgesIgnoringSafeArea(.bottom)
                )
            }
        }
    }
}

struct Legend_Previews: PreviewProvider {
    static var previews: some View {
        Legend {
            Text("This is a legend")
        }
    }
}
