import Foundation

enum Mood {
    case asleep       // nothing running
    case working      // a turn is in flight
    case waiting      // Claude needs the user
    case celebrating  // just finished
}

/// Watches for Claude Code activity.
///
/// Claude Code hooks write a tiny state file (see hook.sh) whenever something
/// happens. We poll its mtime rather than watching it, because the hook writes
/// atomically via rename and a file watch would follow the wrong inode.
///
/// Two things stop Clawd getting stuck "working" forever:
///   * a heartbeat deadline, because `Stop` does not fire when a turn is
///     interrupted with Esc or when the process is killed, and
///   * a liveness sweep over ~/.claude/sessions/<pid>.json, so quitting Claude
///     entirely puts Clawd straight back to sleep.
final class TaskMonitor {

    static let stateDirectory = NSHomeDirectory() + "/.clawdpet"
    static let stateFile = stateDirectory + "/state.json"
    private static let sessionsDirectory = NSHomeDirectory() + "/.claude/sessions"

    /// How long a turn may go quiet before we assume it ended.
    ///
    /// This has to be two-tier. A tool can run for minutes — `PreToolUse` fires,
    /// then nothing at all until `PostToolUse` — so a single short timeout would
    /// put Clawd to sleep in the middle of a long build. Anything else means the
    /// model is generating, which is bounded much more tightly.
    private let toolInFlightTimeout: TimeInterval = 600
    private let thinkingTimeout: TimeInterval = 120

    /// The most generous window, used when deciding whether a state file is stale.
    private var heartbeatTimeout: TimeInterval { toolInFlightTimeout }

    /// True when the last thing we saw was a tool starting.
    private var toolInFlight = false
    /// How long to celebrate after `Stop` before dozing off.
    private let celebrateDuration: TimeInterval = 1.2
    private let sessionSweepInterval: TimeInterval = 2.0

    private(set) var mood: Mood = .asleep

    /// Fires on each newly observed hook event: (event, toolName).
    var onEvent: ((String, String?) -> Void)?

    private var lastStateMtime: TimeInterval = 0
    private var lastEventAt: Date?
    private var celebratingSince: Date?
    private var lastSessionSweep = Date.distantPast
    private var anySessionAlive = false
    private var needsAttention = false

    func poll() {
        sweepSessionsIfDue()
        readStateIfChanged()
        resolveMood()
    }

    // MARK: - State file

    private func readStateIfChanged() {
        let fm = FileManager.default
        guard let attrs = try? fm.attributesOfItem(atPath: Self.stateFile),
              let modified = attrs[.modificationDate] as? Date else { return }

        let mtime = modified.timeIntervalSince1970
        guard mtime > lastStateMtime else { return }
        lastStateMtime = mtime

        guard let data = fm.contents(atPath: Self.stateFile),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let event = object["event"] as? String else { return }

        // Trust the timestamp the hook recorded, not the moment we noticed the file.
        // Otherwise a state file left over from an old session makes Clawd spring to
        // life the instant it launches.
        let stamped = (object["ts"] as? Double).map { Date(timeIntervalSince1970: $0) } ?? modified
        guard Date().timeIntervalSince(stamped) <= heartbeatTimeout else { return }

        let tool = (object["tool"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let notify = (object["notify"] as? String) ?? ""

        apply(event: event, tool: tool, notify: notify, at: stamped)
        onEvent?(event, tool)
    }

    private func apply(event: String, tool: String?, notify: String, at when: Date) {
        switch event {
        case "Stop", "StopFailure":
            celebratingSince = when
            lastEventAt = nil

        case "SessionEnd":
            celebratingSince = nil
            lastEventAt = nil

        case "Notification":
            // Only the notifications that actually want the user's attention.
            celebratingSince = nil
            lastEventAt = when
            needsAttention = ["permission_prompt", "idle_prompt", "agent_needs_input"].contains(notify)

        default:
            // UserPromptSubmit, Pre/PostToolUse, SubagentStart/Stop, SessionStart.
            // Any of these means the turn moved on, so we are no longer blocked.
            celebratingSince = nil
            needsAttention = false
            lastEventAt = when
        }

        // `PreToolUse` with no matching `PostToolUse` yet means a tool is running.
        switch event {
        case "PreToolUse", "SubagentStart":
            toolInFlight = true
        default:
            toolInFlight = false
        }
    }

    private func resolveMood() {
        guard anySessionAlive else {
            mood = .asleep
            celebratingSince = nil
            lastEventAt = nil
            needsAttention = false
            return
        }

        if let since = celebratingSince {
            mood = Date().timeIntervalSince(since) < celebrateDuration ? .celebrating : .asleep
            if mood == .asleep { celebratingSince = nil }
            return
        }

        guard let last = lastEventAt else {
            mood = .asleep
            return
        }

        let budget = toolInFlight ? toolInFlightTimeout : thinkingTimeout
        if Date().timeIntervalSince(last) > budget {
            mood = .asleep
            lastEventAt = nil
            needsAttention = false
            toolInFlight = false
        } else {
            mood = needsAttention ? .waiting : .working
        }
    }

    // MARK: - Session liveness

    private func sweepSessionsIfDue() {
        guard Date().timeIntervalSince(lastSessionSweep) >= sessionSweepInterval else { return }
        lastSessionSweep = Date()
        anySessionAlive = liveSessionCount() > 0
    }

    private func liveSessionCount() -> Int {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: Self.sessionsDirectory) else { return 0 }

        var alive = 0
        for name in names where name.hasSuffix(".json") {
            let path = Self.sessionsDirectory + "/" + name
            guard let data = fm.contents(atPath: path),
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let pid = object["pid"] as? Int else { continue }
            if isRunning(pid: pid) { alive += 1 }
        }
        return alive
    }

    private func isRunning(pid: Int) -> Bool {
        if kill(pid_t(pid), 0) == 0 { return true }
        // EPERM means the process exists, we just may not signal it.
        return errno == EPERM
    }
}
