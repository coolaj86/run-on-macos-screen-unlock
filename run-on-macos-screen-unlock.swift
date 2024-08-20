import Foundation

let name = (CommandLine.arguments[0] as NSString).lastPathComponent
let version = "1.0.0"
let build = "2024-08-19-001"

let versionMessage = """
\(name) \(version) (\(build))

"""

let copyrightMessage = """
Copyright 2024 AJ ONeal <aj@therootcompany.com>

"""

let helpMessage = """
Runs a user-specified command whenever the screen is unlocked by
listening for the "com.apple.screenIsUnlocked" event, using /usr/bin/command -v
to find the program in the user's PATH (or the explicit path given), and then
runs it with /usr/bin/command, which can run aliases and shell functions also.

USAGE
  \(name) [OPTIONS] <command> [--] [command-arguments]

OPTIONS
  --version, -V, version
      Display the version information and exit.
  --help, help
      Display this help and exit.

DESCRIPTION
  \(name) is a simple command-line tool that demonstrates how to handle
  version and help flags in a Swift program following POSIX conventions.

"""

signal(SIGINT) { _ in
    printForHuman("received ctrl+c, exiting...\n")
    exit(0)
}

func printForHuman(_ message: String) {
    if let data = message.data(using: .utf8) {
        FileHandle.standardError.write(data)
    }
}

func getCommandPath(_ command: String) -> String? {
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

class ScreenLockObserver {
    var commandPath: String
    var commandArgs: ArraySlice<String>

    init(_ commandArgs: ArraySlice<String>) {
        self.commandPath = commandArgs.first!
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
            printForHuman("Failed to run \(self.commandPath): \(error.localizedDescription)\n")
            if let nsError = error as NSError? {
                printForHuman("Error details: \(nsError)\n")
            }
            exit(1)
        }

        task.waitUntilExit()
    }
}

@discardableResult
func removeItem(_ array: inout ArraySlice<String>, _ item: String) -> Bool {
    if let index = array.firstIndex(of: item) {
        array.remove(at: index)
        return true
    }
    return false
}

func processArgs(_ args: inout ArraySlice<String>) -> ArraySlice<String> {
    var childArgs: ArraySlice<String> = []
    if let delimiterIndex = args.firstIndex(of: "--") {
        let childArgsIndex = delimiterIndex + 1
        childArgs = args[childArgsIndex...]
        args.removeSubrange(delimiterIndex...)
    }
    if removeItem(&args, "--help") || removeItem(&args, "help") {
        printForHuman(versionMessage)
        printForHuman("\n")
        printForHuman(helpMessage)
        printForHuman("\n")
        printForHuman(copyrightMessage)
        exit(0)
    }
    if removeItem(&args, "--version") || removeItem(&args, "-V") || removeItem(&args, "version") {
        printForHuman(versionMessage)
        printForHuman(copyrightMessage)
        exit(0)
    }

    childArgs = args + childArgs
    guard childArgs.count > 0 else {
        printForHuman(versionMessage)
        printForHuman("\n")
        printForHuman(helpMessage)
        printForHuman("\n")
        printForHuman(copyrightMessage)
        exit(1)
    }

    let commandName = childArgs.first!
    guard let commandPath = getCommandPath(commandName) else {
        printForHuman("ERROR:\n    \(commandName) not found in PATH\n")
        exit(1)
    }

    childArgs[childArgs.startIndex] = commandPath
    return childArgs
}

var args = CommandLine.arguments[1...]
let commandArgs = processArgs(&args)
_ = ScreenLockObserver(commandArgs)

RunLoop.main.run()
