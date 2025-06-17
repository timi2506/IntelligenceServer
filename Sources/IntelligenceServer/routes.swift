import Vapor
import FoundationModels
import AsyncHTTPClient
func routes(_ app: Application) throws {
    let routesPrint =
    """
    Available Routes:
    
    1. GET / and /routes           
    - Returns these Routes.
    
    2. GET /respond
    - Input: Provide the prompt in one of the following ways:
        • As a query parameter:   ?prompt=YourPromptHere
        • As JSON in the body:    { "prompt": "YourPromptHere" }
        • As plain text in the body: YourPromptHere
    - Output: Returns the generated response as plain text (String).
    
    3. GET /respondJSON
    - Same input options as /respond.
    - Output: Returns the generated response in a JSON object: { "output": "..." }
    
    4. GET /stream
    - Same input options as /respond.
    - Output: Streams the generated response as plain text (chunked).
    
    5. GET /streamJSON
    - Same input options as /respond.
    - Output: Streams the generated response as JSON objects (chunked): { "output": "..." }
    """
    
    app.get { req async in
        return routesPrint
    }
    app.get("routes") { req async in
        return routesPrint
    }
    
    app.get("respond") { req async throws -> String in
        let input = try await getInput(from: req)
        
        let response = try await LanguageModelSession(transcript: Transcript()).respond(to: input)
        return response.content
    }
    app.get("respondJSON") { req async throws -> OutputBody in
        let input = try await getInput(from: req)
        
        let response = try await LanguageModelSession(transcript: Transcript()).respond(to: input)
        let output = OutputBody(output: response.content)
        
        return output
    }
    app.get("stream") { req async throws -> Response in
        let input = try await getInput(from: req)

        return Response(body: .init(asyncStream: { writer in
            do {
                let stream = LanguageModelSession(transcript: Transcript()).streamResponse(to: input)
                
                for try await stringChunk in stream {
                    var buffer = ByteBufferAllocator().buffer(capacity: stringChunk.utf8.count)
                    buffer.writeString(stringChunk)
                    try await writer.writeBuffer(buffer)
                }
                try await writer.write(.end)
            } catch {
                try await writer.write(.error(error))
            }
        }))
    }
    app.get("streamJSON") { req async throws -> Response in
        let input = try await getInput(from: req)

        return Response(body: .init(asyncStream: { writer in
            do {
                let stream = LanguageModelSession(transcript: Transcript()).streamResponse(to: input)
                
                for try await stringChunk in stream {
                    let jsonChunk = try encodeToJSONString(OutputBody(output: stringChunk))
                    var buffer = ByteBufferAllocator().buffer(capacity: jsonChunk.utf8.count)
                    buffer.writeString(jsonChunk)
                    try await writer.writeBuffer(buffer)
                }
                try await writer.write(.end)
            } catch {
                try await writer.write(.error(error))
            }
        }))
    }
}

import Vapor

struct PromptBody: Content {
    let prompt: String
}

struct OutputBody: Content {
    let output: String
}

func encodeToJSONString<T: Content>(_ content: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys] // optional for nicer formatting
    let data = try encoder.encode(content)
    guard let jsonString = String(data: data, encoding: .utf8) else {
        throw Abort(.internalServerError, reason: "Failed to convert JSON data to string")
    }
    return jsonString
}

func getInput(from req: Request) async throws -> String {
    // 1. Try query param "input"
    if let input = req.query[String.self, at: "prompt"] {
        return input
    }
    
    // 2. Try JSON body with { "prompt": "..." }
    if let promptBody = try? req.content.decode(PromptBody.self) {
        return promptBody.prompt
    }
    
    // 3. Try raw string body
    if let rawBody = req.body.string, !rawBody.isEmpty {
        return rawBody
    }
    
    // 4. If all fail, throw error
    throw Abort(.badRequest, reason: "Missing prompt")
}
