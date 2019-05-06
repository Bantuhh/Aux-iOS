//
//  QueueCell.swift
//  Aux
//
//  Created by Daniel on 4/11/19.
//  Copyright © 2019 Daniel. All rights reserved.
//

import UIKit

class QueueCell: UITableViewCell {

    @IBOutlet weak var albumArtImage: UIImageView!
    
    @IBOutlet weak var songNameLabel: UILabel!
    
    @IBOutlet weak var artistNameLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }


    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
