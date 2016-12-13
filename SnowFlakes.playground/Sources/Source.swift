import Foundation
import Cocoa
import SceneKit

// Flake appearance options
public var segmentLength:  CGFloat = 0.0       // The length of flake lines
public var flakeDensity:   Int     = 0         // Increase to make it 'flakier'
public var flakeStroke:    NSColor = NSColor() // Border color
public var strokeWidth:    CGFloat = 0.0       // Border width
public var flakeFillStart: NSColor = NSColor() // Fill gradient - 1st color
public var flakeFillEnd:   NSColor = NSColor() // Fill gradient - 2nd color

// Other options
public var path:           String  = ""        // The exported file path

public extension CGFloat {
    
    /*
     Convenience function for degrees -> radians
     */
    func radians() -> CGFloat {
        return CGFloat(M_PI) * self / 180
    }
}

public extension NSPoint {
    
    /*
     Convenience init for deducing NSPoint coordinates
     given segment length and angle
     */
    init(after length: CGFloat, angle: CGFloat) {
        self.x = cos(angle.radians()) * length
        self.y = sin(angle.radians()) * length
    }
}

public extension NSBezierPath {
    
    /*
     The Koch sequence function, drawn on an existing path
     4 segments: _/\_ (60 deg angle)
     */
    func koch(on path: NSBezierPath, times: Int, length: CGFloat, baseAngle: CGFloat) {
        // Recursive call if the flake is dense
        guard times == 1 else {
            koch(on: path, times: times - 1, length: length / 3, baseAngle: baseAngle)
            koch(on: path, times: times - 1, length: length / 3, baseAngle: baseAngle + 60)
            koch(on: path, times: times - 1, length: length / 3, baseAngle: baseAngle - 60)
            koch(on: path, times: times - 1, length: length / 3, baseAngle: baseAngle)
            
            return
        }
        
        // Draw the 4 segments
        path.relativeLine(to: NSPoint(after: length, angle: baseAngle + 0))     // seg. 1: _
        path.relativeLine(to: NSPoint(after: length, angle: baseAngle + 60))    // seg. 2: /
        path.relativeLine(to: NSPoint(after: length, angle: baseAngle - 60))    // seg. 3: \
        path.relativeLine(to: NSPoint(after: length, angle: baseAngle))         // seg. 4: _
    }
    
    /*
     The actual snow flake function
     3 segments: /_\ (120 deg angle)
     */
    func makeSnowFlake(from point: NSPoint, times: Int, length: CGFloat) {
        self.move(to: point)
        
        koch(on: self, times: times, length: length, baseAngle: 0)              // seg. 1: /
        koch(on: self, times: times, length: length, baseAngle: -120)           // seg. 2: _
        koch(on: self, times: times, length: length, baseAngle: -240)           // seg. 3: \
        
        self.close()
    }
    
    /*
     Measure execution time for the drawing
     l=75.0, d=5 on late 2013 baseline rMBP 15'' -> ~12s
     */
    func makeSnowFlakeAndMeasure(from point: NSPoint, times: Int, length: CGFloat) -> Double {
        let start = DispatchTime.now()
        
        self.makeSnowFlake(from: point, times: times, length: length)
        
        let end = DispatchTime.now()
        
        let elapsedTimeNanos = end.uptimeNanoseconds - start.uptimeNanoseconds
        
        return Double(elapsedTimeNanos) / 1_000_000_000
    }
}

/*
 Compute flake starting NSPoint to center it in the NSRect
 */
func flakeStart(for length: CGFloat, in rect: NSRect) -> NSPoint {
    return NSMakePoint(length / sqrt(2 * length / 50),
                       rect.maxY - length)
}

/*
 Create a NSRect with correct size (4 times the given length)
 */
public func flakeRect(for length: CGFloat) -> NSRect {
    return NSRect(x: 0, y: 0, width: length * 4, height: length * 4)
}

/*
 Export the bezier path to a specified path in a DAE file
 */
public func exportBezierPath(_ path: NSBezierPath, to url: String) -> Bool {
    let shape = SCNShape(path: path, extrusionDepth: 1.0)
    
    let node = SCNNode(geometry: shape)
    
    let scene = SCNScene.init()
    
    scene.rootNode.addChildNode(node)
    
    scene.write(to: URL.init(fileURLWithPath: url),
                options: nil,
                delegate: nil,
                progressHandler: nil)
    
    return true
}

/*
 Custom NSView for the flake
 */
public class FlakeView : NSView {
    
    // Create the path
    public let flakePath = NSBezierPath()
    
    override public func draw(_ dirtyRect: NSRect) {
        // Print execution time
        Swift.print(flakePath.makeSnowFlakeAndMeasure(from: flakeStart(for: segmentLength,
                                                                       in: dirtyRect),
                                                      times: flakeDensity,
                                                      length: segmentLength))
        
        // Draw stroke
        flakeStroke.setStroke()
        flakePath.lineWidth = strokeWidth
        flakePath.stroke()
        
        // Draw background gradient
        NSGradient(starting: flakeFillStart, ending: flakeFillEnd)?
            .draw(in: flakePath, angle: 90.0)
    }
}

/*
 Create the flake view
 */
public func makeFlakeView() -> FlakeView {
    return FlakeView(frame: flakeRect(for: segmentLength))
}
