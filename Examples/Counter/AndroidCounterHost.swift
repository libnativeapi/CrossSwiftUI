import CSwiftUIAndroid
import SwiftUI

@MainActor @_cdecl("Java_dev_crossswiftui_android_counter_CounterActivity_nativeCreate")
public func createCounter(_ env: SwiftUIJNIEnvironment, _ activity: jobject) -> jlong {
  AndroidHost.retain(root: AnyView(CounterView()))
}
