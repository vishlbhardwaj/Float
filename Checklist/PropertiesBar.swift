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
            HStack(spacing: 12) {
                // Size picker
                Menu {
                    ForEach(StickyNoteSize.allCases, id: \.self) { size in
                        Button(action: {
                            note.updateNoteSize(to: size)
                        }) {
                            Text(size.rawValue.capitalized)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                
                // Font size picker
                Menu {
                    ForEach(FontSize.allCases, id: \.self) { size in
                        Button(action: {
                            note.updateTextSize(to: size)
                        }) {
                            Text(size.rawValue)
                        }
                    }
                } label: {
                    Image(systemName: "textformat.size")
                }
                
                // Font style picker
                Menu {
                    ForEach(FontStyle.allCases, id: \.self) { style in
                        Button(action: {
                            withAnimation {
                                selectedFontStyle = style
                                for index in note.items.indices {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        note.items[index].fontStyle = style
                                    }
                                }
                            }
                        }) {
                            Text(style.displayName)
                        }
                    }
                } label: {
                    Image(systemName: "textformat")
                }
                
                Spacer()
                
                // List style toggle
                Button(action: {
                    withAnimation {
                        let newStyle: ListStyle = note.listStyle == .checkbox ? .bullet : .checkbox
                        note.listStyle = newStyle
                    }
                }) {
                    Image(systemName: note.listStyle == .checkbox ? "checklist" : "list.bullet")
                }
                
                // Color picker
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if showSizePicker { showSizePicker = false }
                        if showFontStylePicker { showFontStylePicker = false }
                        if showTextSizePicker { showTextSizePicker = false }
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
                
                // Delete button
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
            .padding(8)
            .background(note.style.backgroundColor.darker(by: 0.05))
            .cornerRadius(8)
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
        .zIndex(1000)
    }
}
