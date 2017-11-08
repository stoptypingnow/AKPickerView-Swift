//
//  AKPickerView.swift
//  AKPickerView
//
//  Created by Akio Yasui on 1/29/15.
//  Copyright (c) 2015 Akkyie Y. All rights reserved.
//

import UIKit

/**
 Styles of AKPickerView.
 
 - Wheel: Style with 3D appearance like UIPickerView.
 - Flat:  Flat style.
 */
public enum AKPickerViewStyle {
    case wheel
    case flat
}

// MARK: - Protocols
// MARK: AKPickerViewDataSource
/**
 Protocols to specify the number and type of contents.
 */
@objc public protocol AKPickerViewDataSource {
    func numberOfItemsInPickerView(_ pickerView: AKPickerView) -> Int
    func pickerView(_ pickerView: AKPickerView, titleForItem: Int) -> String?
    func pickerView(_ pickerView: AKPickerView, imageForItem: Int) -> UIImage?
}

//extension AKPickerViewDataSource {
//    func pickerView(_ pickerView: AKPickerView, titleForItem: Int) -> String? {
//        return nil
//    }
//    func pickerView(_ pickerView: AKPickerView, imageForItem: Int) -> UIImage? {
//        return nil
//    }
//}

// MARK: AKPickerViewDelegate
/**
 Protocols to specify the attitude when user selected an item,
 and customize the appearance of labels.
 */
@objc public protocol AKPickerViewDelegate: UIScrollViewDelegate {
    func pickerView(_ pickerView: AKPickerView, didSelectItem: Int)
    func pickerView(_ pickerView: AKPickerView, marginForItem: Int) -> CGSize
    func pickerView(_ pickerView: AKPickerView, configureLabel label: UILabel, forItem item: Int)
    func pickerView(_ pickerView: AKPickerView, willScrollToItem: Int)
}

//extension AKPickerViewDelegate {
//    func pickerView(_ pickerView: AKPickerView, didSelectItem: Int) {
//        return;
//    }
//    func pickerView(_ pickerView: AKPickerView, marginForItem: Int) -> CGSize {
//        return CGSize(width: 0.0, height: 0.0);
//    }
//    func pickerView(_ pickerView: AKPickerView, configureLabel label: UILabel, forItem item: Int) {
//        return;
//    }
//    func pickerView(_ pickerView: AKPickerView, willScrollToItem: Int) {
//        return;
//    }
//}

// MARK: - Private Classes and Protocols
// MARK: AKCollectionViewLayoutDelegate
/**
 Private. Used to deliver the style of the picker.
 */
private protocol AKCollectionViewLayoutDelegate {
    func pickerViewStyleForCollectionViewLayout(_ layout: AKCollectionViewLayout) -> AKPickerViewStyle
}

// MARK: AKCollectionViewCell
/**
 Private. A subclass of UICollectionViewCell used in AKPickerView's collection view.
 */
private class AKCollectionViewCell: UICollectionViewCell {
    var label: UILabel!
    var imageView: UIImageView!
    var font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    var highlightedFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    var attributedText: NSAttributedString? {
        didSet {
            self.label.attributedText = attributedText
        }
    }
    
    override var isSelected: Bool {
        didSet {
            //            let animation = CATransition()
            //            animation.type = kCATransitionFade
            //            animation.duration = 0.15
            //            self.label.layer.add(animation, forKey: "")
            self.label.font = isSelected ? highlightedFont : font
            self.label.isHighlighted = isSelected
        }
    }
    
    
    func initialize() {
        self.layer.isDoubleSided = false
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        
        self.label = UILabel(frame: self.contentView.bounds)
        self.label.backgroundColor = UIColor.clear
        self.label.textAlignment = .center
        self.label.textColor = UIColor.gray
        self.label.numberOfLines = 1
        self.label.lineBreakMode = .byTruncatingTail
        self.label.highlightedTextColor = UIColor.black
        self.label.font = self.font
        self.label.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleBottomMargin, .flexibleRightMargin]
        self.contentView.addSubview(self.label)
        
        self.imageView = UIImageView(frame: self.contentView.bounds)
        self.imageView.backgroundColor = UIColor.clear
        self.imageView.contentMode = .center
        self.imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.contentView.addSubview(self.imageView)
    }
    
    init() {
        super.init(frame: CGRect.zero)
        self.initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialize()
    }
    
    required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize()
    }
}

