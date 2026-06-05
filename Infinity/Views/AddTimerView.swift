import SwiftUI

struct AddTimerView: View {
    var onDismiss: () -> Void = {}
    @EnvironmentObject var store: TimerStore

    init(editing item: TimerItem? = nil, onDismiss: @escaping () -> Void = {}) {
        self.onDismiss = onDismiss
        if let item {
            _editingID    = State(initialValue: item.id)
            _name         = State(initialValue: item.name)
            _emoji        = State(initialValue: item.emoji)
            _kind         = State(initialValue: item.kind)
            _startDate    = State(initialValue: item.startDate)
            _targetDate   = State(initialValue: item.targetDate)
            _repeat_      = State(initialValue: item.repeatOption)
            _displayUnit  = State(initialValue: item.displayUnit)
            _customEmoji  = State(initialValue: true)
            if item.kind == .timer {
                let d = Int(max(0, item.targetDate.timeIntervalSinceNow))
                _h = State(initialValue: d / 3_600)
                _m = State(initialValue: (d % 3_600) / 60)
                _s = State(initialValue: d % 60)
            }
        }
    }

    // Form state
    @State private var editingID: UUID? = nil
    @State private var name        = ""
    @State private var emoji       = TimerKind.timer.defaultEmoji
    @State private var customEmoji = false
    @State private var kind        = TimerKind.timer
    @State private var startDate   = Date()
    @State private var targetDate  = Date().addingTimeInterval(86_400)
    @State private var repeat_     = RepeatOption.never
    @State private var displayUnit = DisplayUnit.auto
    @State private var h = 0
    @State private var m = 5
    @State private var s = 0

    @State private var showEmoji = false
    @State private var showStart = false
    @State private var showEnd   = false
    @FocusState private var nameFocused: Bool
    @Namespace private var segNS

