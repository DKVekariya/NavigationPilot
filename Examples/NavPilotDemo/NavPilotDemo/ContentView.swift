//
//  ContentView.swift
//  NavPilotDemo
//
//  Created by DK on 07/04/26.
//

import SwiftUI

struct ContentView: View {
    @State var showSheet: Bool = true
    @State var navType: NavigationType = .pushPop
    var body: some View {
        ///Uncomment one by one and run you can check the different different Navigation Scenario
        Group {
            HStack {
                Button("Change Navigation") {
                    showSheet.toggle()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.yellow)
            
            switch navType {
            case .pushPop:
                E1SimplePush()
            case .passData:
                E2PushWithData()
            case .closerPass:
                E3CloserPass()
            case .splitScreen:
                E4SplitScreen()
            }
        }
        .sheet(isPresented: $showSheet) {
            VStack {
                ForEach(NavigationType.allCases, id: \.self) { nav in
                    Button(action: {
                        self.navType = nav
                        self.showSheet.toggle()
                    }) {
                        HStack {
                            Text(nav.rawValue.capitalized)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .presentationDetents([.height(250)])
        }
    }
}

#Preview {
    ContentView()
}


enum NavigationType:String, Hashable, CaseIterable {
    case pushPop
    case passData
    case closerPass
    case splitScreen
}
