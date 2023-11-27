//
//  Models.swift
//
//
//  Created by Alfian Losari on 02/03/23.
//

import Foundation

public struct PlainMessage: Codable {
    public let role: String
    public let content: String
}

public enum MessageContentType: String, Encodable {
    enum CodingKeys: String, CodingKey {
        case text
        case imageURL = "image_url"
    }
    
    case text
    case imageURL
}

public struct ImageInput: Encodable {
    public enum Detail: String, Encodable {
        case auto, low, high
    }
    
    public enum SupportedType: String, Encodable {
        case png, jpeg
    }
    
    public enum ImageType {
        case base64Encoded(String, SupportedType)
        case url(String)
    }
    
    enum CodingKeys: String, CodingKey {
        case url
        case detail
    }
    
    let imageType: ImageType
    let detail: Detail
    
    var url: String {
        return switch imageType {
        case .base64Encoded(let string, let supportedType):
            "data:image/\(supportedType.rawValue);base64,\(string)"
        case .url(let string):
            string
        }
    }
    
    public init(imageType: ImageType, detail: Detail = .auto) {
        self.imageType = imageType
        self.detail = detail
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try container.encode(detail, forKey: .detail)
    }
}

public protocol MessageContent: Encodable {
    var type: MessageContentType { get }
}

public struct TextMessageContent: MessageContent {
    public let type: MessageContentType
    public let text: String
    
    init(content: String) {
        self.type = .text
        self.text = content
    }
}

public struct ImageMessageContent: MessageContent {
    public enum CodingKeys: String, CodingKey {
        case type
        case imageInput = "image_url"
    }
    
    public let type: MessageContentType
    public let imageInput: ImageInput
    
    init(imageInput: ImageInput) {
        self.type = .imageURL
        self.imageInput = imageInput
    }
}

public class Message: Encodable {
    enum CodingKeys: CodingKey {
        case role
        case content
    }
    
    public let role: String
    
    init(role: String) {
        self.role = role
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(AnyEncodable(getContent()), forKey: .content)
    }
    
    public func getContent() -> [MessageContent] {
        fatalError("Implement in subclass")
    }
}

public class TextMessage: Message {
    let content: [TextMessageContent]
    
    init(role: String, text: String) {
        content = [TextMessageContent(content: text)]
        super.init(role: role)
    }
    
    public override func getContent() -> [MessageContent] {
        return content
    }
}

public class ImageMessage: Message {
    let content: [MessageContent]
    
    init(role: String, text: String, imageInput: ImageInput) {
        content = [
            TextMessageContent(content: text),
            ImageMessageContent(imageInput: imageInput)
        ]
        
        super.init(role: role)
    }
    
    public override func getContent() -> [MessageContent] {
        return content
    }
}

extension Array where Element == TextMessage {
    var contentCount: Int { map { $0.content }.count }
    var content: String { reduce("") { $0 + ($1.content.first?.text ?? "") } }
}

struct Request: Encodable {
    enum CodingKeys: String, CodingKey {
        case model
        case temperature
        case messages
        case stream
        case maxTokens = "max_tokens"
    }
    
    let model: String
    let temperature: Double
    let messages: [Message]
    let stream: Bool
    let maxTokens: Int?
}

struct ErrorRootResponse: Decodable {
    let error: ErrorResponse
}

struct ErrorResponse: Decodable {
    let message: String
    let type: String?
}

struct CompletionResponse: Decodable {
    let choices: [Choice]
    let usage: Usage?
}

struct Usage: Decodable {
    let promptTokens: Int?
    let completionTokens: Int?
    let totalTokens: Int?
}

struct Choice: Decodable {
    let finishReason: String?
    let message: PlainMessage
}

struct StreamCompletionResponse: Decodable {
    let choices: [StreamChoice]
}

struct StreamChoice: Decodable {
    let finishReason: String?
    let delta: StreamMessage
}

struct StreamMessage: Decodable {
    let content: String?
    let role: String?
}
