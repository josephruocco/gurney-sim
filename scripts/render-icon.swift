// Run: swift scripts/render-icon.swift [output.png]
// Vector master: assets/gurney-journey.svg. Keep these drawing coordinates in sync.
import AppKit
import ImageIO
import UniformTypeIdentifiers
let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "ios/Gurney/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let size = 1024
let c = CGContext(data:nil,width:size,height:size,bitsPerComponent:8,bytesPerRow:size*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
c.scaleBy(x: 10.24, y: 10.24)
c.translateBy(x: 0, y: 100)
c.scaleBy(x: 1, y: -1)
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor { CGColor(red:r/255,green:g/255,blue:b/255,alpha:1) }
let cream = color(238,234,221), mint = color(105,212,170)
c.setFillColor(color(16,39,43)); c.fill(CGRect(x:0,y:0,width:100,height:100))
func line(_ points: [CGPoint], _ width: CGFloat, _ stroke: CGColor) {
 c.setStrokeColor(stroke); c.setLineWidth(width); c.setLineCap(.round); c.setLineJoin(.round)
 c.beginPath(); c.addLines(between: points); c.strokePath()
}
func pts(_ numbers: [CGFloat]) -> [CGPoint] { stride(from:0,to:numbers.count,by:2).map { CGPoint(x:numbers[$0],y:numbers[$0+1]) } }
c.saveGState(); c.translateBy(x:50,y:55); c.rotate(by: -.pi/18); c.translateBy(x:-50,y:-55)
line(pts([24,34,24,57,77,57,77,43]),5,cream)
line(pts([24,48,77,48]),5,cream)
line(pts([33,57,40,72,65,72,72,57]),5,cream)
line(pts([30,41,42,41]),7,cream)
c.setFillColor(cream)
for x in [35,63] { c.fillEllipse(in:CGRect(x:x,y:75,width:8,height:8)) }
c.restoreGState()
line(pts([63,22,79,22]),5,mint); line(pts([71,14,71,30]),5,mint)
line(pts([12,63,21,63]),3,mint); line(pts([9,72,23,72]),3,mint)
let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath:output) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination,c.makeImage()!,nil)
precondition(CGImageDestinationFinalize(destination), "Could not write icon")
