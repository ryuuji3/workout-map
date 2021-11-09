//
//  LoadingLabel.swift
//  workout-map
//
//  Created by Josh Lalonde on 2021-10-30.
//

import SwiftUI

struct LabeledCalculation<Label: View, Result: View>: View {
    var isLoading = false
    
    @ViewBuilder var label: Label
    @ViewBuilder var result: Result
    
    var body: some View {
        HStack {
            label
                .padding(.trailing, 10)
            
            if isLoading {
                ProgressView().progressViewStyle(.circular)
            } else {
                result
            }
        }.padding()
    }
}

struct LoadingLabel_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            LabeledCalculation(
                isLoading: true,
                label: {
                    Text("Label:")
                },
                result: {
                    Text("Result")
                }
            )
            
            LabeledCalculation(
                isLoading: false,
                label: {
                    Text("Label:")
                },
                result: {
                    Text("Result")
                }
            )
        }
    }
}