// MARK: AKCollectionViewLayout
/**
 Private. A subclass of UICollectionViewFlowLayout used in the collection view.
 */
private class AKCollectionViewLayout: UICollectionViewFlowLayout {
    var delegate: AKCollectionViewLayoutDelegate!
    var width: CGFloat!
    var midX: CGFloat!
    var maxAngle: CGFloat!
    
    func initialize() {
        self.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
        self.scrollDirection = .horizontal
        self.minimumLineSpacing = 0.0
    }
    
    override init() {
        super.init()
        self.initialize()
    }
    
    required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize()
    }
    
    fileprivate override func prepare() {
        let visibleRect = CGRect(origin: self.collectionView!.contentOffset, size: self.collectionView!.bounds.size)
        self.midX = visibleRect.midX;
        self.width = visibleRect.width / 2;
        self.maxAngle = .pi / 2
    }
    
    fileprivate override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    fileprivate override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if let attributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes {
            switch self.delegate.pickerViewStyleForCollectionViewLayout(self) {
            case .flat:
                return attributes
            case .wheel:
                let distance = attributes.frame.midX - self.midX;
                let currentAngle = self.maxAngle * distance / self.width / (.pi / 2);
                var transform = CATransform3DIdentity;
                transform = CATransform3DTranslate(transform, -distance, 0, -self.width);
                transform = CATransform3DRotate(transform, currentAngle, 0, 1, 0);
                transform = CATransform3DTranslate(transform, 0, 0, self.width);
                attributes.transform3D = transform;
                attributes.alpha = fabs(currentAngle) < self.maxAngle ? 1.0 : 0.0;
                return attributes;
            }
        }
        
        return nil
    }
    
    fileprivate override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        switch self.delegate.pickerViewStyleForCollectionViewLayout(self) {
        case .flat:
            return super.layoutAttributesForElements(in: rect)
        case .wheel:
            var attributes = [UICollectionViewLayoutAttributes]()
            if self.collectionView!.numberOfSections > 0 {
                for i in 0 ..< self.collectionView!.numberOfItems(inSection: 0) {
                    let indexPath = IndexPath(item: i, section: 0)
                    attributes.append(self.layoutAttributesForItem(at: indexPath)!)
                }
            }
            return attributes
        }
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        var offsetAdjustment: CGFloat = CGFloat.greatestFiniteMagnitude
        let horizontalCenter: CGFloat = proposedContentOffset.x + (self.collectionView!.bounds.width / 2.0)
        let targetRect = CGRect(x: proposedContentOffset.x, y: 0.0, width: self.collectionView!.bounds.size.width, height: self.collectionView!.bounds.size.height)
        let array:[UICollectionViewLayoutAttributes] = self.layoutAttributesForElements(in: targetRect)!
        for layoutAttributes: UICollectionViewLayoutAttributes in array {
            let itemHorizontalCenter: CGFloat = layoutAttributes.center.x
            if abs(itemHorizontalCenter - horizontalCenter) < abs(offsetAdjustment) {
                offsetAdjustment = itemHorizontalCenter - horizontalCenter
            }
        }
        return CGPoint(x: proposedContentOffset.x + offsetAdjustment, y: proposedContentOffset.y)
    }
}

// MARK: AKPickerViewDelegateIntercepter
/**
 Private. Used to hook UICollectionViewDelegate and throw it AKPickerView,
 and if it conforms to UIScrollViewDelegate, also throw it to AKPickerView's delegate.
 */
private class AKPickerViewDelegateIntercepter: NSObject, UICollectionViewDelegate {
    weak var pickerView: AKPickerView?
    weak var delegate: UIScrollViewDelegate?
    
    init(pickerView: AKPickerView, delegate: UIScrollViewDelegate?) {
        self.pickerView = pickerView
        self.delegate = delegate
    }
    
    fileprivate override func forwardingTarget(for aSelector: Selector) -> Any? {
        if self.pickerView!.responds(to: aSelector) {
            return self.pickerView
        } else if self.delegate != nil && self.delegate!.responds(to: aSelector) {
            return self.delegate
        } else {
            return nil
        }
    }
    
    fileprivate override func responds(to aSelector: Selector) -> Bool {
        if self.pickerView!.responds(to: aSelector) {
            return true
        } else if self.delegate != nil && self.delegate!.responds(to: aSelector) {
            return true
        } else {
            return super.responds(to: aSelector)
        }
    }
    
}

