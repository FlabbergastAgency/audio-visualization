import UIKit

class UnknownPleasuresViewController: UIViewController {
    
    var numberOfLines: Int = 80
    var offsetSize: CGFloat = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //for i in 0..<numberOfLines {
            let unknownPleasures = JoyLine()
            //unknownPleasures.setOffset(CGFloat(i) * offsetSize)
            unknownPleasures.frame = view.bounds
            unknownPleasures.backgroundColor = .black
            
            view.addSubview(unknownPleasures)
        //}
    }
}

#Preview {
    UnknownPleasuresViewController()
}
