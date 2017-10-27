//
//  BlueConfig.swift
//  igbluereports
//
//  Created by william donner on 3/13/17.
//
//

import Foundation
enum TinyError:Error {
    case infoplist
    case cantSerializeJSON
}
public class BlueConfig {

  
    var localConfig:[String:Any] = [:]
    var grandConfig:[String:Any] = [:]
    
    fileprivate func readFirstLevelConfig(_ configurl:URL) throws -> [String:Any]  {
        func fallback() -> [String:Any] {
            print("--- cant parse first level config, falling back to embedded configuration")
            return ["grandConfig":"https://billdonner.com/tr/blue-server-config.json","softwarenamed":"igblu","debugPrint":"on"]
        }
        let data = try Data(contentsOf: configurl)
        if let config = try JSONSerialization.jsonObject(with:data, options: .allowFragments) as? [String: Any] {
            return  config
        } else {
            return fallback()
        }
    }
    fileprivate func readSecondLevelConfig(_ configurl:URL) throws -> [String:Any]  {
        func fallback() -> [String:Any] {
            print("--- cant parse second level config, falling back to embedded configuration")
            return ["mocked":"data here is mocked up, for some reason we could not read \(configurl)","date":"\(Date())"]
        }
        do {
            let data = try Data(contentsOf: configurl)
            if let config = try JSONSerialization.jsonObject(with:data, options: .allowFragments) as? [String: Any] {
                return  config
            } else {
                return fallback()
            }
        } catch {
            return fallback()
        }
    }
  
  
  
  func tiny() throws -> String {
    if let iDict = Bundle.main.infoDictionary {
      if let w =  iDict["GRAND-CONFIG"] as? String {
        return w
      }
    }
    throw TinyError.infoplist
  }
    func process(configurl:URL?) throws {
      if configurl == nil {
        // read from infodictionary
        let levtwoconfigurl = try tiny()
        if  let levtwourl = URL(string:levtwoconfigurl)  {
        let levtwoconfig = try readSecondLevelConfig(levtwourl)
          grandConfig = levtwoconfig
          localConfig = ["grandConfig":levtwoconfigurl]
        }
      } else {
        do {
            // read small local config as bootstrap
            let levoneconfig = try readFirstLevelConfig(configurl!)
            if let levtwoconfigurl = levoneconfig["grandConfig"] as? String ,
                let levtwourl = URL(string:levtwoconfigurl) {
                let levtwoconfig = try readSecondLevelConfig(levtwourl)
                grandConfig = levtwoconfig
            }
            localConfig = levoneconfig
        } catch {
          
        }
      }
    }
    
    // quix and easy
    class func load(configurl:URL) throws -> BlueConfig  {
        let bc = BlueConfig()
        do {
            try  bc.process(configurl: configurl)
            return bc
        }
        
    }
}// of BlueConfig
