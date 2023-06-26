//
//  Photo+Extensions.swift
//  Virtual Tourist
//
//  Created by Ademola Fadumo on 24/06/2023.
//

import Foundation
import CoreData

extension Photo {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
