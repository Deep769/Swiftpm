import SwiftUI

struct PathInfo {
    let points: [CGPoint]
    let transform: CGAffineTransform
    let color: Color
    
    /// init
    /// - Parameters:
    ///   - points: array of CGPoint for the path (not closed unless last point == first point
    ///   - transform: transform to apply when drawing
    ///   - color: color to use when drawing
    init(points: [CGPoint], transform: CGAffineTransform = .identity, color: Color = .black) {
        self.points = points
        self.transform = transform
        self.color = color
    }
    
    
    /// get a PathInfo for an aligned rectangle defined by two diagonally opposite points
    /// - Parameters:
    ///   - p1: one corner of rectangle
    ///   - p2: diagonally opposite corner of retangle
    ///   - transform: transform to apply when drawing
    ///   - color: color to use when drawing
    /// - Returns: PathInfo for the rectangle
    static func rectangle(p1: CGPoint, p2: CGPoint, transform: CGAffineTransform = .identity, color: Color = .black) -> PathInfo {
        
        // make path for rectangle from the diagonally opposite points
        let points = [p1, CGPoint(x: p1.x, y: p2.y), p2, CGPoint(x: p2.x, y: p1.y), p1]
        return PathInfo(points: points, transform: transform, color: color)
    }
}


/// a Canvas with normalized x, y coordinates (-1, -1) is bottom left corner and (1, 1) is top right corner
/// supports drawing of an array of PathInfo structs
struct NormalizedCanvasView: View {
    let paths: [PathInfo]
    let showAxes: Bool
    
    /// init
    /// - Parameters:
    ///   - paths: array of PathInfo to draw
    ///   - showAxes: whether or not to show the x- and y-axis
    init(paths: [PathInfo], showAxes: Bool = true) {
        self.paths = paths
        self.showAxes = showAxes
    }
    
    var body: some View {
        Canvas { context, size in
            let halfWidth = size.width / 2.0
            let halfHeight = size.height / 2.0
            
            // the ...by versions apply the transforms in reverse order (scaledBy before the translate)
            //let transform = CGAffineTransform(translationX: halfWidth, y: halfHeight).scaledBy(x: halfWidth, y: -halfHeight)
            
            // compute the transformation from -1 to 1 for x and y (with (-1, -1) at bottom left corner)
            // to Canvas coordinates with (0, 0) at top left and (width, height) at bottom right
            // concatenating applys them in order listed (s before t)
            let t = CGAffineTransform(translationX: halfWidth, y: halfHeight)
            let s = CGAffineTransform(scaleX: halfWidth, y: -halfHeight)
            let transform = s.concatenating(t)
            
            if showAxes {
                drawAxes(context: context, size: size)
            }
            
            for pathInfo in paths {
                // transform each point first by its tranformation and then the viewport transformation
                let transformedPoints = pathInfo.points.map {
                    $0.applying(pathInfo.transform.concatenating(transform))
                }
                // make a path out of the polyline with the transformed points
                let p = Path { path in
                    path.addLines(transformedPoints)
                }
                // draw it with appropriate color
                context.stroke(p, with: .color(pathInfo.color), lineWidth: 1)
            }
        }
    }
    
    /// draw the x- and y-axes
    /// - Parameters:
    ///   - context: Canvas context
    ///   - size: size of Canvas
    func drawAxes(context: GraphicsContext, size: CGSize) {
        let width = size.width
        let height = size.height
        let halfWidth = width / 2.0
        let halfHeight = height / 2.0
        
        // endpoints for x-axis
        let leftX = CGPoint(x: 0, y: halfHeight)
        let rightX = CGPoint(x: width, y: halfHeight)
        
        // end points for y-axis
        let topY = CGPoint(x: halfWidth, y: 0)
        let bottomY = CGPoint(x: halfWidth, y: height)
        
        // make two separate lines for the axes
        let axesPath = Path { path in
            path.move(to: leftX)
            path.addLine(to: rightX)
            path.move(to: topY)
            path.addLine(to: bottomY)
        }
        context.stroke(axesPath, with: .color(.black), lineWidth: 1)
        
    }
}

struct ContentView: View {
    @State private var sx = 1.0
    @State private var sy = 1.0
    @State private var tx = 0.0
    @State private var ty = 0.0
    @State private var angleInDegrees = 0.0
    @State private var transformationString = "R(0)*T(0,0)*S(1,1)"
    @State private var rectangleString = "-0.25 -0.25 0.25 0.25"
    @State private var statusMessage = ""
    @State private var transform = CGAffineTransform(scaleX: 1.0, y: 1.0).concatenating(.init(rotationAngle: 0.0)).concatenating(.init(translationX: 0.0, y: 0.0))
    @State private var paths = [PathInfo.rectangle(p1: CGPoint(x: 0.25, y: -0.25), p2: CGPoint(x: 0.75, y: 0.25), transform: .identity)]
    
    var body: some View {
        VStack {
            ZStack {
                Color.white
                    GeometryReader { geometry in
                        NormalizedCanvasView(paths: paths)
                            .frame(width: 600, height: 600,  alignment: .center)
                            .padding(100)
                    }
            }
            VStack(alignment: .leading) {
                VStack {
                    HStack {
                        Text("Rectangle coordinates:")
                        TextField("Rectangle", text: $rectangleString)
                    }
                    HStack {
                        Text("Transformation:").font(.title2)
                        TextField("Transform", text: $transformationString)
                    }
                }.font(.title2)
                Text(statusMessage).font(.title).frame(alignment: .leading)
            }.padding(40)
        }
        .onChange(of: rectangleString) { _ in
            updateRectangle()
        }
        .onChange(of: transformationString) { _ in
            updateTransform()
        }
        .onAppear() {
            updateTransform()
        }
    }
    
    func updateRectangle() {
        let values = rectangleString.components(separatedBy: .whitespaces)
            .compactMap { Double($0) }
        if values.count == 4 {
            paths = [PathInfo.rectangle(p1: CGPoint(x: values[0], y: values[1]), p2: CGPoint(x: values[2], y: values[3]), transform: transform)]
        } else {
            statusMessage = "invalid four values for rectangle"
        }
    }
    
    func updateTransform() {
        do {
            let parser =  TransformationString(transformationString)
            let t = try parser.parse()
            print(t)
            transform = t
            updateRectangle()
            statusMessage = String(describing: t)
        } catch {
            statusMessage = "invalid transformation string"
        }

    }
    
}
