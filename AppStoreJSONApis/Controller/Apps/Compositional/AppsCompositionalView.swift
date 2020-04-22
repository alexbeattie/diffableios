//
//  AppsCompositionalView.swift
//  AppStoreJSONApis
//
//  Created by Brian Voong on 1/14/20.
//  Copyright © 2020 Brian Voong. All rights reserved.
//

import SwiftUI
//import LBTATools

class CompositionalController: UICollectionViewController {
    
    init() {

        let layout = UICollectionViewCompositionalLayout { (sectionNumber, _) -> NSCollectionLayoutSection? in
            
            if sectionNumber == 0 {
                return CompositionalController.topSection()
            } else {

                let item = NSCollectionLayoutItem.init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1/3)))
                item.contentInsets = .init(top: 0, leading: 0, bottom: 16, trailing: 16)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(0.8), heightDimension: .absolute(300)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .groupPaging
                section.contentInsets.leading = 16
                
                //supplementary
                let kind = UICollectionView.elementKindSectionHeader
                section.boundarySupplementaryItems = [.init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50)), elementKind: kind, alignment: .topLeading)
                ]
                return section
                
            }
        }
        super.init(collectionViewLayout: layout)
    }
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath)
        return header
    }
    static func topSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
        item.contentInsets.bottom = 16
        item.contentInsets.trailing = 16
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(0.8), heightDimension: .absolute(300)), subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets.leading = 16
        section.orthogonalScrollingBehavior = .groupPaging
        return section

    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var socialApps = [SocialApp]()
    var games:AppGroup?
    private func fetchApps() {
        Service.shared.fetchSocialApps { (apps, err) in
            self.socialApps = apps ?? []
            Service.shared.fetchGames { (appGroup, err) in
                //appGroup?.feed.results
                self.games = appGroup
                DispatchQueue.main.async {
                    
                    self.collectionView.reloadData()
                    
                }
            }
        }
    }
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        0
    }
    
    //HEADER
    class CompositionalHeader: UICollectionReusableView {
        
        let label = UILabel(text: "Editor's Choice Games", font: UIFont.boldSystemFont(ofSize: 16))
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(label)
            label.fillSuperview()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    let headerId = "headerId"
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(AppsHeaderCell.self, forCellWithReuseIdentifier: "cellId")
        collectionView.register(AppRowCell.self, forCellWithReuseIdentifier: "smallCellId")
        collectionView.register(CompositionalHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerId)
        collectionView.backgroundColor = .systemBackground
        navigationItem.title = "Apps"
        navigationController?.navigationBar.prefersLargeTitles = true
        //fetchApps()
        setupDiffableDatasource()
    }
    enum AppSection {
        case topSocial
        case grossing
        case freeGames
    }
    lazy var diffableDataSource: UICollectionViewDiffableDataSource<AppSection, AnyHashable> = .init(collectionView: self.collectionView) { (collectionView, indexPath, object) -> UICollectionViewCell? in
        if let object = object as? SocialApp {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath) as! AppsHeaderCell
            cell.app = object
            return cell
        } else if let object = object as? FeedResult {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "smallCellId", for: indexPath) as! AppRowCell
            cell.app = object
            return cell
        }
        return nil
    }
    
    private func setupDiffableDatasource() {
        diffableDataSource.supplementaryViewProvider = .some({ (collectionView, kind, indexPath) -> UICollectionReusableView? in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.headerId, for: indexPath) as! CompositionalHeader
            
            let snapshot = self.diffableDataSource.snapshot()
            if let object = self.diffableDataSource.itemIdentifier(for: indexPath) {
                if let section = snapshot.sectionIdentifier(containingItem: object) {
                    if section == .freeGames {
                        header.label.text = "Games"
                    } else {
                        header.label.text = "Top Grossing"
                    }
                }
            }
            return header
        })
        Service.shared.fetchSocialApps { (socialApps, err) in
            Service.shared.fetchTopGrossing { (appGroup, err) in
                Service.shared.fetchGames { (gamesGroup, err) in
                    var snapshot = self.diffableDataSource.snapshot()
                    
                    //top social
                    snapshot.appendSections([.topSocial, .freeGames, .grossing])
                    snapshot.appendItems(socialApps ?? [], toSection: .topSocial)
                    //top grossing
                    let objects = appGroup?.feed.results ?? []
                    snapshot.appendItems(objects ?? [], toSection: .grossing)
                    snapshot.appendItems(gamesGroup?.feed.results ?? [], toSection: .freeGames)
                    self.diffableDataSource.apply(snapshot)
                }
            }
        }
    }
}

struct AppsView: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<AppsView>) -> UIViewController {
        let controller = CompositionalController()
        return UINavigationController(rootViewController: controller)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<AppsView>) {
        
    }
    
    typealias UIViewControllerType = UIViewController
}

struct AppsCompositionalView_Previews: PreviewProvider {
    static var previews: some View {
        AppsView()
            .edgesIgnoringSafeArea(.all)
    }
}
