import AppKit
for name in ["laurel.leading", "laurel.trailing"] {
    let cfg = NSImage.SymbolConfiguration(pointSize: 900, weight: .regular)
        .applying(NSImage.SymbolConfiguration(paletteColors: [NSColor(srgbRed: 168/255, green: 130/255, blue: 58/255, alpha: 1)]))
    guard let img = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(cfg) else { print("missing \(name)"); continue }
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(img.size.width), pixelsHigh: Int(img.size.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    img.draw(in: NSRect(origin: .zero, size: img.size))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(name).png"))
    print(name, img.size)
}
