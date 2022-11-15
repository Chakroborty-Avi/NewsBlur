//
//  FeedDetailViewController.swift
//  NewsBlur
//
//  Created by David Sinclair on 2020-08-27.
//  Copyright © 2020 NewsBlur. All rights reserved.
//

import UIKit

/// List of stories for a feed.
class FeedDetailViewController: FeedDetailObjCViewController {
    enum SectionLayoutKind: Int, CaseIterable {
        /// Feed cells before the story.
        case feedBeforeStory
        
        /// The selected story.
        case selectedStory
        
        /// Feed cells after the story.
        case feedAfterStory
        
        /// Loading cell at the end.
        case loading
    }
    
    var isGrid: Bool {
        return appDelegate.detailViewController.layout == .grid
    }
    
    var feedColumns: Int {
        guard let pref = UserDefaults.standard.string(forKey: "grid_columns"), let columns = Int(pref) else {
            return 4
        }
        
        return columns
    }
    
    var gridHeight: CGFloat {
        guard let pref = UserDefaults.standard.string(forKey: "grid_height") else {
            return 400
        }
        
        switch pref {
        case "xs":
            return 250
        case "short":
            return 300
        case "tall":
            return 400
        case "xl":
            return 450
        default:
            return 350
        }
    }
    
//    var storyHeight: CGFloat {
//        if let pagesController = appDelegate.storyPagesViewController, let webView = pagesController.currentPage.webView {
//            let frame = pagesController.view.frame
//
//            print("Story pages frame: \(pagesController.view.frame), web height \(webView.scrollView.contentSize.height)")
//
//            pagesController.view.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: 500)
//            pagesController.currentPage.view.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: 500)
//            pagesController.view.layoutIfNeeded()
//
//            let height = webView.scrollView.contentSize.height + 50
//
//            print("... frame now: \(pagesController.view.frame), height: \(height)")
//
//            return height
//        } else {
//            return 1000
//        }
//    }
    
    var dataSource: UICollectionViewDiffableDataSource<SectionLayoutKind, Int>! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changedLayout()
        configureDataSource()
    }
    
    @objc override func changedLayout() {
        if isGrid {
            feedCollectionView.collectionViewLayout = createGridLayout()
        } else {
            feedCollectionView.collectionViewLayout = createListLayout()
        }
        
        feedCollectionView.setNeedsLayout()
    }
    
    @objc override func reload() {
        configureDataSource()
    }
    
    @objc override func reload(_ indexPath: IndexPath) {
        configureDataSource()
    }
}

extension FeedDetailViewController {
    func accessoriesForListCellItem(_ item: Int) -> [UICellAccessory] {
        let isStarred = false //self.starredEmojis.contains(item)
        var accessories = [UICellAccessory.disclosureIndicator()]
        if isStarred {
            let star = UIImageView(image: UIImage(systemName: "star.fill"))
            accessories.append(.customView(configuration: .init(customView: star, placement: .trailing())))
        }
        return accessories
    }
    