    private var isEditing: Bool { editingID != nil }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Theme.divider)

            kindPicker
            Divider().background(Theme.divider)

            nameRow
            Divider().background(Theme.divider)

            // Fixed-height body so switching modes never resizes the window.
            ZStack(alignment: .top) {
                switch kind {
                case .timer:    timerBody
                case .date:     dateBody
                case .progress: progressBody
                }
            }
            .frame(height: 172, alignment: .top)
            .transition(.opacity)
            .id(kind)
        }
        .background(Theme.bg)
        .frame(width: 360)
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { nameFocused = true }
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text(isEditing ? "Edit" : "New Timer")
                .font(.onePlus(14)).foregroundColor(.white)
            HStack {
                Button("Cancel") { dismissForm() }
                    .font(.onePlus(13)).foregroundColor(.white.opacity(0.4))
                    .buttonStyle(.plain)
                Spacer()
                Button(isEditing ? "Save" : "Add", action: save)
                    .font(.onePlus(13, .medium)).foregroundColor(Theme.accentSolid)
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
    }

    // MARK: Kind segmented control

    private var kindPicker: some View {
        HStack(spacing: 0) {
            ForEach(TimerKind.allCases) { k in
                let selected = kind == k
                Text(k.rawValue)
                    .font(.onePlus(12, selected ? .medium : .regular))
                    .foregroundColor(selected ? .white : .white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        ZStack {
                            if selected {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.12))
                                    .matchedGeometryEffect(id: "segPill", in: segNS)
                            }
                        }
                    )
                    .contentShape(Rectangle())          // entire segment is tappable
                    .onTapGesture {
                        guard !selected else { return }
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            kind = k
                            if !customEmoji { emoji = k.defaultEmoji }
                        }
                    }
            }
        }
        .padding(6)
    }

    // MARK: Name + emoji

    private var nameRow: some View {
        HStack(spacing: 14) {
            Button { showEmoji.toggle() } label: {
                Text(emoji).font(.system(size: 26)).frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.06)).clipShape(Circle())
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showEmoji, arrowEdge: .bottom) {
                EmojiPicker(selected: $emoji, custom: $customEmoji, isPresented: $showEmoji)
            }

            TextField("Name (optional)", text: $name)
                .font(.onePlus(16)).foregroundColor(.white)
                .textFieldStyle(.plain).focused($nameFocused)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
    }

    // MARK: Timer body — just the clock

    private var timerBody: some View {
        VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 0) {
                Spacer()
                DurationDigit(value: $h, label: "hours", cap: 23)
                colonDots
                DurationDigit(value: $m, label: "min",   cap: 59)
                colonDots
                DurationDigit(value: $s, label: "sec",   cap: 59)
                Spacer()
            }
            ringsAt
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            // Soft glow — a multi-stop radial gradient (no blur, so it stays
            // clean and contained through page transitions).
            RadialGradient(
                colors: [Theme.accentSolid.opacity(0.20),
                         Theme.accentSolid.opacity(0.05),
                         .clear],
                center: .center, startRadius: 0, endRadius: 150)
                .allowsHitTesting(false)
        )
        .clipped()
    }

    private var colonDots: some View {
        VStack(spacing: 10) {
            Circle().fill(Color.white.opacity(0.18)).frame(width: 7, height: 7)
            Circle().fill(Color.white.opacity(0.18)).frame(width: 7, height: 7)
        }
        .padding(.horizontal, 5)
        .padding(.bottom, 16)   // nudge up so dots sit on the digits' centre line
    }

    @ViewBuilder
    private var ringsAt: some View {
        let total = h * 3_600 + m * 60 + s
        if total > 0 {
            let end = Date().addingTimeInterval(TimeInterval(total))
            (Text("Rings at ").foregroundColor(.white.opacity(0.3))
             + Text(endTime(end)).foregroundColor(Theme.accentSolid))
                .font(.onePlus(11, .light))
        } else {
            Text("Set a duration")
                .font(.onePlus(11, .light)).foregroundColor(.white.opacity(0.2))
        }
    }

    private func endTime(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_IN")
        f.dateFormat = "h:mm a"
        return f.string(from: d)
    }

    // MARK: Date body

    private var dateBody: some View {
        VStack(spacing: 0) {
            dateRow("When", $targetDate, show: $showEnd, time: true)
            Divider().background(Theme.divider)
            menuRow("Repeat", repeat_.rawValue) {
                ForEach(RepeatOption.allCases) { opt in
                    Button(opt.rawValue) { repeat_ = opt }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: Progress body

    private var progressBody: some View {
        VStack(spacing: 0) {
            dateRow("From", $startDate,  show: $showStart, time: false)
            Divider().background(Theme.divider)
            dateRow("To",   $targetDate, show: $showEnd,   time: false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: Reusable rows

    private func dateRow(_ label: String, _ date: Binding<Date>,
                         show: Binding<Bool>, time: Bool) -> some View {
        HStack {
            Text(label).font(.onePlus(15)).foregroundColor(.white)
            Spacer()
            Button { show.wrappedValue.toggle() } label: {
                Text(fmt(date.wrappedValue, time: time))
                    .font(.onePlus(14)).foregroundColor(Theme.accentSolid)
            }
            .buttonStyle(.plain)
            .popover(isPresented: show, arrowEdge: .trailing) {
                pickerPopover(date, time: time)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 15)
    }

    /// Compact typable date (+ time) tag — hugs its fields, type any year directly.
    private func pickerPopover(_ date: Binding<Date>, time: Bool) -> some View {
        VStack(alignment: .trailing, spacing: 8) {
            DatePicker("", selection: date, in: infinityMinDate...infinityMaxDate,
                       displayedComponents: [.date])
                .datePickerStyle(.field)
                .labelsHidden()
                .fixedSize()
                .environment(\.locale, Locale(identifier: "en_GB"))     // dd/MM/yyyy, zero-padded

            if time {
                DatePicker("", selection: date, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.field)
                    .labelsHidden()
                    .fixedSize()
                    .environment(\.locale, Locale(identifier: "en_IN"))  // 12-hour am/pm
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Theme.bgRaised)
        .colorScheme(.dark)
    }

    private func menuRow<C: View>(_ label: String, _ value: String,
                                  @ViewBuilder _ content: () -> C) -> some View {
        HStack {
            Text(label).font(.onePlus(15)).foregroundColor(.white)
            Spacer()
            Menu(value) { content() }
                .menuStyle(.borderlessButton).fixedSize()
                .font(.onePlus(14)).foregroundColor(.white.opacity(0.45))
        }
        .padding(.horizontal, 20).padding(.vertical, 15)
    }

    // MARK: Helpers

    private func fmt(_ d: Date, time: Bool) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_IN")
        f.dateFormat = time ? "d MMM yyyy, h:mm a" : "d MMM yyyy"
        return f.string(from: d)
    }

    private var resolvedName: String {
        let t = name.trimmingCharacters(in: .whitespaces)
        if !t.isEmpty { return t }
        switch kind {
        case .timer:
            if h > 0 { return "\(h)h timer" }
            if m > 0 { return "\(m)m timer" }
            if s > 0 { return "\(s)s timer" }
            return "Timer"
        case .date:     return "Countdown"
        case .progress: return "Progress"
        }
    }

    private func save() {
        if kind == .timer {
            targetDate = Date().addingTimeInterval(TimeInterval(max(h * 3_600 + m * 60 + s, 1)))
            repeat_ = .never
        }
        targetDate = min(targetDate, infinityMaxDate)
        startDate  = min(startDate,  infinityMaxDate)

        var item = isEditing
            ? (store.timers.first { $0.id == editingID } ?? TimerItem())
            : TimerItem()
        item.name         = resolvedName
        item.emoji        = emoji
        item.kind         = kind
        item.startDate    = startDate
        item.targetDate   = targetDate
        item.repeatOption = repeat_
        item.displayUnit  = displayUnit
        item.isCompleted  = false
        if !isEditing { item.createdAt = Date() }

        isEditing ? store.update(item) : store.add(item)
        dismissForm()
    }

    /// Close any open date/emoji picker first, then leave — so the picker
    /// teardown and the screen transition don't resize the window at once.
    private func dismissForm() {
        showStart = false
        showEnd   = false
        showEmoji = false
        DispatchQueue.main.async { onDismiss() }
    }
}

// MARK: - Duration digit (numbers only, max 2, fills from the right)

private struct DurationDigit: View {
    @Binding var value: Int
    let label: String
    let cap: Int

    @State private var text = "00"
    @FocusState private var focused: Bool

    private var active: Bool { value > 0 }

    var body: some View {
        VStack(spacing: 7) {
            TextField("", text: $text)
                .font(.custom("OnePlusSans-Medium", size: 72))
                .foregroundColor(active ? Theme.accentSolid : .white.opacity(0.16))
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .frame(width: 96)
                .focused($focused)
                .shadow(color: active ? Theme.accentSolid.opacity(0.45) : .clear, radius: 18)
                .onChange(of: text) { raw in
                    var digits = raw.filter(\.isNumber)
                    if digits.count > 2 { digits = String(digits.suffix(2)) }   // keep last 2
                    var n = Int(digits) ?? 0
                    if n > cap { n = cap }
                    value = n
                    let formatted = String(format: "%02d", n)
                    if text != formatted { text = formatted }                   // re-pad + reject letters
                }
                .onChange(of: value) { v in
                    let formatted = String(format: "%02d", v)
                    if !focused, text != formatted { text = formatted }         // external updates
                }
                .onAppear { text = String(format: "%02d", value) }
            Text(label.uppercased())
                .font(.onePlus(9, .light)).tracking(2.5)
                .foregroundColor(.white.opacity(active ? 0.55 : 0.25))
        }
    }
}

// MARK: - Emoji Picker

private struct EmojiPicker: View {
    @Binding var selected: String
    @Binding var custom: Bool
    @Binding var isPresented: Bool

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 2), count: 8)
    private let groups: [(String, [String])] = [
        ("Time",      ["⏱","⏰","⏳","⌛","🕐","📅","📆","🗓","⌚","🔔","🌅","🌙"]),
        ("Moments",   ["🎉","🎂","🎆","🥳","🎊","🎁","🏆","💍","❤️","✨","🌟","🥂"]),
        ("Goals",     ["🚀","🎯","💪","🧠","📚","💡","🔥","🏅","💎","📈","✅","🏁"]),
        ("Life",      ["🌱","🌸","🍀","🌊","☀️","🐣","🍼","🎓","🏡","✈️","💼","🩺"]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Icon").font(.onePlus(11)).foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 14).padding(.vertical, 12)
            Divider().background(Theme.divider)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(groups, id: \.0) { name, emojis in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(name.uppercased()).font(.onePlus(8, .light))
                                .foregroundColor(.white.opacity(0.3)).tracking(1.5)
                            LazyVGrid(columns: cols, spacing: 2) {
                                ForEach(emojis, id: \.self) { e in
                                    Button {
                                        selected = e; custom = true; isPresented = false
                                    } label: {
                                        Text(e).font(.system(size: 22))
                                            .frame(width: 36, height: 36)
                                            .background(selected == e ? Color.white.opacity(0.1) : .clear)
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(14)
            }
            .frame(height: 280)
        }
        .background(Theme.bgRaised).frame(width: 320).colorScheme(.dark)
    }
}
