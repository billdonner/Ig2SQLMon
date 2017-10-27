import Foundation

typealias ServerInfo = [String:String]

/// ItemData is safely copied out to callers  so the task schedule can be private
public struct ItemData  {
    var httpgets: Int
    var status: Int
    var server: String
    var port: UInt16
    var name: String
    var uptime: Double
    var description : String
    var version : String
    var inprogress : Bool
    var downcount: Int
    var errorcount:Int
    var statusEndpoint: String
    var displayDecorations : DisplayDecorations
    
    init(_ td:TaskData){
        self.status = td.status
        self.httpgets = td.httpgets
        self.server = td.server
        self.port = td.port
        self.downcount = td.downcount
        self.errorcount = td.errorcount
        self.name = td.name
        self.uptime = td.uptime
        self.description = td.description
        self.version = td.version
        self.inprogress = td.inprogress
        self.displayDecorations = td.displayDecorations
        self.statusEndpoint = td.statusEndpoint
    }
    
    var paddedUptime: String {
        let zuptime = "\(uptime)"
        let str = zuptime.components(separatedBy: ".").first!
        if  let xx = Double(str as String) {
            if xx > 0 {
                let paddedStr = str.leftPadding(toLength:7,  withPad: "0" )
                return paddedStr
            }
        }
        return "9999999"
    }
}



/// each task/row in the class list is a TaskData class instance that is allocated once and updated from all directions

class  TaskData {
    
    var httpgets: Int = 0
    var status: Int
    var server: String
    var port: UInt16
    var name: String
    var uptime: Double
    var errorcount: Int = 0 
    var statusEndpoint: String
    var description : String
    var version : String
    var inprogress = false
    var downcount: Int
    var secsBetweenBadPolls: TimeInterval = 60
    var secsBetweenGoodPolls: TimeInterval = 10
    var selfidx: Int
    var displayDecorations : DisplayDecorations
    
    init(idx: Int, status: Int, name: String, server: String, port:UInt16, statusEndpoint: String, uptime: Double, description: String, version:String, downcount: Int, ish: DisplayDecorations) {
        
        self.selfidx = idx
        self.status = status
        self.name = name
        self.server = server
        self.port = port
        self.statusEndpoint = statusEndpoint
        self.uptime = uptime
        self.version = version
        self.description = description
        self.displayDecorations  = ish
        self.downcount = downcount
    }

    public var debugDescription: String {
        return "\(uptime)" + " " + "\(server)" + " status: \(status)"
    }
}

// MARK: - Sorting

func sortTaskData(lhsIsFolder: Bool, rhsIsFolder: Bool,  ascending: Bool,
                  attributeComparation: Bool) -> Bool {
    if(lhsIsFolder && !rhsIsFolder) {
        return ascending ? true : false
    }
    else if (!lhsIsFolder && rhsIsFolder) {
        return ascending ? false : true
    }
    return attributeComparation
}

func itemComparator<T:Comparable>(lhs: T, rhs: T, ascending: Bool) -> Bool {
    return ascending ? (lhs < rhs) : (lhs > rhs)
}


public func ==(lhs: Date, rhs: Date) -> Bool {
    if lhs.compare(rhs) == .orderedSame {
        return true
    }
    return false
}

public func <(lhs: Date, rhs: Date) -> Bool {
    if lhs.compare(rhs) == .orderedAscending {
        return true
    }
    return false
}


// MARK:  TaskData  Equatable

func ==(lhs: TaskData, rhs: TaskData) -> Bool {
    return (lhs.server == rhs.server)
}


//func dictFor() -> [String:Any]{
//    return [
//        "selfidx": selfidx,
//        "status": status,
//        "name": name,
//        "server": server,
//        "port": port,
//        "httpgets" : httpgets,
//        "statusEndpoint": statusEndpoint,
//        "version": version,
//        "uptime": uptime,
//        "description": description,
//        "displayDecorations": displayDecorations,
//        "downcount": downcount]
//}
//


