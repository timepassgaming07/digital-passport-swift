#!/usr/bin/env swift
// generate_qrcodes.swift — Generates scannable QR code PNGs for Sovereign Trust app
// Run: swift generate_qrcodes.swift

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
#if canImport(AppKit)
import AppKit
#endif

let outDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("QRCodes")

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

let ts = "\(Int(Date().timeIntervalSince1970))"

// 1 — Verifiable Credential (Passport)
generateQR(json: [
    "v": 1, "t": "vc", "id": "vc-passport-001",
    "did": "did:sovereign:user:abc123def456",
    "iss": "did:sovereign:gov:passport-authority",
    "hash": "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0",
    "ts": ts,
    "title": "Digital Passport"
], filename: "qr_credential_passport.png")

// 2 — Verifiable Credential (Driver License)
generateQR(json: [
    "v": 1, "t": "vc", "id": "vc-license-002",
    "did": "did:sovereign:user:abc123def456",
    "iss": "did:sovereign:gov:dmv-authority",
    "hash": "f1e2d3c4b5a6f7e8d9c0b1a2f3e4d5c6b7a8f9e0",
    "ts": ts,
    "docType": "drivers_license",
    "title": "Driver License"
], filename: "qr_credential_license.png")

// 3 — Verifiable Credential (University Degree)
generateQR(json: [
    "v": 1, "t": "vc", "id": "vc-degree-003",
    "did": "did:sovereign:user:abc123def456",
    "iss": "did:sovereign:edu:mit-university",
    "hash": "c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9",
    "ts": ts,
    "title": "Bachelor of Computer Science"
], filename: "qr_credential_degree.png")

// 4 — Product (Luxury Watch)
generateQR(json: [
    "v": 1, "t": "product", "id": "prod-watch-001",
    "did": "did:sovereign:product:omega-speedmaster",
    "iss": "did:sovereign:brand:omega-sa",
    "hash": "d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3",
    "ts": ts,
    "serial": "OMEGA-SM-2025-78432",
    "brand": "Omega",
    "title": "Speedmaster Professional"
], filename: "qr_product_watch.png")

// 5 — Product (Sneakers)
generateQR(json: [
    "v": 1, "t": "product", "id": "prod-sneaker-002",
    "did": "did:sovereign:product:nike-aj1-chicago",
    "iss": "did:sovereign:brand:nike-inc",
    "hash": "e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4",
    "ts": ts,
    "serial": "NIKE-AJ1-2025-CHI-9912",
    "brand": "Nike",
    "title": "Air Jordan 1 Chicago"
], filename: "qr_product_sneakers.png")

// 6 — Handshake / Login
generateQR(json: [
    "v": 1, "t": "handshake", "id": "hs-login-001",
    "did": "did:sovereign:service:secure-portal",
    "iss": "did:sovereign:org:sovereign-trust",
    "hash": "b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9",
    "ts": ts,
    "service": "sovereign-trust-portal",
    "nonce": "n-\(UUID().uuidString.prefix(8))",
    "callback": "https://portal.sovereign.example/auth/callback"
], filename: "qr_handshake_login.png")

// 7 — Document
generateQR(json: [
    "v": 1, "t": "document", "id": "doc-contract-001",
    "did": "did:sovereign:doc:employment-contract",
    "iss": "did:sovereign:org:acme-corp",
    "hash": "a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8",
    "ts": ts,
    "docType": "employment_contract",
    "title": "Employment Agreement — Acme Corp"
], filename: "qr_document_contract.png")

// 8 — DID Identity
generateQR(json: [
    "v": 1, "t": "did", "id": "did-identity-001",
    "did": "did:sovereign:user:abc123def456",
    "iss": "did:sovereign:network:mainnet",
    "hash": "f0e1d2c3b4a5f6e7d8c9b0a1f2e3d4c5b6a7f8e9",
    "ts": ts
], filename: "qr_did_identity.png")

print("\n🎉 All QR codes saved to: \(outDir.path)")
