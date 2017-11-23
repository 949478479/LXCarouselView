//
//  CarouselView.swift
//
//  Created by 从今以后 on 2017/11/11.
//  Copyright © 2017年 从今以后. All rights reserved.
//

import UIKit

public protocol CarouselReusableView: AnyObject {
    static var nib: UINib? { get }
    static var reuseIdentifier: String { get }
}

public extension CarouselReusableView {

    static var nib: UINib? {
        return nil
    }

    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}

@objc public protocol CarouselViewDelegate {
    func carouselView(_ carouselView: CarouselView, willDisplayPage page: Int)
    func carouselView(_ carouselView: CarouselView, didDisplayPage page: Int)
    func carouselView(_ carouselView: CarouselView, didTapPage page: Int)
    func carouselView(_ carouselView: CarouselView, configure cell: UICollectionViewCell, forPage page: Int)
}

public class CarouselView: UIView {

    @IBOutlet public weak var delegate: CarouselViewDelegate?
    
    public var reusableViewType: (UICollectionViewCell & CarouselReusableView).Type? {
        didSet {
            guard oldValue != reusableViewType else { return }

            if let reuseIdentifier = reuseIdentifier {
                if let _ = reusableViewType?.nib {
                    collectionView.register(UINib?.none, forCellWithReuseIdentifier: reuseIdentifier)
                } else {
                    collectionView.register(AnyClass?.none, forCellWithReuseIdentifier: reuseIdentifier)
                }
            }

            guard let reusableViewType = reusableViewType else {
                reuseIdentifier = nil
                return
            }

            reuseIdentifier = reusableViewType.reuseIdentifier

            if let nib = reusableViewType.nib {
                collectionView.register(nib, forCellWithReuseIdentifier: reusableViewType.reuseIdentifier)
            } else {
                collectionView.register(reusableViewType, forCellWithReuseIdentifier: reusableViewType.reuseIdentifier)
            }
        }
    }

    private var reuseIdentifier: String?

	/// 滚动时间间隔，默认 3s。
	public var scrollInterval: TimeInterval = 3 {
        didSet {
            precondition(scrollInterval > scrollDuration && scrollInterval > prefetchingDuration)
            restartTimer()
        }
	}

    /// 预加载提前量，默认 0.1s。
    public var prefetchingDuration: TimeInterval = 0.1 {
        didSet {
            precondition(prefetchingDuration < scrollInterval)
            restartTimer()
        }
    }

    private var actualScrollInterval: TimeInterval {
        return scrollInterval - prefetchingDuration
    }

	/// 滚动动画持续时间，默认 0.5s。
	public var scrollDuration: TimeInterval = 0.5 {
		didSet {
            precondition(scrollDuration < actualScrollInterval)
		}
	}

    private var numberOfPages = 0 {
        didSet {
            switch numberOfPages {
            case 2...:
                numberOfItems = numberOfPages + 2
                currentPage = 0
                currentItem = IndexPath(item: 1, section: 0)
            case 1:
                numberOfItems = 1
                currentPage = 0
                currentItem = IndexPath(item: 0, section: 0)
            case 0:
                numberOfItems = 0
                currentPage = nil
                currentItem = nil
            default:
                fatalError()
            }
        }
    }

    private var numberOfItems = 0
    private var currentPage: Int?
    private var currentItem: IndexPath?
    private var willDisplayPageCallback: ((_ page: Int) -> Void)?

    private var isScrolling = false
    private var isAutoScroll = false
    private var snapshotView: UIView?
    private let scrollAnimationKey = "ScrollAnimationKey"

    private var isTimerInited = false
    private var isTimerSuspended = true
    private lazy var timer: DispatchSourceTimer = {
        defer { isTimerInited = true }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.setEventHandler { [weak self] in self?.performScrollAnimation() }
        return timer
    }()

    private lazy var collectionView = CollectionView(dataSource: self.proxy, delegate: self.proxy)

    private lazy var proxy = Proxy(target: self)

    // MARK: - 初始化
    deinit {
        cancelTimer()
    }

	override init(frame: CGRect) {
		super.init(frame: frame)
		addCollectionView()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		addCollectionView()
	}
}

// MARK: - 添加视图
private extension CarouselView {

	func addCollectionView() {
		addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        collectionView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
		collectionView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
	}
}

// MARK: - 定时器
extension CarouselView {

    private func resumeTimer() {
        guard isTimerSuspended else { return }

        isTimerSuspended = false
        timer.schedule(deadline: .now() + actualScrollInterval, repeating: actualScrollInterval)
        timer.resume()
    }

    private func suspendTimer() {
        guard !isTimerSuspended else { return }

        isTimerSuspended = true
        timer.suspend()
    }

    private func restartTimer() {
        guard isAutoScroll else{ return }

        suspendTimer()
        resumeTimer()
    }

    private func cancelTimer() {
        guard isTimerInited else { return }

        timer.cancel()

        if isTimerSuspended {
            timer.resume()
        }
    }

    public override func willMove(toWindow newWindow: UIWindow?) {
        guard newWindow == nil else { return }
        suspendTimer()
    }

