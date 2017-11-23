//
//  ViewController.swift
//  LXCarouselViewDemo
//
//  Created by 从今以后 on 2017/11/11.
//  Copyright © 2017年 从今以后. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private var textArray = ["0", "1", "2", "3"]

    @IBOutlet private var pageControl: UIPageControl!
	@IBOutlet private var carouselView: CarouselView!

	override func viewDidLoad() {
		super.viewDidLoad()
        pageControl.numberOfPages = textArray.count
        
        carouselView.reusableViewType = CollectionViewCell.self
        carouselView.reloadData(withNumberOfPages: textArray.count)
	}

    @IBAction func startScrolling() {
        carouselView.startScrolling()
    }

    @IBAction func stopScrolling() {
        carouselView.stopScrolling()
    }

    @IBAction func removeCarouselView() {
        carouselView.removeFromSuperview()
    }

    @IBAction func updateDataSource() {
        if textArray.count == 1 {
            textArray = []
        } else if textArray.count == 0 {
            textArray = ["0", "1", "2", "3"]
        } else {
            textArray = ["就一页"]
        }

        pageControl.numberOfPages = textArray.count
        carouselView.reloadData(withNumberOfPages: textArray.count)
    }
}

extension ViewController: CarouselViewDelegate {

    func carouselView(_ carouselView: CarouselView, willDisplayPage page: Int) {
        print("willDisplayPage \(page)")
    }

    func carouselView(_ carouselView: CarouselView, didDisplayPage page: Int) {
        print("didDisplayPage \(page)")
        pageControl.currentPage = page
    }

    func carouselView(_ carouselView: CarouselView, configure cell: UICollectionViewCell, forPage page: Int) {
        print("configure \(page)")

        if let cell = cell as? CollectionViewCell {
            cell.textLabel.text = textArray[page]
        }
    }

    func carouselView(_ carouselView: CarouselView, didTapPage page: Int) {
        print("didTapPage \(page)")
    }
}

class CollectionViewCell: UICollectionViewCell, CarouselReusableView {
	lazy var textLabel: UILabel = {
		let label = UILabel()
		label.font = UIFont.systemFont(ofSize: 50)
		label.backgroundColor = .cyan
		contentView.backgroundColor = .cyan
		contentView.addSubview(label)
		label.translatesAutoresizingMaskIntoConstraints = false
		label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
		label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
		return label
	}()
}
