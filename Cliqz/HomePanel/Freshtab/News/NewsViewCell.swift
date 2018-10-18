//
//  NewsViewCell.swift
//  Client
//
//  Created by Sahakyan on 1/26/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
import SnapKit
import RxSwift

class NewsCellViewModel {
	let url: String
	let title: NSAttributedString
	var logoURL: String?
	var logo: Variable<UIImage?>
	var logoInfo: Variable<LogoInfo?>
	
	init(_ news: News) {
		if let d = news.domain {
			url = d
			logoURL = "http://www.\(d)"
		} else if let t = news.title {
			url = t
		} else {
			url = ""
		}
		let fullTitle = NSMutableAttributedString()
        let customAttributes = NewsCellViewModel.getCustomLabelAttributes()
        
		if news.isBreaking ?? false,
			let t = news.breakingLabel {
			fullTitle.append(NSAttributedString(string: t.uppercased() + ": ", attributes: customAttributes))
		} else if let locallbl = news.localLabel {
			fullTitle.append(NSAttributedString(string: locallbl.uppercased() + ": ", attributes: customAttributes))
		}
		if let shortTitle = news.shortTitle {
			fullTitle.append(NSAttributedString(string: shortTitle))
		} else if let t = news.title {
			fullTitle.append(NSAttributedString(string: t))
		}
		title = fullTitle
		logo = Variable(nil)
		logoInfo = Variable(nil)
	}
    
    private class func getCustomLabelAttributes() -> [NSAttributedStringKey : Any] {
        
        let customAttributes = [NSAttributedStringKey.foregroundColor: UIColor.cliqzBluePrimary,
                                NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 16)]
        
        return customAttributes
    }
}

class NewsViewCell: ClickableUITableViewCell {
	private let disposeBag = DisposeBag()

	var viewModel: NewsCellViewModel? {
		didSet {
			self.titleLabel.attributedText = viewModel?.title
			self.URLLabel.text = viewModel?.url
			if let img = viewModel?.logo.value {
				self.logoImageView.image = img
			} else if let logoInfo = viewModel?.logoInfo.value {
				let placeholder = LogoPlaceholder(logoInfo: logoInfo)
				self.fakeLogoView = placeholder
			}
            
            self.logoImageView.alpha = 0.0
            self.logoImageView.transform = CGAffineTransform.init(scaleX: 0.8, y: 0.8)
			viewModel?.logo.asObservable().subscribe(onNext: { (img) in
                self.logoImageView.image = img
                UIView.animate(withDuration: 0.15, animations: {
                     self.logoImageView.alpha = 1.0
                     self.logoImageView.transform = CGAffineTransform.identity
                })
			}, onError: { (_) in
				self.logoImageView.image = nil
			}, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
            
            viewModel?.logoInfo.asObservable().subscribe(onNext: { (logoInfo) in
                if let info = logoInfo {
                    let placeholder = LogoPlaceholder(logoInfo: info)
                    self.fakeLogoView = placeholder
                    self.logoContainerView.addSubview(placeholder)
                    placeholder.snp.makeConstraints({ (make) in
                        make.top.left.right.bottom.equalTo(self.logoContainerView)
                    })
                }
            }, onError: { (_) in
                self.fakeLogoView = nil
                self.fakeLogoView?.removeFromSuperview()
            }, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
		}
	}

	let titleLabel = UILabel()
	let URLLabel = UILabel()

	lazy var logoContainerView = UIView()
	let logoImageView = UIImageView()
	var fakeLogoView: UIView?

	let cardView = UIView()
    
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.contentView.backgroundColor = UIColor.black.withAlphaComponent(0.40)
		self.backgroundColor = UIColor.clear
		cardView.backgroundColor = UIColor.clear
		cardView.layer.cornerRadius = 4
		contentView.addSubview(cardView)
		cardView.addSubview(titleLabel)
		titleLabel.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium)
		titleLabel.textColor = self.textColor()
		titleLabel.backgroundColor = UIColor.clear
		cardView.addSubview(URLLabel)
		URLLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.medium)
		URLLabel.textColor = UIColor.white
		URLLabel.backgroundColor = UIColor.clear
		titleLabel.numberOfLines = 2
		self.cardView.addSubview(self.logoContainerView)
		logoContainerView.addSubview(logoImageView)
        logoContainerView.layer.cornerRadius = 7
		logoContainerView.layer.masksToBounds = true
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    override func cellPressed(_ gestureRecognizer: UIGestureRecognizer) {
        let touchLocation = gestureRecognizer.location(in: self.cardView)
        
        if titleLabel.frame.contains(touchLocation) {
            clickedElement = "title"
        } else if URLLabel.frame.contains(touchLocation) {
            clickedElement = "url"
        } else if logoContainerView.frame.contains(touchLocation) {
            clickedElement = "logo"
        }
    }

	override func layoutSubviews() {
		super.layoutSubviews()
		let cardViewLeftOffset = 0
		let cardViewRightOffset = -13
		let cardViewTopOffset = 0
		let cardViewBottomOffset = -5
		self.cardView.snp.remakeConstraints { (make) in
			make.left.equalTo(self.contentView).offset(cardViewLeftOffset)
			make.right.equalTo(self.contentView).offset(cardViewRightOffset)
			make.top.equalTo(self.contentView).offset(cardViewTopOffset)
			make.bottom.equalTo(self.contentView).offset(cardViewBottomOffset)
		}
		
		let logoSize = CGSize(width: 48, height: 48)
		logoContainerView.snp.makeConstraints { make in
			make.top.equalTo(self.cardView).offset(10)
			make.left.equalTo(self.cardView).offset(10)
			make.size.equalTo(logoSize)
		}
		self.logoImageView.snp.remakeConstraints { (make) in
			make.top.left.right.bottom.equalTo(self.logoContainerView)
		}
		let URLLeftOffset = 10
		let URLHeight = 18
		self.URLLabel.snp.remakeConstraints { (make) in
			make.top.equalTo(self.cardView).offset(5)
			make.left.equalTo(self.logoImageView.snp.right).offset(URLLeftOffset)
			make.height.equalTo(URLHeight)
			make.right.equalTo(self.cardView)
		}
		self.titleLabel.snp.remakeConstraints { (make) in
			make.top.equalTo(self.URLLabel.snp.bottom)
			make.left.equalTo(self.logoImageView.snp.right).offset(URLLeftOffset)
			make.height.equalTo(38)
			make.right.equalTo(self.cardView)
		}
	}

	override func prepareForReuse() {
        super.prepareForReuse()
		self.viewModel = nil
		self.cardView.transform = CGAffineTransform.identity
		self.cardView.alpha = 1
		self.logoImageView.image = nil
		self.fakeLogoView?.removeFromSuperview()
		self.fakeLogoView = nil
	}

	fileprivate func textColor() -> UIColor {
		return UIColor.white
		// TODO: fix
//		return UIConstants.NormalModeTextColor
	}

}
