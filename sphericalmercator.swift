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

  func px(coordinate: CLLocationCoordinate2D, zoom: Double) -> CLLocationCoordinate2D {
    return CLLocationCoordinate2D()
  }
}
