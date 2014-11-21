import UIKit

typealias AttributesArray = [UICollectionViewLayoutAttributes]
typealias Rects = [CGRect]
typealias Columns = [GridLayoutColumn]

class GridLayout: UICollectionViewFlowLayout {
  var sections = [GridLayoutSection]()
  var delegate: UICollectionViewDelegateGridLayout?
  let sectionInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
  let defaultColumnCount = 1
  let defaultItemSize = CGSize(width: 600, height: 800)

  override func collectionViewContentSize() -> CGSize {
    var height = CGFloat(0)
    var width = CGFloat(0)

    if let lastSection = sections.last {
      height = lastSection.maxY
      width = CGRectGetWidth(collectionView!.frame)
    }

    return CGSize(width: width, height: height)
  }

  override func prepareLayout() {
    let numberOfSections = collectionView?.numberOfSections() ?? 0
    if numberOfSections == 0 { return }

    sections.reserveCapacity(numberOfSections)

    for index in 0..<numberOfSections {
      let itemCount = collectionView?.numberOfItemsInSection(index) ?? 0
      sections.append(GridLayoutSection(itemCount))
    }

    for (sectionIndex, section) in enumerate(sections) {
      prepareLayoutForSection(section, atIndex: sectionIndex)
    }
  }

  func prepareLayoutForSection(section: GridLayoutSection, atIndex index: Int) {
    var previousSectionRect = previousSectionRectForSectionWithIndex(index)
    
    section.rect.origin.x = sectionInsets.left
    section.rect.origin.y = CGRectGetMaxY(previousSectionRect) + sectionInsets.top
    section.rect.size.width = CGRectGetWidth(collectionView?.frame ?? CGRectZero)
    
    let columnCount = columnCountForSectionAtIndex(index)
    section.addColumns(columnCount)
    let columnWidth = section.columnWidth
    
    for itemIndex in 0..<section.itemCount {
      let itemPath = NSIndexPath(forItem: itemIndex, inSection: index)
      let itemSize = itemSizeAtIndexPath(itemPath)
      let itemAspectRatio = itemSize.height / itemSize.width
      
      let column = section.preferredColumn
      
      var itemRect = CGRectZero
      itemRect.origin.x = floor(section.rect.origin.x + CGFloat(column.index) * columnWidth)
      itemRect.origin.y = column.maxY
      itemRect.size = CGSize(width: columnWidth, height: floor(columnWidth * itemAspectRatio))
      column.addItemRect(itemRect)
      
      let itemAttributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: itemPath)
      itemAttributes.frame = itemRect
      section.itemAttributesArray.append(itemAttributes)
    }
    
    section.rect.size.height = section.maxY
  }

  // MARK: - Helper Methods

  func previousSectionRectForSectionWithIndex(index: Int) -> CGRect {
      var previousSectionRect = CGRectZero

      if index > 0 {
        let previousSection = sections[index-1]
        previousSectionRect = previousSection.rect
      }

    return previousSectionRect
  }

  func columnCountForSectionAtIndex(index: Int) -> Int {
    let indexPath = NSIndexPath(index: index)
    return delegate?.collectionView(collectionView!, layout: self, numberOfColumnsInSectionAtIndexPath: indexPath) ?? defaultColumnCount
  }

  func itemSizeAtIndexPath(indexPath: NSIndexPath) -> CGSize {
    return delegate?.collectionView?(collectionView!, layout: self, sizeForItemAtIndexPath: indexPath) ?? defaultItemSize
  }

  // MARK: - Overridden Methods

  override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
    var attributesArray = AttributesArray()

    var visibleSections = sections.filter { CGRectIntersectsRect($0.rect, rect) }
    for section in visibleSections {
      let attributes = section.itemAttributesArray.filter { CGRectIntersectsRect(rect, $0.frame) }
      attributes.map { attributesArray.append($0) }
    }

    return attributesArray
  }

  override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
    var shouldInvalidate = false

    if let oldWidth = collectionView?.bounds.width {
      shouldInvalidate = newBounds.width != oldWidth
    }

    return shouldInvalidate
  }

  override func invalidateLayout() {
    super.invalidateLayout()
    sections.removeAll(keepCapacity: true)
  }
}

class GridLayoutSection {
  var columns = Columns()
  var itemAttributesArray = AttributesArray()
  var itemCount: Int
  var rect = CGRectZero

  var maxY: CGFloat {
    if columns.count == 0 { return 0 }
    var columnMaxY = columns[0].maxY

    for (index, column) in enumerate(columns[1..<columns.count]) {
      columnMaxY = max(column.maxY, columnMaxY)
    }

    return columnMaxY
  }

  var preferredColumn: GridLayoutColumn {
    return columns[preferredColumnIndex]
  }

  var preferredColumnIndex: Int {
    switch columns.count {
    case 1:
      return 0
    default:
      return shortestColumnIndex()
    }
  }

  var columnWidth: CGFloat {
    return floor(rect.size.width / CGFloat(columns.count))
  }

  init(_ numberOfItems: Int) {
    itemCount = numberOfItems
    itemAttributesArray.reserveCapacity(numberOfItems)
  }

  func addColumns(count: Int) {
    for columnIndex in 0..<count {
      columns.append(GridLayoutColumn(index: columnIndex))
    }
  }

  func shortestColumnIndex() -> Int {
    assert(columns.count > 0, "Column count should be superior to 0.")

    var shortestColumnIndex = 0
    
    for (index, column) in enumerate(columns[1..<columns.count]) {
      if column.maxY < columns[shortestColumnIndex].maxY {
        shortestColumnIndex = index + 1
      }
    }
    
    return shortestColumnIndex
  }
}

class GridLayoutColumn {
  var index: Int
  var maxY = CGFloat(0)
  var rects = Rects()

  init(index: Int) {
    self.index = index
  }

  func addItemRect(rect: CGRect) {
    rects.append(rect)
    maxY = CGRectGetMaxY(rect)
  }
}

protocol UICollectionViewDelegateGridLayout: UICollectionViewDelegateFlowLayout {
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: GridLayout, numberOfColumnsInSectionAtIndexPath indexPath: NSIndexPath) -> Int
}