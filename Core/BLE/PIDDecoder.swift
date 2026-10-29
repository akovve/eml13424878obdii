import Foundation

/// Декодер PID OBD-II Mode 01. Приоритет — температура антифриза (PID 05).
struct PIDDecoder {
    static let allPIDs: [String] = [
        "04","05","06","07","08","09","0A","0B","0C","0D","0E","0F","10","11",
        "1F","2F","33","42","43","44","45","46","47","49","4A","4C","5A","5C","5E"
    ]
    static func decode(pid: String, bytes: [UInt8]) -> SensorReading? {
        let p = pid.uppercased()
        switch p {
        case "04":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Нагрузка двигателя", value: Double(bytes[0]) * 100.0 / 255.0, unit: "%")
        case "05":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Температура антифриза", value: Double(bytes[0]) - 40.0, unit: "°C")
        case "06":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Краткосрочная коррекция топлива B1", value: (Double(bytes[0]) - 128.0) * 100.0 / 128.0, unit: "%")
        case "07":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Долгосрочная коррекция топлива B1", value: (Double(bytes[0]) - 128.0) * 100.0 / 128.0, unit: "%")
        case "08":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Краткосрочная коррекция топлива B2", value: (Double(bytes[0]) - 128.0) * 100.0 / 128.0, unit: "%")
        case "09":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Долгосрочная коррекция топлива B2", value: (Double(bytes[0]) - 128.0) * 100.0 / 128.0, unit: "%")
        case "0A":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Давление топлива", value: Double(bytes[0]) * 3.0, unit: "kPa")
        case "0B":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Давление во впускном коллекторе", value: Double(bytes[0]), unit: "kPa")
        case "0C":
            guard bytes.count >= 2 else { return nil }
            return SensorReading(pid: p, name: "Обороты двигателя", value: (Double(bytes[0]) * 256.0 + Double(bytes[1])) / 4.0, unit: "rpm")
        case "0D":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Скорость автомобиля", value: Double(bytes[0]), unit: "km/h")
        case "0E":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Угол опережения зажигания", value: (Double(bytes[0]) - 128.0) / 2.0, unit: "°")
        case "0F":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Температура впуска", value: Double(bytes[0]) - 40.0, unit: "°C")
        case "10":
            guard bytes.count >= 2 else { return nil }
            return SensorReading(pid: p, name: "MAF (расход воздуха)", value: (Double(bytes[0]) * 256.0 + Double(bytes[1])) / 100.0, unit: "g/s")
        case "11":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Положение дросселя", value: Double(bytes[0]) * 100.0 / 255.0, unit: "%")
        case "1F":
            guard bytes.count >= 2 else { return nil }
            return SensorReading(pid: p, name: "Время работы двигателя", value: Double(bytes[0]) * 256.0 + Double(bytes[1]), unit: "s")
        case "2F":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Уровень топлива", value: Double(bytes[0]) * 100.0 / 255.0, unit: "%")
        case "33":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Атмосферное давление", value: Double(bytes[0]), unit: "kPa")
        case "42":
            guard bytes.count >= 2 else { return nil }
            return SensorReading(pid: p, name: "Напряжение бортсети", value: (Double(bytes[0]) * 256.0 + Double(bytes[1])) / 1000.0, unit: "V")
        case "43":
            guard bytes.count >= 2 else { return nil }
            return SensorReading(pid: p, name: "Абсолютная нагрузка", value: (Double(bytes[0]) * 256.0 + Double(bytes[1])) * 100.0 / 255.0, unit: "%")
        case "44":
            guard bytes.count >= 2 else { return nil }
            return SensorReading(pid: p, name: "Коэффициент эквивалентности", value: (Double(bytes[0]) * 256.0 + Double(bytes[1])) / 32768.0, unit: "λ")
        case "45":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Относительное положение дросселя", value: Double(bytes[0]) * 100.0 / 255.0, unit: "%")
        case "46":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Температура окружающей среды", value: Double(bytes[0]) - 40.0, unit: "°C")
        case "47":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Положение дросселя B", value: Double(bytes[0]) * 100.0 / 255.0, unit: "%")
        case "49":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Педаль акселератора D", value: Double(bytes[0]) * 100.0 / 255.0, unit: "%")
        case "4A":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Педаль акселератора E", value: Double(bytes[0]) * 100.0 / 255.0, unit: "%")
        case "4C":
            guard bytes.count >= 3 else { return nil }
            return SensorReading(pid: p, name: "Время работы двигателя (общее)", value: Double(bytes[0]) * 65536.0 + Double(bytes[1]) * 256.0 + Double(bytes[2]), unit: "s")
        case "5A":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Относительное положение педали", value: Double(bytes[0]) * 100.0 / 255.0, unit: "%")
        case "5C":
            guard bytes.count >= 1 else { return nil }
            return SensorReading(pid: p, name: "Температура масла", value: Double(bytes[0]) - 40.0, unit: "°C")
        case "5E":
            guard bytes.count >= 2 else { return nil }
            return SensorReading(pid: p, name: "Расход топлива", value: (Double(bytes[0]) * 256.0 + Double(bytes[1])) / 20.0, unit: "L/h")
        default:
            return nil
        }
    }

    /// Парсинг ответа ELM327 на запрос "01 XX" → массив байт данных.
    static func parseResponse(_ raw: String, pid: String) -> [UInt8]? {
        // Убираем пробелы, \r, >, и всё до 41 XX
        let cleaned = raw.uppercased().replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: ">", with: "")
        let target = "41" + pid.uppercased()
        guard let range = cleaned.range(of: target) else { return nil }
        let after = String(cleaned[range.upperBound...])
        // Берём hex-байты попарно, пока не встретим не-hex
        var bytes: [UInt8] = []
        var i = after.startIndex
        while i < after.endIndex {
            let j = after.index(i, offsetBy: 2, limitedBy: after.endIndex) ?? after.endIndex
            let chunk = String(after[i..<j])
            guard chunk.count == 2, let b = UInt8(chunk, radix: 16) else { break }
            bytes.append(b)
            i = j
        }
        return bytes.isEmpty ? nil : bytes
    }
}