import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let canvas: CGFloat = 1024
let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)

func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    let red = CGFloat((hex >> 16) & 0xFF) / 255
    let green = CGFloat((hex >> 8) & 0xFF) / 255
    let blue = CGFloat(hex & 0xFF) / 255
    return CGColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
}

func makeContext(pixels: Int) -> CGContext {
    guard
        let context = CGContext(
            data: nil,
            width: pixels,
            height: pixels,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    else {
        fatalError("Could not create bitmap context")
    }
    context.setShouldAntialias(true)
    context.interpolationQuality = .high
    return context
}

func drawIcon(in context: CGContext, pixels: Int) {
    let scale = CGFloat(pixels) / canvas
    context.scaleBy(x: scale, y: scale)

    let iconRect = CGRect(x: 100, y: 100, width: 824, height: 824)
    let iconPath = CGPath(
        roundedRect: iconRect,
        cornerWidth: 185,
        cornerHeight: 185,
        transform: nil
    )

    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -18),
        blur: 40,
        color: color(0x000000, alpha: 0.45)
    )
    context.addPath(iconPath)
    context.setFillColor(color(0x000000))
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(iconPath)
    context.clip()

    let background = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [color(0x241055), color(0x5B21B6), color(0x8B5CF6)] as CFArray,
        locations: [0, 0.62, 1]
    )!
    context.drawLinearGradient(
        background,
        start: CGPoint(x: 170, y: 890),
        end: CGPoint(x: 900, y: 120),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )

    let glow = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [color(0xFFFFFF, alpha: 0.28), color(0xFFFFFF, alpha: 0)] as CFArray,
        locations: [0, 1]
    )!
    context.drawRadialGradient(
        glow,
        startCenter: CGPoint(x: 360, y: 880),
        startRadius: 0,
        endCenter: CGPoint(x: 360, y: 880),
        endRadius: 640,
        options: []
    )

    context.restoreGState()

    context.saveGState()
    context.addPath(iconPath)
    context.setStrokeColor(color(0xFFFFFF, alpha: 0.10))
    context.setLineWidth(5)
    context.strokePath()
    context.restoreGState()

    let speaker = CGMutablePath()
    speaker.move(to: CGPoint(x: 318, y: 438))
    speaker.addLine(to: CGPoint(x: 420, y: 438))
    speaker.addLine(to: CGPoint(x: 562, y: 342))
    speaker.addLine(to: CGPoint(x: 562, y: 682))
    speaker.addLine(to: CGPoint(x: 420, y: 586))
    speaker.addLine(to: CGPoint(x: 318, y: 586))
    speaker.closeSubpath()

    context.saveGState()
    context.addPath(speaker)
    context.setFillColor(color(0xFFFFFF))
    context.fillPath()
    context.addPath(speaker)
    context.setStrokeColor(color(0xFFFFFF))
    context.setLineWidth(22)
    context.setLineJoin(.round)
    context.strokePath()
    context.restoreGState()

    let waveCenter = CGPoint(x: 576, y: 512)
    let waves: [(radius: CGFloat, alpha: CGFloat)] = [
        (66, 1.0),
        (134, 0.85),
        (202, 0.62),
    ]
    context.saveGState()
    context.setLineCap(.round)
    context.setLineWidth(30)
    for wave in waves {
        context.setStrokeColor(color(0xFFFFFF, alpha: wave.alpha))
        context.addArc(
            center: waveCenter,
            radius: wave.radius,
            startAngle: -0.82,
            endAngle: 0.82,
            clockwise: false
        )
        context.strokePath()
    }
    context.restoreGState()

    let badgeCenter = CGPoint(x: 746, y: 286)
    context.saveGState()
    context.addEllipse(
        in: CGRect(
            x: badgeCenter.x - 158,
            y: badgeCenter.y - 158,
            width: 316,
            height: 316
        )
    )
    context.setFillColor(color(0x1B0B3A))
    context.fillPath()

    context.addEllipse(
        in: CGRect(
            x: badgeCenter.x - 130,
            y: badgeCenter.y - 130,
            width: 260,
            height: 260
        )
    )
    context.clip()
    let badgeGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [color(0xFFD166), color(0xFF7A00)] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        badgeGradient,
        start: CGPoint(x: badgeCenter.x, y: badgeCenter.y + 140),
        end: CGPoint(x: badgeCenter.x, y: badgeCenter.y - 140),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
    context.restoreGState()

    context.saveGState()
    context.setFillColor(color(0xFFFFFF))
    let barLength: CGFloat = 128
    let barThickness: CGFloat = 34
    context.addPath(
        CGPath(
            roundedRect: CGRect(
                x: badgeCenter.x - barLength / 2,
                y: badgeCenter.y - barThickness / 2,
                width: barLength,
                height: barThickness
            ),
            cornerWidth: barThickness / 2,
            cornerHeight: barThickness / 2,
            transform: nil
        )
    )
    context.addPath(
        CGPath(
            roundedRect: CGRect(
                x: badgeCenter.x - barThickness / 2,
                y: badgeCenter.y - barLength / 2,
                width: barThickness,
                height: barLength
            ),
            cornerWidth: barThickness / 2,
            cornerHeight: barThickness / 2,
            transform: nil
        )
    )
    context.fillPath()
    context.restoreGState()
}

func writePNG(pixels: Int, to url: URL) {
    let context = makeContext(pixels: pixels)
    drawIcon(in: context, pixels: pixels)
    guard let image = context.makeImage() else {
        fatalError("Could not render \(pixels)px image")
    }
    guard
        let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        )
    else {
        fatalError("Could not create PNG destination at \(url.path)")
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("Could not write \(url.path)")
    }
}

try FileManager.default.createDirectory(
    at: outputDirectory,
    withIntermediateDirectories: true
)

let variants: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for variant in variants {
    writePNG(
        pixels: variant.pixels,
        to: outputDirectory.appendingPathComponent(variant.name)
    )
}
