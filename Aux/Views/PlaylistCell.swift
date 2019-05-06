//
//  PlaylistCell.swift
//  Aux
//
//  Created by Daniel on 4/30/19.
//  Copyright © 2019 Daniel. All rights reserved.
//

import UIKit

class PlaylistCell: UITableViewCell {

    @IBOutlet weak var playlistThumbnail: UIImageView!
    
    @IBOutlet weak var playlistNameLabel: UILabel!
    
    @IBOutlet weak var numSongsLabel: UILabel!
    
    var playlistThumbnailURL: String!
    
    var ownerID: String!
    
    var playlistID: String!
    
    var numSongs: String!
    
    var delegate: MyCustomCellDelegator!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func moreButtonPressed(_ sender: Any) {
        let playlist = Playlist(name: playlistNameLabel.text!, numSongs: numSongs, thumbnailURL: playlistThumbnailURL, playlistID: playlistID, ownerID: ownerID)
        
        if self.delegate != nil {
            self.delegate.callSegueFromCell(myData: playlist)
        }
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
