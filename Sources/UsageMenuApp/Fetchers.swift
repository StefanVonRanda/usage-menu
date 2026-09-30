import Foundation
import Security

enum UsageFetcherError: LocalizedError, Sendable {
    case claudeTokenNotFound
    case codexAuthNotFound(String)
    case httpError(Int, String)
    case decodeError(String)

    var errorDescription: String? {
        switch self {
        case .claudeTokenNotFound:
            return "Claude token not found in Keychain (run `claude login`)"
        case .codexAuthNotFound(let detail):
            return "Codex auth not found: \(detail) (run codex login)"
        case .httpError(let code, let body):
            return "HTTP \(code): \(body.prefix(160))"
        case .decodeError(let detail):
            return "Decode error: \(detail)"
        }
    }
}

struct ClaudeKeychain {
    /// Reads the OAuth access token stored by Claude Code in the login keychain
    /// under service "Claude Code-credentials".
    static func accessToken() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            throw UsageFetcherError.claudeTokenNotFound
        }
        // Stored JSON: {"claudeAiOauth": {"accessToken": "sk-ant-oat01-..."}}
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let oauth = json["claudeAiOauth"] as? [String: Any],
           let token = oauth["accessToken"] as? String, !token.isEmpty {
            return token
        }
        // Fallback: raw string token
        if let raw = String(data: data, encoding: .utf8), !raw.isEmpty {
            return raw.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        throw UsageFetcherError.claudeTokenNotFound
    }
}

struct CodexAuth: Codable {
    struct Tokens: Codable {
        var access_token: String?
        var account_id: String?
    }
    var tokens: Tokens?
}

struct UsageFetchers {
    static func fetchClaude() async throws -> ClaudeUsageResponse {
        let token = try ClaudeKeychain.accessToken()
        var req = URLRequest(url: URL(string: "https://claude.ai/api/oauth/usage")!)
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("claude-code/2.1.285", forHTTPHeaderField: "User-Agent")
        req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        req.timeoutInterval = 20
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw UsageFetcherError.httpError(-1, "no response")
        }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw UsageFetcherError.httpError(http.statusCode, body)
        }
        do {
            return try JSONDecoder().decode(ClaudeUsageResponse.self, from: data)
        } catch {
            throw UsageFetcherError.decodeError(error.localizedDescription)
        }
    }

    static func fetchCodex() async throws -> CodexUsageResponse {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let authURL = home.appendingPathComponent(".codex/auth.json")
        guard let data = try? Data(contentsOf: authURL) else {
            throw UsageFetcherError.codexAuthNotFound("~/.codex/auth.json missing")
        }
        let auth: CodexAuth
        do {
            auth = try JSONDecoder().decode(CodexAuth.self, from: data)
        } catch {
            throw UsageFetcherError.codexAuthNotFound("unparseable auth.json")
        }
        guard let access = auth.tokens?.access_token, !access.isEmpty else {
            throw UsageFetcherError.codexAuthNotFound("no access_token")
        }
        guard let accountId = auth.tokens?.account_id, !accountId.isEmpty else {
            throw UsageFetcherError.codexAuthNotFound("no account_id")
        }
        var req = URLRequest(url: URL(string: "https://chatgpt.com/backend-api/codex/usage")!)
        req.httpMethod = "GET"
        req.setValue("Bearer \(access)", forHTTPHeaderField: "Authorization")
        req.setValue(accountId, forHTTPHeaderField: "ChatGPT-Account-Id")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("codex-cli/0.44.0", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 20
        let (respData, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw UsageFetcherError.httpError(-1, "no response")
        }
        guard http.statusCode == 200 else {
            let body = String(data: respData, encoding: .utf8) ?? ""
            throw UsageFetcherError.httpError(http.statusCode, body)
        }
        do {
            return try JSONDecoder().decode(CodexUsageResponse.self, from: respData)
        } catch {
            throw UsageFetcherError.decodeError(error.localizedDescription)
        }
    }

    static func fetchAll() async -> UsageSnapshot {
        async let claudeTask: Result<ClaudeUsageResponse, Error> = {
            do { return .success(try await fetchClaude()) }
            catch { return .failure(error) }
        }()
        async let codexTask: Result<CodexUsageResponse, Error> = {
            do { return .success(try await fetchCodex()) }
            catch { return .failure(error) }
        }()
        let claudeResult = await claudeTask
        let codexResult = await codexTask
        var snap = UsageSnapshot(fetchedAt: Date())
        switch claudeResult {
        case .success(let v): snap.claude = v
        case .failure(let e): snap.claudeError = e.localizedDescription
        }
        switch codexResult {
        case .success(let v): snap.codex = v
        case .failure(let e): snap.codexError = e.localizedDescription
        }
        return snap
    }
}
