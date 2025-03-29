import SwiftUI
import AppKit
import ConfettiSwiftUI

struct StickyNoteView: View {
    @ObservedObject var note: StickyNote
    @State private var editingItemId: UUID?
    @State private var newItemText: String = ""
    @FocusState private var isFocused: Bool
    @State private var isDragging: Bool = false
    @State private var opacity: Double = 1.0
    @State private var scrollProxy: ScrollViewProxy?
    @State private var shadowRadius: CGFloat = 4
    @State private var elevation: CGFloat = 1.0
    @State private var shadowOpacity: Double = 0.1
    @State private var rotation: Double = 0
    @State private var confettiTrigger: Int = 0
    @State private var showCheckbox: Bool = false
    @State private var scrollTrigger: Int = 0
    @State private var dragRotation: Double = 0
    @State private var followThroughRotation: Double = 0
    @State private var lastDragValue: CGFloat = 0
    @State private var isViewActive: Bool = false
    @State private var showPropertiesBar: Bool = false
    @State private var selectedColor: Color = .black
    @State private var selectedFontSize: FontSize = .medium
    @State private var selectedFontStyle: FontStyle = .simple
    @State private var currentEditingIndex: Int = 0
    let creationDate: Date = Date()
    var onDelete: () -> Void
    
    // Computed dimensions and spacing
    private var noteWidth: CGFloat { note.noteSize.dimensions.width }
    private var noteHeight: CGFloat { note.noteSize.dimensions.height }
    private let horizontalPadding: CGFloat = 20
    private let contentTopPadding: CGFloat = 12
    private let headerTopOffset: CGFloat = -8
    private let checkboxWidth: CGFloat = 24
    private let dateLeftOffset: CGFloat = 4
    private let bottomSafeArea: CGFloat = 20
    
    // New properties for positioning
    private let propertiesBarHeight: CGFloat = 48
    private let propertiesBarGap: CGFloat = 16
    private let propertiesBarPadding: CGFloat = 32
    private let minimumTopSpace: CGFloat = 16 // Minimum space needed from window top
    
    // ADD: Animation properties for smoother transitions
    @State private var isResizing: Bool = false
    @State private var previousNoteSize: StickyNoteSize?
    @State private var horizontalStretch: CGFloat = 1.0
    @State private var verticalStretch: CGFloat = 1.0
    @State private var resizeRotation: CGFloat = 0
    
    // ADD: New properties for shimmer and text animation
    @State private var isResizingText: Bool = false
    @State private var shimmerOffset: CGFloat = -100
    @State private var staggeredDelay: Double = 0
    