    func leadingSwipeActionConfigurationForListCellItem(_ item: Int) -> UISwipeActionsConfiguration? {
        let isStarred = false //self.starredEmojis.contains(item)
        let starAction = UIContextualAction(style: .normal, title: nil) {
            [weak self] (_, _, completion) in
            guard let self = self else {
                completion(false)
                return
            }
            
            // Don't check again for the starred state. We promised in the UI what this action will do.
            // If the starred state has changed by now, we do nothing, as the set will not change.
//            if isStarred {
//                self.starredEmojis.remove(item)
//            } else {
//                self.starredEmojis.insert(item)
//            }
            
            // Reconfigure the cell of this item
            // Make sure we get the current index path of the item.
            if let currentIndexPath = self.dataSource.indexPath(for: item) {
                if let cell = self.feedCollectionView.cellForItem(at: currentIndexPath) as? UICollectionViewListCell {
                    UIView.animate(withDuration: 0.2) {
                        cell.accessories = self.accessoriesForListCellItem(item)
                    }
                }
            }
            
            completion(true)
        }
        starAction.image = UIImage(systemName: isStarred ? "star.slash" : "star.fill")
        starAction.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [starAction])
    }
    
    func createListLayout() -> UICollectionViewLayout {
//        let size = NSCollectionLayoutSize(
//            widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
//            heightDimension: NSCollectionLayoutDimension.estimated(200)
//        )
//        let item = NSCollectionLayoutItem(layoutSize: size)
//        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: 1)
//
//        let section = NSCollectionLayoutSection(group: group)
//        section.interGroupSpacing = 0
//
//        return UICollectionViewCompositionalLayout(section: section)
        
        
        
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.leadingSwipeActionsConfigurationProvider = { [weak self] (indexPath) in
            guard let self else { return nil }
            guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
            return self.leadingSwipeActionConfigurationForListCellItem(item)
        }
        
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }
    
    func createGridLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex: Int,
                                                            layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            guard let sectionLayoutKind = SectionLayoutKind(rawValue: sectionIndex) else {
                return nil
            }
            
            let isStory = sectionLayoutKind == .selectedStory
            let isLoading = sectionLayoutKind == .loading
            let columns = isStory || isLoading ? 1 : self.feedColumns
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            
            let groupHeight = isStory ? NSCollectionLayoutDimension.absolute(self.storyHeight) : isLoading ? NSCollectionLayoutDimension.absolute(100) : NSCollectionLayoutDimension.absolute(self.gridHeight)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: groupHeight)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columns)
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10)
            
            return section
        }
        
        return layout
    }
}

extension FeedDetailViewController {
    func configureDataSource() {
        let feedCellRegistration = UICollectionView.CellRegistration<FeedDetailCollectionCell, Int> { (cell, indexPath, identifier) in
            
//            cell.frame.size.height = self.heightForRow(at: indexPath)
            
            self.prepareFeedCell(cell, indexPath: indexPath)
        }
        
        let storyCellRegistration = UICollectionView.CellRegistration<StoryPagesCollectionCell, Int> { (cell, indexPath, identifier) in
            self.prepareStoryCell(cell, indexPath: indexPath)
        }
        
        let loadingCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Int> { (cell, indexPath, identifier) in
            self.prepareLoading(cell, indexPath: indexPath)
        }
        
        dataSource = UICollectionViewDiffableDataSource<SectionLayoutKind, Int>(collectionView: feedCollectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: Int) -> UICollectionViewCell? in
            guard let sectionKind = SectionLayoutKind(rawValue: indexPath.section) else {
                return nil
            }
            
            switch sectionKind {
            case .feedBeforeStory, .feedAfterStory:
                return collectionView.dequeueConfiguredReusableCell(using: feedCellRegistration, for: indexPath, item: identifier)
            case .selectedStory:
                if self.isGrid {
                    return collectionView.dequeueConfiguredReusableCell(using: storyCellRegistration, for: indexPath, item: identifier)
                } else {
                    return collectionView.dequeueConfiguredReusableCell(using: feedCellRegistration, for: indexPath, item: identifier)
                }
            case .loading:
                return collectionView.dequeueConfiguredReusableCell(using: loadingCellRegistration, for: indexPath, item: identifier)
            }
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<SectionLayoutKind, Int>()
        
        let storyCount = Int(appDelegate.storiesCollection.storyLocationsCount)
        
        snapshot.appendSections(SectionLayoutKind.allCases)
        
        if self.messageView.isHidden {
            if storyCount > 0 {
                let selectedIndex = appDelegate.storiesCollection.indexOfActiveStory()
                
                if selectedIndex < 0 {
                    snapshot.appendItems(Array(0..<storyCount), toSection: .feedBeforeStory)
                } else {
                    snapshot.appendItems(Array(0..<selectedIndex), toSection: .feedBeforeStory)
                    snapshot.appendItems([selectedIndex], toSection: .selectedStory)
                    
                    if selectedIndex + 1 < storyCount {
                        snapshot.appendItems(Array(selectedIndex + 1..<storyCount), toSection: .feedAfterStory)
                    }
                }
            }
            
            snapshot.appendItems([-1], toSection: .loading)
        }
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}
