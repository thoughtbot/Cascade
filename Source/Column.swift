import CoreGraphics.CGGeometry
import UIKit.UICollectionViewLayout
import Foundation.NSIndexPath
import Runes

struct Column {
    let index: Int
    let frame: CGRect
    let width: CGFloat
    let attributes: [UICollectionViewLayoutAttributes]
    let spacing: CGFloat

    var bottomEdge: CGFloat {
        return frame.maxY
    }

    init(index: Int, width: CGFloat, minX: CGFloat, minY: CGFloat, spacing: CGFloat) {
        self.index = index
        self.width = width
        self.attributes = []
        self.frame = CGRect(x: minX, y: minY, width: width, height: 0)
        self.spacing = spacing
    }
}

extension Column {
    init(column: Column, frame: CGRect, attributes: [UICollectionViewLayoutAttributes]) {
        self.index = column.index
        self.width = column.width
        self.frame = frame
        self.attributes = attributes
        self.spacing = column.spacing
    }

    func addItemWithSize(itemSize: CGSize, atIndexPath indexPath: NSIndexPath) -> Column {
        let aspectRatio = itemSize.height / itemSize.width
        let itemRect = CGRect(x: frame.minX,
            y: bottomEdge + spacing,
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
    return columns.sort { $0.bottomEdge < $1.bottomEdge }.first
}

func tallestColumn(columns: [Column]) -> Column? {
    return columns.sort { $0.bottomEdge > $1.bottomEdge }.first
}

func addItemToColumn(column: Column)(indexPath: NSIndexPath)(size: CGSize) -> Column {
    return column.addItemWithSize(size, atIndexPath: indexPath)
}

func replaceColumn(var columns: [Column])(oldColumn: Column)(newColumn: Column) -> [Column] {
    columns.removeAtIndex <^> columns.indexOf(oldColumn)
    return columns + [newColumn]
}