    // ADD: Shimmer gradient properties
    private let shimmerAnimation = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)
    private let staggerInterval: Double = 0.05
    
    var body: some View {
        GeometryReader { geometry in
            let totalRequiredSpace = propertiesBarHeight + propertiesBarGap + noteHeight
            let windowCenter = geometry.size.height / 2
            
            // Calculate sticky note position - ensure it's centered or adjusted if needed
            let adjustedNoteY = max(
                windowCenter,
                totalRequiredSpace / 2
            )
            
            // Calculate properties bar position - exactly 16px above note
            let propertiesBarY = adjustedNoteY - (noteHeight / 2) - 16 - (propertiesBarHeight / 2)
            
            // Background for tap handling
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    isViewActive = false
                    isFocused = false
                    editingItemId = nil
                }
            
            // Properties bar with exact positioning
            if showPropertiesBar && !isDragging {
                PropertiesBar(
                    note: note,
                    onDelete: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            opacity = 0
                            showPropertiesBar = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onDelete()
                        }
                    },
                    selectedColor: $selectedColor,
                    selectedFontSize: Binding(
                        get: { note.fontSize },
                        set: { note.updateTextSize(to: $0) }
                    ),
                    selectedFontStyle: $selectedFontStyle
                )
                .frame(width: min(460, max(noteWidth + propertiesBarPadding, 380)))
                .position(
                    x: geometry.size.width / 2,
                    y: max(propertiesBarHeight/2 + minimumTopSpace, propertiesBarY)
                )
                .zIndex(2000)
            }

            // Main sticky note
            ZStack {
                // Background and content in same transform
                ZStack {
                    // Background with shimmer effect
                    RoundedRectangle(cornerRadius: 20)
                        .fill(note.style.backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                note.style.backgroundColor.darker(by: 0.1),
                                lineWidth: 1
                            )
                            .opacity(0.3)
                        )
                        .overlay(
                            Group {
                                if isResizingText {
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0),
                                            Color.white.opacity(0.5),
                                            Color.white.opacity(0)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .offset(x: shimmerOffset)
                                    .blur(radius: 8)
                                }
                            }
                        )
                        .shadow(
                            color: Color.black.opacity(isDragging ? 0.2 : 0.1),
                            radius: isDragging ? 15 : 8,
                            x: 0,
                            y: isDragging ? 8 : 4
                        )
                    
                    // Content
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        HStack(spacing: 0) {
                            HStack(spacing: 0) {
                                Spacer().frame(width: dateLeftOffset)
                                Text(formattedDate)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 100, alignment: .leading)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    showPropertiesBar.toggle()
                                }
                            }) {
                                Image(systemName: showPropertiesBar ? "xmark.circle.fill" : "ellipsis")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .font(.system(size: 20))
                                    .frame(width: 20, height: 20)
                                    .contentShape(Rectangle())
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .opacity(isDragging ? 0 : 1)
                        }
                        .offset(y: headerTopOffset)
                        
                        Spacer().frame(height: 8)
                        
                        todoListContent
                            .opacity(isResizingText ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, contentTopPadding)
                    .padding(.bottom, bottomSafeArea)
                }
            }
            .frame(width: noteWidth, height: noteHeight)
            .rotationEffect(.degrees(dragRotation + resizeRotation))
            .scaleEffect(elevation)
            .scaleEffect(x: horizontalStretch, y: verticalStretch)
            .opacity(opacity)
            .position(x: geometry.size.width / 2, y: adjustedNoteY)
            .gesture(dragGesture)
            .onChange(of: note.noteSize) { newSize in
                guard let previous = previousNoteSize else {
                    previousNoteSize = newSize
                    return
                }
                
                let isGrowing = newSize.dimensions.width > previous.dimensions.width
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if isGrowing {
                        horizontalStretch = 1.1
                        verticalStretch = 0.95
                        resizeRotation = 2
                        elevation = 1.05
                    } else {
                        horizontalStretch = 0.95
                        verticalStretch = 1.05
                        resizeRotation = -2
                        elevation = 0.95
                    }
                }
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.65).delay(0.1)) {
                    horizontalStretch = 0.98
                    verticalStretch = 1.02
                    resizeRotation = isGrowing ? -1 : 1
                }
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.2)) {
                    horizontalStretch = 1.0
                    verticalStretch = 1.0
                    resizeRotation = 0
                    elevation = 1.0
                }
                
                previousNoteSize = newSize
            }
            .onChange(of: note.fontSize) { oldSize, newSize in
                withAnimation(.spring(
                    response: 0.7,
                    dampingFraction: 0.6
                )) {
                    isResizingText = true
                    shimmerOffset = noteWidth + 100
                }
                
                // Account for both disappearing and appearing animations
                let itemCount = Double(note.items.count)
                let disappearStaggerDuration = itemCount * 0.15 // Staggered disappearing
                let disappearDuration = 0.7 // Base disappear animation
                let appearStaggerDuration = itemCount * 0.15 // Staggered appearing
                let appearDuration = 0.7 // Base appear animation
                let transitionBuffer = 0.3 // Buffer between disappear and appear phases
                
                let totalDuration = disappearStaggerDuration + disappearDuration + transitionBuffer + appearStaggerDuration + appearDuration
                
                DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
                    withAnimation(.spring(
                        response: 0.7,
                        dampingFraction: 0.6
                    )) {
                        isResizingText = false
                        shimmerOffset = -100
                    }
                }
                
                handleFontSizeChange(from: oldSize, to: newSize)
            }
            
            confettiLayer
        }
        .frame(
            minWidth: noteWidth + 80,
            minHeight: noteHeight + propertiesBarHeight + 16 + minimumTopSpace + 40
        )
        .ignoresSafeArea()
    }
    
    private var todoListContent: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 8) {
                        if note.items.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(Array(sortedItems.enumerated()), id: \.element.id) { index, item in
                                TodoItemView(
                                    item: item,
                                    isEditing: editingItemId == item.id,
                                    note: note,
                                    index: index,
                                    totalItems: sortedItems.count,
                                    onStartEditing: {
                                        editingItemId = item.id
                                        currentEditingIndex = index
                                    },
                                    onToggle: {
                                        if let index = note.items.firstIndex(where: { $0.id == item.id }) {
                                            note.items[index].isCompleted.toggle()
                                            checkCompletion()
                                        }
                                    },
                                    onUpdate: { newText in
                                        if let index = note.items.firstIndex(where: { $0.id == item.id }) {
                                            note.items[index].text = newText
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                                withAnimation {
                                                    proxy.scrollTo(item.id, anchor: .bottom)
                                                }
                                            }
                                        }
                                    },
                                    onDelete: {
                                        if let index = note.items.firstIndex(where: { $0.id == item.id }) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                note.items.remove(at: index)
                                                
                                                if !note.items.isEmpty {
                                                    let newIndex = max(0, index - 1)
                                                    let newItem = note.items[newIndex]
                                                    editingItemId = newItem.id
                                                } else {
                                                    editingItemId = nil
                                                    isFocused = true
                                                }
                                            }
                                        }
                                    },
                                    onInsertAfter: {
                                        if let index = note.items.firstIndex(where: { $0.id == item.id }) {
                                            let newItem = TodoItem(
                                                text: "",
                                                isCompleted: false,
                                                textColor: selectedColor,
                                                fontSize: selectedFontSize,
                                                fontStyle: selectedFontStyle
                                            )
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                note.items.insert(newItem, at: index + 1)
                                                editingItemId = newItem.id
                                            }
                                        }
                                    },
                                    onColorChange: { color, range in
                                        if let index = note.items.firstIndex(where: { $0.id == item.id }) {
                                            note.items[index].textColor = color
                                        }
                                    }
                                )
                                .id(item.id)
                                .transition(.opacity)
                                .animation(
                                    .spring(
                                        response: 0.7,
                                        dampingFraction: 0.6
                                    )
                                    .delay(Double(index) * 0.1),
                                    value: note.fontSize
                                )
                            }
                        }
                        
                        Spacer().frame(height: bottomSafeArea)
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
                    .onChange(of: editingItemId) { newValue in
                        if let id = newValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo(id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: noteHeight - contentTopPadding - bottomSafeArea - 60)
            .scrollIndicators(.visible)
            .onTapGesture {
                isViewActive = true
                handleTap()
            }
            
            LinearGradient(
                gradient: Gradient(colors: [
                    note.style.backgroundColor.opacity(0.0),
                    note.style.backgroundColor.opacity(0.1),
                    note.style.backgroundColor.opacity(0.4),
                    note.style.backgroundColor
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            .padding(.bottom, bottomSafeArea)
            .allowsHitTesting(false)
        }
        .frame(height: noteHeight - contentTopPadding - bottomSafeArea - 60)
    }
    
    private var emptyStateView: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: newItemText.isEmpty ? "circle.dotted" : "circle")
                .foregroundColor(newItemText.isEmpty ? .gray.opacity(0.4) : .gray)
                .font(.system(size: 16))
                .frame(width: checkboxWidth, alignment: .center)
                .allowsHitTesting(false)
            
            CustomTextField(
                text: $newItemText,
                isFocused: true,
                textColor: selectedColor,
                fontSize: selectedFontSize,
                fontStyle: selectedFontStyle,
                isCompleted: false,
                selectedRange: .constant(nil),
                onUpdate: { _ in },
                onSubmit: {
                    if !newItemText.isEmpty {
                        let firstItem = TodoItem(
                            text: newItemText,
                            isCompleted: false,
                            textColor: selectedColor,
                            fontSize: selectedFontSize,
                            fontStyle: selectedFontStyle
                        )
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            note.items.append(firstItem)
                            newItemText = ""
                            
                            let newItem = TodoItem(
                                text: "",
                                isCompleted: false,
                                textColor: selectedColor,
                                fontSize: selectedFontSize,
                                fontStyle: selectedFontStyle
                            )
                            note.items.append(newItem)
                            editingItemId = newItem.id
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    scrollProxy?.scrollTo(newItem.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                },
                onDelete: { },
                onColorChange: { _, _ in },
                note: note
            )
            .frame(maxWidth: .infinity)
            .overlay(
                Group {
                    if newItemText.isEmpty {
                        Text("Add to do items")
                            .foregroundColor(.gray.opacity(0.4))
                            .font(Font(selectedFontStyle.font(size: selectedFontSize.size)))
                            .allowsHitTesting(false)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
    
    private var confettiLayer: some View {
        Color.clear
            .confettiCannon(
                trigger: $confettiTrigger,
                num: 50,
                confettis: [.shape(.circle), .shape(.triangle)],
                colors: [.red, .green, .yellow, .pink, .purple],
                openingAngle: Angle(degrees: 0),
                closingAngle: Angle(degrees: 360),
                radius: 200,
                repetitions: 1,
                repetitionInterval: 0.1
            )
    }
    
    private var deleteButton: some View {
        Button(action: {
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onDelete()
            }
        }) {
            Text("Move to Trash")
            Image(systemName: "trash")
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isDragging {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isDragging = true
                        elevation = 1.05
                        if showPropertiesBar {
                            showPropertiesBar = false
                        }
                    }
                }
                
                let dragX = value.translation.width
                let targetRotation = min(max(dragX * 0.15, -8), 8)
                
                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6)) {
                    dragRotation = targetRotation
                }
                
                lastDragValue = dragX
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.width * 0.05
                isDragging = false
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    dragRotation = 0
                    elevation = 0.98
                }
                
                if abs(velocity) > 0.5 {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        dragRotation = velocity * 0.2
                    }
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1)) {
                        dragRotation = -velocity * 0.1
                    }
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.2)) {
                        dragRotation = 0
                    }
                }
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.3)) {
                    elevation = 1.0
                }
                
                lastDragValue = 0
            }
    }
    
    private func handleDragEndAnimation(velocity: CGFloat) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            followThroughRotation = velocity * 0.8
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.2)) {
            followThroughRotation = -velocity * 0.3
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.4)) {
            followThroughRotation = 0
        }
    }
    
    private var hasEmptyItem: Bool {
        note.items.contains { $0.text.isEmpty }
    }
    
    private var sortedItems: [TodoItem] {
        note.items.sorted { item1, item2 in
            if item1.isCompleted == item2.isCompleted {
                return item1.createdAt < item2.createdAt
            }
            return !item1.isCompleted && item2.isCompleted
        }
    }
    
    private var allItemsCompleted: Bool {
        !note.items.isEmpty && note.items.allSatisfy { $0.isCompleted }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: creationDate)
    }
    
    private func checkCompletion() {
        if allItemsCompleted && !note.items.isEmpty {
            confettiTrigger += 1
        }
    }
    
    private func handleTap() {
        if !hasEmptyItem {
            let newItem = TodoItem(
                text: "",
                isCompleted: false,
                textColor: selectedColor,
                fontSize: selectedFontSize,
                fontStyle: selectedFontStyle
            )
            note.items.append(newItem)
            editingItemId = newItem.id
        } else {
            if let emptyItem = note.items.first(where: { $0.text.isEmpty }) {
                editingItemId = emptyItem.id
            }
        }
    }
    
    private func handleMoveToPreviousItem() {
        if currentEditingIndex > 0 {
            currentEditingIndex -= 1
            editingItemId = note.items[currentEditingIndex].id
            scrollProxy?.scrollTo(editingItemId, anchor: .center)
        }
    }
    
    private func handleMoveToNextItem() {
        if currentEditingIndex < note.items.count - 1 {
            currentEditingIndex += 1
            editingItemId = note.items[currentEditingIndex].id
            scrollProxy?.scrollTo(editingItemId, anchor: .center)
        }
    }
    
    private func handleFontSizeChange(from oldSize: FontSize, to newSize: FontSize) {
        withAnimation(.spring(
            response: 0.7,
            dampingFraction: 0.6
        )) {
            isResizingText = true
            shimmerOffset = noteWidth + 100
        }
        
        // Account for both disappearing and appearing animations
        let itemCount = Double(note.items.count)
        let disappearStaggerDuration = itemCount * 0.1 // Each item takes 0.1s to start disappearing
        let disappearDuration = 0.7 // Base disappear animation
        let appearStaggerDuration = itemCount * 0.1 // Each item takes 0.1s to start appearing
        let appearDuration = 0.7 // Base appear animation
        let transitionBuffer = 0.3 // Buffer between disappear and appear phases
        
        let totalDuration = disappearStaggerDuration + disappearDuration + transitionBuffer + appearStaggerDuration + appearDuration
        
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            withAnimation(.spring(
                response: 0.7,
                dampingFraction: 0.6
            )) {
                isResizingText = false
                shimmerOffset = -100
            }
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
