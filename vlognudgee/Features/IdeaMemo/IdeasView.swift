//
//  IdeasView.swift
//  VlogNudge
//
//  A simple place to jot down video ideas for later. Tap an idea to edit,
//  swipe to mark it used or delete. The "+" (and the Today-screen "Capture
//  idea" button / Capture-idea intent) open the editor straight away.
//

import SwiftUI
import SwiftData

struct IdeasView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \IdeaMemo.createdAt, order: .reverse) private var ideas: [IdeaMemo]

    @State private var showEditor = false
    @State private var editingIdea: IdeaMemo?

    var body: some View {
        NavigationStack {
            Group {
                if ideas.isEmpty {
                    emptyState
                } else {
                    ideaList
                }
            }
            .navigationTitle("Ideas")
            .safeAreaInset(edge: .bottom) { addButton }
            .sheet(isPresented: $showEditor) {
                IdeaEditorView(idea: editingIdea)
            }
            .onChange(of: appState.composeIdea, initial: true) { _, compose in
                if compose {
                    presentEditor(for: nil)
                    appState.composeIdea = false
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: VNSpacing.lg) {
            Image(systemName: "lightbulb")
                .font(.system(size: 56))
                .foregroundStyle(VNColor.textTertiary)
            Text("No ideas yet")
                .font(VNFont.title2)
                .foregroundStyle(VNColor.textPrimary)
            Text("Jot down video ideas whenever they strike — we'll keep them here so you always have something to film.")
                .font(VNFont.callout)
                .foregroundStyle(VNColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, VNSpacing.xxxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VNColor.dominant)
    }

    // MARK: - List

    private var ideaList: some View {
        List {
            ForEach(ideas) { idea in
                IdeaRow(idea: idea)
                    .contentShape(Rectangle())
                    .onTapGesture { presentEditor(for: idea) }
                    .listRowBackground(VNColor.secondary)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            delete(idea)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            toggleUsed(idea)
                        } label: {
                            Label(idea.usedAt == nil ? "Used" : "Unmark",
                                  systemImage: idea.usedAt == nil ? "checkmark" : "arrow.uturn.backward")
                        }
                        .tint(VNColor.success)
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(VNColor.dominant)
    }

    // MARK: - Add button

    private var addButton: some View {
        Button {
            presentEditor(for: nil)
        } label: {
            HStack(spacing: VNSpacing.sm) {
                Image(systemName: "plus")
                Text("New idea")
            }
            .font(VNFont.headline)
            .foregroundStyle(VNColor.dominant)
            .frame(maxWidth: .infinity)
            .padding(.vertical, VNSpacing.lg)
            .background(VNColor.accent, in: RoundedRectangle(cornerRadius: VNRadius.lg))
            .padding(.horizontal, VNSpacing.lg)
            .padding(.bottom, VNSpacing.sm)
        }
        .buttonStyle(.plain)
        .background(
            LinearGradient(
                colors: [VNColor.dominant, VNColor.dominant.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 40)
            .allowsHitTesting(false),
            alignment: .top
        )
    }

    // MARK: - Actions

    private func presentEditor(for idea: IdeaMemo?) {
        editingIdea = idea
        showEditor = true
    }

    private func toggleUsed(_ idea: IdeaMemo) {
        idea.usedAt = idea.usedAt == nil ? Date() : nil
        try? modelContext.save()
    }

    private func delete(_ idea: IdeaMemo) {
        modelContext.delete(idea)
        try? modelContext.save()
    }
}

// MARK: - Idea Row

struct IdeaRow: View {
    let idea: IdeaMemo

    private var isUsed: Bool { idea.usedAt != nil }

    var body: some View {
        HStack(alignment: .top, spacing: VNSpacing.md) {
            Image(systemName: isUsed ? "checkmark.circle.fill" : "lightbulb.fill")
                .font(.system(size: 20))
                .foregroundStyle(isUsed ? VNColor.success : VNColor.accent)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                Text(idea.text)
                    .font(VNFont.body)
                    .foregroundStyle(isUsed ? VNColor.textSecondary : VNColor.textPrimary)
                    .strikethrough(isUsed)
                    .lineLimit(4)
                Text(idea.createdAt, style: .date)
                    .font(VNFont.caption)
                    .foregroundStyle(VNColor.textTertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, VNSpacing.xs)
        .accessibilityLabel(isUsed ? "Used idea: \(idea.text)" : "Idea: \(idea.text)")
    }
}

// MARK: - Editor

struct IdeaEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// nil = composing a new idea; non-nil = editing an existing one.
    let idea: IdeaMemo?
    @State private var text: String
    @FocusState private var focused: Bool

    init(idea: IdeaMemo?) {
        self.idea = idea
        _text = State(initialValue: idea?.text ?? "")
    }

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                VNColor.dominant.ignoresSafeArea()

                TextEditor(text: $text)
                    .focused($focused)
                    .font(VNFont.body)
                    .foregroundStyle(VNColor.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(VNSpacing.lg)

                if text.isEmpty {
                    Text("What's the video idea?")
                        .font(VNFont.body)
                        .foregroundStyle(VNColor.textTertiary)
                        .padding(.horizontal, VNSpacing.lg + 5)
                        .padding(.top, VNSpacing.lg + 8)
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle(idea == nil ? "New idea" : "Edit idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(trimmed.isEmpty)
                }
            }
            .onAppear { focused = true }
        }
    }

    private func save() {
        guard !trimmed.isEmpty else { dismiss(); return }
        if let idea {
            idea.text = trimmed
        } else {
            modelContext.insert(IdeaMemo(text: trimmed))
        }
        try? modelContext.save()
        dismiss()
    }
}
