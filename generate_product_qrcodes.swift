#!/usr/bin/env swift
// generate_product_qrcodes.swift — Generates scannable product QR codes for demo
// Run: swift generate_product_qrcodes.swift

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CryptoKit
#if canImport(AppKit)
import AppKit
#endif

let outDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("QRCodes").appendingPathComponent("Products")

try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

func generateQR(json: [String: Any], filename: String) {
    guard let data = try? JSONSerialization.data(withJSONObject: json),
          let str = String(data: data, encoding: .utf8) else {
        print("❌ Failed to serialize \(filename)")
        return
    }
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(str.utf8)
    filter.correctionLevel = "M"
    guard let output = filter.outputImage else { print("❌ No QR output for \(filename)"); return }
    let scale: CGFloat = 10
    let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    guard let cgImg = context.createCGImage(scaled, from: scaled.extent) else { return }
    let rep = NSBitmapImageRep(cgImage: cgImg)
    guard let png = rep.representation(using: .png, properties: [:]) else { return }
    let path = outDir.appendingPathComponent(filename)
    try? png.write(to: path)
    print("✅ \(filename) (\(Int(scaled.extent.width))×\(Int(scaled.extent.height)))")
}

func sha256Hex(_ input: String) -> String {
    let digest = SHA256.hash(data: Data(input.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
}

func productPayload(id: String, did: String, serial: String, brand: String, title: String) -> [String: Any] {
    let ts = "\(Int(Date().timeIntervalSince1970))"
    let nonce = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    let hash = sha256Hex("\(id)|\(serial)|\(did)|\(nonce)|\(ts)")
    return [
        "v": 1,
        "t": "product",
        "id": id,
        "did": did,
        "iss": did,
        "hash": hash,
        "ts": ts,
        "nonce": nonce,
        "serial": serial,
        "brand": brand,
        "title": title
    ]
}

// ============================================
// AUTHENTIC PRODUCTS (pre-registered in app seed data)
// Consumer scanning these will see VERIFIED immediately
// ============================================

// 1. Apple MacBook Pro M4 (matches pr1)
generateQR(json: productPayload(
    id: "pr1",
    did: "did:sov:Apple-Corp-0xAPPLE",
    serial: "C02ZF4KHMD6T",
    brand: "Apple",
    title: "MacBook Pro M4"
), filename: "qr_macbook_pro_m4.png")

// 2. Nike Air Jordan 1 (matches prod-nike-aj1)
generateQR(json: productPayload(
    id: "prod-nike-aj1",
    did: "did:sov:Nike-Inc-0xNIKE",
    serial: "NIKE-AJ1-2025-CHI-9912",
    brand: "Nike",
    title: "Air Jordan 1 Retro High OG"
), filename: "qr_nike_air_jordan_1.png")

// 3. Omega Speedmaster (matches prod-omega-speed)
generateQR(json: productPayload(
    id: "prod-omega-speed",
    did: "did:sov:Omega-SA-0xOMEGA",
    serial: "OMEGA-SM-2025-78432",
    brand: "Omega",
    title: "Speedmaster Professional"
), filename: "qr_omega_speedmaster.png")

// 4. Dyson Airwrap (matches prod-dyson-airwrap)
generateQR(json: productPayload(
    id: "prod-dyson-airwrap",
    did: "did:sov:Dyson-Ltd-0xDYSON",
    serial: "DYS-AW-2025-IN-44821",
    brand: "Dyson",
    title: "Airwrap Multi-Styler Complete"
), filename: "qr_dyson_airwrap.png")

// ============================================
// MANUFACTURER-ONLY PRODUCTS
// NOT pre-registered — manufacturer MUST scan these first
// Consumer scanning before manufacturer → shows FAKE/UNREGISTERED
// After manufacturer scans → consumer sees VERIFIED
// ============================================

// 5. Samsung Galaxy S26 Ultra — requires manufacturer verification
generateQR(json: productPayload(
    id: "prod-samsung-s26",
    did: "did:sov:Samsung-Electronics-0xSAM",
    serial: "SAM-S26U-2026-IND-77201",
    brand: "Samsung",
    title: "Galaxy S26 Ultra"
), filename: "qr_samsung_galaxy_s26.png")

// 6. Sony WH-1000XM6 — requires manufacturer verification
generateQR(json: productPayload(
    id: "prod-sony-xm6",
    did: "did:sov:Sony-Corp-0xSONY",
    serial: "SONY-XM6-2026-JP-55102",
    brand: "Sony",
    title: "WH-1000XM6 Headphones"
), filename: "qr_sony_wh1000xm6.png")

// 7. Ray-Ban Meta Smart Glasses — requires manufacturer verification
generateQR(json: productPayload(
    id: "prod-rayban-meta",
    did: "did:sov:RayBan-Meta-0xRBAN",
    serial: "RB-META-2026-IT-33019",
    brand: "Ray-Ban",
    title: "Meta Smart Glasses"
), filename: "qr_rayban_meta.png")

// ============================================
// COUNTERFEIT / FAKE PRODUCTS (will ALWAYS fail)
// ============================================

// 8. Fake Rolex (not in registry → shows FAKE/unregistered)
generateQR(json: productPayload(
    id: "prod-fake-rolex-999",
    did: "did:sov:Unknown-0xFAKE",
    serial: "FAKE-RLX-2025-00000",
    brand: "Rolex",
    title: "Submariner (FAKE)"
), filename: "qr_FAKE_rolex.png")

// 9. Fake Nike (wrong serial — registered ID but mismatched serial → COUNTERFEIT)
generateQR(json: productPayload(
    id: "prod-nike-aj1",
    did: "did:sov:Nike-Inc-0xNIKE",
    serial: "FAKE-SERIAL-0000",
    brand: "Nike",
    title: "Air Jordan 1 (COUNTERFEIT)"
), filename: "qr_FAKE_nike_wrong_serial.png")

// 10. Fake Louis Vuitton (not in registry → FAKE)
generateQR(json: productPayload(
    id: "prod-fake-lv-bag",
    did: "did:sov:Unknown-0xFAKELV",
    serial: "FAKE-LV-2025-00001",
    brand: "Louis Vuitton",
    title: "Neverfull MM (FAKE)"
), filename: "qr_FAKE_louis_vuitton.png")

print("\n🎉 All product QR codes saved to: \(outDir.path)")
print("""

📋 PRODUCT VERIFICATION SYSTEM:

  🔶 VALID DYNAMIC PRODUCT QRs (manufacturer must verify in app first):
      - qr_macbook_pro_m4.png         (Apple MacBook Pro M4)
      - qr_nike_air_jordan_1.png      (Nike Air Jordan 1)
      - qr_omega_speedmaster.png      (Omega Speedmaster)
      - qr_dyson_airwrap.png          (Dyson Airwrap)
     - qr_samsung_galaxy_s26.png     (Samsung Galaxy S26 Ultra)
     - qr_sony_wh1000xm6.png        (Sony WH-1000XM6)
     - qr_rayban_meta.png            (Ray-Ban Meta Smart Glasses)
     → Consumer scan BEFORE manufacturer = ❌ FAKE / UNREGISTERED
     → After manufacturer scans in Manufacturer Verify = ✅ VERIFIED

  ❌ ALWAYS FAKE (will never verify):
     - qr_FAKE_rolex.png             (Unregistered product)
     - qr_FAKE_nike_wrong_serial.png (Serial number mismatch)
     - qr_FAKE_louis_vuitton.png     (Unregistered product)

  FLOW: Manufacturer Verify → Scan QR → Product registered in persistent DB
        Consumer → Scan same QR → Shows VERIFIED with manufacturer details
        Consumer → Scan unregistered QR → Shows FAKE / NOT VERIFIED
""")
