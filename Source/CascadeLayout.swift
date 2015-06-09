import UIKit.UICollectionViewFlowLayout
import Runes

public class CascadeLayout: UICollectionViewFlowLayout {
    public var delegate: CascadeLayoutDelegate?

    let defaultColumnCount = 1
    let defaultItemSize = CGSize(width: 600, height: 800)

    var sections = [Section]()

    override public func collectionViewContentSize() -> CGSize {
        let size = makeSize
            <^> effectiveWidth
            <*> tallestSection(sections)?.bottomEdge

        return size ?? CGSizeZero
    }

    var effectiveWidth: CGFloat? {
        return collectionView.map { $0.frame.width - $0.contentInset.left - $0.contentInset.right }
    }

    func columnWidthForSectionAtIndex(index: Int) -> CGFloat {
        let numberOfColumns = columnCountForSectionAtIndex(index)
        let containerWidth = effectiveWidth ?? 0
        return (containerWidth - minimumLineSpacing * CGFloat(numberOfColumns - 1)) / CGFloat(numberOfColumns)
    }

    override public func prepareLayout() {
        let numberOfSections = collectionView?.numberOfSections() ?? 0

        sections = (0..<numberOfSections).reduce([]) { sections, index in
            let numberOfItems = self.collectionView?.numberOfItemsInSection(index) ?? 0
            let columns = self.columnsForSectionAtIndex(index, numberOfItems: numberOfItems, previousSection: sections.last)
            let section = Section(numberOfItems: numberOfItems, columns: columns)
            return sections + [section]
        }
    }

    func columnsForSectionAtIndex(index: Int, numberOfItems: Int, previousSection: Section?) -> [Column] {
        let previousBottomEdge = previousSection?.bottomEdge ?? 0
        let numberOfColumns = columnCountForSectionAtIndex(index)
        let columnWidth = columnWidthForSectionAtIndex(index)

        let columns: [Column] = (0..<numberOfColumns).map { columnIndex in
            let minX = CGFloat(columnIndex) * (columnWidth + self.minimumLineSpacing)
            return Column(index: columnIndex, width: columnWidth, minX: minX, minY: previousBottomEdge, spacing: self.minimumInteritemSpacing)
        }

        return (0..<numberOfItems).reduce(columns) { columns, itemIndex in
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

    override public func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes: [[UICollectionViewLayoutAttributes]] = sections.map { section in
            return section.itemAttributes.filter { item in rect.intersects(item.frame)}
        }

        return flatten(attributes)
    }

    override public func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let itemAttributes = sections[indexPath.section].itemAttributes
        let index = itemAttributes.map { $0.indexPath }.indexOf(indexPath)
        return index.map { itemAttributes[$0] } ?? UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
    }

    override public func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return collectionView?.bounds.width != .Some(newBounds.width)
    }

    override public func invalidateLayout() {
        super.invalidateLayout()
        sections = []
    }
}
