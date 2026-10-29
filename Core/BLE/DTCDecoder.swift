import Foundation

enum DTCDecoder {
    static func decode(_ raw: String) -> [DTCCode] {
        let cleaned = raw.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: ">", with: "")
        guard let range = cleaned.range(of: "43") else { return [] }
        let payload = String(cleaned[range.upperBound...])
        var bytes: [UInt8] = []
        var i = payload.startIndex
        while i < payload.endIndex {
            let j = payload.index(i, offsetBy: 2, limitedBy: payload.endIndex) ?? payload.endIndex
            let chunk = String(payload[i..<j])
            guard chunk.count == 2, let b = UInt8(chunk, radix: 16) else { break }
            bytes.append(b)
            i = j
        }
        var result: [DTCCode] = []
        var idx = 0
        while idx + 1 < bytes.count {
            let b1 = bytes[idx]
            let b2 = bytes[idx+1]
            idx += 2
            if b1 == 0 && b2 == 0 { continue }
            let code = decodePair(b1, b2)
            result.append(DTCCode(code: code, description: description(for: code)))
        }
        return result
    }

    private static func decodePair(_ a: UInt8, _ b: UInt8) -> String {
        let typeChar: Character
        switch (a & 0xC0) >> 6 {
        case 0: typeChar = "P"
        case 1: typeChar = "C"
        case 2: typeChar = "B"
        default: typeChar = "U"
        }
        let d1 = (a & 0x30) >> 4
        let d2 = a & 0x0F
        let d3 = (b & 0xF0) >> 4
        let d4 = b & 0x0F
        return "\(typeChar)\(d1)\(String(format: "%X", d2))\(String(format: "%X", d3))\(String(format: "%X", d4))"
    }

    static func description(for code: String) -> String {
        // Минимальная локальная база. Расширять по SAE J2012.
        let map: [String: String] = [
            "P0115": "Датчик температуры ОЖ — цепь",
            "P0117": "Датчик температуры ОЖ — низкий сигнал",
            "P0118": "Датчик температуры ОЖ — высокий сигнал",
            "P0119": "Датчик температуры ОЖ — прерывистый сигнал",
            "P0128": "Термостат — температура ниже нормы",
            "P0217": "Перегрев двигателя",
        ]
        return map[code] ?? "Код ошибки OBD-II"
    }
}
