//
//  WDImageView.swift
//  PopOn2
//
//  Created by maoqiang on 4/17/19.
//  Copyright © 2019 wordoor. All rights reserved.
//

import UIKit
import SnapKit
import Kingfisher

let kScreenWidth_s = UIScreen.main.bounds.width
let kScreenHeight_s = UIScreen.main.bounds.height


class WDImageView : UIView {

    private var urls:[String]! = [String]() //需要浏览图片Urls集合
    private var imageViews:[WDImageView]!
    private var subImageViews:[UIImageView]! = [UIImageView]()
    private var imageUrl: String!
    
    private var oldframe: CGRect!
    
    private var index:Int!{
        didSet{
            self.currentIndex = index
        }
    }
    private var currentIndex:Int!
    
    /// 查找同一父级目录下的WDImageView
    private func findSameLevelWDImageView() -> (imageViews:[WDImageView]?, urls:[String]?){
        
        var imageViews = [WDImageView]()
        var urls = [String]()
    
        if (self.next?.isKind(of: UIView.self))!{
            let supView: UIView = self.next as! UIView
            var i: Int = 0
            for view in supView.subviews {
                if view.isMember(of: WDImageView.self){
                    weak var imageView: WDImageView? = view as? WDImageView
                    
                    imageViews.append(imageView!)
                    urls.append(imageView!.imageUrl)
                    imageView!.index = i
                    i = i+1
                }
            }
        }
        return (imageViews, urls)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.left.top.right.bottom.equalToSuperview()
        }
    }
    
    /// 设置原图与缩略图
    public func setImage(imageUrl:String!, thumbnailUrl:String!) {
        
        self.imageUrl = imageUrl
        
        // 如果是本地图片则不可预览
        imageView.kf.setImage(with: URL(string: thumbnailUrl), placeholder: UIImage(named: "placeholder"))
        let tap : UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tapAction))
        self.addGestureRecognizer(tap)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 计算缩略图在keyWindow上的frame
        oldframe = self.imageView.convert(self.imageView.frame, to: UIApplication.shared.keyWindow!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 点击浏览
    @objc private func tapAction(){
        
        (self.imageViews, self.urls) = self.findSameLevelWDImageView()
        
        // 添加动画覆盖层
        self.coverimgView.frame = oldframe
        self.coverView.addSubview(coverimgView)
        coverimgView.kf.setImage(with: URL(string: self.imageUrl), placeholder: UIImage(named: "placeholder"))
        UIApplication.shared.keyWindow!.addSubview(coverView)
        self.imageView.alpha = 0
        
        // 放大动画
        UIView.animate(withDuration: 0.3, animations: {
            self.coverimgView.frame = CGRect(x: 0, y: 0, width: kScreenWidth_s, height: kScreenHeight_s)
            UIView.animate(withDuration: 0.1, animations: {
                self.coverView.backgroundColor = UIColor.black
            })
        }) { (complete) in
            self.imageView.alpha = 1
            self.coverView.backgroundColor = UIColor.clear
            self.coverimgView.removeFromSuperview()
            self.coverView.removeFromSuperview()

            // 添加预览页面
            self.layoutScrollView()
        }
    }
    
    /// 点击退出
    @objc private func exitAction(){
        
        for imageView in self.subImageViews! {
            imageView.superview?.removeFromSuperview()
            imageView.removeFromSuperview()
        }
        subImageViews.removeAll()
        self.scrollView.removeFromSuperview()
        self.pageLabel.removeFromSuperview()
        
        let imageView: WDImageView = self.imageViews[currentIndex]
        coverimgView.kf.setImage(with: URL(string: imageView.imageUrl), placeholder: UIImage(named: "placeholder"))
        UIApplication.shared.keyWindow!.addSubview(coverView)
        coverView.addSubview(self.coverimgView)
        imageView.imageView.alpha = 0
        
        UIView.animate(withDuration: 0.3, animations: {
            self.coverimgView.frame = imageView.oldframe
        }) { (complete) in
            imageView.imageView.alpha = 1
            self.coverView.removeFromSuperview()
            self.coverimgView.removeFromSuperview()
        }
    }
    
    /// 添加预览页面
    private func layoutScrollView(){
        
        scrollView.delegate = self
        let keyWindow = UIApplication.shared.keyWindow!
        keyWindow.addSubview(self.scrollView)
        keyWindow.bringSubviewToFront(self.scrollView)
        
        keyWindow.addSubview(self.pageLabel)
        self.pageLabel.text = "\(index+1)/\(urls.count)"
        pageLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(80)
        }
        
        scrollView.contentSize = CGSize(width: kScreenWidth_s * CGFloat(self.urls!.count), height:kScreenHeight_s)
        scrollView.contentOffset = CGPoint(x: kScreenWidth_s * CGFloat(self.index), y: 0)
        
        for (i, url) in self.urls.enumerated() {
            
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: kScreenWidth_s, height: kScreenHeight_s))
            imageView.kf.setImage(with: URL(string: url), placeholder: UIImage(named: "placeholder"))
            imageView.isUserInteractionEnabled = true
            imageView.contentMode = .scaleAspectFit
            
            let scrollView = UIScrollView(frame: CGRect(x: CGFloat(i) * kScreenWidth_s, y: 0, width: kScreenWidth_s, height: kScreenHeight_s))
            scrollView.isPagingEnabled = false
            scrollView.isScrollEnabled = true
            scrollView.backgroundColor = UIColor.black
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.maximumZoomScale = 3;
            scrollView.delegate = self
            scrollView.bouncesZoom = true
            scrollView.bounces = false
            
            let tap : UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(exitAction))
            scrollView.addGestureRecognizer(tap)
            scrollView.addSubview(imageView)
            self.subImageViews.append(imageView)
            
            self.scrollView.addSubview(scrollView)
        }
    }
    
    
    /// 放大时更新subImageView point
    private func centerOfScrollViewContent(scrollView:UIScrollView) -> CGPoint{
        let offsetx = scrollView.frame.size.width > scrollView.contentSize.width ? (scrollView.frame.size.width - scrollView.contentSize.width) * 0.5 : 0.0
        
        let offsety = scrollView.frame.size.height > scrollView.contentSize.height ? (scrollView.frame.size.height - scrollView.contentSize.height) * 0.5 : 0.0
        
        let actualCenter = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetx, y: scrollView.contentSize.height * 0.5 + offsety)
        
        return actualCenter
        
    }
    
    private var coverimgView: UIImageView! = {
        let coverimgView = UIImageView()
        coverimgView.contentMode = .scaleAspectFit
        return coverimgView
    }()
    
    private var coverView:UIView! = {
        let coverView = UIView(frame: CGRect(x: 0, y: 0, width: kScreenWidth_s, height: kScreenHeight_s))
        coverView.backgroundColor = UIColor.clear
        return coverView
    }()
    
    private let imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private var scrollView : UIScrollView = {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: kScreenWidth_s, height: kScreenHeight_s))
        scrollView.isPagingEnabled = true
        scrollView.isScrollEnabled = true
        scrollView.backgroundColor = UIColor.black
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let pageLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont.init(name: "PingFangSC-Regular", size: 16)
        label.textColor = UIColor.white
        return label
    }()
}

extension WDImageView : UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.subImageViews[self.currentIndex]
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView !== self.scrollView {
            let imageView = self.subImageViews[self.currentIndex]
            imageView.center = self.centerOfScrollViewContent(scrollView: scrollView)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView === self.scrollView {
            currentIndex = Int(scrollView.contentOffset.x) / Int(kScreenWidth_s)
            self.pageLabel.text = "\(currentIndex+1)/\(urls.count)"
        }
    }
}
