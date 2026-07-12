import CoreGraphics
import Foundation
import ImageIO

private struct RGB {
    let r: Double
    let g: Double
    let b: Double
}

private struct Lab {
    let l: Double
    let a: Double
    let b: Double
}

private struct Bitmap {
    let width: Int
    let height: Int
    let bytes: [UInt8]

    init(path: String) throws {
        let url = URL(fileURLWithPath: path) as CFURL
        guard let source = CGImageSourceCreateWithURL(url, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ReportError.cannotDecode(path)
        }
        let imageWidth = image.width
        let imageHeight = image.height
        var storage = [UInt8](repeating: 0, count: imageWidth * imageHeight * 4)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            throw ReportError.noSRGB
        }
        let drew = storage.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: imageWidth,
                height: imageHeight,
                bitsPerComponent: 8,
                bytesPerRow: imageWidth * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.interpolationQuality = .none
            context.draw(
                image,
                in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)
            )
            return true
        }
        guard drew else { throw ReportError.cannotDraw(path) }
        width = imageWidth
        height = imageHeight
        bytes = storage
    }

    func rgb(x: Int, y: Int) -> RGB {
        let offset = (y * width + x) * 4
        return RGB(
            r: Double(bytes[offset]) / 255,
            g: Double(bytes[offset + 1]) / 255,
            b: Double(bytes[offset + 2]) / 255
        )
    }
}

private enum ReportError: Error, CustomStringConvertible {
    case usage
    case cannotDecode(String)
    case cannotDraw(String)
    case dimensions
    case noSRGB

    var description: String {
        switch self {
        case .usage: return "usage: perceptual-report.swift ACTUAL REFERENCE"
        case .cannotDecode(let path): return "cannot decode \(path)"
        case .cannotDraw(let path): return "cannot convert \(path) to sRGB"
        case .dimensions: return "actual and reference dimensions differ"
        case .noSRGB: return "the system sRGB colour space is unavailable"
        }
    }
}

private func linear(_ value: Double) -> Double {
    value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
}

private func lab(_ rgb: RGB) -> Lab {
    let r = linear(rgb.r)
    let g = linear(rgb.g)
    let b = linear(rgb.b)
    let x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047
    let y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b
    let z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883
    func f(_ value: Double) -> Double {
        value > 216.0 / 24389.0
            ? pow(value, 1.0 / 3.0)
            : (841.0 / 108.0) * value + 4.0 / 29.0
    }
    let fx = f(x)
    let fy = f(y)
    let fz = f(z)
    return Lab(l: 116 * fy - 16, a: 500 * (fx - fy), b: 200 * (fy - fz))
}

private func degrees(_ radians: Double) -> Double {
    let value = radians * 180 / .pi
    return value < 0 ? value + 360 : value
}

private func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }

