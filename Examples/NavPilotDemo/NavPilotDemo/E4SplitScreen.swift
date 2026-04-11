//
//  E4SplitScreen.swift
//  NavPilot
//
//  Created by DK on 02/04/26.
//

import SwiftUI
import NavPilot

enum E4FeedRoute: Hashable {
    case feed
    case post(id: Int, title: String)
    case authorProfile(name: String)
}

// ── Right pane: Chat ─────────────────────────────────────────

enum E4ChatRoute: Hashable {
    case inbox
    case thread(id: Int, with: String)
    case newMessage
}

// ── Root ─────────────────────────────────────────────────────

struct E4SplitScreen: View {
    @StateObject var feedPilot = NavPilot(initial: E4FeedRoute.feed)
    @StateObject var chatPilot = NavPilot(initial: E4ChatRoute.inbox)

    var body: some View {
        VStack(spacing: 0) {
            // Left pane — Feed
            NavPilotHost(feedPilot) { route in
                switch route {
                case .feed:
                    E4FeedView()
                case .post(let id, let title):
                    E4PostView(id: id, title: title)
                case .authorProfile(let name):
                    E4AuthorProfileView(name: name)
                }
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Right pane — Chat
            NavPilotHost(chatPilot) { route in
                switch route {
                case .inbox:
                    E4InboxView()
                case .thread(let id, let person):
                    E4ThreadView(id: id, person: person)
                case .newMessage:
                    E4NewMessageView()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// ── Feed pane views ───────────────────────────────────────────

struct E4FeedView: View {
    @EnvironmentObject var pilot: NavPilot<E4FeedRoute>

    let posts = [(1, "Swift Tips"), (2, "SwiftUI Tricks"), (3, "Async/Await")]

    var body: some View {
        List(posts, id: \.0) { id, title in
            Button {
                pilot.push(.post(id: id, title: title))
            } label: {
                Label(title, systemImage: "doc.text")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(.mint)
        .navigationTitle("Feed")
    }
}

struct E4PostView: View {
    @EnvironmentObject var pilot: NavPilot<E4FeedRoute>
    let id: Int
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Post #\(id)").font(.caption).foregroundStyle(.secondary)
            Text(title).font(.title2).bold()
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque euismod.")
                .foregroundStyle(.secondary)
            Spacer()
            Button("View Author Profile") {
                pilot.push(.authorProfile(name: "Jane Doe"))
            }
            Button("Back to Feed") { pilot.pop() }
            Button("Pop to Root")  { pilot.popToRoot() }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(.green)
        .navigationTitle(title)
    }
}

struct E4AuthorProfileView: View {
    @EnvironmentObject var pilot: NavPilot<E4FeedRoute>
    let name: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            Text(name).font(.title2).bold()
            Text("iOS Developer & Writer").foregroundStyle(.secondary)
            Spacer()
            Button("Back to Post")  { pilot.pop() }
            Button("Back to Feed")  { pilot.popTo(.feed) }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(.cyan)
        .navigationTitle("Author")
    }
}

// ── Chat pane views ───────────────────────────────────────────

struct E4InboxView: View {
    @EnvironmentObject var pilot: NavPilot<E4ChatRoute>

    let threads = [(1, "Alice"), (2, "Bob"), (3, "Carol")]

    var body: some View {
        List {
            Section {
                ForEach(threads, id: \.0) { id, person in
                    Button {
                        pilot.push(.thread(id: id, with: person))
                    } label: {
                        Label(person, systemImage: "bubble.left")
                    }
                }
            }
            Section {
                Button {
                    pilot.push(.newMessage)
                } label: {
                    Label("New Message", systemImage: "square.and.pencil")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(.yellow)
        .navigationTitle("Inbox")
    }
}

struct E4ThreadView: View {
    @EnvironmentObject var pilot: NavPilot<E4ChatRoute>
    let id: Int
    let person: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            HStack {
                Image(systemName: "bubble.left.fill").foregroundStyle(.blue)
                Text("Hey! How are you?")
                Spacer()
            }
            HStack {
                Spacer()
                Text("I'm good, thanks!")
                Image(systemName: "bubble.right.fill").foregroundStyle(.green)
            }
            Spacer()
            Button("New Message")  { pilot.push(.newMessage) }
            Button("Back to Inbox") { pilot.pop() }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(.indigo)
        .navigationTitle(person)
    }
}

struct E4NewMessageView: View {
    @EnvironmentObject var pilot: NavPilot<E4ChatRoute>
    @State private var recipient = ""

    var body: some View {
        VStack(spacing: 20) {
            TextField("To:", text: $recipient)
                .textFieldStyle(.roundedBorder)
            Text("Type your message below…")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Send & Go to Inbox") {
                pilot.popToRoot()   // jump all the way back to inbox
            }
            Button("Cancel") { pilot.pop() }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color.orange)
        .navigationTitle("New Message")
    }
}
