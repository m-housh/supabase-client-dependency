import Foundation
import GoTrue
import IdentifiedCollections

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
  static let databaseClientDecoder = { () -> JSONDecoder in
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
  static let databaseClientEncoder = { () -> JSONEncoder in
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .custom { date, encoder in
      var container = encoder.singleValueContainer()
      let string = dateFormatter.string(from: date)
      try container.encode(string)
    }
    return encoder
  }()
}

extension Data {
  func decoding<T: Decodable>(as type: T.Type, with decoder: JSONDecoder) throws -> T {
    try decoder.decode(T.self, from: self)
  }
}

extension Array where Element == (any Encodable) {

  func anyJSON(encoder: JSONEncoder) throws -> [[String: AnyJSON]] {
    let encoded = try self.map { try encoder.encode($0) }
    return try encoded.map {
      try JSONDecoder.databaseClientDecoder.decode([String: AnyJSON].self, from: $0)
    }
  }
}