// MARK: - AKPickerView
// TODO: Make these delegate conformation private
/**
 Horizontal picker view. This is just a subclass of UIView, contains a UICollectionView.
 */
public class AKPickerView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, AKCollectionViewLayoutDelegate {
    
    // MARK: - Properties
    // MARK: Readwrite Properties
    /// Readwrite. Data source of picker view.
    @IBOutlet public weak var dataSource: AKPickerViewDataSource? = nil
    /// Readwrite. Delegate of picker view.
    @IBOutlet public weak var delegate: AKPickerViewDelegate? = nil {
        didSet {
            self.intercepter.delegate = delegate
        }
    }
    
    /// Readwrite. Kerning for all cells.
    public lazy var kerning = 1.0
    
    /// Readwrite. A font which used in NOT selected cells.
    public lazy var font = UIFont.systemFont(ofSize: 20)
    
    /// Readwrite. A font which used in selected cells.
    public lazy var highlightedFont = UIFont.boldSystemFont(ofSize: 20)
    
    /// Readwrite. A color of the text on NOT selected cells.
    @IBInspectable public lazy var textColor: UIColor = UIColor.darkGray
    
    /// Readwrite. A color of the text on selected cells.
    @IBInspectable public lazy var highlightedTextColor: UIColor = UIColor.black
    
    /// Readwrite. A float value which indicates the spacing between cells.
    @IBInspectable public var interitemSpacing: CGFloat = 0.0
    
    /// Readwrite. The style of the picker view. See AKPickerViewStyle.
    public var pickerViewStyle = AKPickerViewStyle.wheel
    
    /// Readwrite. The scroll direction of the picker view.
    /// Note vertical isn't implemented for 'wheel' style picker yet.
    public var pickerScrollDirection = UICollectionViewScrollDirection.horizontal {
        didSet {
            collectionViewLayout.scrollDirection = pickerScrollDirection
            collectionViewLayout.invalidateLayout()
        }
    }
    
    /// Readwrite. A float value which determines the perspective representation which used when using AKPickerViewStyle.Wheel style.
    @IBInspectable public var viewDepth: CGFloat = 1000.0 {
        didSet {
            self.collectionView.layer.sublayerTransform = self.viewDepth > 0.0 ? {
                var transform = CATransform3DIdentity;
                transform.m34 = -1.0 / self.viewDepth;
                return transform;
                }() : CATransform3DIdentity;
        }
    }
    /// Readwrite. A boolean value indicates whether the mask is disabled.
    @IBInspectable public var maskDisabled: Bool! = nil {
        didSet {
            self.collectionView.layer.mask = self.maskDisabled == true ? nil : {
                let maskLayer = CAGradientLayer()
                maskLayer.frame = self.collectionView.bounds
                maskLayer.colors = [
                    UIColor.clear.cgColor,
                    UIColor.black.cgColor,
                    UIColor.black.cgColor,
                    UIColor.clear.cgColor]
                maskLayer.locations = [0.0, 0.33, 0.66, 1.0]
                maskLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
                maskLayer.endPoint = CGPoint(x: 1.0, y: 0.0)
                return maskLayer
                }()
        }
    }
    
    public var showsVerticalScrollIndicator: Bool = true {
        didSet {
            self.collectionView.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        }
    }
    
    // MARK: Readonly Properties
    /// Readonly. Index of currently selected item.
    public private(set) var selectedItem: Int = 0
    /// Readonly. The point at which the origin of the content view is offset from the origin of the picker view.
    public var contentOffset: CGPoint {
        get {
            return self.collectionView.contentOffset
        }
    }
    
    // MARK: Private Properties
    /// Private. A UICollectionView which shows contents on cells.
    fileprivate var collectionView: UICollectionView!
    /// Private. An intercepter to hook UICollectionViewDelegate then throw it picker view and its delegate
    fileprivate var intercepter: AKPickerViewDelegateIntercepter!
    /// Private. A UICollectionViewFlowLayout used in picker view's collection view.
    fileprivate lazy var collectionViewLayout: AKCollectionViewLayout = {
        let layout = AKCollectionViewLayout()
        layout.delegate = self
        return layout
    }()
    
    // MARK: - Functions
    // MARK: View Lifecycle
    /**
     Private. Initializes picker view's subviews and friends.
     */
    fileprivate func initialize() {
        self.collectionView?.removeFromSuperview()
        self.collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: self.collectionViewLayout)
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.backgroundColor = UIColor.clear
        self.collectionView.decelerationRate = UIScrollViewDecelerationRateNormal
        self.collectionView.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        self.collectionView.dataSource = self
        self.collectionView.register(
            AKCollectionViewCell.self,
            forCellWithReuseIdentifier: NSStringFromClass(AKCollectionViewCell.self))
        self.addSubview(self.collectionView)
        
