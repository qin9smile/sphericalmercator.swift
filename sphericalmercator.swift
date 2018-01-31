import Foundation

class SphericalMercator {
  let EPSLN = 1.0e-10
  let D2R = Double.pi / 180
  let R2D = 180 / Double.pi
  let A = 6378137.0
  let MAXEXTENT = 20037508.342789244

  let size: Double


  var cache: [Double: CacheSize] = [:]

  class CacheSize {
    var Bc: [Double] = []
    var Cc: [Double] = []
    var zc: [Double] = []
    var Ac: [Double] = []
  }

  public init() {
    self.size = 256;
    if cache[self.size] == nil {
      var size = self.size
      cache[size] = CacheSize()
      let c = cache[size]
      for _ in 0..<30 {
        c?.Bc.append(size / 360)
        c?.Cc.append(size / (2 * Double.pi))
        c?.zc.append(size / 2)
        c?.Ac.append(size)
        size *= 2
      }
    }
  }

  /// Convert lon lat to screen pixel value
  func px(coordinate: CLLocationCoordinate2D, zoom: Int) -> CGPoint? {
    guard let cacheSize = cache[size] else {
      return nil
    }

    let d = cacheSize.zc[zoom]
    let f = min(max(sin(D2R * coordinate.latitude), -0.9999), 0.9999)
    var x = round(d + coordinate.longitude * cacheSize.Bc[zoom])
    var y = round(d + 0.5 * log((1 + f) / (1 - f)) * (-cacheSize.Cc[zoom]))
    if x > cacheSize.Ac[zoom] {
      x = cacheSize.Ac[zoom]
    }

    if y > cacheSize.Ac[zoom] {
      y = cacheSize.Ac[zoom]
    }
    return CGPoint(x: x, y: y)
  }

  /// Convert screen pixel value to Coordinate
  func ll(px: CGPoint, zoom: Int) -> CLLocationCoordinate2D? {
    guard let cacheSize = cache[size] else {
      return nil
    }
    let g = (Double(px.y) - cacheSize.zc[zoom]) / (-cacheSize.Cc[zoom])
    let longitude = (Double(px.x) - cacheSize.zc[zoom]) / cacheSize.Bc[zoom]
    let latitude = R2D * (2 * atan(exp(g)) - 0.5 * Double.pi)
    return CLLocationCoordinate2D.init(latitude: latitude, longitude: longitude)
  }
}
