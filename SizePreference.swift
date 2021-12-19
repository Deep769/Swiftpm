//
//  File.swift
//  Transforms
//
//  Created by David M Reed on 12/18/21.
//

import SwiftUI

typealias UpdateSizeFunction = ((CGSize) -> Void)

/// PreferenceKey for SizeReaderPreferenceModifier
struct SizeReaderPreference: PreferenceKey {
    static var defaultValue: CGSize? = nil
    
    static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
        // if no new value, nothing to change
        guard let next = nextValue() else {
            return
        }
        // update to last value
        value = next
    }
}

// used for View extension `sizeReader(sizeReader: @escaping UpdateSizeFunction)`
struct SizeReaderPreferenceModifier: ViewModifier {
    /// function that is called with the updated size (if the size is not nil)
    var updateSize: UpdateSizeFunction?
    
    func body(content: Content) -> some View {
        // use overlay since otherwise GeometryReader takes all available space
        content.overlay(GeometryReader { geometry in
            // set the preference to the size of the content view
            Color.clear.preference(key: SizeReaderPreference.self, value: geometry.size)
        })
            .onPreferenceChange(SizeReaderPreference.self) {
                // only update if not nil
                if let size = $0 {
                    updateSize?(size)
                }
            }
    }
}

extension View {
    /***
     use this to get the size of a view
     - Parameter sizeReader: function that is called with the update size
     - Returns: modified View
     
     example usage:
     ```
     struct Cell: View {
     var sharedHeight: CGFloat? = 0
     @State private var size: CGSize = CGSize(width: 0, height: 0)
     var body: some View {
     Text("Cell Row \(sharedHeight ?? 0) \(size.height)")
     .frame(height: CGFloat(Int.random(in: 50...90)))
     .frame(minHeight: sharedHeight)
     // use the sizeReader to get the size and set it to the @State variable
     .sizeReader() {
     self.size = $0
     }
     }
     }
     ```
     */
    func sizeReader(sizeReader: @escaping UpdateSizeFunction) -> some View {
        self.modifier(SizeReaderPreferenceModifier(updateSize: sizeReader))
    }
}
