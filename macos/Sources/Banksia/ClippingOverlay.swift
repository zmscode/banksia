import CoreGraphics
import Foundation

/// Build an overlay marking clipped pixels: highlights (any channel at the top
/// of range) in red, deep shadows (all channels near zero) in blue, everything
/// else clear. Premultiplied RGBA so it composites straight over the frame at
/// the viewer's transform. Runs off the main actor — it scans every pixel.
func makeClippingOverlay(from image: CGImage) -> CGImage? {
    let width = image.width
    let height = image.height
    guard width > 0, height > 0,
          let data = image.dataProvider?.data,
          let src = CFDataGetBytePtr(data) else { return nil }
    let rowBytes = image.bytesPerRow

    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    return pixels.withUnsafeMutableBytes { raw -> CGImage? in
        let dst = raw.bindMemory(to: UInt8.self).baseAddress!
        for y in 0..<height {
            let srcRow = y * rowBytes
            let dstRow = y * width * 4
            for x in 0..<width {
                let p = srcRow + x * 4
                let r = src[p], g = src[p + 1], b = src[p + 2]
                let o = dstRow + x * 4
                if r >= 254 || g >= 254 || b >= 254 {
                    dst[o] = 178; dst[o + 1] = 35; dst[o + 2] = 35; dst[o + 3] = 178
                } else if r <= 2 && g <= 2 && b <= 2 {
                    dst[o] = 35; dst[o + 1] = 77; dst[o + 2] = 178; dst[o + 3] = 178
                }
            }
        }
        guard let ctx = CGContext(
            data: raw.baseAddress, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        return ctx.makeImage()
    }
}