    public override func didMoveToWindow() {
        guard isAutoScroll, window != nil else { return }
        resumeTimer()
    }
}

// MARK: - 滚动动画
private extension CarouselView {

    @objc func performScrollAnimation() {
        guard !isScrolling else { return }
        guard let snapshotView = collectionView.snapshotView(afterScreenUpdates: false) else { return }

        isScrolling = true

        self.snapshotView = snapshotView
        snapshotView.frame = collectionView.frame
        snapshotView.transform = CGAffineTransform(translationX: -snapshotView.frame.width, y: 0)
        addSubview(snapshotView)

        collectionView.contentOffset.x += collectionView.bounds.width

        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fillMode = .backwards
        animation.duration = scrollDuration
        animation.beginTime = CACurrentMediaTime() + prefetchingDuration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        animation.fromValue = 0
        snapshotView.layer.add(animation, forKey: scrollAnimationKey)

        animation.delegate = proxy
        animation.fromValue = collectionView.bounds.width
        collectionView.layer.add(animation, forKey: scrollAnimationKey)
    }

    func removeSnapshotView() {
        snapshotView?.removeFromSuperview()
        snapshotView = nil
    }
}

// MARK: - 滚动处理
public extension CarouselView {

    func startScrolling() {
        guard !isAutoScroll, numberOfPages > 1 else { return }

        isAutoScroll = true

        if window != nil {
            resumeTimer()
        }
    }

    func stopScrolling() {
        guard isAutoScroll else { return }

        isAutoScroll = false
        removeScrollAnimation()
        suspendTimer()
    }

    private func removeScrollAnimation() {
        snapshotView?.layer.removeAnimation(forKey: scrollAnimationKey)
        collectionView.layer.removeAnimation(forKey: scrollAnimationKey)
    }

    private func handleWillBeginDragging() {
        suspendTimer()
    }

    private func handleDidEndScrolling() {
        adjustContentOffsetIfNeeded()
        updateCurrentItemAndPage()

        delegate?.carouselView(self, didDisplayPage: currentPage!)

        if isAutoScroll {
            resumeTimer()
        }
    }

    private func adjustContentOffsetIfNeeded() {
        let contentOffsetX = collectionView.contentOffset.x
        let contentWidth = collectionView.contentSize.width
        let collectionViewWidth = collectionView.bounds.width

        if contentOffsetX >= contentWidth - collectionViewWidth {
            collectionView.contentOffset.x = collectionViewWidth
        } else if contentOffsetX <= 0 {
            collectionView.contentOffset.x = contentWidth - 2 * collectionViewWidth
        }
    }

    private func updateCurrentItemAndPage() {
        let pageWidth = collectionView.bounds.width
        let contentWidth = collectionView.contentSize.width
        let contentOffset = collectionView.contentOffset.x
        let item = Int(contentOffset.truncatingRemainder(dividingBy: contentWidth) / pageWidth)
        let indexPath = IndexPath(item: item, section: 0)

        currentItem = indexPath
        currentPage = page(for: indexPath)
    }
}

// MARK: - 刷新内容
public extension CarouselView {

    func reloadData(withNumberOfPages num: Int) {
        stopScrolling()

        numberOfPages = num

        self.willDisplayPageCallback = { [weak self] page in
            guard let `self` = self else { return }

            if page == 0 {
                self.willDisplayPageCallback = nil
                self.delegate?.carouselView(self, didDisplayPage: 0)
            }
        }

        DispatchQueue.main.async {
            self.collectionView.reloadData()
            
            if num > 1 {
                DispatchQueue.main.async {
                    self.collectionView.contentOffset.x = self.collectionView.frame.width
                }
            }
        }
    }
}

// MARK: - 辅助方法
private extension CarouselView {

    func page(for indexPath: IndexPath) -> Int {
        switch indexPath.item {
        case 0:
            return numberOfPages - 1
        case numberOfItems - 1:
            return 0
        default:
            return indexPath.item - 1
        }
    }
}

// MARK: - UICollectionViewDataSource
extension CarouselView {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return numberOfItems
	}

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier!, for: indexPath)
	}
}

// MARK: - UICollectionViewDelegate
extension CarouselView {

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let page = self.page(for: indexPath)
        delegate?.carouselView(self, willDisplayPage: page)
        delegate?.carouselView(self, configure: cell, forPage: page)
        willDisplayPageCallback?(page)
    }

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let delegate = delegate else { return }
        delegate.carouselView(self, didTapPage: page(for: indexPath))
	}
}

// MARK: - UIScrollViewDelegate
extension CarouselView {

	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		handleWillBeginDragging()
	}

	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		if decelerate {
			isUserInteractionEnabled = false
		} else {
			handleDidEndScrolling()
		}
	}

	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		isUserInteractionEnabled = true
        handleDidEndScrolling()
	}
}

// MARK: - CAAnimationDelegate
extension CarouselView {

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
		isScrolling = false
        removeSnapshotView()
		handleDidEndScrolling()
	}
}

extension CarouselView: PublicProtocolProxy {}
