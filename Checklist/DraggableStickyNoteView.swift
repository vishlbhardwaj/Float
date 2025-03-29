import Cocoa
import SwiftUI

class DraggableStickyNoteView: NSView {
    var note: StickyNote
    var onDelete: () -> Void

    init(note: StickyNote, onDelete: @escaping () -> Void) {
        self.note = note
        self.onDelete = onDelete
        super.init(frame: NSRect(x: 20, y: 20, width: 350, height: 420))
        self.wantsLayer = true
        self.layer?.cornerRadius = 32
        self.layer?.backgroundColor = NSColor.clear.cgColor
        
        // Add a SwiftUI view to this NSView
        let hostingView = NSHostingView(rootView: StickyNoteView(note: note, onDelete: onDelete))
        hostingView.frame = self.bounds
        hostingView.autoresizingMask = [.width, .height]
        self.addSubview(hostingView)

        // Add dragging functionality
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.addGestureRecognizer(panGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handlePan(_ gesture: NSPanGestureRecognizer) {
        guard let superview = self.superview else { return }
        
        let translation = gesture.translation(in: superview)
        self.frame.origin.x += translation.x
        self.frame.origin.y -= translation.y
        gesture.setTranslation(.zero, in: superview)
    }
}
