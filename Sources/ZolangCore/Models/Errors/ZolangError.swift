//
//  ZolangError.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 26/06/2018.
//

import Foundation

public struct ZolangError: Error {
    public let type: ErrorType
    public let file: String
    public let line: Int
    
    public var localizedDescription: String {
        return "Error in file: \(file) - line: \(line) - message: \(type.localizedDescription)"
    }
}
