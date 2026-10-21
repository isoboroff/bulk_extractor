import Foundation

public enum ProcessRunnerError: LocalizedError {
    case processFailed(exitCode: Int32)
    case executableNotFound(path: String)
    case launchFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .processFailed(let code):
            return "Process exited with non-zero status code: \(code)"
        case .executableNotFound(let path):
            return "Executable not found at path: \(path)"
        case .launchFailed(let msg):
            return "Failed to launch process: \(msg)"
        }
    }
}

public class ProcessRunner {
    private var process: Process?
    private var isTerminated = false
    
    public init() {}
    
    public func run(
        executablePath: String,
        arguments: [String],
        environment: [String: String]? = nil,
        onStdout: @escaping (String) -> Void,
        onStderr: @escaping (String) -> Void
    ) async throws {
        guard FileManager.default.isExecutableFile(atPath: executablePath) else {
            throw ProcessRunnerError.executableNotFound(path: executablePath)
        }
        
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: executablePath)
        proc.arguments = arguments
        
        var env = ProcessInfo.processInfo.environment
        if let customEnv = environment {
            for (k, v) in customEnv { env[k] = v }
        }
        proc.environment = env
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        proc.standardOutput = stdoutPipe
        proc.standardError = stderrPipe
        
        self.process = proc
        self.isTerminated = false
        
        try proc.run()
        
        // Read streams asynchronously
        async let stdoutTask: () = readLines(from: stdoutPipe.fileHandleForReading, callback: onStdout)
        async let stderrTask: () = readLines(from: stderrPipe.fileHandleForReading, callback: onStderr)
        
        _ = await (stdoutTask, stderrTask)
        
        proc.waitUntilExit()
        
        if proc.terminationStatus != 0 && !isTerminated {
            throw ProcessRunnerError.processFailed(exitCode: proc.terminationStatus)
        }
    }
    
    private func readLines(from handle: FileHandle, callback: @escaping (String) -> Void) async {
        do {
            for try await line in handle.bytes.lines {
                if !line.isEmpty {
                    callback(line)
                }
            }
        } catch {
            // Stream closed or broken pipe
        }
    }
    
    public func terminate() {
        isTerminated = true
        guard let p = process, p.isRunning else { return }
        
        // Attempt SIGINT first so bulk_extractor can finalize reports cleanly
        p.interrupt()
        
        // Fallback to terminate after brief grace period if still running
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) { [weak p] in
            if let p = p, p.isRunning {
                p.terminate()
            }
        }
    }
}
