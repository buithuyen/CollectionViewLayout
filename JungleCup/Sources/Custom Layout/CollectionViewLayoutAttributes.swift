//
//  CollectionViewLayoutAttributes.swift
//  Adayroi
//
//  Created by ThuyenBV on 7/30/19.
//  Copyright © 2019 Vincommerce. All rights reserved.
//

import UIKit

// ==================================================================================
// MARK: - CollectionViewLayoutType
// ==================================================================================

enum CollectionViewLayoutType: String {
  case cover
  case menu
  case sectionHeader
  case sectionFooter
  case cell
  
  var id: String {
    return self.rawValue
  }
  
  var kind: String {
    return "Kind\(self.rawValue.capitalized)"
  }
}

// ==================================================================================
// MARK: - CollectionViewLayoutAttributes
// ==================================================================================

final class CollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
  
  // MARK: - Properties
  var initialOrigin: CGPoint = .zero
  var totalContentHeight = CGFloat(0)
  var headerOverlayAlpha = CGFloat(0)
  
  // MARK: - Life Cycle
  override func copy(with zone: NSZone?) -> Any {
    guard let copiedAttributes = super.copy(with: zone) as? CollectionViewLayoutAttributes else {
      return super.copy(with: zone)
    }
    
    copiedAttributes.totalContentHeight = totalContentHeight
    copiedAttributes.initialOrigin = initialOrigin
    copiedAttributes.headerOverlayAlpha = headerOverlayAlpha
    return copiedAttributes
  }
  
  override func isEqual(_ object: Any?) -> Bool {
    guard let otherAttributes = object as? CollectionViewLayoutAttributes else {
      return false
    }
    
    if otherAttributes.totalContentHeight != totalContentHeight
      || otherAttributes.initialOrigin != initialOrigin
      || otherAttributes.headerOverlayAlpha != headerOverlayAlpha {
      return false
    }
    
    return super.isEqual(object)
  }
}
