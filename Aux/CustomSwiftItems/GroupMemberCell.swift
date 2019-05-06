//
//  GroupMemberCell.swift
//  Aux
//
//  Created by Daniel on 5/2/19.
//  Copyright © 2019 Daniel. All rights reserved.
//

import UIKit

class GroupMemberCell: UITableViewCell {

    @IBOutlet weak var memberNameLabel: UILabel!
    
    @IBOutlet weak var memberProfilePicture: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
