# IntelligenceServer

A Simple Apple Intelligence AI Server for macOS 26+ on M1 or higher Macs

## Getting Started
To run a prebuilt version of IntelligenceServer (EXPERIMENTAL) go to the [latest Release](https://github.com/timi2506/IntelligenceServer/releases/latest)

To build the project using the Swift Package Manager, run the following command in the terminal from the root of the project:
```bash
swift build
```

To run the project and start the server, use the following command:
```bash
swift run
```

To execute tests, use the following command:
```bash
swift test
```

### Available Routes
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
  
### Roadmap
OpenAI Compatible Routes for use in Apps like Xcode
