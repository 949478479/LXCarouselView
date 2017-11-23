# LXCarouselView

利用 UICollectionView 实现的轮播图，可通过 UICollectionViewCell 自定义内容。

```
pod 'LXCarouselView'
```

```swift
import LXCarouselView

class CollectionViewCell: UICollectionViewCell, CarouselReusableView {
    // ...
}

class ViewController: UIViewController {

    private let textList = ["0", "1", "2", "3"]

    @IBOutlet private var pageControl: UIPageControl!
    @IBOutlet private var carouselView: CarouselView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageControl.numberOfPages = textArray.count
        
        carouselView.reusableViewType = CollectionViewCell.self
        carouselView.reloadData(withNumberOfPages: textList.count)
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
	
    func carouselView(_ carouselView: CarouselView, didTapPage page: Int) {
        print("didTapPage \(page)")
    }
    
    func carouselView(_ carouselView: CarouselView, configure cell: UICollectionViewCell, forPage page: Int) {
        print("configure \(page)")

        if let cell = cell as? CollectionViewCell {
            // 配置内容。。。
        }
    }
}
```
