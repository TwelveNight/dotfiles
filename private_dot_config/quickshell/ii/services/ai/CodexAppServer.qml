import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property bool running: appServer.running
    property bool ready: false
    property bool busy: false
    property int nextRequestId: 1
    property int initializeRequestId: -1
    property int threadStartRequestId: -1
    property int turnStartRequestId: -1
    property string threadId: ""
    property string activeTurnId: ""
    property string pendingPrompt: ""
    property string pendingSystemPrompt: ""

    signal delta(string text)
    signal finished()
    signal failed(string message)
    signal tokenUsage(int input, int output, int total)
    signal modelResolved(string model)
    signal connectionReset()

    function sendMessage(message) {
        appServer.write(JSON.stringify(message) + "\n");
    }

    function startTurn(prompt, systemPrompt) {
        if (root.busy) {
            root.failed("Codex is still processing the previous message.");
            return false;
        }

        root.pendingPrompt = prompt;
        root.pendingSystemPrompt = systemPrompt;
        root.busy = true;

        if (!appServer.running) {
            root.ready = false;
            root.threadId = "";
            root.activeTurnId = "";
            appServer.running = true;
        } else if (root.ready) {
            root.continuePendingTurn();
        }
        return true;
    }

    function resetThread() {
        root.threadId = "";
        root.activeTurnId = "";
    }

    function continuePendingTurn() {
        if (!root.busy || !root.ready)
            return;
        if (root.threadId.length === 0)
            root.startThread();
        else
            root.startPendingTurn();
    }

    function startThread() {
        root.threadStartRequestId = root.nextRequestId++;
        const params = {
            cwd: Quickshell.env("HOME") || "/tmp",
            ephemeral: true,
            approvalPolicy: "never",
            sandbox: "read-only",
            developerInstructions: root.pendingSystemPrompt
        };
        root.sendMessage({
            method: "thread/start",
            id: root.threadStartRequestId,
            params: params
        });
    }

    function startPendingTurn() {
        root.turnStartRequestId = root.nextRequestId++;
        root.activeTurnId = "";
        root.sendMessage({
            method: "turn/start",
            id: root.turnStartRequestId,
            params: {
                threadId: root.threadId,
                input: [{
                    type: "text",
                    text: root.pendingPrompt
                }],
                approvalPolicy: "never",
                sandboxPolicy: {
                    type: "readOnly",
                    networkAccess: false
                }
            }
        });
    }

    function fail(message) {
        if (!root.busy)
            return;
        root.busy = false;
        root.activeTurnId = "";
        root.failed(message);
    }

    function handleMessage(line) {
        if (line.length === 0)
            return;

        let message;
        try {
            message = JSON.parse(line);
        } catch (error) {
            console.warn("[Codex] Could not parse app-server output:", error, line);
            return;
        }

        if (message.error) {
            root.fail(message.error.message || JSON.stringify(message.error));
            return;
        }

        if (message.id === root.initializeRequestId) {
            root.sendMessage({
                method: "initialized",
                params: {}
            });
            root.ready = true;
            root.continuePendingTurn();
            return;
        }

        if (message.id === root.threadStartRequestId) {
            root.threadId = message.result?.thread?.id || "";
            if (message.result?.model)
                root.modelResolved(message.result.model);
            if (root.threadId.length === 0) {
                root.fail("Codex did not return a thread ID.");
                return;
            }
            root.startPendingTurn();
            return;
        }

        if (message.id === root.turnStartRequestId) {
            root.activeTurnId = message.result?.turn?.id || root.activeTurnId;
            return;
        }

        if (message.method === "turn/started") {
            if (message.params?.threadId === root.threadId)
                root.activeTurnId = message.params?.turn?.id || root.activeTurnId;
            return;
        }

        if (message.method === "item/agentMessage/delta") {
            if (message.params?.threadId !== root.threadId)
                return;
            if (root.activeTurnId.length > 0 && message.params?.turnId !== root.activeTurnId)
                return;
            root.delta(message.params?.delta || "");
            return;
        }

        if (message.method === "thread/tokenUsage/updated") {
            if (message.params?.threadId !== root.threadId)
                return;
            const usage = message.params?.tokenUsage?.last;
            if (usage) {
                root.tokenUsage(usage.inputTokens ?? -1, usage.outputTokens ?? -1, usage.totalTokens ?? -1);
            }
            return;
        }

        if (message.method === "turn/completed") {
            if (message.params?.threadId !== root.threadId)
                return;
            const turn = message.params?.turn;
            if (root.activeTurnId.length > 0 && turn?.id !== root.activeTurnId)
                return;
            if (turn?.status === "failed") {
                root.fail(turn?.error?.message || "The Codex turn failed.");
                return;
            }
            root.busy = false;
            root.activeTurnId = "";
            root.finished();
            return;
        }

        if (message.method === "error") {
            root.fail(message.params?.error?.message || message.params?.message || "Codex reported an error.");
        }
    }

    property Process appServer: Process {
        command: ["codex", "app-server"]
        stdinEnabled: true

        onRunningChanged: {
            if (!running)
                return;
            root.initializeRequestId = root.nextRequestId++;
            root.sendMessage({
                method: "initialize",
                id: root.initializeRequestId,
                params: {
                    clientInfo: {
                        name: "quickshell_ai",
                        title: "Quickshell AI",
                        version: "0.1.0"
                    }
                }
            });
        }

        stdout: SplitParser {
            onRead: line => root.handleMessage(line)
        }

        stderr: SplitParser {
            onRead: line => console.warn("[Codex app-server]", line)
        }

        onExited: (exitCode, exitStatus) => {
            const wasReady = root.ready;
            root.ready = false;
            root.threadId = "";
            root.activeTurnId = "";
            if (root.busy)
                root.fail(`Codex app-server exited (${exitCode}, ${exitStatus}).`);
            if (wasReady)
                root.connectionReset();
        }
    }
}
