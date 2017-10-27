//
//  Ig2SQLStatus
//  Ig2SQL
//
//  Created by william donner on 10/26/17.
//

import Foundation
public struct Ig2SQLStatus: Codable {
    let servertitle: String
    let applicationName: String
    let dbName: String
    let description: String
    let company: String
    let organization: String
    let location: String
    let version: String
    let serverurl: String
    let serverport: UInt16
    let uptime: Double
    let timenow: Date
    let httpgets: Int
    let status:Int
}
public protocol Ig2SQLStatusProtocol {
    func prepareforxmt() -> Ig2SQLStatus
    func rcvthenprocess(completion:(Ig2SQLStatus) -> ())
}
