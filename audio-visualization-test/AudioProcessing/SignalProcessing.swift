import UIKit
import Accelerate

class SignalProcessing {
    static func rms(data: [Float], frameLength: UInt) -> Float {
        var val: Float = 0
        let sizeLimitLow: Float = 0.15
        let sizeLimitHigh: Float = 0.3
        vDSP_measqv(data, 1, &val, min(vDSP_Length(data.count), frameLength))
        var db = 10*log10f(val)
        db = 160 + db;
        db = db - 120
        let divider = Float(40/sizeLimitLow)
        var adjustedVal = sizeLimitLow + db/divider

        if (adjustedVal < sizeLimitLow) {
            adjustedVal = sizeLimitLow
        } else if (adjustedVal > sizeLimitHigh) {
            adjustedVal = sizeLimitHigh
        }

        return adjustedVal
    }
    
    static func fft(data: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float] {
        var realIn = [Float](repeating: 0, count: 2048)
        var imagIn = [Float](repeating: 0, count: 2048)
        var realOut = [Float](repeating: 0, count: 2048)
        var imagOut = [Float](repeating: 0, count: 2048)
        
        for i in 0...2047 {
            realIn[i] = data[i]
        }
        
        vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)
        
        var complex = DSPSplitComplex(realp: &realOut, imagp: &imagOut)
        
        var magnitudes = [Float](repeating: 0, count: 1024)
        
        vDSP_zvabs(&complex, 1, &magnitudes, 1, 1024)
        
        var normalizedMagnitudes = [Float](repeating: 0.0, count: 1024)
        var scalingFactor = Float(18.0/1024)
        vDSP_vsmul(&magnitudes, 1, &scalingFactor, &normalizedMagnitudes, 1, 1024)
        
        return normalizedMagnitudes
    }
}
