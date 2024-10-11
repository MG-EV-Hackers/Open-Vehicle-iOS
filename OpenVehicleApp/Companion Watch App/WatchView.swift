//
//  ContentView.swift
//  Companion Watch App
//
//  Created by Peter Harry on 11/10/2024.
//  Copyright © 2024 Open Vehicle Systems. All rights reserved.
//

import SwiftUI

enum CarMode {
  static let identifierKey = "identifier"
  case driving
  case charging
  case idle
  var identifier: String {
    switch self {
    case .driving:
      return "Driving"
    case .charging:
      return "Charging"
    case .idle:
      return "Parked"
    }
  }
  var color: Color {
    switch self {
    case .driving:
      return .blue
    case .charging:
      return .red
    case .idle:
      return .green
    }
  }
}

struct WatchView: View {
  @ObservedObject var metrics = WatchModel.shared
  let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

  var body: some View {
    let metricVal = metrics.metricVal
    let socDouble = 50.0 //Double(metric.linevoltage) ?? 0.0
    let carMode = metrics.carMode
    let phoneImage = metrics.sessionAvailable ? "iphone.gen3.circle" : "iphone.gen3.slash.circle"
    GeometryReader { watchGeo in
      VStack {
        Button(action: {
          metrics.getChargeData()
        }) {
          Label(carMode.identifier, systemImage: phoneImage)
        }
        .controlSize(.mini)
        .foregroundStyle(carMode.color)
        //              HStack {
        //                Text(carMode.identifier)
        //                  .foregroundStyle(carMode.color)
        //                  .font(.caption)
        //                Image(systemName: "phone")
        //              }
        Image("battery_000")
          .resizable()
          .scaledToFit()
          .frame(width: watchGeo.size.width * 0.9, height: watchGeo.size.height * 0.3, alignment: .center)
          .frame(width: watchGeo.size.width, height: watchGeo.size.height * 0.3, alignment: .center)
          .overlay(ProgressBar(value:
                                socDouble,
                               maxValue: 100,
                               backgroundColor: .clear,
                               foregroundColor: color(forChargeLevel: socDouble)
                              )
            .frame(width: watchGeo.size.width * 0.7, height: watchGeo.size.height * 0.25)
            .frame(width: watchGeo.size.width, height: watchGeo.size.height * 0.25)
            .opacity(0.6)
            .padding(0)
          )
          .overlay(
            VStack {
              Text("\(String(format:"%0.1f",(Float(metricVal.carsoc))))%")
                .fontWeight(.bold)
                .foregroundColor(Color.white)
              Text("\(String(format:"%0.1fKm",(Float(metricVal.estimated_range))))")
                .fontWeight(.bold)
                .foregroundColor(Color.white)
            }
              .background(Color.clear)
              .opacity(0.9))
        switch carMode {
        case .charging:
          SubView(Text1: "Full", Data1: timeConvert(time: String(metricVal.charge_etr_full)),
                  Text2: "\(metricVal.charge_limit_soc)%", Data2: timeConvert(time: String(metricVal.charge_etr_soc)),
                  Text3: "\(metricVal.charge_limit_range)K", Data3: timeConvert(time: String(metricVal.charge_etr_range)),
                  Text4: "Dur", Data4: timeConvert(time: "\((Int(metricVal.chargeduration))/60)"),
                  Text5: "kWh", Data5: String(format:"%0.1f",(Float(metricVal.chargekwh))),
                  Text6: "@ kW", Data6: String(format:"%0.1f",(Float(metricVal.power))))
        case .driving:
          SubView(Text1: "PWR", Data1: String(format:"%0.1f",(Float(metricVal.power))),
                  Text2: "ODO", Data2: String(metricVal.odometer),
                  Text3: "Cons", Data3: "0.00", //String(format:"%0.2f",(Float(metricVal.consumption) ?? 0.00)),
                  Text4: "Time", Data4: "0.00", //String(format:"%0.2f",(Float(metricVal.drivetime) ?? 0.00)),
                  Text5: "Trip", Data5: "0.00", //String(format:"%0.1f°",(Float(metricVal.tripmeter))),
                  Text6: "12V", Data6: "\(metricVal.vehicle12v)V")
        default:
          SubView(Text1: "Motor", Data1: "\(metricVal.temperature_motor)", //"\(metricValVal.temperature_motor)°",
                  Text2: "Batt", Data2: "\(metricVal.temperature_battery)", //"\(metricValVal.temperature_battery)°",
                  Text3: "PEM", Data3: "\(metricVal.temperature_pem)", //"\(metricValVal.temperature_pem)°",
                    Text4: "Amb", Data4: "\(0)", //"\(metricValVal.temperature_ambient)°",
                    Text5: "Cabin", Data5: "\(0)", //"\(metricValVal.temperature_cabin)°",
                    Text6: "12V", Data6: "\(metricVal.vehicle12v)V")
        }
      }
    }
    .onReceive(timer) { count in
      metrics.getChargeData()
    }
  }
}

func timeConvert(time: String) -> String {
  guard let intTime = Int(time) else { return "--:--" }
  if intTime <= 0 {
    return "--:--"
  }
  return String(format: "%d:%02d",(Int(time) ?? 0)/60,(Int(time) ?? 0)%60)
}

func timeConvertHours(time: String) -> String {
  guard let intTime = Int(time) else { return "--:--:--" }
  if intTime <= 0 {
    return "--:--:--"
  }
  return String(format: "%d:%02d:%02d",intTime/3600,(intTime % 3600) / 60,(intTime % 3600) % 60)
}


#Preview {
    WatchView()
}
