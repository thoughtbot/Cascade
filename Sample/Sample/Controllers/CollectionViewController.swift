import UIKit
import Cascade

class CollectionViewController: UICollectionViewController, CascadeLayoutDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = collectionView?.collectionViewLayout as? CascadeLayout
        layout?.delegate = self
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 50
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("default", forIndexPath: indexPath) as UICollectionViewCell
        cell.backgroundColor = UIColor(red: random(255)/255, green: random(255)/255, blue: random(255)/255, alpha: 1)
        return cell;
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: CascadeLayout, numberOfColumnsInSectionAtIndexPath indexPath: NSIndexPath) -> Int {
        return 2
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: random(50, minimum: 40), height: random(50, minimum: 40))
    }
}

func random(maximum: UInt32, minimum: CGFloat = 0) -> CGFloat {
    return max(CGFloat(arc4random_uniform(maximum)), minimum)
}
