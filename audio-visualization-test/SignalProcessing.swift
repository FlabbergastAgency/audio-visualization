import UIKit
import Accelerate

class SignalProcessing {
    static func rms(data: UnsafeMutablePointer<Float>, frameLength: UInt) -> Float {
        var val: Float = 0
        let sizeLimitLow: Float = 0.18
        let sizeLimitHigh: Float = 0.4
        vDSP_measqv(data, 1, &val, frameLength)
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
    
    static func interpolate(current: Float, previous: Float) -> [Float] {
        var vals = [Float](repeating: 0, count: 31)
        vals[30] = current
        vals[15] = (current + previous)/2
        vals[8] = (vals[15] + previous)/2
        vals[4] = (vals[8] + previous)/2
        vals[2] = (vals[4] + previous)/2
        vals[1] = (vals[2] + previous)/2
        vals[28] = (vals[15] + current)/2
        vals[14] = (vals[8] + vals[28])/2
        vals[7] = (vals[4] + vals[14])/2
        vals[23] = (vals[14] + vals[28])/2
        vals[11] = (vals[8] + vals[14])/2
        vals[5] = (vals[2] + vals[8])/2
        vals[3] = (vals[1] + vals[5])
        vals[29] = (vals[28] + current)/2
        vals[26] = (vals[23] + vals[29])/2
        vals[22] = (vals[14] + current)/2
        vals[20] = (vals[29] + vals[11])/2
        vals[18] = (vals[14] + vals[22])/2
        vals[16] = (vals[14] + vals[18])/2
        vals[13] = (vals[11] + vals[15])/2
        vals[12] = (vals[8] + vals[16])/2
        vals[10] = (vals[7] + vals[13])/2
        vals[9] = (vals[5] + vals[13])/2
        vals[6] = (vals[3] + vals[9])/2
        vals[24] = (vals[22] + vals[26])/2
        vals[27] = (vals[24] + current)/2
        vals[26] = (vals[29] + vals[24])/2
        vals[21] = (vals[24] + vals[18])/2
        vals[17] = (vals[20] + vals[14])/2
        vals[19] = (vals[17] + vals[21])/2
        vals[0] = (previous + vals[1])/2

        return vals
    }
    
    static func fft(data: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float] {
        var realIn = [Float](repeating: 0, count: 1024)
        var imagIn = [Float](repeating: 0, count: 1024)
        var realOut = [Float](repeating: 0, count: 1024)
        var imagOut = [Float](repeating: 0, count: 1024)
        
        for i in 0...1023 {
            realIn[i] = data[i]
        }
        
        vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)
        
        var complex = DSPSplitComplex(realp: &realOut, imagp: &imagOut)
        
        var magnitudes = [Float](repeating: 0, count: 512)
        
        vDSP_zvabs(&complex, 1, &magnitudes, 1, 512)
        
        var normalizedMagnitudes = [Float](repeating: 0.0, count: 512)
        var scalingFactor = Float(18.0/512)
        vDSP_vsmul(&magnitudes, 1, &scalingFactor, &normalizedMagnitudes, 1, 512)
        
        return normalizedMagnitudes
    }
}
