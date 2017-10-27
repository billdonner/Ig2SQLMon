//
//  TaskList.swift
//  igbluemon
//
//  Created by bill donner on 3/14/17.
//  Copyright © 2017 billdonner. All rights reserved.
//

import Foundation

public enum DisplayDecorations : Int {
    case reddish
    case yellowish
    case blueish
}

public enum TaskSortOrdering: String {
    case status
    case server
    case uptime
    case description
    case name
    case version
}

extension Data {
    func printdata(_ e: String.Encoding){
        if let str = String.init(data: self, encoding:e)  {
            print ("utf8>>  \(str)")
        }
    }
}

extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let newLength = self.characters.count
        if newLength < toLength {
            return String(repeatElement(character, count: toLength - newLength)) + self
        } else { 
            return String(self [index(self.startIndex, offsetBy: newLength - toLength)...])
        }
    }
}

/// the TL is the tasklist, one row per TaskData element
///  it is completely static, essentially a fancy global

struct MasterTasks {
    
    static  let jsonDecoder = JSONDecoder()
    static let framesPerSecond:Double = 20

    fileprivate static var taskRows: [TaskData] = []
    
    static var info : [String:Any] = [:] //maps url to taskRows indicies
    
    static var  session  =  { () -> URLSession in
        let urlconfig = URLSessionConfiguration.default
        urlconfig.timeoutIntervalForRequest = 15
        urlconfig.timeoutIntervalForResource = 15
        return  URLSession(configuration: urlconfig, delegate: nil, delegateQueue: nil)
    }()
    
    
    static func setup() throws{
        let bc =   BlueConfig()
        try bc.process( configurl: nil)
        if  let bt = bc.grandConfig["servers"] as? [ServerInfo] {
            MasterTasks.make(bt)
        }
    }
    
    static  func runScheduler() {
        // counts down each task and starts remote api call whenever apvarpriate
        let theRows = taskRows // copy so it can mutate
        // print ("runSched entrance with sss \(sss)")
        var theIndex = 0
        for task in theRows  { // each on list
            
            let dorun = countDown(idx: theIndex)
            let inprog = task.inprogress   // skip if busy
            
            //print("runSched countdown \ {(dorun) inprog \(inprog) for poll \(task.server)")
            
            if dorun && !inprog {
                task.displayDecorations = .yellowish
                let key = "\(task.server):\(task.port)"
                // print("runSched will poll \(task.server) idx \(MasterTasks.idx(url:task.server))")
                remoteHTTPCall(task.statusEndpoint,key: key) { istat  in
                    guard let ig2SQLStatus = istat else { print("Nil remote call"); return}
                    if let merow = idx(key: key) {
                        if ig2SQLStatus.status == (200) {
                            let td =  taskRows[merow ]
                            td.status = ig2SQLStatus.status
                            td.httpgets = ig2SQLStatus.httpgets
                            td.name = ig2SQLStatus.servertitle
                            td.description = ig2SQLStatus.description
                            td.version = ig2SQLStatus.version
                            td.server = ig2SQLStatus.serverurl
                            td.port = ig2SQLStatus.serverport
                            td.uptime = ig2SQLStatus.uptime
                            td.displayDecorations = .blueish
                        } else {
                            // in case of error copy fordward much of the exisating taskdata
                            //let td = MasterTasks.taskList.taskRows[merow ]
                            
                            let td =  taskRows[merow ]
                            td.errorcount += 1
                            td.status =  ig2SQLStatus.status
                            td.displayDecorations = .reddish
                            td.downcount = Int(td.secsBetweenBadPolls * framesPerSecond)// wait a minute after bad response
                        }
                    }
                }//remoteHTTPCall
            }// not in progress
            theIndex += 1
        }// for loop
    }// run scheduler
    
    //TODO: fix sorting
    static func reloadTaskList(ordering:TaskSortOrdering,ascending:Bool) {
        //   taskRows = contentsOrderedBy(ordering, ascending: ascending)
    }
    static func newTaskList() {
        // MasterTasks.taskList = TaskList()
    }
    static func itemData(row:Int) -> ItemData {
        return ItemData(taskRows[row])
    }
    static func tasksCount()->Int {
        return taskRows.count
    }
    
    static func idx(key:String) -> Int? {
        /// let key = "\(url):\(port)"
        if let  t = info[key] as?   Int {
            return t
        }
        return nil
    }
    
    //countdown and reset for this entry
    static func countDown(idx:Int) -> Bool { 
        let td = taskRows[idx]
        td.downcount -= 1
        if td.downcount <= 0 {
            td.downcount   = Int(td.secsBetweenGoodPolls * framesPerSecond)
            return true
        }
        return false
    }
    
