#!/usr/bin/env swift
// generate_appicon.swift — Run: swift generate_appicon.swift
// Creates a 1024x1024 app icon matching the Sovereign Trust futuristic blue theme.

import Foundation
import CoreGraphics
import CoreImage
import AppKit

let size: CGFloat = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()

guard let ctx = CGContext(
    data: nil,
    width: Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("Cannot create context") }

// 1. Deep navy gradient background
let bgColors: [CGFloat] = [
    0.015, 0.025, 0.10, 1.0,   // top: near-black navy
    0.04, 0.08, 0.22, 1.0,     // mid
    0.02, 0.04, 0.14, 1.0      // bottom: deep navy
]
let bgGradient = CGGradient(colorSpace: colorSpace, colorComponents: bgColors, locations: [0, 0.5, 1], count: 3)!
ctx.drawLinearGradient(bgGradient,
    start: CGPoint(x: size/2, y: size),
    end: CGPoint(x: size/2, y: 0),
    options: [])

// 2. Blue glow orb in center
let glowCenter = CGPoint(x: size * 0.5, y: size * 0.48)
let glowColors: [CGFloat] = [
    0.15, 0.50, 0.90, 0.35,    // bright blue center
    0.08, 0.30, 0.70, 0.15,    // mid
    0.04, 0.10, 0.30, 0.0      // fade
]
let glowGradient = CGGradient(colorSpace: colorSpace, colorComponents: glowColors, locations: [0, 0.4, 1], count: 3)!
ctx.drawRadialGradient(glowGradient,
    startCenter: glowCenter, startRadius: 0,
    endCenter: glowCenter, endRadius: size * 0.45,
    options: [])

// 3. Shield outline
let cx = size / 2
let cy = size * 0.42
let shieldW: CGFloat = size * 0.28
let shieldH: CGFloat = size * 0.35

ctx.setStrokeColor(CGColor(red: 0.13, green: 0.82, blue: 0.93, alpha: 0.9))
ctx.setLineWidth(size * 0.025)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)

// Shield path
ctx.beginPath()
ctx.move(to: CGPoint(x: cx, y: cy - shieldH * 0.5))
ctx.addLine(to: CGPoint(x: cx + shieldW * 0.5, y: cy - shieldH * 0.28))
ctx.addLine(to: CGPoint(x: cx + shieldW * 0.5, y: cy + shieldH * 0.15))
ctx.addQuadCurve(to: CGPoint(x: cx, y: cy + shieldH * 0.5),
                 control: CGPoint(x: cx + shieldW * 0.35, y: cy + shieldH * 0.42))
ctx.addQuadCurve(to: CGPoint(x: cx - shieldW * 0.5, y: cy + shieldH * 0.15),
                 control: CGPoint(x: cx - shieldW * 0.35, y: cy + shieldH * 0.42))
ctx.addLine(to: CGPoint(x: cx - shieldW * 0.5, y: cy - shieldH * 0.28))
ctx.closePath()
ctx.strokePath()

// 4. Lock keyhole inside shield
let lockCy = cy - shieldH * 0.05
let lockR: CGFloat = size * 0.05
ctx.setFillColor(CGColor(red: 0.13, green: 0.82, blue: 0.93, alpha: 0.85))
ctx.fillEllipse(in: CGRect(x: cx - lockR, y: lockCy - lockR, width: lockR*2, height: lockR*2))

// Lock body (rectangle below)
let lockBodyW: CGFloat = size * 0.035
let lockBodyH: CGFloat = size * 0.06
ctx.fill(CGRect(x: cx - lockBodyW/2, y: lockCy + lockR * 0.5, width: lockBodyW, height: lockBodyH))

// 5. Circling ring around shield
ctx.setStrokeColor(CGColor(red: 0.13, green: 0.82, blue: 0.93, alpha: 0.25))
ctx.setLineWidth(size * 0.008)
let ringR: CGFloat = size * 0.30
ctx.strokeEllipse(in: CGRect(x: cx - ringR, y: cy - ringR, width: ringR*2, height: ringR*2))

// 6. "ST" text below
let textY = size * 0.75
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: size * 0.08, weight: .bold),
    .foregroundColor: NSColor(red: 0.13, green: 0.82, blue: 0.93, alpha: 0.7)
]
let str = NSAttributedString(string: "SOVEREIGN TRUST", attributes: attrs)
let line = CTLineCreateWithAttributedString(str)
let bounds = CTLineGetBoundsWithOptions(line, [])

ctx.saveGState()
ctx.textPosition = CGPoint(x: cx - bounds.width/2, y: size - textY - bounds.height/2)
CTLineDraw(line, ctx)
ctx.restoreGState()

// Save
guard let image = ctx.makeImage() else { fatalError("Cannot make image") }
let rep = NSBitmapImageRep(cgImage: image)
guard let pngData = rep.representation(using: .png, properties: [:]) else { fatalError("Cannot create PNG") }

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon-1024.png"
try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("Generated \(outputPath) (\(pngData.count) bytes)")
