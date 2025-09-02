//
//  ActionButtons.swift
//  NearMe
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/5/4.
//

import SwiftUI
import MapKit

struct ActionButtons: View {
    
    let mapItem: MKMapItem
    
    var body: some View {
        HStack{
            Button(action: {
                if let phone = mapItem.phoneNumber {
                    let numericPhoneNumber = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                    makeCall(phone: numericPhoneNumber)
                }
            },label: {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("call")
                }
            }).buttonStyle(.bordered)
            
            
            Button(action: {
                MKMapItem.openMaps(with:[mapItem])
            },label: {
                HStack {
                    Image(systemName: "car.circle.fill")
                    Text("Take me there")
                }
            }).buttonStyle(.bordered)
                .tint(.green)
            Spacer()
        }
    }
}

#Preview {
    ActionButtons(mapItem: PreviewData.apple)
}
