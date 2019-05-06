//
//  BeginGroupSessionButton.swift
//  Aux
//
//  Created by Daniel on 5/1/19.
//  Copyright © 2019 Daniel. All rights reserved.
//

import Foundation
import UIKit

class GroupSessionButton: UIButton {
    
    fileprivate let buttonBackgroundColor =
        UIColor(rgb: 0xEA711A)
    fileprivate let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.init(name: "Raleway-v4020-Bold", size: 16)!,
        .foregroundColor: UIColor.white,
        .kern: 2.0
    ]
    
    init(title: String) {
        super.init(frame: CGRect.zero)
        backgroundColor = buttonBackgroundColor
        contentEdgeInsets = UIEdgeInsets(top: 15.0, left: 40.0, bottom: 15.0, right: 40.0)
        layer.cornerRadius = 10.0
        translatesAutoresizingMaskIntoConstraints = false
        let title = NSAttributedString(string: title, attributes: titleAttributes)
        setAttributedTitle(title, for: .normal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
