import SwiftUI
import UIKit

@main
struct ColorWheelToolApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var selectedHue: Double = 0
    @State private var selectedBrightness: Double = 1

    private let saturation: Double = 1

    private var selectedColor: Color {
        Color(hue: selectedHue, saturation: saturation, brightness: selectedBrightness)
    }

    var body: some View {
        VStack(spacing: 24) {
            ColorWheelView(
                selectedHue: selectedHue,
                selectedBrightness: selectedBrightness,
                onSelect: { hue, brightness in
                    selectColor(hue: hue, brightness: brightness)
                }
            )
            .frame(maxWidth: 420)
            .frame(maxHeight: 420)
            .aspectRatio(1, contentMode: .fit)

            VStack(spacing: 12) {
                FineAdjustmentsView(
                    hue: selectedHue,
                    saturation: saturation,
                    brightness: selectedBrightness,
                    onSelectHue: { hue in
                        selectColor(hue: hue, brightness: selectedBrightness)
                    }
                )
                HarmonyView(
                    hue: selectedHue,
                    saturation: saturation,
                    brightness: selectedBrightness,
                    onSelectHue: { hue in
                        selectColor(hue: hue, brightness: selectedBrightness)
                    }
                )
                PreviewView(color: selectedColor, hex: ColorConverter.hexString(hue: selectedHue, saturation: saturation, brightness: selectedBrightness))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
    }

    private func selectColor(hue: Double, brightness: Double) {
        selectedHue = hue
        selectedBrightness = brightness
        let hex = ColorConverter.hexString(hue: hue, saturation: saturation, brightness: brightness)
        UIPasteboard.general.string = hex
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

struct ColorWheelView: View {
    let selectedHue: Double
    let selectedBrightness: Double
    let onSelect: (Double, Double) -> Void

    private let segmentCount = 24
    private let ringCount = 10
    private let saturation: Double = 1

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                ForEach(0..<ringCount, id: \.self) { ring in
                    ForEach(0..<segmentCount, id: \.self) { segment in
                        let hue = Double(segment) / Double(segmentCount)
                        let brightness = brightnessValue(for: ring)
                        let angleStep = 360.0 / Double(segmentCount)
                        let epsilonAngle = 0.12
                        let epsilonRadius = 0.001
                        let startAngle = Double(segment) * angleStep - epsilonAngle
                        let endAngle = Double(segment + 1) * angleStep + epsilonAngle
                        let inner = max(0, Double(ring) / Double(ringCount) - epsilonRadius)
                        let outer = min(1, Double(ring + 1) / Double(ringCount) + epsilonRadius)

                        RingSegmentShape(
                            startAngle: .degrees(startAngle),
                            endAngle: .degrees(endAngle),
                            innerRadiusFraction: inner,
                            outerRadiusFraction: outer
                        )
                        .fill(Color(hue: hue, saturation: saturation, brightness: brightness))
                        .overlay {
                            if isSelected(hue: hue, brightness: brightness) {
                                ZStack {
                                    RingSegmentShape(
                                        startAngle: .degrees(startAngle),
                                        endAngle: .degrees(endAngle),
                                        innerRadiusFraction: inner,
                                        outerRadiusFraction: outer
                                    )
                                    .stroke(Color.black.opacity(0.85), lineWidth: 2)
                                    RingSegmentShape(
                                        startAngle: .degrees(startAngle),
                                        endAngle: .degrees(endAngle),
                                        innerRadiusFraction: inner,
                                        outerRadiusFraction: outer
                                    )
                                    .stroke(Color.white.opacity(0.95), lineWidth: 1)
                                }
                            }
                        }
                        .contentShape(
                            RingSegmentShape(
                                startAngle: .degrees(startAngle),
                                endAngle: .degrees(endAngle),
                                innerRadiusFraction: inner,
                                outerRadiusFraction: outer
                            )
                        )
                        .onTapGesture {
                            onSelect(hue, brightness)
                        }
                    }
                }
            }
            .frame(width: side, height: side)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func brightnessValue(for ring: Int) -> Double {
        let progress = Double(ring) / Double(ringCount - 1)
        let adjusted = pow(1.0 - progress, 0.8)
        return 0.1 + (0.9 * adjusted)
    }

    private func isSelected(hue: Double, brightness: Double) -> Bool {
        abs(hue - selectedHue) < 0.0001 && abs(brightness - selectedBrightness) < 0.0001
    }
}

struct FineAdjustmentsView: View {
    let hue: Double
    let saturation: Double
    let brightness: Double
    let onSelectHue: (Double) -> Void

    private let offsetsInDegrees: [Double] = [-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(offsetsInDegrees, id: \.self) { offset in
                let adjustedHue = shiftedHue(base: hue, degrees: offset)
                Rectangle()
                    .fill(Color(hue: adjustedHue, saturation: saturation, brightness: brightness))
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectHue(adjustedHue)
                    }
            }
        }
    }

    private func shiftedHue(base: Double, degrees: Double) -> Double {
        let shifted = base + (degrees / 360.0)
        return shifted.truncatingRemainder(dividingBy: 1).wrappedUnitInterval
    }
}

struct HarmonyView: View {
    let hue: Double
    let saturation: Double
    let brightness: Double
    let onSelectHue: (Double) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(harmonyOffsets, id: \.self) { offset in
                let adjustedHue = shiftedHue(base: hue, degrees: offset)
                Rectangle()
                    .fill(Color(hue: adjustedHue, saturation: saturation, brightness: brightness))
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectHue(adjustedHue)
                    }
            }
        }
    }

    private var harmonyOffsets: [Double] {
        [180, 120, -120, 30, -30]
    }

    private func shiftedHue(base: Double, degrees: Double) -> Double {
        let shifted = base + (degrees / 360.0)
        return shifted.truncatingRemainder(dividingBy: 1).wrappedUnitInterval
    }
}

struct PreviewView: View {
    let color: Color
    let hex: String

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(color)
                .frame(width: 92, height: 92)

            VStack(alignment: .leading, spacing: 6) {
                Text("HEX")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(hex)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RingSegmentShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadiusFraction: Double
    let outerRadiusFraction: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) * 0.5
        let innerRadius = maxRadius * innerRadiusFraction
        let outerRadius = maxRadius * outerRadiusFraction

        var path = Path()
        path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        return path
    }
}

enum ColorConverter {
    static func hexString(hue: Double, saturation: Double, brightness: Double) -> String {
        let uiColor = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        if !uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            guard let converted = uiColor.cgColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil),
                  let components = converted.components else {
                return "#000000"
            }

            if components.count >= 3 {
                r = components[0]
                g = components[1]
                b = components[2]
            } else if components.count == 2 {
                r = components[0]
                g = components[0]
                b = components[0]
            } else {
                return "#000000"
            }
        }

        let red = clampTo255(r)
        let green = clampTo255(g)
        let blue = clampTo255(b)

        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    private static func clampTo255(_ value: CGFloat) -> Int {
        let safe = value.isFinite ? value : 0
        return Int(round(min(1, max(0, safe)) * 255))
    }
}

private extension Double {
    var wrappedUnitInterval: Double {
        self >= 0 ? self : self + 1
    }
}
