import SwiftUI

struct DictionarySettingsTab: View {
    @AppStorage("enableDictionary") private var enableDictionary = true
    @State private var terms: [(String, String)] = []
    @State private var customWords: [String] = []
    @State private var userRules: [String] = []
    @State private var newKey = ""
    @State private var newValue = ""
    @State private var newCustomWord = ""
    @State private var newRule = ""

    private let engine = DictionaryEngine()

    var body: some View {
        Form {
            Section("Dictionary") {
                Toggle("Enable dictionary", isOn: $enableDictionary)
                Text("When enabled, terms are replaced in text and custom words are sent to the LLM for correct spelling.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // MARK: - Transformation Rules
            Section {
                Text("Rules that the LLM follows when transforming your speech into text. Add your own or modify the defaults.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Add new rule input
                HStack {
                    TextField("Add a new rule...", text: $newRule)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addRule() }
                    Button(action: addRule) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .disabled(newRule.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                // Rules list
                if userRules.isEmpty {
                    Text("No rules defined. Add rules or reset to defaults.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(userRules.enumerated()), id: \.offset) { index, rule in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 24, alignment: .trailing)

                                Text(rule)
                                    .font(.system(size: 12))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(3)

                                Button {
                                    engine.removeUserRule(at: index)
                                    refreshData()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                                .help("Delete rule")
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 4)
                            .background(
                                index % 2 == 0
                                    ? Color.clear
                                    : Color(nsColor: .controlBackgroundColor).opacity(0.3)
                            )
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                HStack {
                    Spacer()
                    Button("Reset to Defaults") {
                        engine.resetUserRulesToDefaults()
                        refreshData()
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            } header: {
                Label("Transformation Rules", systemImage: "text.badge.checkmark")
            }

            // MARK: - Custom Words & Acronyms
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add words, names, acronyms, or technical terms that you use frequently. The STT and LLM models will use these to produce correct spelling.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView {
                        FlowLayout(spacing: 6) {
                            ForEach(customWords, id: \.self) { word in
                                HStack(spacing: 4) {
                                    Text(word)
                                        .font(.system(size: 12))
                                    Button {
                                        engine.removeCustomWord(word)
                                        refreshData()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                            }
                        }
                    }
                    .frame(minHeight: 40, maxHeight: 120)

                    HStack {
                        TextField("Add word or acronym...", text: $newCustomWord)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { addCustomWord() }
                        Button("Add") { addCustomWord() }
                            .disabled(newCustomWord.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            } header: {
                Text("Custom Words & Acronyms")
            }

            // MARK: - Term Replacements
            Section("Term Replacements") {
                if terms.isEmpty {
                    Text("No replacements defined. Add terms that STT often gets wrong.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 0) {
                    ForEach(terms, id: \.0) { key, value in
                        HStack {
                            Text(key)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\u{2192}")
                                .foregroundColor(.secondary)
                            Text(value)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            Button(role: .destructive) {
                                engine.removeTerm(key: key)
                                refreshData()
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red.opacity(0.7))
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 3)
                        if key != terms.last?.0 { Divider() }
                    }
                }

                HStack {
                    Text("Heard as")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("e.g. mac os", text: $newKey)
                        .textFieldStyle(.roundedBorder)
                    Text("Replace with")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("e.g. macOS", text: $newValue)
                        .textFieldStyle(.roundedBorder)
                    Button("+") {
                        guard !newKey.isEmpty, !newValue.isEmpty else { return }
                        engine.addTerm(key: newKey, value: newValue)
                        newKey = ""; newValue = ""
                        refreshData()
                    }
                    .disabled(newKey.isEmpty || newValue.isEmpty)
                }
            }

            Section {
                HStack {
                    Button("Remove All") {
                        for (key, _) in terms { engine.removeTerm(key: key) }
                        engine.removeAllCustomWords()
                        refreshData()
                    }
                    .foregroundColor(.red)
                    Spacer()
                    Button("Reset Dictionary to Defaults") {
                        try? FileManager.default.removeItem(atPath: NSHomeDirectory() + "/.mystt/dictionary.json")
                        engine.loadDictionary()
                        refreshData()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { refreshData() }
    }

    private func addCustomWord() {
        let word = newCustomWord.trimmingCharacters(in: .whitespaces)
        guard !word.isEmpty else { return }
        engine.addCustomWord(word)
        newCustomWord = ""
        refreshData()
    }

    private func addRule() {
        let rule = newRule.trimmingCharacters(in: .whitespaces)
        guard !rule.isEmpty else { return }
        engine.addUserRule(rule)
        newRule = ""
        refreshData()
    }

    private func refreshData() {
        terms = engine.terms.sorted { $0.key < $1.key }
        customWords = engine.customWords
        userRules = engine.userRules
    }
}

// MARK: - Flow Layout (tag cloud)

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .init(frame.size))
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
