//
//  ContentView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 17/10/24.
//

import SwiftUI
import Defaults

struct ContentView: View {
    
    @EnvironmentObject var viewModel: NotchViewModel
    
    var body: some View {
        ZStack {
            NotchLayout()
                .padding(.horizontal, viewModel.notchState == .open ? Defaults[.cornerRadiusScaling] ? (viewModel.sizes.cornerRadius.opened.inset! - 5) : (viewModel.sizes.cornerRadius.closed.inset! - 5) : 12)
                .padding([.horizontal, .bottom], viewModel.notchState == .open ? 12 : 0)
                .background(.black)
                .mask {
                    NotchShape(cornerRadius: ((viewModel.notchState == .open) && Defaults[.cornerRadiusScaling]) ? viewModel.sizes.cornerRadius.opened.inset : viewModel.sizes.cornerRadius.closed.inset)
                }
                .onAppear(perform: {
                    // the notch view already starts shaped after 0.1s
                    // change to `DispatchQueue.main.async { ... }` to make it start on open
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(viewModel.animation) {
                            if viewModel.firstLaunch {
                                viewModel.open()
                            }
                        }
                    }
                })
        }
        .frame(maxWidth: Sizes().size.opened.width! + 40, maxHeight: Sizes().size.opened.height! + 20, alignment: .top)
        .shadow(color: (viewModel.notchState == .open && Defaults[.enableShadow] ? .black.opacity(0.6) : .clear), radius: Defaults[.cornerRadiusScaling] ? 10 : 5)
        .environmentObject(viewModel)
        
    }
    
    @ViewBuilder
    func NotchLayout() -> some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                    Spacer()
                    HelloAnimation()
                        .frame(width: 200, height: 80)
                        .onAppear(perform: {
                            viewModel.closeHello()
                        })
                        .padding(.top, 40)
                    Spacer()
            }
        }
    }
}

#Preview {
    // DEBUG ONLY
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    ContentView().environmentObject(appDelegate.viewModel)
}
