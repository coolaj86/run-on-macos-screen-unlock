import ArgumentParser
import Foundation

let name = (CommandLine.arguments[0] as NSString).lastPathComponent
let version = "1.0.1"
let build = "2024-08-20-001"
let author = "AJ ONeal <aj@therootcompany.com>"

let versionMessage = "\(name) \(version) (\(build))"
let copyrightMessage = "Copyright 2024 \(author)"

let abstract = "runs a command when screen is unlocked"

let discussion = """
Runs a user-specified command whenever the screen is unlocked by
listening for the "com.apple.screenIsUnlocked" event, using /usr/bin/command -v
to find the program in the user's PATH (or the explicit path given), and then
runs it with /usr/bin/command, which can run aliases and shell functions also.
"""

let helpMessage2 = """
USAGE
  \(name) [OPTIONS] <command> [--] [command-arguments]

OPTIONS
  --version, -V, version
      Display the version information and exit.
  --help, help
      Display this help and exit.
"""

signal(SIGINT) { _ in
    printForHuman("received ctrl+c, exiting...")
    exit(0)
}

func printForHuman(_ message: String) {
    if let data = "\(message)\n".data(using: .utf8) {
        FileHandle.standardError.write(data)
    }
}

class ScreenLockObserver {
    var commandPath: String
    var commandArgs: [String]

    init(_ commandArgs: [String]) {
        commandPath = commandArgs.first!
        self.commandArgs = commandArgs

        let dnc = DistributedNotificationCenter.default()

        _ = dnc.addObserver(forName: NSNotification.Name("com.apple.screenIsLocked"), object: nil, queue: .main) { _ in
            NSLog("notification: com.apple.screenIsLocked")
        }

        NSLog("Waiting for 'com.apple.screenIsUnlocked' to run \(self.commandArgs)")
        _ = dnc.addObserver(forName: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil, queue: .main) { _ in
            NSLog("notification: com.apple.screenIsUnlocked")
            self.runOnUnlock()
        }
    }

    private func runOnUnlock() {
        let task = Process()
        task.launchPath = "/usr/bin/command"
        task.arguments = Array(commandArgs)
        task.standardOutput = FileHandle.standardOutput
        task.standardError = FileHandle.standardError

        do {
            try task.run()
        } catch {
            printForHuman("Failed to run \(commandPath): \(error.localizedDescription)")
            if let nsError = error as NSError? {
                printForHuman("Error details: \(nsError)")
            }
            exit(1)
        }

        task.waitUntilExit()
    }
}

struct RunOnMacosScreenUnlock: ParsableCommand {
    @Flag(name: [.customShort("V")], help: "version")
    var showVersion: Bool = false

    // note: `--` is handled POSIX-correctly (all flags and options after -- are parsed as arguments)
    @Argument(help: "The command and arguments to run after screen unlock.")
    var commandAndArgs: [String]

    // note: printed if no arguments are provided, or if --help is passed.
    static var configuration = CommandConfiguration(
        abstract: abstract,
        discussion: discussion,
        version: "\(versionMessage)\n\(copyrightMessage)",
        shouldDisplay: true,
        subcommands: [Help.self, Version.self],
        helpNames: [.long]
        /* versionNames: [.long, .customShort("-V")], */
    )

	struct Help: ParsableCommand {
        static let configuration = CommandConfiguration()

        mutating func run() {
            let helpMessage = RunOnMacosScreenUnlock.helpMessage(includeHidden: false)
            print(helpMessage)
        }
    }

	struct Version: ParsableCommand {
        static let configuration = CommandConfiguration()

        mutating func run() {
            let helpMessage = RunOnMacosScreenUnlock.helpMessage(includeHidden: false)
            print(helpMessage)
        }
    }

    mutating func validate() throws {
        if showVersion || commandAndArgs.contains("version") {
            print(versionMessage)
            print(copyrightMessage)
            throw ExitCode.success
        }

        /* if commandAndArgs.contains("help") { */
        /*     let helpMessage = Self.helpMessage(includeHidden: false) */
        /*     print(helpMessage) */
        /*     /1* print("\(versionMessage) - \(abstract)") *1/ */
        /*     /1* print() *1/ */
        /*     /1* print(discussion) *1/ */
        /*     /1* print() *1/ */
        /*     /1* print(helpMessage2) *1/ */
        /*     /1* print() *1/ */
        /*     /1* print(copyrightMessage) *1/ */
        /*     throw ExitCode.success */
        /* } */

        /* guard !commandAndArgs.isEmpty else { */
        /*     throw ValidationError("No command provided. Use --help to see usage.") */
        /* } */
    }

    func run() throws {
        var childArgs = commandAndArgs
        print(childArgs)

        // Extract and resolve the command
        guard let commandName = childArgs.first else {
            throw ValidationError("No command provided.")
        }

        guard let commandPath = getCommandPath(commandName) else {
            throw ValidationError("ERROR:\n    \(commandName) not found in PATH")
        }

        // Replace the command name with the resolved path
        childArgs[childArgs.startIndex] = commandPath

        _ = ScreenLockObserver(childArgs)
    }

    private func getCommandPath(_ command: String) -> String? {
        let commandv = Process()
        commandv.launchPath = "/usr/bin/command"
        commandv.arguments = ["-v", command]

        let pipe = Pipe()
        commandv.standardOutput = pipe
        commandv.standardError = FileHandle.standardError

        try! commandv.run()
        commandv.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let commandPath = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        else {
            return nil
        }

        if commandv.terminationStatus != 0, commandPath.isEmpty {
            return nil
        }

        return commandPath
    }

    private func executeChildProcess(with args: [String]) {
        // Implement the logic to execute the child process with the provided arguments
        print("Executing command with arguments: \(args)")
    }
}

RunOnMacosScreenUnlock.main()
RunLoop.main.run()
