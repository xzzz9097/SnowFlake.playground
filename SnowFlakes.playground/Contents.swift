// A snow flakes generator in Swift, using Koch pattern

import Cocoa
import PlaygroundSupport
import SceneKit

// Flake appearance options
segmentLength  = 175.0     // The length of flake lines
flakeDensity   = 5         // Increase to make it 'flakier'
flakeStroke    = .darkGray // Border color
strokeWidth    = 3.0       // Border width
flakeFillStart = .blue     // Fill gradient - 1st color
flakeFillEnd   = .cyan     // Fill gradient - 2nd color

// Other options
path           = "/Users/lyrae/Desktop/file.dae"

// Append to Xcode playground's live page
PlaygroundPage.current.liveView = makeFlakeView()
