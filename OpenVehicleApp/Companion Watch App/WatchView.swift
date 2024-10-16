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
                                metricVal.carsoc,
                               maxValue: 100,
                               backgroundColor: .clear,
                               foregroundColor: color(forChargeLevel: metricVal.carsoc)
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
          let text1 = metricVal.charge_etr_full > 0 ? "Full" : ""
          let data1 = metricVal.charge_etr_full > 0 ? timeConvert(time: String(metricVal.charge_etr_full)) : ""
          let text2 = metricVal.charge_limit_range > 0 && metricVal.charge_etr_range > 0 ? "\(metricVal.charge_limit_range)K" : ""
          let data2 = metricVal.charge_limit_range > 0 && metricVal.charge_etr_range > 0 ? timeConvert(time: String(metricVal.charge_etr_range)) : ""
          let text3 = metricVal.charge_limit_soc > 0 && metricVal.charge_etr_soc > 0 ? "\(metricVal.charge_limit_soc)%" : ""
          let data3 = metricVal.charge_limit_soc > 0 && metricVal.charge_etr_soc > 0 ? timeConvert(time: String(metricVal.charge_etr_soc)) : ""
          SubView(
                  Text1: text1, Data1: data1,
                  Text2: text2, Data2: data2,
                  Text3: text3, Data3: data3,
                  Text4: "Dur", Data4: timeConvert(time: "\((Int(metricVal.chargeduration))/60)"),
                  Text5: "kWh", Data5: String(format:"%0.2f",(Float(metricVal.chargekwh))),
                  Text6: "@ kW", Data6: String(format:"%0.1f",(Float(metricVal.power))))
        case .driving:
          SubView(Text1: "PWR", Data1: String(format:"%0.1f",(Float(metricVal.power))),
                  Text2: "ODO", Data2: String(metricVal.odometer),
                  Text3: "Used", Data3: String(format:"%0.2f",(Float(metricVal.energyused)/1000)),
                  Text4: "Rxed", Data4: String(format:"%0.2f",(Float(metricVal.energyrecd)/1000)),
                  Text5: "Trip", Data5: String(format:"%0.1f",(Float(metricVal.tripmeter)/10)),
                  Text6: "12V", Data6: "\(metricVal.vehicle12v)V")
        default:
          SubView(Text1: "Motor", Data1: "\(metricVal.temperature_motor)°",
                  Text2: "Batt", Data2: "\(metricVal.temperature_battery)°",
                  Text3: "PEM", Data3: "\(metricVal.temperature_pem)°",
                  Text4: "Amb", Data4: "\(metricVal.temperature_ambient)°",
                  Text5: "Parked", Data5: String(format:"%d:%02d",metricVal.parktime/3600,(metricVal.parktime%3600)/60),
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
