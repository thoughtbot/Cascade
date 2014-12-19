import CoreGraphics.CGGeometry
import UIKit.UICollectionViewLayout
import Foundation.NSIndexPath

struct Column {
    let index: Int
    let frame: CGRect
    let width: CGFloat
    let attributes = [UICollectionViewLayoutAttributes]()

    var bottomEdge: CGFloat {
        return frame.maxY
    }

    init(index: Int, width: CGFloat, minY: CGFloat) {
        self.index = index
        self.width = width
        self.frame = CGRect(x: CGFloat(index) * width,
            y: minY,
            width: width,
            height: 0)
    }
}

extension Column {
    init(column: Column, frame: CGRect, attributes: [UICollectionViewLayoutAttributes]) {
        self.index = column.index
        self.width = column.width
        self.frame = frame
        self.attributes = attributes
    }

    func addItemWithSize(itemSize: CGSize, atIndexPath indexPath: NSIndexPath) -> Column {
        let aspectRatio = itemSize.height / itemSize.width
        let itemRect = CGRect(x: frame.minX,
            y: bottomEdge,
            width: floor(width),
            height: floor(width * aspectRatio))

        let itemAttributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        itemAttributes.frame = itemRect

        let newAttributes = attributes + [itemAttributes]
        let newFrame = frame.rectByUnion(itemRect)

        return Column(column: self, frame: newFrame, attributes: newAttributes)
    }
}

extension Column: Equatable { }

func ==(lhs: Column, rhs: Column) -> Bool {
    return (lhs.index == rhs.index) && (lhs.bottomEdge == rhs.bottomEdge)
}

func shortestColumn(columns: [Column]) -> Column? {
    return sorted(columns) { $0.bottomEdge < $1.bottomEdge }.first
}

func tallestColumn(columns: [Column]) -> Column? {
    return sorted(columns) { $0.bottomEdge > $1.bottomEdge }.first
}

func addItemToColumn(column: Column)(indexPath: NSIndexPath)(size: CGSize) -> Column {
    return column.addItemWithSize(size, atIndexPath: indexPath)
}

func replaceColumn(var columns: [Column])(oldColumn: Column)(newColumn: Column) -> [Column] {
    columns.removeAtIndex <^> find(columns, oldColumn)
    return columns + [newColumn]
}
