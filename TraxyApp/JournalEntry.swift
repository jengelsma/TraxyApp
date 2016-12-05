//
//  JournalEntry.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 12/2/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import Foundation

enum EntryType : Int {
    case text = 1
    case photo
    case audio
    case video
}

struct JournalEntry {
    var key : String?
    var type: EntryType?
    var caption : String?
    var url : String?
    var date : Date?
    var lat : Double?
    var lng : Double?
    
    init(key: String?, type: EntryType?, caption: String?, url: String?, date: Date?, lat: Double?, lng: Double?)
    {
        self.key = key
        self.type = type
        self.caption = caption
        self.url = url
        self.date = date
        self.lat = lat
        self.lng = lng
    }
}