    static func make(_ x:[ServerInfo]) {
        var idx = 0
        info = [:]
        for each in x {
            if let comment = each["comment"] {
                print ("comment:\(comment)")
            }
            if let bb = each["server"],  let cc = each["status-url"] ,
                let components =  URLComponents(string: cc),
                let cp = components.port {
                let port = UInt16(cp)
                let key = "\(bb):\(port)"
                
                info[key] = idx
                taskRows.append(TaskData(idx: idx, status: 100, name:bb, server: bb, port:port ,statusEndpoint:cc , uptime: 0.0, description: "", version:"", downcount: idx, ish:.reddish))
            }
            idx += 1
        } // for
    }
    
    static  func contentsOrderedBy(_ orderedBy: TaskSortOrdering, ascending: Bool) -> [TaskData] {
        let sortedFiles: [TaskData]
        switch orderedBy {
        case .status:
            sortedFiles = taskRows.sorted {
                return sortTaskData(lhsIsFolder:true, rhsIsFolder: true, ascending: ascending,
                                    attributeComparation:itemComparator(lhs:$0.status, rhs: $1.status, ascending:ascending))
            }
        case .server:
            sortedFiles = taskRows.sorted {
                return sortTaskData(lhsIsFolder:true, rhsIsFolder: true, ascending:ascending,
                                    attributeComparation:itemComparator(lhs:$0.server, rhs: $1.server, ascending: ascending))
            }
        case .uptime:
            sortedFiles =  taskRows.sorted {
                return sortTaskData(lhsIsFolder:true, rhsIsFolder: true, ascending:ascending,
                                    attributeComparation:itemComparator(lhs:$0.uptime, rhs: $1.uptime, ascending:ascending))
            }
        case .description:
            sortedFiles =  taskRows.sorted {
                return sortTaskData(lhsIsFolder:true, rhsIsFolder: true, ascending:ascending,
                                    attributeComparation:itemComparator(lhs:$0.description, rhs: $1.description, ascending:ascending))
            }
        case .version:
            sortedFiles =  taskRows.sorted {
                return sortTaskData(lhsIsFolder:true, rhsIsFolder: true, ascending:ascending,
                                    attributeComparation:itemComparator(lhs:$0.version, rhs: $1.version, ascending:ascending))
            }
        case .name:
            sortedFiles =  taskRows.sorted {
                return sortTaskData(lhsIsFolder:true, rhsIsFolder: true, ascending:ascending,
                                    attributeComparation:itemComparator(lhs:$0.name, rhs: $1.name, ascending:ascending))
            }
        }
        return sortedFiles
    }
}
extension MasterTasks {

    // make a remoteurl call
    // - the baseurl is used only as a key to obtain the index in the taskrows table
    
    static func remoteHTTPCall(_ remoteurl: String,  key: String, completion:@escaping (Ig2SQLStatus?)->())
    {
        guard let idx = info[key] as?  Int else { return }
        let t =  taskRows[idx]
        guard !t.inprogress else { return }
        
        let url  = URL(string: remoteurl)!
        let request = URLRequest(url: url)
        
        t.inprogress = true
        let task = session.dataTask(with: request) {data,response,error in
            t.inprogress = false
            
            if let httpResponse = response as? HTTPURLResponse  {
                let code = httpResponse.statusCode
                guard code == 200 else {
                    print("remoteHTTPCall to \(url) completing with error \(code)")
                    completion(nil) //fix
                    return
                }
            }
            guard error == nil  else {
                let er = error! as NSError
                print("remoteHTTPCall to \(url) completing  code nserror \(er.code) \(er)")
                //let code = er.code
                completion(nil) //fix
                return
            }
            /// parse what we got
            
            if let data = data {
                data.printdata( .utf8)
                let model = try?   jsonDecoder.decode(Ig2SQLStatus.self, from: data)
                completion(model)
                return // from closure
            }
        }
        task.resume()
    }
}//extension



//    static func arrayOfItems () -> [String:Any] {
//        var ari : [[String:Any]]=[]
//        for task in taskRows {
//            let item = task.dictFor()
//            ari.append(item)
//        }
//        let result:[String:Any] = ["comment":"aydyd","items":ari]
//        return result
//    }


//    static func masterDict() -> [String:Any] {
//        var out:[[String:Any]] = []
//        for row in taskRows {
//            let tr = row.dictFor()
//            out.append(tr)
//        }
//        let final :  [String:Any] = ["comment":"hoobee","server":out]
//        return final
//
//    }

//    static func jsonData() throws -> Data {
//        let dict = masterDict()
//        if let json = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
//            return json
//        }
//        throw TinyError.cantSerializeJSON
//    }

