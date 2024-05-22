
import Foundation

public extension String {
    
    /// Decodes a String into an instance of a given Decodable type T (or nil), assuming UTF8 encoding.
    func decoded<T: Decodable>() -> T? {
        try? JSONDecoder().decode(T.self, from: self.data(using: .utf8) ?? Data())
    }
}

public extension Encodable {
    
    /// Encodes an Encodable into a JSON string with a UTF8 encoding.
    func encoded() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return .init(data: data, encoding: .utf8)!
    }
}
