import Foundation
import GoTrue

private let dateFormatterWithFractionalSeconds = { () -> ISO8601DateFormatter in
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  return formatter
}()

private let dateFormatter = { () -> ISO8601DateFormatter in
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime]
  return formatter
}()

extension JSONDecoder {
  static let databaseClient = { () -> JSONDecoder in
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let string = try container.decode(String.self)

      let supportedFormatters = [dateFormatterWithFractionalSeconds, dateFormatter]

      for formatter in supportedFormatters {
        if let date = formatter.date(from: string) {
          return date
        }
      }

      throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "Invalid date format: \(string)"
      )
    }
    return decoder
  }()
}

extension JSONEncoder {
  static let databaseClient = { () -> JSONEncoder in
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .custom { date, encoder in
      var container = encoder.singleValueContainer()
      let string = dateFormatter.string(from: date)
      try container.encode(string)
    }
    return encoder
  }()
}

extension Dictionary where Key == String, Value == AnyJSON {

  func decoding<T: Decodable>(as type: T.Type) throws -> T {
    print("Decoding dictionary: \(self)")
    let encoded = try JSONEncoder.databaseClient.encode(self)
    return try JSONDecoder.databaseClient.decode(T.self, from: encoded)
  }
}

extension Array where Element == [String: AnyJSON] {
  func decoding<T: Decodable>(as type: T.Type) throws -> [T] {
    try self.map { try $0.decoding(as: T.self) }
  }

}
