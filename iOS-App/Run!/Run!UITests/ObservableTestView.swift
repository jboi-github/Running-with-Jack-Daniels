//
//  ObservableTestView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 26.12.21.
//

import SwiftUI

class ObservableTest: ObservableObject {
    static let sharedInstance = ObservableTest()
    
    @Published var t1: Int = 0
    @Published var t2: Int = 0
    
    func changeT1(to: Int) {t1 = to}
    func changeT2(to: Int) {t2 = to}
}

struct ObservableTestView: View {
    @ObservedObject var T = ObservableTest.sharedInstance
    
    var body: some View {
        VStack {
            T1(t1: T.t1)
            T2(t2: T.t2)
            T12b()
            
            Button {
                T.changeT1(to: T.t1 + 1)
            } label: {
                Text("Inc T1")
            }
            Button {
                T.changeT2(to: T.t2 + 1)
            } label: {
                Text("Inc T2")
            }
        }
    }
}

private struct T1: View {
    let t1: Int
    
    var body: some View {
        print("T1")
        return Text("T1: \(t1) - \(Date().timeIntervalSince1970)")
    }
}

private struct T2: View {
    let t2: Int
    
    var body: some View {
        print("T2")
        return Text("T2: \(t2) - \(Date().timeIntervalSince1970)")
    }
}

private struct T12b: View {
    @ObservedObject var T = ObservableTest.sharedInstance

    var body: some View {
        print("T12b")
        return VStack {
            Text("T1: \(T.t1), T2: \(T.t2) - \(Date().timeIntervalSince1970)")

            Button {
                T.changeT1(to: T.t1 + 1)
            } label: {
                Text("Inc T1 in T12b")
            }
        }
    }
}

struct ObservableTestView_Previews: PreviewProvider {
    static var previews: some View {
        ObservableTestView()
    }
}
