//
//  SearchCell.swift
//  Aux
//
//  Created by Daniel on 4/27/19.
//  Copyright © 2019 Daniel. All rights reserved.
//

import UIKit

class SearchCell: UITableViewCell {

    @IBOutlet weak var songLabel: UILabel!
    
    @IBOutlet weak var artistLabel: UILabel!
    
    @IBOutlet weak var albumArtImage: UIImageView!
    
    var albumArtImageURI: String!
    
    var playURI: String!
    
    var trackLink: String!
    
    var platform: String!
    
    var delegate: MyCustomCellDelegator!
    
    @IBAction func optionButtonPressed(_ sender: Any) {
        let track = Track(name: songLabel.text!, artist: artistLabel.text!, imageURL: albumArtImageURI, playURI: playURI, trackLink: trackLink)
        
        if self.delegate != nil {
            self.delegate.callSegueFromCell(myData: track)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