// Sharma, Wu, and Dalal CIEDE2000 with unit weighting factors.
private func deltaE00(_ first: Lab, _ second: Lab) -> Double {
    let c1 = hypot(first.a, first.b)
    let c2 = hypot(second.a, second.b)
    let cMean = (c1 + c2) / 2
    let c7 = pow(cMean, 7)
    let g = 0.5 * (1 - sqrt(c7 / (c7 + pow(25.0, 7))))
    let a1 = (1 + g) * first.a
    let a2 = (1 + g) * second.a
    let cp1 = hypot(a1, first.b)
    let cp2 = hypot(a2, second.b)
    let hp1 = cp1 == 0 ? 0 : degrees(atan2(first.b, a1))
    let hp2 = cp2 == 0 ? 0 : degrees(atan2(second.b, a2))
    let deltaL = second.l - first.l
    let deltaC = cp2 - cp1
    var deltaH = hp2 - hp1
    if cp1 * cp2 == 0 { deltaH = 0 }
    else if deltaH > 180 { deltaH -= 360 }
    else if deltaH < -180 { deltaH += 360 }
    let deltaBigH = 2 * sqrt(cp1 * cp2) * sin(radians(deltaH / 2))
    let lMean = (first.l + second.l) / 2
    let cpMean = (cp1 + cp2) / 2
    var hpMean = hp1 + hp2
    if cp1 * cp2 == 0 { hpMean = hp1 + hp2 }
    else if abs(hp1 - hp2) <= 180 { hpMean /= 2 }
    else if hpMean < 360 { hpMean = (hpMean + 360) / 2 }
    else { hpMean = (hpMean - 360) / 2 }
    let t = 1
        - 0.17 * cos(radians(hpMean - 30))
        + 0.24 * cos(radians(2 * hpMean))
        + 0.32 * cos(radians(3 * hpMean + 6))
        - 0.20 * cos(radians(4 * hpMean - 63))
    let sl = 1 + 0.015 * pow(lMean - 50, 2) / sqrt(20 + pow(lMean - 50, 2))
    let sc = 1 + 0.045 * cpMean
    let sh = 1 + 0.015 * cpMean * t
    let rotation = 30 * exp(-pow((hpMean - 275) / 25, 2))
    let rc = 2 * sqrt(pow(cpMean, 7) / (pow(cpMean, 7) + pow(25.0, 7)))
    let rt = -sin(radians(2 * rotation)) * rc
    let dl = deltaL / sl
    let dc = deltaC / sc
    let dh = deltaBigH / sh
    return sqrt(dl * dl + dc * dc + dh * dh + rt * dc * dh)
}

private func luminance(_ rgb: RGB) -> Double {
    0.2126 * linear(rgb.r) + 0.7152 * linear(rgb.g) + 0.0722 * linear(rgb.b)
}

private func percentile(_ sorted: [Double], _ fraction: Double) -> Double {
    sorted[Int(Double(sorted.count - 1) * fraction)]
}

private func report(actual: Bitmap, reference: Bitmap) throws {
    guard actual.width == reference.width, actual.height == reference.height else {
        throw ReportError.dimensions
    }
    let pixelCount = actual.width * actual.height
    let step = max(1, Int(ceil(sqrt(Double(pixelCount) / 1_000_000))))
    var deltas: [Double] = []
    deltas.reserveCapacity(pixelCount / (step * step) + 1)
    var sumX = 0.0, sumY = 0.0, sumXX = 0.0, sumYY = 0.0, sumXY = 0.0
    var count = 0.0
    for y in stride(from: 0, to: actual.height, by: step) {
        for x in stride(from: 0, to: actual.width, by: step) {
            let first = actual.rgb(x: x, y: y)
            let second = reference.rgb(x: x, y: y)
            deltas.append(deltaE00(lab(first), lab(second)))
            let lx = luminance(first), ly = luminance(second)
            sumX += lx; sumY += ly; sumXX += lx * lx; sumYY += ly * ly
            sumXY += lx * ly; count += 1
        }
    }
    deltas.sort()
    let meanX = sumX / count, meanY = sumY / count
    let varianceX = sumXX / count - meanX * meanX
    let varianceY = sumYY / count - meanY * meanY
    let covariance = sumXY / count - meanX * meanY
    let c1 = 0.0001, c2 = 0.0009
    let ssim = ((2 * meanX * meanY + c1) * (2 * covariance + c2))
        / ((meanX * meanX + meanY * meanY + c1) * (varianceX + varianceY + c2))
    print("dimensions=\(actual.width)x\(actual.height) samples=\(deltas.count) step=\(step)")
    print(String(format: "ssim=%.6f deltaE00_median=%.3f deltaE00_p95=%.3f",
                 ssim, percentile(deltas, 0.5), percentile(deltas, 0.95)))
}

do {
    guard CommandLine.arguments.count == 3 else { throw ReportError.usage }
    let actual = try Bitmap(path: CommandLine.arguments[1])
    let reference = try Bitmap(path: CommandLine.arguments[2])
    try report(actual: actual, reference: reference)
} catch {
    FileHandle.standardError.write(Data("perceptual-report: \(error)\n".utf8))
    exit(1)
}
