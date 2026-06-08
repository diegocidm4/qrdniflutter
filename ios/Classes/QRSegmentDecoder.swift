//
//  QRSegmentDecoder.swift
//  TramiteFoto
//
//  Created by CQeSolutions on 07/06/2026.
//  Copyright © 2026 Diego. All rights reserved.
//


//  QRSegmentDecoder.swift
//  Reensambla el payload lógico de un QR a partir del stream de bits
//  del errorCorrectedPayload, segmento a segmento (byte, alfanumérico,
//  numérico), igual que hacen los decodificadores completos.

import Foundation

enum QRSegmentDecoder {

    static func reassemble(payload: Data, version: Int) -> Data? {
        let bytes = [UInt8](payload)
        var bitPos = 0
        let totalBits = bytes.count * 8

        func readBits(_ n: Int) -> Int? {
            guard n > 0, bitPos + n <= totalBits else { return nil }
            var value = 0
            for _ in 0..<n {
                let byteIndex = bitPos >> 3
                let bitIndex = 7 - (bitPos & 7)
                value = (value << 1) | Int((bytes[byteIndex] >> UInt8(bitIndex)) & 1)
                bitPos += 1
            }
            return value
        }

        func countBits(forMode mode: Int) -> Int? {
            switch mode {
            case 0b0001: return version <= 9 ? 10 : (version <= 26 ? 12 : 14) // numérico
            case 0b0010: return version <= 9 ? 9  : (version <= 26 ? 11 : 13) // alfanumérico
            case 0b0100: return version <= 9 ? 8  : 16                        // byte
            default: return nil
            }
        }

        let alphaTable = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:".utf8)
        var out = [UInt8]()

        while bitPos + 4 <= totalBits {
            guard let mode = readBits(4) else { break }
            if mode == 0b0000 { break } // terminador

            if mode == 0b0111 { // ECI: saltar el designador (1, 2 o 3 bytes)
                guard let first = readBits(8) else { return nil }
                if first & 0x80 != 0 {
                    if first & 0x40 == 0 { _ = readBits(8) } else { _ = readBits(16) }
                }
                continue
            }

            guard let cBits = countBits(forMode: mode),
                  let count = readBits(cBits) else { return nil }

            switch mode {
            case 0b0100: // BYTE: count bytes tal cual
                for _ in 0..<count {
                    guard let b = readBits(8) else { return nil }
                    out.append(UInt8(b))
                }
            case 0b0010: // ALFANUMÉRICO: 11 bits por par de caracteres
                var remaining = count
                while remaining >= 2 {
                    guard let v = readBits(11), v < 45 * 45 else { return nil }
                    out.append(alphaTable[v / 45])
                    out.append(alphaTable[v % 45])
                    remaining -= 2
                }
                if remaining == 1 {
                    guard let v = readBits(6), v < 45 else { return nil }
                    out.append(alphaTable[v])
                }
            case 0b0001: // NUMÉRICO: 10 bits por trío de dígitos
                var remaining = count
                while remaining >= 3 {
                    guard let v = readBits(10) else { return nil }
                    out.append(contentsOf: String(format: "%03d", v).utf8)
                    remaining -= 3
                }
                if remaining == 2 {
                    guard let v = readBits(7) else { return nil }
                    out.append(contentsOf: String(format: "%02d", v).utf8)
                } else if remaining == 1 {
                    guard let v = readBits(4) else { return nil }
                    out.append(contentsOf: String(v).utf8)
                }
            default:
                return nil // modo no soportado (kanji...): abortar al fallback
            }
        }

        return out.isEmpty ? nil : Data(out)
    }
}
