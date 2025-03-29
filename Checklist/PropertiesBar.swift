import SwiftUI
import Shimmer

struct StickyNoteStyle {
    var backgroundColor: Color
    var textColor: Color
}

struct PropertiesBar: View {
    @ObservedObject var note: StickyNote
    var onDelete: () -> Void
    @State private var showColorPicker = false
    @State private var showSizePicker = false
    @State private var showTextSizePicker = false
    @State private var showFontStylePicker = false
    @State private var selectedColor: Color = .black
    @State private var selectedFontStyle: FontStyle = .system
    @State private var selectedFontSize: FontSize = .medium
    
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
                .background(
                    configuration.isPressed ?
                    Color.white.opacity(0.1) :
                    Color.clear
                )
        }
    }
    
    var body: some View {
        ZStack {
            HStack(spacing: buttonSpacing) {
                let isCheckboxStyle = note.listStyle == .checkbox
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        let newStyle: ListStyle = isCheckboxStyle ? .bullet : .checkbox
                        note.listStyle = newStyle
                    }
                }) {
                    let imageName = isCheckboxStyle ? "list.bullet" : "checklist"
                    Image(systemName: imageName)
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                        .frame(width: barHeight, height: barHeight)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.2))
                                .opacity(note.listStyle == .bullet ? 1 : 0)
                                .padding(8)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(ToolbarButtonStyle())
                .opacity(showListButton ? 1 : 0)
                .offset(y: showListButton ? 0 : 10)
                
                VerticalDivider()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if showColorPicker { showColorPicker = false }
                        if showFontStylePicker { showFontStylePicker = false }
                        if showTextSizePicker { showTextSizePicker = false }
                        showSizePicker.toggle()
                    }
                }) {
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
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(ToolbarButtonStyle())
                .opacity(showSizeButton ? 1 : 0)
                .offset(y: showSizeButton ? 0 : 10)
                .overlay(
                    Group {
                        if showSizePicker {
                            VStack(spacing: 4) {
                                ForEach(noteSizes, id: \.self) { size in
                                    let isSelected = note.noteSize == size
                                    Button(action: {
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
                                                .fill(Color.white.opacity(isSelected ? 0.1 : 0))
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.black)
                                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                            )
                            .offset(y: 50)
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                            .zIndex(100)
                        }
                    }, alignment: .top
                )
                .zIndex(10)
                
                VerticalDivider()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if showColorPicker { showColorPicker = false }
                        if showFontStylePicker { showFontStylePicker = false }
                        if showSizePicker { showSizePicker = false }
                        showTextSizePicker.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "textformat.size")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                        Text(note.fontSize.rawValue)
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    }
                    .frame(width: 64, height: barHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.2))
                            .opacity(showTextSizePicker ? 1 : 0)
                            .padding(8)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(ToolbarButtonStyle())
                .opacity(showTextSizeButton ? 1 : 0)
                .offset(y: showTextSizeButton ? 0 : 10)
                .overlay(
                    Group {
                        if showTextSizePicker {
                            VStack(spacing: 4) {
                                ForEach(fontSizes, id: \.self) { size in
                                    let isSelected = note.fontSize == size
                                    Button(action: {
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
                                                .fill(Color.white.opacity(isSelected ? 0.1 : 0))
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.black)
                                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                            )
                            .offset(y: 50)
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                            .zIndex(100)
                        }
                    }, alignment: .top
                )
                .zIndex(9)
                
                VerticalDivider()
                
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
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(ToolbarButtonStyle())
                .opacity(showFontStyleButton ? 1 : 0)
                .offset(y: showFontStyleButton ? 0 : 10)
                .overlay(
                    Group {
                        if showFontStylePicker {
                            VStack(spacing: 4) {
                                ForEach(fontStyles, id: \.self) { style in
                                    let isSelected = selectedFontStyle == style
                                    Button(action: {
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
                                                .fill(Color.white.opacity(isSelected ? 0.1 : 0))
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.black)
                                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                            )
                            .offset(y: 50)
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                            .zIndex(100)
                        }
                    }, alignment: .top
                )
                .zIndex(10)
                
                VerticalDivider()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if showSizePicker {
                            showSizePicker = false
                        }
                        if showFontStylePicker {
                            showFontStylePicker = false
                        }
                        if showTextSizePicker {
                            showTextSizePicker = false
                        }
                        showColorPicker.toggle()
                    }
                }) {
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
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(ToolbarButtonStyle())
                .opacity(showColorButton ? 1 : 0)
                .offset(y: showColorButton ? 0 : 10)
                .overlay(
                    Group {
                        if showColorPicker {
                            VStack(spacing: 8) {
                                ForEach(colors, id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                        )
                                        .onTapGesture {
                                            withAnimation {
                                                selectedColor = color
                                                showColorPicker = false
                                            }
                                        }
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
                            .zIndex(100)
                        }
                    }, alignment: .top
                )
                .zIndex(8)
                
                VerticalDivider()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onDelete()
                    }
                }) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red.opacity(0.8))
                        .font(.system(size: 16))
                        .frame(width: barHeight, height: barHeight)
                        .contentShape(Rectangle())
                }
                .buttonStyle(ToolbarButtonStyle())
                .opacity(showDeleteButton ? 1 : 0)
                .offset(y: showDeleteButton ? 0 : 10)
            }
            .frame(height: barHeight)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.95))
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            )
        }
        .zIndex(1000)
        .clipped()
        .allowsHitTesting(true)
    }
    .onAppear {
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
    .onDisappear {
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
}
