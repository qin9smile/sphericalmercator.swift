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


  /// Convert tile xyz value to Bounds of the form
  func bbox(x: Double, y: Double, zoom: Int, tmsStyle: Bool, srs: String) -> Bounds {
    var _y = y
    if tmsStyle {
      _y = (Double(truncating: NSDecimalNumber(decimal: pow(2, zoom))) - 1) - y
    }

    let ws = ll(px: CGPoint(x: x * size, y: (+_y + 1) * size), zoom: zoom)!
    let en = ll(px: CGPoint(x: (+x + 1) * size, y: _y * size), zoom: zoom)!
    let bounds = Bounds(ws: ws, en: en)
    if srs == "900913" {
      return convert(bounds, to: "900913")
    }
    return bounds
  }

  /// Convert bbounds to xyz bounds
  func xyz(bbox: Bounds, zoom: Int, tmsStyle: Bool, srs: String) -> XYZBounds {
    var _bbox = bbox
    if srs == "900913" {
      _bbox = convert(bbox, to: "WGS84")
    }

    let px_ll = px(coordinate: bbox.ws, zoom: zoom)!
    let px_ur = px(coordinate: bbox.en, zoom: zoom)!

    // Y = 0 for XYZ is the top hency minY use px_ur.y
    let x = [floor(px_ll.x / size), floor((px_ur.x - 1) / size)]
    let y = [floor(px_ur.y / size), floor((px_ll.y - 1) / size)]

    let xyzBounds = XYZBounds(minPoint: Point(x: x.min()! < 0 ? 0 : x.min()!, y: y.min()! < 0 ? 0 : y.min()!), maxPoint: Point(x: x.max()!, y: y.max()!))

    if tmsStyle {
      let minY = Double(truncating: NSDecimalNumber(decimal: pow(2, zoom))) - 1 - xyzBounds.maxPoint.y
      let maxY = Double(truncating: NSDecimalNumber(decimal: pow(2, zoom))) - 1 - xyzBounds.minPoint.y
      xyzBounds.minPoint.y = minY
      xyzBounds.maxPoint.y = maxY
    }

    return xyzBounds
  }

  /// Convert projection of given bbox
  func convert(_ bounds: Bounds, to srs: String) -> Bounds {
    if srs == "900913" {
      return Bounds()
    } else {
      return Bounds()
    }
  }

   // Convert Coordinate to 900913 Point
  func forward(_ coordinate: CLLocationCoordinate2D) -> Point {
    let point = Point(x: A * coordinate.longitude * D2R,
                      y: A * log(tan(Double.pi * 0.25 + 0.5 * coordinate.latitude * D2R)))

    // if xy value is beyond maxextent (e.g. poles), return maxextent.
    if point.x > MAXEXTENT {
        point.x = MAXEXTENT
    } else if point.x < -MAXEXTENT {
      point.x = -MAXEXTENT
    }

    if point.y > MAXEXTENT {
      point.y = MAXEXTENT
    } else if point.y < -MAXEXTENT {
      point.y = -MAXEXTENT
    }

    return point
  }

  // Convert 900913 Point to Coordinate
  func inverse(_ point: Point) -> CLLocationCoordinate2D {
    return CLLocationCoordinate2D.init(latitude: (Double.pi * 0.5) - 2.0 * atan(exp(-point.y / A)) * R2D, longitude: point.x * R2D / A)
  }
}
