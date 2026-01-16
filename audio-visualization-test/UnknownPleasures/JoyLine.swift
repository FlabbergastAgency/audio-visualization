import UIKit
import Charts

class JoyLine: UIView {
    var viewWidth: CGFloat = UIScreen.main.bounds.width
    var numberOfControlPoints: Int = 100
    
    var frequencyHeight: CGFloat = 0
    var frequencyPosition: CGFloat = 0
    
    var randomHeight: CGFloat = 5
    var peakHeight: CGFloat = 20
    
    var offset: CGFloat?
    
    var currentRms: CGFloat = 0
    
    var points: [CGPoint] = []
    var scales: [CGFloat] = []
    var addedScales: [CGFloat] = []
    
    var silentStrength: CGFloat = 0.15
    
    let shapeLayer = CAShapeLayer()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    init(offset: CGFloat) {
        self.offset = offset
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    fileprivate func setup() {
        
        for i in 0..<numberOfControlPoints {
            points.append(drawPoint(i))
            scales.append(silentStrength)
            addedScales.append(0.0)
            
            let silentLength = numberOfControlPoints / 4
            let kneeLength = numberOfControlPoints / 8
            
            if (i > silentLength + kneeLength && i < numberOfControlPoints - silentLength - kneeLength) {
                scales[i] = 1.0
            } else if (i > silentLength && i <= silentLength + kneeLength ) {
                let localIndex = i - silentLength
                let t = CGFloat(localIndex) / CGFloat(kneeLength)
                scales[i] = silentStrength + (1.0 - silentStrength) * smoothStep(t)
            } else if (i < numberOfControlPoints - silentLength && i >= numberOfControlPoints - silentLength - kneeLength) {
                let localIndex = (numberOfControlPoints - silentLength) - i
                let t = CGFloat(localIndex) / CGFloat(kneeLength)
                scales[i] = silentStrength + (1.0 - silentStrength) * smoothStep(t)
            }
        }
        
        updateJoyLine()
        
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.fillColor = UIColor.black.cgColor
        shapeLayer.lineWidth = 1.0
        shapeLayer.position = CGPoint(x: 0, y: 200)
        self.backgroundColor = .clear
        self.layer.addSublayer(shapeLayer)
    }
    
    func drawPoint(_ i: Int) -> CGPoint {
        let segmentLength = (viewWidth / CGFloat(numberOfControlPoints))
        let segment = segmentLength * CGFloat(i)
        
        return CGPoint(x: segment, y: offset!)
    }
    
    func rmsChanged(rms: CGFloat) {
        let rmsScaled = rms * 70
        addedScales[0] = rmsScaled * -scales[0]
        points[0].y = offset! + addedScales[0]
        updatePoints(rmsScaled: rmsScaled)
    }
    
    func updatePoints(rmsScaled: CGFloat) {
        for i in (1..<points.count).reversed() {
            if(points[i].y != points[i - 1].y) {
                addedScales[i] = rmsScaled * -scales[i]
                points[i].y = points[i - 1].y - addedScales[i - 1] + addedScales[i]
            }
        }
        
        updateJoyLine()
    }
    
    func updateJoyLine() {
        
        let path = CGMutablePath()
        
        path.move(to: points.first!)
        
        for point in points {
            path.addLine(to: point)
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        smoothTransition(to: path)
        CATransaction.commit()
    }
    
    func smoothTransition(to newPath: CGPath) {
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 0.2
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fromValue = shapeLayer.path
        animation.toValue = newPath
        
        shapeLayer.add(animation, forKey: "path")
        shapeLayer.path = newPath
    }
    
    func smoothStep(_ t: CGFloat) -> CGFloat {
        return t * t * (3 - 2 * t)
    }
}

#Preview{
    JoyLine()
}
