//
//  CollectionViewLayout.swift
//  Adayroi
//
//  Created by ThuyenBV on 7/30/19.
//  Copyright © 2019 Vincommerce. All rights reserved.
//

import UIKit
import AsyncDisplayKit

// ==================================================================================
// MARK: - CollectionViewLayoutDelegate
// ==================================================================================

@objc public protocol CollectionViewLayoutDelegate {
  func collectionView(_ collectionView:UICollectionView, sizeForItem indexPath:IndexPath) -> CGSize
  
  // Header, footer
  @objc optional func collectionView(_ collectionView:UICollectionView, sizeForHeaderSection section: Int) -> CGSize
  @objc optional func collectionView(_ collectionView:UICollectionView, sizeForFooterSection section: Int) -> CGSize
  
  // Cover, menu
  @objc optional func collectionView(sizeForCover collectionView:UICollectionView) -> CGSize
  @objc optional func collectionView(sizeForMenu collectionView:UICollectionView) -> CGSize
}

// ==================================================================================
// MARK: - CollectionViewLayout
// ==================================================================================

final class CollectionViewLayout: UICollectionViewLayout {
  
  // MARK: - Properties
  weak var delegate: CollectionViewLayoutDelegate?
  
  var isMenuSticky: Bool                  = true
  var isCoverStretchy: Bool               = true
  var isAlphaOnHeaderActive: Bool         = true
  var isSectionHeadersSticky: Bool        = true
  
  var minimumLineSpacing: CGFloat         = 0
  var minimumInteritemSpacing: CGFloat    = 0
  var headerOverlayMaxAlphaValue: CGFloat = 0
  
  private var zIndex                      = 0
  private var numberOfColumns             = 2
  private var cellPadding: CGFloat        = 0
  
  private var contentHeight               = CGFloat()
  private var oldBounds                   = CGRect.zero
  private var coverSize                   = CGSize.zero
  private var menuSize                    = CGSize.zero
  
  private var cache = [CollectionViewLayoutType: [IndexPath: CollectionViewLayoutAttributes]]()
  
  // MARK: Getter
  private var contentOffset: CGPoint {
    return collectionView.contentOffset
  }
  
  private var numberOfSections: Int {
    return collectionView.numberOfSections
  }
  
  private func numberOfItems(inSection section: Int) -> Int {
    return collectionView.numberOfItems(inSection: section)
  }
  
  fileprivate var contentWidth: CGFloat {
    get {
      let bounds = collectionView.bounds
      let insets = collectionView.contentInset
      return bounds.width - insets.left - insets.right
    }
  }
  
  // MARK: Override Getter
  override public var collectionView: UICollectionView {
    return super.collectionView!
  }
  
  override public class var layoutAttributesClass: AnyClass {
    return CollectionViewLayoutAttributes.self
  }
  
  override public var collectionViewContentSize: CGSize {
    return CGSize(width: collectionView.frame.width, height: contentHeight)
  }
}

// ==================================================================================
// MARK: - CollectionViewLayout - CORE PROCESS
// ==================================================================================

extension CollectionViewLayout {
  
  override public func prepare() {
    guard let delegate = delegate else { return}
    guard numberOfSections > 0 else { return}
    guard cache.isEmpty else { return }
    
    print("CollectionViewLayout - prepare()")
    prepareCache()
    contentHeight = 0
    zIndex = 0
    oldBounds = collectionView.bounds
    
    var xOffsets = [CGFloat]()
    let collumnWidth = contentWidth / CGFloat(numberOfColumns)
    
    for collumn in 0..<numberOfColumns {
      xOffsets.append(CGFloat(collumn) * collumnWidth)
    }
    
    // Cover
    if let coverSize = delegate.collectionView?(sizeForCover: collectionView) {
      self.coverSize = coverSize
      
      let headerAttributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutType.cover.kind,
                                                            with: IndexPath(item: 0, section: 0))
      prepareElement(size: coverSize, type: .cover, attributes: headerAttributes)
    }
    