        self.intercepter = AKPickerViewDelegateIntercepter(pickerView: self, delegate: self.delegate)
        self.collectionView.delegate = self.intercepter
        
        self.maskDisabled = self.maskDisabled == nil ? false : self.maskDisabled
    }
    
    public init() {
        super.init(frame: CGRect.zero)
        self.initialize()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialize()
    }
    
    public required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize()
    }
    
    deinit {
        self.collectionView.delegate = nil
    }
    
    // MARK: Layout
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if self.dataSource != nil && self.dataSource!.numberOfItemsInPickerView(self) > 0 {
            self.collectionView.collectionViewLayout = self.collectionViewLayout
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.scrollToItem(self.selectedItem, animated: false)
        }
        self.collectionView.layer.mask?.frame = self.collectionView.bounds
    }
    
    open override var intrinsicContentSize : CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: max(self.font.lineHeight, self.highlightedFont.lineHeight))
    }
    
    // MARK: Calculation Functions
    
    /**
     Private. Used to calculate bounding size of given string with picker view's font and highlightedFont
     
     :param: string A NSString to calculate size
     :returns: A CGSize which contains given string just.
     */
    fileprivate func sizeForString(_ string: NSString) -> CGSize {
        let size = string.size(attributes: [NSFontAttributeName: self.font, NSKernAttributeName: self.kerning])
        let highlightedSize = string.size(attributes: [NSFontAttributeName: self.highlightedFont, NSKernAttributeName: self.kerning])
        return CGSize(
            width: ceil(max(size.width, highlightedSize.width)),
            height: ceil(max(size.height, highlightedSize.height)))
    }
    
    /**
     Private. Used to calculate the x-coordinate of the content offset of specified item.
     
     :param: item An integer value which indicates the index of cell.
     :returns: An x-coordinate of the cell whose index is given one.
     */
    fileprivate func offsetForItem(_ item: Int) -> CGFloat {
        var offset: CGFloat = 0
        for i in 0 ..< item {
            let indexPath = IndexPath(item: i, section: 0)
            let cellSize = self.collectionView(
                self.collectionView,
                layout: self.collectionView.collectionViewLayout,
                sizeForItemAt: indexPath)
            if collectionViewLayout.scrollDirection == .horizontal {
                offset += cellSize.width
            }
            else {
                offset += cellSize.height
            }
        }
        
        let firstIndexPath = IndexPath(item: 0, section: 0)
        let firstSize = self.collectionView(
            self.collectionView,
            layout: self.collectionView.collectionViewLayout,
            sizeForItemAt: firstIndexPath)
        let selectedIndexPath = IndexPath(item: item, section: 0)
        let selectedSize = self.collectionView(
            self.collectionView,
            layout: self.collectionView.collectionViewLayout,
            sizeForItemAt: selectedIndexPath)
        if collectionViewLayout.scrollDirection == .horizontal {
            offset -= (firstSize.width - selectedSize.width) / 2.0
        }
        else {
            offset -= (firstSize.height - selectedSize.height) / 2.0
        }
        
        return offset
    }
    
    // MARK: View Controls
    /**
     Reload the picker view's contents and styles. Call this method always after any property is changed.
     */
    public func reloadData() {
        self.invalidateIntrinsicContentSize()
        self.collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.reloadData()
        if self.dataSource != nil && self.dataSource!.numberOfItemsInPickerView(self) > 0 {
            self.selectItem(self.selectedItem, animated: false, notifySelection: false)
        }
    }
    
    /**
     Move to the cell whose index is given one without selection change.
     
     :param: item     An integer value which indicates the index of cell.
     :param: animated True if the scrolling should be animated, false if it should be immediate.
     */
    public func scrollToItem(_ item: Int, animated: Bool = false) {
        switch self.pickerViewStyle {
        case .flat:
            let scrollPosition: UICollectionViewScrollPosition
            if collectionViewLayout.scrollDirection == .horizontal {
                scrollPosition = .centeredHorizontally
            }
            else {
                scrollPosition = .centeredVertically
            }
            self.collectionView.scrollToItem(
                at: IndexPath(
                    item: item,
                    section: 0),
                at: scrollPosition,
                animated: animated)
        case .wheel:
            self.collectionView.setContentOffset(
                CGPoint(
                    x: self.offsetForItem(item),
                    y: self.collectionView.contentOffset.y),
                animated: animated)
        }
    }
    
    /**
     Select a cell whose index is given one and move to it.
     
     :param: item     An integer value which indicates the index of cell.
     :param: animated True if the scrolling should be animated, false if it should be immediate.
     */
    public func selectItem(_ item: Int, animated: Bool = false) {
        self.selectItem(item, animated: animated, notifySelection: true)
    }
    
    /**
     Private. Select a cell whose index is given one and move to it, with specifying whether it calls delegate method.
     
     :param: item            An integer value which indicates the index of cell.
     :param: animated        True if the scrolling should be animated, false if it should be immediate.
     :param: notifySelection True if the delegate method should be called, false if not.
     */
    public func selectItem(_ item: Int, animated: Bool, notifySelection: Bool) {
        guard self.dataSource!.numberOfItemsInPickerView(self) > item else { return }
        
        self.collectionView.selectItem(
            at: IndexPath(item: item, section: 0),
            animated: animated,
            scrollPosition: UICollectionViewScrollPosition())
        self.scrollToItem(item, animated: animated)
        self.selectedItem = item
        if notifySelection {
            self.delegate?.pickerView(self, didSelectItem: item)
        }
    }
    
    // MARK: Delegate Handling
    /**
     Private.
     */
    fileprivate func didEndScrolling() {
        switch self.pickerViewStyle {
        case .flat:
            let center = self.convert(self.collectionView.center, to: self.collectionView)
            if let indexPath = self.collectionView.indexPathForItem(at: center) {
                self.selectItem(indexPath.item, animated: true, notifySelection: true)
            }
        case .wheel:
            if let numberOfItems = self.dataSource?.numberOfItemsInPickerView(self) {
                for i in 0 ..< numberOfItems {
                    let indexPath = IndexPath(item: i, section: 0)
                    let cellSize = self.collectionView(
                        self.collectionView,
                        layout: self.collectionView.collectionViewLayout,
                        sizeForItemAt: indexPath)
                    if self.offsetForItem(i) + cellSize.width / 2 > self.collectionView.contentOffset.x {
                        self.selectItem(i, animated: true, notifySelection: true)
                        break
                    }
                }
            }
        }
    }
    
    // MARK: UICollectionViewDataSource
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.dataSource != nil && self.dataSource!.numberOfItemsInPickerView(self) > 0 ? 1 : 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource != nil ? self.dataSource!.numberOfItemsInPickerView(self) : 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(AKCollectionViewCell.self), for: indexPath) as! AKCollectionViewCell
        if let title = self.dataSource?.pickerView(self, titleForItem: indexPath.item) {
            cell.label.text = title
            cell.label.textColor = self.textColor
            cell.label.highlightedTextColor = self.highlightedTextColor
            cell.label.font = self.font
            cell.font = self.font
            cell.highlightedFont = self.highlightedFont
            
            let mutableAttributedText = NSMutableAttributedString(string: title)
            let textRange = NSMakeRange(0, mutableAttributedText.length)
            mutableAttributedText.addAttribute(NSKernAttributeName, value: kerning, range: textRange)
            cell.attributedText = mutableAttributedText
            
            cell.label.bounds = CGRect(origin: CGPoint.zero, size: self.sizeForString(title as NSString))
            if let delegate = self.delegate {
                delegate.pickerView(self, configureLabel: cell.label, forItem: indexPath.item)
                let margin = delegate.pickerView(self, marginForItem: indexPath.item);
                cell.label.frame = cell.label.frame.insetBy(dx: -margin.width, dy: -margin.height)
            }
        } else if let image = self.dataSource?.pickerView(self, imageForItem: indexPath.item) {
            cell.imageView.image = image
        }
        cell.isSelected = (indexPath.item == self.selectedItem)
        return cell
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if self.collectionViewLayout.scrollDirection == .horizontal {
            var maxHeight = collectionView.frame.height - collectionView.contentInset.top - collectionView.contentInset.bottom
            guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout  else { return CGSize.zero }
            maxHeight = maxHeight - flowLayout.sectionInset.top - flowLayout.sectionInset.bottom
            
            var size = CGSize(width: self.interitemSpacing, height: collectionView.bounds.size.height)
            if let title = self.dataSource?.pickerView(self, titleForItem: indexPath.item) {
                size.width += self.sizeForString(title as NSString).width
                 if let delegate = self.delegate {
                    let margin = delegate.pickerView(self, marginForItem: indexPath.item)
                    size.width += margin.width * 2
                }
            } else if let image = self.dataSource?.pickerView(self, imageForItem: indexPath.item) {
                size.width += image.size.width
            }
            return size
        }
        else {
            var maxWidth = collectionView.frame.width - collectionView.contentInset.left - collectionView.contentInset.right
            guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout  else { return CGSize.zero }
            maxWidth = maxWidth - flowLayout.sectionInset.left - flowLayout.sectionInset.right
            
            var size = CGSize(width: maxWidth, height: self.interitemSpacing)
            if let title = self.dataSource?.pickerView(self, titleForItem: indexPath.item) {
                size.height += self.sizeForString(title as NSString).height
                if let delegate = self.delegate {
                    let margin = delegate.pickerView(self, marginForItem: indexPath.item)
                    size.height += margin.height * 2
                }
            } else if let image = self.dataSource?.pickerView(self, imageForItem: indexPath.item) {
                size.height += image.size.height
            }
            return size
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let number = self.collectionView(collectionView, numberOfItemsInSection: section)
        let firstIndexPath = IndexPath(item: 0, section: section)
        let firstSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: firstIndexPath)
        let lastIndexPath = IndexPath(item: number - 1, section: section)
        let lastSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: lastIndexPath)
        
        if self.collectionViewLayout.scrollDirection == .horizontal {
            return UIEdgeInsetsMake(
                0, (collectionView.bounds.size.width - firstSize.width) / 2,
                0, (collectionView.bounds.size.width - lastSize.width) / 2
            )
        }
        else {
            return UIEdgeInsetsMake((collectionView.bounds.size.height - firstSize.height) / 2, 0,
                                    (collectionView.bounds.size.height - lastSize.height) / 2, 0)
        }
    }
    
    // MARK: UICollectionViewDelegate
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectItem(indexPath.item, animated: true)
        delegate?.pickerView(self, willScrollToItem: indexPath.item)
    }
    
    // MARK: UIScrollViewDelegate
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.delegate?.scrollViewDidEndDecelerating?(scrollView)
        self.didEndScrolling()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.delegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
        if !decelerate {
            self.didEndScrolling()
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.delegate?.scrollViewDidScroll?(scrollView)
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        self.collectionView.layer.mask?.frame = self.collectionView.bounds
        CATransaction.commit()
    }

