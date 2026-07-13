import Foundation

struct PerceptualMetrics: Equatable {
    let sampleCount: Int
    let deltaE00Mean: Double
    let deltaE00Median: Double
    let deltaE00P95: Double
    let deltaE00Maximum: Double
    let ssim: Double
    let finiteOutput: Bool

    static func compare(
        actualRGBA: [UInt8],
        referenceRGBA: [UInt8]
    ) -> PerceptualMetrics? {
        guard actualRGBA.count == referenceRGBA.count,
              actualRGBA.count.isMultiple(of: 4),
              !actualRGBA.isEmpty
        else { return nil }

        var deltas: [Double] = []
        deltas.reserveCapacity(actualRGBA.count / 4)
        var sumActual = 0.0
        var sumReference = 0.0
        var sumActualSquared = 0.0
        var sumReferenceSquared = 0.0
        var sumProduct = 0.0

        for offset in stride(from: 0, to: actualRGBA.count, by: 4) {
            let actual = RGB(
                red: Double(actualRGBA[offset]) / 255,
                green: Double(actualRGBA[offset + 1]) / 255,
                blue: Double(actualRGBA[offset + 2]) / 255
            )
            let reference = RGB(
                red: Double(referenceRGBA[offset]) / 255,
                green: Double(referenceRGBA[offset + 1]) / 255,
                blue: Double(referenceRGBA[offset + 2]) / 255
            )
            deltas.append(deltaE00(lab(actual), lab(reference)))
            let actualLuminance = luminance(actual)
            let referenceLuminance = luminance(reference)
            sumActual += actualLuminance
            sumReference += referenceLuminance
            sumActualSquared += actualLuminance * actualLuminance
            sumReferenceSquared += referenceLuminance * referenceLuminance
            sumProduct += actualLuminance * referenceLuminance
        }

        deltas.sort()
        let count = Double(deltas.count)
        let meanActual = sumActual / count
        let meanReference = sumReference / count
        let varianceActual = sumActualSquared / count - meanActual * meanActual
        let varianceReference = sumReferenceSquared / count - meanReference * meanReference
        let covariance = sumProduct / count - meanActual * meanReference
        let c1 = 0.0001
        let c2 = 0.0009
        let ssimNumerator = (2 * meanActual * meanReference + c1) * (2 * covariance + c2)
        let ssimDenominator = (meanActual * meanActual + meanReference * meanReference + c1)
            * (varianceActual + varianceReference + c2)
        let deltaMean = deltas.reduce(0, +) / count

        return PerceptualMetrics(
            sampleCount: deltas.count,
            deltaE00Mean: deltaMean,
            deltaE00Median: percentile(deltas, 0.50),
            deltaE00P95: percentile(deltas, 0.95),
            deltaE00Maximum: deltas.last!,
            ssim: ssimNumerator / ssimDenominator,
            finiteOutput: deltas.allSatisfy(\.isFinite) && ssimDenominator.isFinite
        )
    }
}

private struct RGB {
    let red: Double
    let green: Double
    let blue: Double
}

private struct Lab {
    let lightness: Double
    let a: Double
    let b: Double
}

private func linear(_ value: Double) -> Double {
    value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
}

private func lab(_ rgb: RGB) -> Lab {
    let red = linear(rgb.red)
    let green = linear(rgb.green)
    let blue = linear(rgb.blue)
    let x = (0.4124564 * red + 0.3575761 * green + 0.1804375 * blue) / 0.95047
    let y = 0.2126729 * red + 0.7151522 * green + 0.0721750 * blue
    let z = (0.0193339 * red + 0.1191920 * green + 0.9503041 * blue) / 1.08883
    func curve(_ value: Double) -> Double {
        value > 216.0 / 24389.0
            ? pow(value, 1.0 / 3.0)
            : (841.0 / 108.0) * value + 4.0 / 29.0
    }
    let curvedX = curve(x)
    let curvedY = curve(y)
    let curvedZ = curve(z)
    return Lab(
        lightness: 116 * curvedY - 16,
        a: 500 * (curvedX - curvedY),
        b: 200 * (curvedY - curvedZ)
    )
}

