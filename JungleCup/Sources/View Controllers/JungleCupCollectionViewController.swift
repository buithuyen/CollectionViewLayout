/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit

final class JungleCupCollectionViewController: UICollectionViewController {
 
  // MARK: - Properties
  var customLayout: CollectionViewLayout? {
    return collectionView?.collectionViewLayout as? CollectionViewLayout
  }

  private let teams: [Team] = [Owls(), Giraffes(), Parrots(), Tigers()]
  private let sections = ["Goalkeeper", "Defenders", "Midfielders", "Forwards"]
  private var displayedTeam = 0

  override var prefersStatusBarHidden: Bool {
    return true
  }

  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()

    setupCollectionViewLayout()
  }
}

private extension JungleCupCollectionViewController {

  func setupCollectionViewLayout() {
    guard let collectionView = collectionView, let customLayout = customLayout else { return }
    customLayout.delegate = self
    
    collectionView.register(UINib(nibName: "HeaderView", bundle: nil),
                            forSupplementaryViewOfKind: CollectionViewLayoutType.cover.kind,
                            withReuseIdentifier: CollectionViewLayoutType.cover.id)

    collectionView.register(UINib(nibName: "MenuView", bundle: nil),
                            forSupplementaryViewOfKind: CollectionViewLayoutType.menu.kind,
                            withReuseIdentifier: CollectionViewLayoutType.menu.id)

    customLayout.headerOverlayMaxAlphaValue = CGFloat(0.6)
    customLayout.minimumInteritemSpacing = 3
    customLayout.minimumLineSpacing = 3
  }
}

extension JungleCupCollectionViewController: CollectionViewLayoutDelegate {
  func collectionView(_ collectionView: UICollectionView, sizeForItem indexPath: IndexPath) -> CGSize {
    if indexPath.section == 0 {
      return CGSize(width: collectionView.bounds.width, height: 200)
    }
    
    if indexPath.section > 2 {
      return CGSize(width: collectionView.bounds.width, height: 400)
    }
    
    return CGSize(width: collectionView.bounds.width * 0.5, height: 200)
  }
  
  func collectionView(sizeForCover collectionView: UICollectionView) -> CGSize {
    return CGSize(width: collectionView.frame.width, height: 300)
  }

  func collectionView(sizeForMenu collectionView: UICollectionView) -> CGSize {
    return CGSize(width: collectionView.frame.width, height: 70)
  }
  
  func collectionView(_ collectionView: UICollectionView, sizeForHeaderSection section: Int) -> CGSize {
    return CGSize(width: collectionView.frame.width, height: 50)
  }
  
  func collectionView(_ collectionView: UICollectionView, sizeForFooterSection section: Int) -> CGSize {
    return CGSize(width: collectionView.frame.width, height: 50)
  }
}

//MARK: - UICollectionViewDataSource
extension JungleCupCollectionViewController {

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return sections.count
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return teams[displayedTeam].playerPictures[section].count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionViewLayoutType.cell.id, for: indexPath)
    if let playerCell = cell as? PlayerCell {
      playerCell.picture.image = UIImage(named: teams[displayedTeam].playerPictures[indexPath.section][indexPath.item])
    }
    return cell
  }

  override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionElementKindSectionHeader:
      let supplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                              withReuseIdentifier: CollectionViewLayoutType.sectionHeader.id,
                                                                              for: indexPath)
      if let sectionHeaderView = supplementaryView as? SectionHeaderView {
        sectionHeaderView.title.text = sections[indexPath.section]
      }
      return supplementaryView

    case UICollectionElementKindSectionFooter:
      let supplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                              withReuseIdentifier: CollectionViewLayoutType.sectionFooter.id,
                                                                              for: indexPath)
      if let sectionFooterView = supplementaryView as? SectionFooterView {
        sectionFooterView.mark.text = "Strength: \(teams[displayedTeam].marks[indexPath.section])"
      }
      return supplementaryView

    case CollectionViewLayoutType.cover.kind:
      let topHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                          withReuseIdentifier: CollectionViewLayoutType.cover.id,
                                                                          for: indexPath)
      return topHeaderView

    case CollectionViewLayoutType.menu.kind:
      let menuView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                     withReuseIdentifier: CollectionViewLayoutType.menu.id,
                                                                     for: indexPath)
      if let menuView = menuView as? MenuView {
        menuView.delegate = self
      }
      return menuView

    default:
      fatalError("Unexpected element kind")
    }
  }
}

// MARK: - MenuViewDelegate
extension JungleCupCollectionViewController: MenuViewDelegate {

  func reloadCollectionViewDataWithTeamIndex(_ index: Int) {
    displayedTeam = index
    collectionView?.reloadData()
  }
}
