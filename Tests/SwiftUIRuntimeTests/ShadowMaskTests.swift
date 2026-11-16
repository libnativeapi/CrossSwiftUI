import Foundation
import XCTest

@testable import SwiftUIRuntime

final class ShadowMaskTests: XCTestCase {
  private func mask(_ radius: Double, scale: Double = 1) throws -> ShadowMask {
    try XCTUnwrap(
      ShadowMask(
        width: 160, height: 120, cornerRadius: 12,
        radius: radius, scale: scale))
  }

  private func alpha(_ mask: ShadowMask, x: Double, y: Double) -> Double {
    let px = Int(floor((x + mask.inset) * mask.scale))
    let py = Int(floor((y + mask.inset) * mask.scale))
    return Double(mask.alpha[py * mask.width + px]) / 255
  }

  func testLargeShadowHasSmoothGaussianFalloffBeyondOldLayerLimit() throws {
    for radius in [8.0, 24.0, 48.0] {
      let mask = try mask(radius)
      var previous = 1.0
      for distance in 0...Int(radius * 3) {
        let coverage = alpha(mask, x: -Double(distance) - 0.5, y: 60)
        XCTAssertLessThanOrEqual(coverage, previous)
        // Gaussian integral over a rectangular silhouette at the side midpoint.
        let x = -Double(distance) - 0.5
        let expectedX = (erf((160 - x) / (radius * sqrt(2))) - erf(-x / (radius * sqrt(2)))) / 2
        let expectedY = erf(60 / (radius * sqrt(2)))
        XCTAssertEqual(coverage, expectedX * expectedY, accuracy: 0.025)
        previous = coverage
      }
      XCTAssertGreaterThan(alpha(mask, x: -radius, y: 60), 0.08)
      XCTAssertLessThan(alpha(mask, x: -radius * 3, y: 60), 0.005)
    }
  }

  func testMaskIsSymmetricAndHasTransparentPadding() throws {
    let mask = try mask(24)
    for y in 0..<mask.height {
      for x in 0..<mask.width {
        let value = Int(mask.alpha[y * mask.width + x])
        XCTAssertLessThanOrEqual(
          abs(value - Int(mask.alpha[y * mask.width + mask.width - x - 1])), 1)
        XCTAssertLessThanOrEqual(
          abs(value - Int(mask.alpha[(mask.height - y - 1) * mask.width + x])), 1)
      }
      XCTAssertEqual(mask.alpha[y * mask.width], 0)
      XCTAssertEqual(mask.alpha[y * mask.width + mask.width - 1], 0)
    }
    XCTAssertTrue(mask.alpha.prefix(mask.width).allSatisfy { $0 == 0 })
    XCTAssertTrue(mask.alpha.suffix(mask.width).allSatisfy { $0 == 0 })
  }

  func testHighDPIKeepsLogicalBlurAndRoundedCorners() throws {
    let normal = try mask(16)
    let retina = try mask(16, scale: 2)
    for x in stride(from: -40.0, through: 20, by: 2) {
      XCTAssertEqual(alpha(normal, x: x, y: 60), alpha(retina, x: x, y: 60), accuracy: 0.015)
    }
    XCTAssertLessThan(alpha(normal, x: 0, y: 0), alpha(normal, x: 0, y: 60))
  }

  func testZeroRadiusAndInvalidGeometry() throws {
    let mask = try mask(0)
    XCTAssertEqual(alpha(mask, x: -1, y: 60), 0)
    XCTAssertEqual(alpha(mask, x: 1, y: 60), 1)
    XCTAssertEqual(alpha(mask, x: 0, y: 0), 0)
    XCTAssertNil(ShadowMask(width: 0, height: 30, cornerRadius: 4, radius: 8))
    XCTAssertNil(ShadowMask(width: 30, height: 30, cornerRadius: .nan, radius: 8))
    XCTAssertNil(ShadowMask(width: 30, height: 30, cornerRadius: 4, radius: .infinity))
    let capsule = try XCTUnwrap(
      ShadowMask(width: 80, height: 26, cornerRadius: .infinity, radius: 1))
    XCTAssertLessThan(alpha(capsule, x: 1, y: 1), 0.05)
    XCTAssertGreaterThan(alpha(capsule, x: 40, y: 13), 0.99)
    let large = try XCTUnwrap(
      ShadowMask(width: 10_000, height: 5000, cornerRadius: 100, radius: 100))
    XCTAssertLessThanOrEqual(large.width, 2048)
    XCTAssertLessThanOrEqual(large.height, 2048)
  }

  @MainActor
  func testShadowCornerRadiusFollowsLayeredAndClippedSilhouettes() throws {
    func shadowedCorner<V: View>(_ view: V) throws -> Double {
      let renderer = Renderer(
        backend: FakeBackend(), root: AnyView(view), size: Size(width: 300, height: 200))
      renderer.mount()
      func find(_ node: Element) -> Element? {
        if !node.props.shadows.isEmpty { return node }
        for child in node.children {
          if let found = find(child) { return found }
        }
        return nil
      }
      let matched: Element? = renderer.tree.flatMap(find)
      return try XCTUnwrap(matched).shadowCornerRadius
    }

    let button = Text("Save")
      .frame(width: 80, height: 26)
      .background { RoundedRectangle(cornerRadius: 9999, style: .circular).fill(.black) }
      .overlay { RoundedRectangle(cornerRadius: 9999, style: .circular).strokeBorder(.clear, lineWidth: 1) }
      .shadow(color: .black, radius: 1, x: 0, y: 1)
    XCTAssertEqual(try shadowedCorner(button), 9999)

    let popover = Text("Sheet")
      .frame(width: 120, height: 80)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 14, style: .circular))
      .overlay { RoundedRectangle(cornerRadius: 14, style: .circular).strokeBorder(.gray, lineWidth: 1) }
      .shadow(color: .black, radius: 8, x: 0, y: 4)
    XCTAssertEqual(try shadowedCorner(popover), 14)

    let thumb = Circle()
      .fill(.white)
      .frame(width: 16, height: 16)
      .overlay(Circle().strokeBorder(.gray, lineWidth: 1))
      .shadow(color: .black, radius: 1.5, x: 0, y: 1)
    XCTAssertTrue(try shadowedCorner(thumb).isInfinite)

    let sharpCard = ZStack {
      Circle().fill(.red).frame(width: 16, height: 16)
    }
    .frame(width: 80, height: 40)
    .background(.white)
    .shadow(color: .black, radius: 4, x: 0, y: 2)
    XCTAssertEqual(try shadowedCorner(sharpCard), 0)
  }
}