private func degrees(_ radians: Double) -> Double {
    let value = radians * 180 / .pi
    return value < 0 ? value + 360 : value
}

private func radians(_ degrees: Double) -> Double {
    degrees * .pi / 180
}

private func deltaE00(_ first: Lab, _ second: Lab) -> Double {
    let chromaFirst = hypot(first.a, first.b)
    let chromaSecond = hypot(second.a, second.b)
    let chromaMean = (chromaFirst + chromaSecond) / 2
    let chromaPower = pow(chromaMean, 7)
    let adjustment = 0.5 * (1 - sqrt(chromaPower / (chromaPower + pow(25.0, 7))))
    let adjustedAFirst = (1 + adjustment) * first.a
    let adjustedASecond = (1 + adjustment) * second.a
    let adjustedChromaFirst = hypot(adjustedAFirst, first.b)
    let adjustedChromaSecond = hypot(adjustedASecond, second.b)
    let hueFirst = adjustedChromaFirst == 0 ? 0 : degrees(atan2(first.b, adjustedAFirst))
    let hueSecond = adjustedChromaSecond == 0 ? 0 : degrees(atan2(second.b, adjustedASecond))
    let deltaLightness = second.lightness - first.lightness
    let deltaChroma = adjustedChromaSecond - adjustedChromaFirst
    var deltaHue = hueSecond - hueFirst
    if adjustedChromaFirst * adjustedChromaSecond == 0 {
        deltaHue = 0
    } else if deltaHue > 180 {
        deltaHue -= 360
    } else if deltaHue < -180 {
        deltaHue += 360
    }
    let deltaBigHue = 2 * sqrt(adjustedChromaFirst * adjustedChromaSecond)
        * sin(radians(deltaHue / 2))
    let lightnessMean = (first.lightness + second.lightness) / 2
    let adjustedChromaMean = (adjustedChromaFirst + adjustedChromaSecond) / 2
    var hueMean = hueFirst + hueSecond
    if adjustedChromaFirst * adjustedChromaSecond == 0 {
        hueMean = hueFirst + hueSecond
    } else if abs(hueFirst - hueSecond) <= 180 {
        hueMean /= 2
    } else if hueMean < 360 {
        hueMean = (hueMean + 360) / 2
    } else {
        hueMean = (hueMean - 360) / 2
    }
    let weighting = 1
        - 0.17 * cos(radians(hueMean - 30))
        + 0.24 * cos(radians(2 * hueMean))
        + 0.32 * cos(radians(3 * hueMean + 6))
        - 0.20 * cos(radians(4 * hueMean - 63))
    let scaleLightness = 1 + 0.015 * pow(lightnessMean - 50, 2)
        / sqrt(20 + pow(lightnessMean - 50, 2))
    let scaleChroma = 1 + 0.045 * adjustedChromaMean
    let scaleHue = 1 + 0.015 * adjustedChromaMean * weighting
    let rotation = 30 * exp(-pow((hueMean - 275) / 25, 2))
    let rotationChroma = 2 * sqrt(
        pow(adjustedChromaMean, 7)
            / (pow(adjustedChromaMean, 7) + pow(25.0, 7))
    )
    let rotationTerm = -sin(radians(2 * rotation)) * rotationChroma
    let lightness = deltaLightness / scaleLightness
    let chroma = deltaChroma / scaleChroma
    let hue = deltaBigHue / scaleHue
    return sqrt(
        lightness * lightness + chroma * chroma + hue * hue
            + rotationTerm * chroma * hue
    )
}

private func luminance(_ rgb: RGB) -> Double {
    0.2126 * linear(rgb.red) + 0.7152 * linear(rgb.green) + 0.0722 * linear(rgb.blue)
}

private func percentile(_ sorted: [Double], _ fraction: Double) -> Double {
    let rank = max(1, Int(ceil(fraction * Double(sorted.count))))
    return sorted[rank - 1]
}
