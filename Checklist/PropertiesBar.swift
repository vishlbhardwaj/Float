import SwiftUI
import Shimmer

struct PropertiesBar: View {
    @ObservedObject var note: StickyNote
    var onDelete: () -> Void
    @State private var showColorPicker = false
    @State private var showSizePicker = false
    @State private var showTextSizePicker = false
    @State private var showFontStylePicker = false
    @Binding var selectedColor: Color
    @Binding var selectedFontSize: FontSize
    @Binding var selectedFontStyle: FontStyle
    let selectedRange: NSRange?
    let onColorSelected: (Color, NSRange?) -> Void
    
    @State private var showListButton = false
    @State private var showSizeButton = false
    @State private var showTextSizeButton = false
    @State private var showFontStyleButton = false
    @State private var showColorButton = false
    @State private var showDeleteButton = false
    
    let colors: [Color] = [
        .black, .red, .orange, .blue, .purple
    ]
    
    let noteSizes: [StickyNoteSize] = [
        .small, .medium, .large
    ]
    
    let fontSizes: [FontSize] = [
        .small, .medium, .large
    ]
    
    let fontStyles: [FontStyle] = FontStyle.allCases
    
    private let buttonSpacing: CGFloat = 0
    private let buttonPadding: CGFloat = 12
    private let barHeight: CGFloat = 48
    
