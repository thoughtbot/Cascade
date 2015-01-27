import UIKit.UICollectionViewFlowLayout
import Runes

public class CascadeLayout: UICollectionViewFlowLayout {
    public var delegate: CascadeLayoutDelegate?

    let defaultColumnCount = 1
    let defaultItemSize = CGSize(width: 600, height: 800)

    var sections = [Section]()

    override public func collectionViewContentSize() -> CGSize {
        let size = makeSize
            <^> collectionView?.frame.width
            <*> tallestSection(sections)?.bottomEdge

        return size ?? CGSizeZero
    }

    override public func prepareLayout() {
        let numberOfSections = collectionView?.numberOfSections() ?? 0

        sections = reduce(0..<numberOfSections, []) { sections, index in
            let numberOfItems = self.collectionView?.numberOfItemsInSection(index) ?? 0
            let columns = self.columnsForSectionAtIndex(index, numberOfItems: numberOfItems, previousSection: sections.last)
            let section = Section(numberOfItems: numberOfItems, columns: columns)
            return sections + [section]
        }
    }

    func columnsForSectionAtIndex(index: Int, numberOfItems: Int, previousSection: Section?) -> [Column] {
        let previousBottomEdge = previousSection?.bottomEdge ?? 0
        let numberOfColumns = columnCountForSectionAtIndex(index)
        let containerWidth = collectionView?.frame.width ?? 0

        let columns: [Column] = map(0..<numberOfColumns) { columnIndex in
            return Column(index: columnIndex, width: containerWidth / CGFloat(numberOfColumns), minY: previousBottomEdge)
        }

        return reduce(0..<numberOfItems, columns) { columns, itemIndex in
            let indexPath = NSIndexPath(forItem: itemIndex, inSection: index)
            let itemSize = self.itemSizeAtIndexPath(indexPath)
            let oldColumn = shortestColumn(columns)
            let newColumn = addItemToColumn <^> oldColumn <*> indexPath <*> itemSize
            return (replaceColumn(columns) <^> oldColumn <*> newColumn) ?? columns

        }
    }

    func columnCountForSectionAtIndex(index: Int) -> Int {
        let indexPath = NSIndexPath(index: index)
        switch (delegate, collectionView) {
        case let (.Some(del), .Some(collection)):
            return del.collectionView(collection, layout: self, numberOfColumnsInSectionAtIndexPath: indexPath)
        default:
            return defaultColumnCount
        }
    }

    func itemSizeAtIndexPath(indexPath: NSIndexPath) -> CGSize {
        switch (delegate, collectionView) {
        case let (.Some(del), .Some(collection)):
            return del.collectionView?(collection, layout: self, sizeForItemAtIndexPath: indexPath) ?? defaultItemSize
        default:
            return defaultItemSize
        }
    }

    override public func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        let attributes: [[UICollectionViewLayoutAttributes]] = map(sections) { section in
            return section.itemAttributes.filter { item in rect.intersects(item.frame)}
        }

        return flatten(attributes)
    }

    override public func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return collectionView?.bounds.width != .Some(newBounds.width)
    }

    override public func invalidateLayout() {
        super.invalidateLayout()
        sections = []
    }
}
