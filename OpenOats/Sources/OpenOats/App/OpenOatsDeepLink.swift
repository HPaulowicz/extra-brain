import Foundation

enum OpenOatsDeepLink {
    static func parse(_ url: URL) -> ExternalCommand? {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "openoats" || scheme == "extrabrain"
        else {
            return nil
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let host = url.host?.lowercased() ?? ""
        let rawSessionID = queryValue(named: "sessionID", in: components)
            ?? queryValue(named: "sessionId", in: components)
            ?? queryValue(named: "id", in: components)
            ?? pathSessionID(from: url)
        let sessionID = rawSessionID.flatMap(SessionIDValidator.normalize(_:))

        switch host {
        case "start":
            return .startSession
        case "stop":
            return .stopSession
        case "notes":
            return .openNotes(sessionID: sessionID)
        default:
            return nil
        }
    }

    private static func queryValue(named name: String, in components: URLComponents?) -> String? {
        components?.queryItems?.first(where: { $0.name == name })?.value
    }

    private static func pathSessionID(from url: URL) -> String? {
        let trimmedPath = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return trimmedPath.isEmpty ? nil : trimmedPath
    }
}
