// Joins snapshots into one labeled contact sheet, so an agent can look at a
// whole pose in one image. With "fold", it shades the band the iPhone Duo's
// fold crosses: the middle of the long side, 20 pt on each side (the fold is
// 40 pt wide when partly folded, margins included).
// Usage: swiftc -O sheet.swift -o sheet && ./sheet <out.png> <fold|none> <png>...
import AppKit

let args = CommandLine.arguments
guard args.count > 3 else {
    print("usage: sheet <out.png> <fold|none> <png>...")
    exit(1)
}
let out = args[1]
let fold = args[2] == "fold"
let paths = args.dropFirst(3).filter { !$0.hasSuffix(".part") }
let images = paths.compactMap { path in NSImage(contentsOfFile: path).map { (path, $0) } }
guard let first = images.first?.1 else {
    print("no images")
    exit(1)
}

let tile: CGFloat = 360
let scale = tile / max(first.size.width, first.size.height)
let width = (first.size.width * scale).rounded(), height = (first.size.height * scale).rounded()
let label: CGFloat = 22, gap: CGFloat = 8
let columns = min(4, images.count), rows = (images.count + columns - 1) / columns
let size = NSSize(width: CGFloat(columns) * (width + gap) + gap,
                  height: CGFloat(rows) * (height + label + gap) + gap)

let sheet = NSImage(size: size)
sheet.lockFocus()
NSColor(white: 0.5, alpha: 1).setFill()
NSRect(origin: .zero, size: size).fill()
for (index, (path, image)) in images.enumerated() {
    let column = CGFloat(index % columns), row = CGFloat(index / columns)
    let x = gap + column * (width + gap)
    let y = size.height - (row + 1) * (height + label + gap)
    let frame = NSRect(x: x, y: y + label, width: width, height: height)
    image.draw(in: frame)
    if fold {
        // The Duo's long inner side is 951 pt, whichever way the image is turned.
        let pointsPerPixel = max(frame.width, frame.height) / 951
        let band = 20 * pointsPerPixel
        NSColor.systemRed.withAlphaComponent(0.28).setFill()
        if frame.width > frame.height {
            NSRect(x: frame.midX - band, y: frame.minY, width: band * 2, height: frame.height).fill()
        } else {
            NSRect(x: frame.minX, y: frame.midY - band, width: frame.width, height: band * 2).fill()
        }
    }
    let name = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
    name.draw(at: NSPoint(x: x, y: y + 4),
              withAttributes: [.font: NSFont.systemFont(ofSize: 13, weight: .medium), .foregroundColor: NSColor.white])
}
sheet.unlockFocus()

guard let tiff = sheet.tiffRepresentation, let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else {
    print("could not write \(out)")
    exit(1)
}
try png.write(to: URL(fileURLWithPath: out))
print(out)
