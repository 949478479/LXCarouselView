//
//  CollectionView.swift
//  LXCarouselView
//
//  Created by 吕小怼 on 2019/3/19.
//  Copyright © 2019 从今以后. All rights reserved.
//

import UIKit

class CollectionView: UICollectionView {

    init(dataSource: UICollectionViewDataSource, delegate: UICollectionViewDelegate) {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.sectionInset = .zero

        super.init(frame: .zero, collectionViewLayout: flowLayout)

        translatesAutoresizingMaskIntoConstraints = false
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        backgroundColor = .white
        isPagingEnabled = true
        bounces = false
        
        self.dataSource = dataSource
        self.delegate = delegate
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var contentInset: UIEdgeInsets {
        set {}
        get { return .zero }
    }

    override var adjustedContentInset: UIEdgeInsets {
        set {}
        get { return .zero }
    }

    override var frame: CGRect {
        didSet {
            (collectionViewLayout as! UICollectionViewFlowLayout).itemSize = frame.size
        }
    }

    override var bounds: CGRect {
        didSet {
            (collectionViewLayout as! UICollectionViewFlowLayout).itemSize = bounds.size
        }
    }
}
