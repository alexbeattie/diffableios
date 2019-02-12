//
//  SearchResult.swift
//  AppStoreJSONApis
//
//  Created by Brian Voong on 2/11/19.
//  Copyright © 2019 Brian Voong. All rights reserved.
//

import Foundation

struct SearchResult: Decodable {
    let resultCount: Int
    let results: [Result]
}

struct Result: Decodable {
    let trackName: String
    let primaryGenreName: String
    var averageUserRating: Float?
}