    // Menu
    if let menuSize = delegate.collectionView?(sizeForMenu: collectionView) {
      self.menuSize = menuSize
      
      let menuAttributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutType.menu.kind,
                                                          with: IndexPath(item: 0, section: 0))
      prepareElement(size: menuSize, type: .menu, attributes: menuAttributes)
    }
    
    for section in 0 ..< collectionView.numberOfSections {
      
      // Header
      let sectionHeaderAttributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                                                                   with: IndexPath(item: 0, section: section))
      if let sectionsHeaderSize = delegate.collectionView?(collectionView, sizeForHeaderSection: section) {
        prepareElement(size: sectionsHeaderSize, type: .sectionHeader, attributes: sectionHeaderAttributes)
      }
      
      var yOffsets = [CGFloat](repeating: contentHeight,
                               count: numberOfColumns)
      
      // Cell
      let beginOffset = yOffsets.max() ?? 0
      
      for item in 0 ..< collectionView.numberOfItems(inSection: section) {
        let cellIndexPath = IndexPath(item: item, section: section)
        let itemSize = delegate.collectionView(collectionView, sizeForItem: cellIndexPath)
        
        // Mặc định chèn vào cột thấp hơn.
        var column = yOffsets.index(of: yOffsets.min() ?? 0) ?? 0
        var xOffset = xOffsets[column]
        
        // Nếu cell width > collumnWidth thì xuống dòng khác
        if itemSize.width > collumnWidth {
          column = yOffsets.index(of: yOffsets.max() ?? 0) ?? 0
          xOffset = xOffsets[0]
        }
        
        let interitemSpace = column > 0 ? minimumInteritemSpacing : 0
        let lineInterSpace = minimumLineSpacing
        
        let frame = CGRect(
          x: xOffset + interitemSpace,
          y: yOffsets[column] + lineInterSpace,
          width: itemSize.width,
          height: itemSize.height
        )
        
        print("CollectionViewLayout - cellFrame: \(frame)")
        
        let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
        let attributes = CollectionViewLayoutAttributes(forCellWith: cellIndexPath)
        attributes.frame = insetFrame
        attributes.zIndex = zIndex
        
        contentHeight = max(contentHeight, frame.maxY)
        cache[.cell]?[cellIndexPath] = attributes
        zIndex += 1
        
        yOffsets[column] = yOffsets[column] + itemSize.height + minimumLineSpacing + (cellPadding * 2)
      }
      
      sectionHeaderAttributes.totalContentHeight = (yOffsets.max() ?? 0) - beginOffset
      
      // Footer
      if let sectionsFooterSize = delegate.collectionView?(collectionView, sizeForFooterSection: section) {
        let sectionFooterAttributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionFooter,
                                                                     with: IndexPath(item: 0, section: section))
        prepareElement(size: sectionsFooterSize, type: .sectionFooter, attributes: sectionFooterAttributes)
      }
    }
    
    updateZIndexes()
  }
  
  override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    if oldBounds.size != newBounds.size {
      cache.removeAll(keepingCapacity: true)
      print("CollectionViewLayout - shouldInvalidateLayout(true)")
    }
    return true
  }
  
  override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
    super.invalidateLayout(with: context)
    
    if context.invalidateDataSourceCounts {
      cache.removeAll(keepingCapacity: true)
      print("CollectionViewLayout - invalidateLayout(with context)")
    }
  }
  
  override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    switch elementKind {
    case UICollectionElementKindSectionHeader:
      return cache[.sectionHeader]?[indexPath]
      
    case UICollectionElementKindSectionFooter:
      return cache[.sectionFooter]?[indexPath]
      
    case CollectionViewLayoutType.cover.kind:
      return cache[.cover]?[indexPath]
      
    default:
      return cache[.menu]?[indexPath]
    }
  }
  
  override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    return cache[.cell]?[indexPath]
  }
  
  override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    var visibleLayoutAttributes = [CollectionViewLayoutAttributes]()
    
    for (type, elementInfos) in cache {
      for (indexPath, attributes) in elementInfos {
        if attributes.frame.intersects(rect) {
          updateSupplementaryViews(type, attributes: attributes, collectionView: collectionView, indexPath: indexPath)
          visibleLayoutAttributes.append(attributes)
        } else if type == .cover || type == .menu || type == .sectionHeader {
          updateSupplementaryViews(type, attributes: attributes, collectionView: collectionView, indexPath: indexPath)
          visibleLayoutAttributes.append(attributes)
        }
      }
    }
    return visibleLayoutAttributes
  }
}

// ==================================================================================
// MARK: - CollectionViewLayout - PRIVATE FUNCTION
// ==================================================================================

extension CollectionViewLayout {
  
  private func prepareCache() {
    cache.removeAll(keepingCapacity: true)
    
    cache[.cover]         = [IndexPath: CollectionViewLayoutAttributes]()
    cache[.menu]          = [IndexPath: CollectionViewLayoutAttributes]()
    cache[.sectionHeader] = [IndexPath: CollectionViewLayoutAttributes]()
    cache[.sectionFooter] = [IndexPath: CollectionViewLayoutAttributes]()
    cache[.cell]          = [IndexPath: CollectionViewLayoutAttributes]()
  }
  
  private func prepareElement(size: CGSize, type: CollectionViewLayoutType, attributes: CollectionViewLayoutAttributes) {
    guard size != .zero else { return }
    
    attributes.initialOrigin = CGPoint(x: 0, y: contentHeight)
    attributes.frame = CGRect(origin: attributes.initialOrigin, size: size)
    
    attributes.zIndex = zIndex
    zIndex += 1
    
    contentHeight = attributes.frame.maxY
    
    cache[type]?[attributes.indexPath] = attributes
  }
  