// Removed this to fix bounce back issues when scrolling
//    public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
//                                          withVelocity velocity: CGPoint,
//                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {
//
//        if collectionViewLayout.scrollDirection == .horizontal {
//            let newCollectionViewCenter = CGPoint(x: targetContentOffset.pointee.x + collectionView.frame.width / 2.0, y: targetContentOffset.pointee.y)
//
//            guard let indexPath = self.collectionView.indexPathForItem(at: newCollectionViewCenter),
//                let cell = collectionView.cellForItem(at: indexPath) else { return }
//
//            self.delegate?.pickerView?(self, willScrollToItem: indexPath.item)
//            let cellCenter = cell.center
//            let newOffset = CGPoint(x: cellCenter.x - collectionView.frame.width / 2.0, y: 0.0)
//            targetContentOffset.pointee = newOffset
//        }
//        else {
//            let newCollectionViewCenter = CGPoint(x: targetContentOffset.pointee.x + collectionView.frame.width / 2.0,
//                                                  y: targetContentOffset.pointee.y + collectionView.frame.height / 2.0)
//
//            guard let indexPath = self.collectionView.indexPathForItem(at: newCollectionViewCenter),
//                let cell = collectionView.cellForItem(at: indexPath) else { return }
//
//            delegate?.pickerView?(self, willScrollToItem: indexPath.item)
//            let cellCenter = cell.center
//            let newOffset = CGPoint(x: cellCenter.x - collectionView.frame.width / 2.0,
//                                    y: cellCenter.y - collectionView.frame.height / 2.0)
//            targetContentOffset.pointee = newOffset
//        }
//    }
    
    // MARK: AKCollectionViewLayoutDelegate
    fileprivate func pickerViewStyleForCollectionViewLayout(_ layout: AKCollectionViewLayout) -> AKPickerViewStyle {
        return self.pickerViewStyle
    }
    
}

