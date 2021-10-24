import SwiftUI
import Combine

struct LoadingSpinner: View {
    var progress: Double
    
    var body: some View {
        ProgressView(
            value: progress
        )
            .progressViewStyle(SpinnerStyle())
            .padding()
    }
}

struct SpinnerStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        let completion: Double = configuration.fractionCompleted ?? 0
        let progressColor: Color = completion < 1 ? .yellow : .green
        let textColor: Color = completion < 1 ? .orange : .green
        
        ZStack {
            Circle()
                .stroke(.gray, style: StrokeStyle(lineWidth: 5))
                .background(Circle().fill(.white).opacity(0.8))
                .padding()
                .frame(width: 200)
            
            Circle()
                .trim(from: 0, to: completion)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 5))
                .rotationEffect(.degrees(-90))
                .padding()
                .frame(width: 200)
            
            Text(
                completion < 1
                    ? "Loading: \(Int(completion * 100))%"
                    : "Done!"
            ).foregroundColor(textColor)
        }
    }
}

struct WorkoutSpinner_Previews: PreviewProvider {
    static var previews: some View {
        LoadingSpinner(progress: 0.3)
    }
}
