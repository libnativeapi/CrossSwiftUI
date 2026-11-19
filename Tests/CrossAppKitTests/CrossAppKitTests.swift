import XCTest
@testable import CrossAppKit

final class CrossAppKitTests: XCTestCase {
  func testCoordinateYFlipRoundTrip() {
    let primaryH: CGFloat = 1080
    let appKitRect = NSRect(x: 200, y: 300, width: 750, height: 475)
    let topLeft = CrossAppKitCoordinates.rectToNativeTopLeft(appKitRect, primaryHeight: primaryH)
    XCTAssertEqual(topLeft.x, 200, accuracy: 0.001)
    XCTAssertEqual(topLeft.y, 1080 - 300 - 475, accuracy: 0.001)
    let restored = CrossAppKitCoordinates.rectFromNativeTopLeft(
      x: topLeft.x, y: topLeft.y, width: topLeft.width, height: topLeft.height, primaryHeight: primaryH
    )
    XCTAssertEqual(restored, appKitRect)
  }

  func testDynamicColorResolvesByAppearance() {
    let color = CrossAppKit.NSColor(name: nil) { appearance in
      appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        ? CrossAppKit.NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.4)
        : CrossAppKit.NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.55)
    }
    let dark = color.resolved(for: CrossAppKit.NSAppearance(named: .darkAqua))
    let light = color.resolved(for: CrossAppKit.NSAppearance(named: .aqua))
    XCTAssertEqual(dark.r, 1.0, accuracy: 0.001)
    XCTAssertEqual(dark.a, 0.4, accuracy: 0.001)
    XCTAssertEqual(light.r, 0.0, accuracy: 0.001)
    XCTAssertEqual(light.a, 0.55, accuracy: 0.001)
  }

  func testFontTextStylePreservesDescriptorWeight() {
    let headline = CrossAppKit.NSFont.preferredFont(forTextStyle: .headline)
    XCTAssertEqual(headline.pointSize, 13)
    XCTAssertEqual(headline.fontDescriptor.weight, CrossAppKit.NSFont.Weight.bold)
    let scaled = CrossAppKit.NSFont(descriptor: headline.fontDescriptor, size: 16)
    XCTAssertEqual(scaled?.pointSize, 16)
    XCTAssertEqual(scaled?.fontDescriptor.weight, CrossAppKit.NSFont.Weight.bold)
  }

  func testBundleAwareXCAassetsPDFResolution() throws {
    let tmp = FileManager.default.temporaryDirectory
      .appendingPathComponent("crossappkit-xcassets-\(UUID().uuidString)")
    let imageset = tmp.appendingPathComponent("FluentIcons.xcassets/ic_fluent_home_20_regular.imageset")
    try FileManager.default.createDirectory(at: imageset, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmp) }

    let pdfURL = imageset.appendingPathComponent("ic_fluent_home_20_regular.pdf")
    try "%PDF-1.4\n".write(to: pdfURL, atomically: true, encoding: .utf8)
    let contentsJSON = """
    {
      "images" : [
        {
          "filename" : "ic_fluent_home_20_regular.pdf",
          "idiom" : "universal"
        }
      ],
      "info" : { "author" : "xcode", "version" : 1 }
    }
    """
    try contentsJSON.write(
      to: imageset.appendingPathComponent("Contents.json"),
      atomically: true,
      encoding: .utf8
    )

    let bundle = try XCTUnwrap(Bundle(url: tmp))
    let resolved = CrossAppKit.NSImage.resolveAssetPath(named: "ic_fluent_home_20_regular", in: bundle)
    XCTAssertEqual(
      resolved.map { URL(fileURLWithPath: $0).standardizedFileURL.path },
      pdfURL.standardizedFileURL.path
    )
    let nsImg = bundle.image(forResource: "ic_fluent_home_20_regular")
    XCTAssertNotNil(nsImg)
    XCTAssertEqual(
      nsImg?.filePath.map { URL(fileURLWithPath: $0).standardizedFileURL.path },
      pdfURL.standardizedFileURL.path
    )
  }
}