  private func updateSupplementaryViews(_ type: CollectionViewLayoutType, attributes: CollectionViewLayoutAttributes, collectionView: UICollectionView, indexPath: IndexPath) {
    if type == .cover, isCoverStretchy {
      
      let updatedHeight = min(collectionView.frame.height,
                              max(coverSize.height, coverSize.height - contentOffset.y))
      
      let scaleFactor = updatedHeight / coverSize.height
      let delta = (updatedHeight - coverSize.height) / 2
      let scale = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
      let translation = CGAffineTransform(translationX: 0, y: min(contentOffset.y, coverSize.height) + delta)
      attributes.transform = scale.concatenating(translation)
      if isAlphaOnHeaderActive {
        attributes.headerOverlayAlpha = min(headerOverlayMaxAlphaValue, contentOffset.y / coverSize.height)
      }
      
    } else if type == .menu, isMenuSticky {
      
      attributes.transform = CGAffineTransform(translationX: 0, y: max(attributes.initialOrigin.y, contentOffset.y) - coverSize.height)
    } else if type == .sectionHeader, isSectionHeadersSticky {
      
      let menuOffset = isMenuSticky ? menuSize.height : 0
      let maxOffset = max(0, contentOffset.y - attributes.initialOrigin.y + menuOffset)
      
      attributes.transform =  CGAffineTransform(translationX: 0,
                                                y: min(attributes.totalContentHeight, maxOffset))
    }
  }
  
  private func updateZIndexes(){
    guard let sectionHeaders = cache[.sectionHeader] else { return }
    
    var sectionHeadersZIndex = zIndex
    for (_, attributes) in sectionHeaders {
      attributes.zIndex = sectionHeadersZIndex
      sectionHeadersZIndex += 1
    }
    
    cache[.menu]?.first?.value.zIndex = sectionHeadersZIndex
  }
}

// ==================================================================================
// MARK: - CollectionViewLayoutInspector
// ==================================================================================

class CollectionViewLayoutInspector: NSObject, ASCollectionViewLayoutInspecting {
  
  func collectionView(_ collectionView: ASCollectionView, constrainedSizeForNodeAt indexPath: IndexPath) -> ASSizeRange {
    
    guard let layout = collectionView.collectionViewLayout as? CollectionViewLayout else { return ASSizeRangeUnconstrained }
    
    let size = layout.delegate?.collectionView(collectionView, sizeForItem: indexPath) ?? CGSize.zero
    return ASSizeRangeMake(size)
  }
  
  func collectionView(_ collectionView: ASCollectionView, constrainedSizeForSupplementaryNodeOfKind: String, at indexPath: IndexPath) -> ASSizeRange {
    
    guard let layout = collectionView.collectionViewLayout as? CollectionViewLayout else { return ASSizeRangeUnconstrained }
    
    switch constrainedSizeForSupplementaryNodeOfKind {
    case UICollectionElementKindSectionHeader:
      let size = layout.delegate?.collectionView?(collectionView, sizeForHeaderSection: indexPath.section) ?? CGSize.zero
      return ASSizeRangeMake(size)
    case UICollectionElementKindSectionFooter:
      let size = layout.delegate?.collectionView?(collectionView, sizeForFooterSection: indexPath.section) ?? CGSize.zero
      return ASSizeRangeMake(size)
    case CollectionViewLayoutType.cover.kind:
      let size = layout.delegate?.collectionView?(sizeForCover: collectionView) ?? CGSize.zero
      return ASSizeRangeMake(size)
    case CollectionViewLayoutType.menu.kind:
      let size = layout.delegate?.collectionView?(sizeForMenu: collectionView) ?? CGSize.zero
      return ASSizeRangeMake(size)
    default:
      return ASSizeRangeZero
    }
  }
  
  func collectionView(_ collectionView: ASCollectionView, numberOfSectionsForSupplementaryNodeOfKind kind: String) -> UInt {
    
    if (kind == UICollectionElementKindSectionHeader
      || kind == UICollectionElementKindSectionFooter
      || kind == CollectionViewLayoutType.cover.kind
      || kind == CollectionViewLayoutType.menu.kind) {
      return UInt((collectionView.dataSource?.numberOfSections!(in: collectionView))!)
    } else {
      return 0
    }
  }
  
  func collectionView(_ collectionView: ASCollectionView, supplementaryNodesOfKind kind: String, inSection section: UInt) -> UInt {
    if (kind == UICollectionElementKindSectionHeader
      || kind == UICollectionElementKindSectionFooter
      || kind == CollectionViewLayoutType.cover.kind
      || kind == CollectionViewLayoutType.menu.kind) {
      return 1
    } else {
      return 0
    }
  }
  
  func scrollableDirections() -> ASScrollDirection {
    return ASScrollDirectionVerticalDirections;
  }
}