    struct VerticalDivider: View {
        var body: some View {
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 24)
        }
    }
    
    struct ToolbarButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .contentShape(Rectangle())
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
        }
    }
    
    var body: some View {
        ZStack {
            buttonsHStack()
        }
        .frame(maxWidth: .infinity)
        .onAppear(perform: handleAppear)
        .onDisappear(perform: handleDisappear)
        .zIndex(1000)
    }
    
    // MARK: - Appearance Handlers
    
    private func handleAppear() {
        withAnimation(.easeOut(duration: 0.2).delay(0.1)) {
            showListButton = true
        }
        withAnimation(.easeOut(duration: 0.2).delay(0.115)) {
            showSizeButton = true
        }
        withAnimation(.easeOut(duration: 0.2).delay(0.125)) {
            showTextSizeButton = true
        }
        withAnimation(.easeOut(duration: 0.2).delay(0.135)) {
            showFontStyleButton = true
        }
        withAnimation(.easeOut(duration: 0.2).delay(0.145)) {
            showColorButton = true
        }
        withAnimation(.easeOut(duration: 0.2).delay(0.2)) {
            showDeleteButton = true
        }
    }
    
    private func handleDisappear() {
        showListButton = false
        showFontStyleButton = false
        showSizeButton = false
        showTextSizeButton = false
        showColorButton = false
        showDeleteButton = false
        showColorPicker = false
        showFontStylePicker = false
        showSizePicker = false
        showTextSizePicker = false
    }
    
    private func buttonsHStack() -> some View {
        HStack(spacing: buttonSpacing) {
            listStyleButton()
            VerticalDivider()
            sizeButton()
            VerticalDivider()
            textSizeButton()
            VerticalDivider()
            fontStyleButton()
            VerticalDivider()
            colorButton()
            VerticalDivider()
            deleteButton()
        }
        .frame(height: barHeight)
        .background(barBackground())
        .padding(.horizontal, 12)
    }
    
    private func barBackground() -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.black.opacity(0.95))
            .shadow(
                color: Color.black.opacity(0.25), 
                radius: 12, 
                x: 0, 
                y: 4
            )
    }
    
    // MARK: - Button Components
    
    private func listStyleButton() -> some View {
        let isCheckboxStyle = note.listStyle == .checkbox
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                let newStyle: ListStyle = isCheckboxStyle ? .bullet : .checkbox
                note.listStyle = newStyle
            }
        }) {
            listStyleButtonContent(isCheckboxStyle: isCheckboxStyle)
        }
        .buttonStyle(ToolbarButtonStyle())
        .opacity(showListButton ? 1 : 0)
        .offset(y: showListButton ? 0 : 10)
    }
    
    private func listStyleButtonContent(isCheckboxStyle: Bool) -> some View {
        let imageName = isCheckboxStyle ? "checklist" : "list.bullet"
        return Image(systemName: imageName)
            .foregroundColor(.white)
            .font(.system(size: 14))
            .frame(width: barHeight, height: barHeight)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.2))
                    .opacity(note.listStyle == .checkbox ? 1 : 0)
                    .padding(8)
                    .clipShape(Rectangle())
            )
            .contentShape(Rectangle())
    }
    
    private func sizeButton() -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if showColorPicker { showColorPicker = false }
                if showFontStylePicker { showFontStylePicker = false }
                if showTextSizePicker { showTextSizePicker = false }
                showSizePicker.toggle()
            }
        }) {
            sizeButtonContent()
        }
        .buttonStyle(ToolbarButtonStyle())
        .opacity(showSizeButton ? 1 : 0)
        .offset(y: showSizeButton ? 0 : 10)
        .overlay(
            Group {
                if showSizePicker {
                    sizePickerOverlay()
                }
            }, alignment: .top
        )
        .zIndex(10)
    }
    
    private func sizeButtonContent() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .foregroundColor(.white)
                .font(.system(size: 14))
            Text(note.noteSize.rawValue.capitalized)
                .foregroundColor(.white)
                .font(.system(size: 14))
        }
        .frame(width: 96, height: barHeight)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.2))
                .opacity(showSizePicker ? 1 : 0)
                .padding(8)
                .clipShape(Rectangle())
        )
        .contentShape(Rectangle())
    }
    
    private func textSizeButton() -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if showColorPicker { showColorPicker = false }
                if showFontStylePicker { showFontStylePicker = false }
                if showSizePicker { showSizePicker = false }
                showTextSizePicker.toggle()
            }
        }) {
            textSizeButtonContent()
        }
        .buttonStyle(ToolbarButtonStyle())
        .opacity(showTextSizeButton ? 1 : 0)
        .offset(y: showTextSizeButton ? 0 : 10)
        .overlay(
            Group {
                if showTextSizePicker {
                    textSizePickerOverlay()
                }
            }, alignment: .top
        )
        .zIndex(9)
    }
    
    private func textSizeButtonContent() -> some View {
        Text(String(format: "%.0f", note.fontSize.size))
            .foregroundColor(.white)
            .font(.system(size: 14))
            .frame(width: 64, height: barHeight)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.2))
                    .opacity(showTextSizePicker ? 1 : 0)
                    .padding(8)
                    .clipShape(Rectangle())
            )
            .contentShape(Rectangle())
    }
    
    private func fontStyleButton() -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if showColorPicker {
                    showColorPicker = false
                }
                if showSizePicker {
                    showSizePicker = false
                }
                if showTextSizePicker {
                    showTextSizePicker = false
                }
                showFontStylePicker.toggle()
            }
        }) {
            fontStyleButtonContent()
        }
        .buttonStyle(ToolbarButtonStyle())
        .opacity(showFontStyleButton ? 1 : 0)
        .offset(y: showFontStyleButton ? 0 : 10)
        .overlay(
            Group {
                if showFontStylePicker {
                    fontStylePickerOverlay()
                }
            }, alignment: .top
        )
        .zIndex(10)
    }
    
    private func fontStyleButtonContent() -> some View {
        HStack(spacing: 8) {
            Text("Aa")
                .font(Font(selectedFontStyle.font(size: 14)))
                .foregroundColor(.white)
            
            Image(systemName: "chevron.down")
                .foregroundColor(.white)
                .font(.system(size: 12))
        }
        .frame(width: 64, height: barHeight)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.2))
                .opacity(showFontStylePicker ? 1 : 0)
                .padding(8)
                .clipShape(Rectangle())
        )
        .contentShape(Rectangle())
    }
    
    private func colorButton() -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if showSizePicker { showSizePicker = false }
                if showFontStylePicker { showFontStylePicker = false }
                if showTextSizePicker { showTextSizePicker = false }
                showColorPicker.toggle()
            }
        }) {
            colorButtonContent()
        }
        .buttonStyle(ToolbarButtonStyle())
        .opacity(showColorButton ? 1 : 0)
        .offset(y: showColorButton ? 0 : 10)
        .overlay(
            Group {
                if showColorPicker {
                    colorPickerOverlay()
                }
            }, alignment: .top
        )
        .zIndex(8)
    }
    
    private func colorButtonContent() -> some View {
        HStack(spacing: 6) {
            Image(systemName: "pencil.tip")
                .foregroundColor(.white)
                .font(.system(size: 16))
            
            Circle()
                .fill(selectedColor)
                .frame(width: 14, height: 14)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
        .frame(width: 64, height: barHeight)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.2))
                .opacity(showColorPicker ? 1 : 0)
                .padding(8)
                .clipShape(Rectangle())
        )
        .contentShape(Rectangle())
    }
    
    private func deleteButton() -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onDelete()
            }
        }) {
            deleteButtonContent()
        }
        .buttonStyle(ToolbarButtonStyle())
        .opacity(showDeleteButton ? 1 : 0)
        .offset(y: showDeleteButton ? 0 : 10)
    }
    
    private func deleteButtonContent() -> some View {
        Image(systemName: "trash.fill")
            .foregroundColor(.red.opacity(0.8))
            .font(.system(size: 16))
            .frame(width: barHeight, height: barHeight)
            .contentShape(Rectangle())
    }
    
    // MARK: - Picker Overlays
    
    private func colorPickerOverlay() -> some View {
        VStack(spacing: 8) {
            ForEach(colors, id: \.self) { color in
                colorCircle(color)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .offset(y: 50)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }
    
    private func colorCircle(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 24, height: 24)
            .overlay(strokeOverlay(for: color))
            .onTapGesture { handleColorTap(color) }
    }
    
    private func strokeOverlay(for color: Color) -> some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
            Circle()
                .strokeBorder(Color.white, lineWidth: selectedColor == color ? 2 : 0)
        }
    }
    
    private func handleColorTap(_ color: Color) {
        withAnimation {
            selectedColor = color
            onColorSelected(color, selectedRange)
            showColorPicker = false
        }
    }
    
    // Extracted Helper Views for Pickers
    
    private func sizePickerOverlay() -> some View {
        VStack(spacing: 4) {
            ForEach(noteSizes, id: \.self) { size in
                sizePickerRow(for: size)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(pickerBackground())
        .offset(y: 50)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
        .zIndex(100)
    }
    
    private func sizePickerRow(for size: StickyNoteSize) -> some View {
        let isSelected = note.noteSize == size
        return Button(action: {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.6)) {
                note.updateNoteSize(to: size)
                showSizePicker = false
            }
        }) {
            HStack(spacing: 8) {
                Text(size.rawValue.capitalized)
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                }
            }
            .padding(8)
            .frame(width: 96)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
                    .padding(2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func textSizePickerOverlay() -> some View {
        VStack(spacing: 4) {
            ForEach(fontSizes, id: \.self) { size in
                textSizePickerRow(for: size)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(pickerBackground())
        .offset(y: 50)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
        .zIndex(100)
    }
    
    private func textSizePickerRow(for size: FontSize) -> some View {
        let isSelected = note.fontSize == size
        return Button(action: {
            note.isShimmering = true
            withAnimation(.easeOut(duration: 0.2)) {
                showTextSizePicker = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    note.updateTextSize(to: size)
                }
            }
        }) {
            HStack(spacing: 8) {
                Text(size.rawValue)
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                }
            }
            .padding(8)
            .frame(width: 64)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
                    .padding(2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func fontStylePickerOverlay() -> some View {
        VStack(spacing: 4) {
            ForEach(fontStyles, id: \.self) { style in
                fontStylePickerRow(for: style)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(pickerBackground())
        .offset(y: 50)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
        .zIndex(100)
    }
    
    private func fontStylePickerRow(for style: FontStyle) -> some View {
        let isSelected = selectedFontStyle == style
        return Button(action: {
            note.isShimmering = true
            
            withAnimation(.easeOut(duration: 0.2)) {
                showFontStylePicker = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    selectedFontStyle = style
                    for index in note.items.indices {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            note.items[index].fontStyle = style
                        }
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        note.isShimmering = false
                    }
                }
            }
        }) {
            HStack(spacing: 8) {
                Text(style.displayName)
                    .font(Font(style.font(size: 14)))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                }
            }
            .padding(8)
            .frame(width: 120)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
                    .padding(2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func pickerBackground() -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.black)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}
