import Foundation

#if !os(macOS)
  public enum vDSP {
    public enum FourierTransformDirection: Sendable {
      case forward
      case inverse
    }

    public enum DFTTransformType: Sendable {
      case complexComplex
      case complexReal
    }

    public final class DiscreteFourierTransform<T: FloatingPoint>: @unchecked Sendable {
      public let count: Int
      public init(
        previous: DiscreteFourierTransform<T>? = nil,
        count: Int,
        direction: FourierTransformDirection,
        transformType: DFTTransformType,
        ofType: T.Type
      ) throws {
        self.count = count
      }

      public func transform(
        inputReal: [T],
        inputImaginary: [T],
        outputReal: inout [T],
        outputImaginary: inout [T]
      ) {
        let n = min(count, outputReal.count, outputImaginary.count)
        for i in 0..<n {
          outputReal[i] = 0
          outputImaginary[i] = 0
        }
      }
    }

    public static func rootMeanSquare(_ vector: [Float]) -> Float {
      guard !vector.isEmpty else { return 0 }
      var sum: Float = 0
      for v in vector { sum += v * v }
      return (sum / Float(vector.count)).squareRoot()
    }
  }
#endif
