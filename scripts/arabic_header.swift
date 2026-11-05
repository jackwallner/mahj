// Draws right-to-left App Store headers with CoreText, which shapes Arabic
// (Pillow here has no raqm). Used by localize_appstore_screenshots.py.
//
// stdin: JSON array of
//   {text, font, canvasWidth, canvasHeight, top, maxWidth, size, minSize,
//    maxLines, lineGap (multiple of size), color:[r,g,b], out}
// stdout: JSON array of {out, size, lines, bounds:[x0,y0,x1,y1]} (top-left origin)
// Writes a transparent PNG per job; the caller pastes it over the gradient.
import AppKit
import Foundation

struct Job: Codable {
    let text, font, out: String
    let canvasWidth, canvasHeight, top, maxWidth, size, minSize, maxLines: Int
    let lineGap: Double
    let color: [Int]
}
struct Result: Codable { let out: String; let size: Int; let lines: Int; let bounds: [Int] }

func attributed(_ text: String, _ job: Job, _ size: Int) -> NSAttributedString {
    let font = NSFont(name: job.font, size: CGFloat(size)) ?? NSFont.systemFont(ofSize: CGFloat(size), weight: .bold)
    let c = job.color
    let colour = NSColor(srgbRed: CGFloat(c[0]) / 255, green: CGFloat(c[1]) / 255, blue: CGFloat(c[2]) / 255, alpha: 1)
    return NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: colour, .languageIdentifier: "ar"])
}

func width(_ s: NSAttributedString) -> Double {
    CTLineGetTypographicBounds(CTLineCreateWithAttributedString(s), nil, nil, nil)
}

/// Greedy wrap in logical order, then rebalance the last two lines so the
/// lines are close in length.
func wrap(_ text: String, _ job: Job, _ size: Int) -> [String] {
    let words = text.split(separator: " ").map(String.init)
    var lines: [String] = []
    var current = ""
    for word in words {
        let trial = current.isEmpty ? word : current + " " + word
        if width(attributed(trial, job, size)) <= Double(job.maxWidth) || current.isEmpty {
            current = trial
        } else {
            lines.append(current)
            current = word
        }
    }
    lines.append(current)
    if lines.count == 2 {
        var best = lines
        var bestDiff = abs(width(attributed(lines[0], job, size)) - width(attributed(lines[1], job, size)))
        for split in 1..<words.count {
            let a = words[..<split].joined(separator: " "), b = words[split...].joined(separator: " ")
            let wa = width(attributed(a, job, size)), wb = width(attributed(b, job, size))
            if max(wa, wb) <= Double(job.maxWidth), abs(wa - wb) < bestDiff { best = [a, b]; bestDiff = abs(wa - wb) }
        }
        lines = best
    }
    return lines
}

func render(_ job: Job) -> Result {
    var size = job.size
    var lines = wrap(job.text, job, size)
    while (lines.count > job.maxLines || lines.contains { width(attributed($0, job, size)) > Double(job.maxWidth) }) && size > job.minSize {
        size -= 2
        lines = wrap(job.text, job, size)
    }
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: job.canvasWidth, pixelsHigh: job.canvasHeight,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    var x0 = Int.max, y0 = Int.max, x1 = 0, y1 = 0
    let step = Double(size) * job.lineGap
    for (i, text) in lines.enumerated() {
        let line = CTLineCreateWithAttributedString(attributed(text, job, size))
        let box = CTLineGetImageBounds(line, ctx)
        // Top of the first line's ink sits at `top`; later lines follow at a fixed step.
        let inkTop = Double(job.top)
        let firstBaselineFromTop = inkTop + Double(size) * 0.8
        let baseline = firstBaselineFromTop + Double(i) * step
        ctx.textMatrix = .identity
        ctx.textPosition = CGPoint(x: (Double(job.canvasWidth) - box.width) / 2 - box.minX,
                                   y: Double(job.canvasHeight) - baseline)
        CTLineDraw(line, ctx)
        let lx = (Double(job.canvasWidth) - box.width) / 2
        x0 = min(x0, Int(lx)); x1 = max(x1, Int(lx + box.width))
        y0 = min(y0, Int(baseline - box.maxY)); y1 = max(y1, Int(baseline - box.minY))
    }
    let png = rep.representation(using: .png, properties: [:])!
    try! png.write(to: URL(fileURLWithPath: job.out))
    return Result(out: job.out, size: size, lines: lines.count, bounds: [x0, y0, x1, y1])
}

let jobs = try! JSONDecoder().decode([Job].self, from: FileHandle.standardInput.readDataToEndOfFile())
print(String(data: try! JSONEncoder().encode(jobs.map(render)), encoding: .utf8)!)
