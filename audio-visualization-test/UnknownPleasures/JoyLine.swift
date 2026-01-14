import UIKit

class JoyLine: UIView {
    var viewWidth: CGFloat = UIScreen.main.bounds.width
    
    var frequencyHeight: CGFloat = 0
    var frequencyPosition: CGFloat = 0
    
    var silentHeight: CGFloat = 0.05
    var silentLength: CGFloat = UIScreen.main.bounds.width / 4
    
    var numberOfControlPoints: Int = 100
    
    var offset: CGFloat!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        offset = 0.0
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setOffset(_ offset: CGFloat) {
        self.offset = offset
    }
    
    fileprivate func setup() {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = createJoyLine().cgPath
        
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.fillColor = UIColor.black.cgColor
        shapeLayer.lineWidth = 1.0
        shapeLayer.position = CGPoint(x: 0, y: 100)
        
        self.layer.addSublayer(shapeLayer)
    }
    
    func createJoyLine() -> UIBezierPath {
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: offset))
        
        for i in 0..<numberOfControlPoints {
            let segmentLength = (viewWidth / CGFloat(numberOfControlPoints))
            let segment = segmentLength * CGFloat(i)
            path.addQuadCurve(to: CGPoint(x: segment, y: offset), controlPoint: CGPoint(x: segment - segmentLength / 2, y: offset + CGFloat.random(in: -5...5)))
        }
        
        return path
    }
}
