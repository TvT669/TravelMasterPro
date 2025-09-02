//
//  SearchOptionsView.swift
//  NearMe
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/5/3.
//

import SwiftUI

struct SearchOptionsView: View {
    let searchOptions = ["Restaurants": "fork.knife","Hotels": "bed.double.fill","Coffee": "cup.and.saucer.fill", "Gas": "fuelpump.fill"]
    
    let onSelected: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false){
            HStack{
                /*排序后的字典条目数组
                使用键（Key）作为唯一标识
                解构元组为键值对*/
                ForEach(searchOptions.sorted(by: >),id: \.0) { key , value in
                    Button(action: {
                        onSelected(key)
                    },label: {
                        HStack{
                            Image(systemName:value)
                            Text(key)
                        }
                    }
                    )}
                .buttonStyle(.borderedProminent)
                .tint(Color(red:236/255, green: 240/255, blue: 241/255,opacity: 1.0))
                .foregroundStyle(.black)
                .padding(4)
            }
        }
    }
}
#Preview {
    SearchOptionsView(onSelected: {_ in})
}
