//
//  WatchModel.swift
//  OVWatch Watch App
//
//  Created by Peter Harry on 29/2/2024.
//  Copyright © 2024 Open Vehicle Systems. All rights reserved.
//

import Combine
import WatchConnectivity
import os

struct Doors: OptionSet {
  let rawValue: Int
  
  static let leftDoor = Doors(rawValue: 1 << 0)
  static let rightDoor = Doors(rawValue: 1 << 1)
  static let chargePort = Doors(rawValue: 1 << 2)
  static let pilot = Doors(rawValue: 1 << 3)
  static let charging = Doors(rawValue: 1 << 4)
  static let handBrake = Doors(rawValue: 1 << 6)
  static let carOn = Doors(rawValue: 1 << 7)
}

struct WatchMetric {
  var charging: Bool
  var caron: Bool
  var chargestate: String
  var estimated_range: Double
  var charge_etr_full: Double
  var charge_etr_soc: Double
  var charge_etr_range: Double
  var charge_limit_soc: Double
  var charge_limit_range: Double
  var parktime: Double
  var units: String
  var chargeduration: Double
  var chargekwh: Double
  var chargecurrent: Double
  var linevoltage: Double
  var power: Double
  var tripmeter: Double
  var energyrecd: Double
  var energyused: Double
  var temperature_motor: Double
  var temperature_battery: Double
  var temperature_pem: Double
  var temperature_ambient: Double
  var voltage_cabin: Double
  var vehicle12v: Double
  var carsoc: Double
  var doors: Doors
  var odometer: Int
  
  static let initial = WatchMetric(charging: false, caron: false, chargestate: "", estimated_range: 0.0, charge_etr_full: 0.0, charge_etr_soc: 0.0, charge_etr_range: 0.0, charge_limit_soc: 0.0, charge_limit_range: 0.0, parktime: 0.0, units: "K", chargeduration: 0.0, chargekwh: 0.0, chargecurrent: 0.0, linevoltage: 0.0, power: 0.0, tripmeter: 0.0, energyrecd: 0.0, energyused: 0.0, temperature_motor: 0.0, temperature_battery: 0.0, temperature_pem: 0.0, temperature_ambient: 0.0, voltage_cabin: 0.0, vehicle12v: 0.0, carsoc: 0.0, doors: Doors(rawValue: 0), odometer: 0)
    
}

class WatchModel: NSObject, ObservableObject {
  static let shared = WatchModel()
  @Published var metricVal = WatchMetric.initial
  var carMode: CarMode {
    get {
      if metricVal.charging {
        return .charging
      } else if metricVal.doors.contains(.carOn)  {
        return .driving
      }
      return .idle
    }
  }
  
  var statusCharging = false
  var charging = false
  var sessionAvailable = false
  var topic = ""
  var session: WCSession
  
  init(session: WCSession = .default) {
    self.session = session
    super.init()
    self.session.delegate = self
    session.activate()
  }
}

extension OSLog {
    static let subsystem = "au.com.prhenterprises.openvehicle"
    static let plants = OSLog(subsystem: OSLog.subsystem, category: "phone")
    static let watch = OSLog(subsystem: OSLog.subsystem, category: "watch")
}

extension WatchModel: WCSessionDelegate {
  
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
      os_log(.debug, log: .watch, "Finished activating session %lu (error: %s)", activationState == .activated, error?.localizedDescription ?? "")
  }
  
  func getChargeData() {
    if session.isReachable {
      sessionAvailable = true
      let message = ["msg": "charge"]
      session.sendMessage(message, replyHandler: { (payload) in
        let reply = payload["reply"] as! Dictionary<String, Any>
        DispatchQueue.main.async{
          self.metricVal.carsoc = reply["soc"] as! Double
          self.metricVal.chargestate = reply["chargingstate"] as! String
          self.metricVal.estimated_range = reply["estrange"] as! Double
          self.metricVal.charge_etr_full = reply["durationfull"] as! Double
          self.metricVal.charge_etr_soc = reply["durationsoc"] as! Double
          self.metricVal.charge_etr_range = reply["durationrange"] as! Double
          self.metricVal.charge_limit_soc = reply["limitsoc"] as! Double
          self.metricVal.charge_limit_range = reply["limitrange"] as! Double
          self.metricVal.parktime = reply["car_parktime"] as! Double
          self.metricVal.units = reply["units"] as! String
          self.metricVal.chargeduration = reply["chargeduration"] as! Double
          self.metricVal.chargekwh = reply["chargekwh"] as! Double
          self.metricVal.chargecurrent = reply["current"] as! Double
          self.metricVal.linevoltage = reply["linevoltage"] as! Double
          self.metricVal.power = reply["power"] as! Double
          self.metricVal.tripmeter = reply["car_trip"] as! Double
          //self.metricVal.energyrecd = reply["soc"] as! Double
          //self.metricVal.energyused = reply["soc"] as! Double
          self.metricVal.temperature_motor = reply["car_tmotor"] as! Double
          self.metricVal.temperature_battery = reply["car_tbattery"] as! Double
          self.metricVal.temperature_pem = reply["car_tpem"] as! Double
          self.metricVal.temperature_ambient = reply["soc"] as! Double
          self.metricVal.voltage_cabin = reply["soc"] as! Double
          self.metricVal.vehicle12v = reply["lowvoltage"] as! Double
          let doors1 = reply["doors1"] as! Int
          self.metricVal.doors = Doors(rawValue: doors1)
          self.metricVal.odometer = reply["odometer"] as! Int
          
          if (self.metricVal.chargestate == "charging") {
            self.metricVal.charging = true
          } else {
            self.metricVal.charging = false
          }
        }
        os_log(.debug, log: .watch, "Received reply")
      }, errorHandler: { error in
        os_log(.debug, log: .watch, "Error: %s", error.localizedDescription)
      })
    } else {
      sessionAvailable = false
      os_log(.error, log: .watch, "Session not reachable")
    }
  }
}
