import Foundation
import CoreLocation

/// 一个轨迹点。跟安卓的 JSON 一模一样，存下来两边能互相看。
struct 点: Codable {
    var t: Int64
    var lat: Double
    var lng: Double
    var s: Float
    var a: Float

    var 速度Kmh: Double { Double(s) * 3.6 }
}

/// 一趟骑行
final class 一趟: Codable {
    var start: Int64 = 0
    var end: Int64 = 0
    /// 正在记录。正常停止改 false；被杀的时候它一直是 true —— 断裂检测靠它
    var recording: Bool = false
    var broken: Bool = false
    var pauseMs: Int64 = 0
    var points: [点] = []

    enum CodingKeys: String, CodingKey {
        case start, end, recording, broken, pauseMs, points
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        start = try c.decodeIfPresent(Int64.self, forKey: .start) ?? 0
        end = try c.decodeIfPresent(Int64.self, forKey: .end) ?? 0
        recording = try c.decodeIfPresent(Bool.self, forKey: .recording) ?? false
        broken = try c.decodeIfPresent(Bool.self, forKey: .broken) ?? false
        pauseMs = try c.decodeIfPresent(Int64.self, forKey: .pauseMs) ?? 0
        points = try c.decodeIfPresent([点].self, forKey: .points) ?? []
    }

    // MARK: 四个数

    /// 距离（米）。跳过精度差的点、跳过原地漂移。
    func 距离米() -> Double {
        guard points.count >= 2 else { return 0 }
        var d = 0.0
        for i in 1..<points.count {
            let p = points[i - 1], q = points[i]
            if q.a > 30 { continue }
            let 米 = 两点距离(p.lat, p.lng, q.lat, q.lng)
            if 米 < 3 { continue }
            d += 米
        }
        return d
    }

    func 距离公里() -> Double { 距离米() / 1000 }

    func 有效毫秒() -> Int64 {
        guard start > 0 else { return 0 }
        let 末 = end > 0 ? end : Int64(Date().timeIntervalSince1970 * 1000)
        return max(0, 末 - start - pauseMs)
    }

    func 均速Kmh() -> Double {
        let h = Double(有效毫秒()) / 3_600_000
        guard h > 0 else { return 0 }
        return 距离公里() / h
    }

    /// 最高速。先丢掉精度差的点，不然静止时跳出一个假最高。
    func 最高Kmh() -> Double {
        let 好的 = points.filter { $0.a <= 30 && $0.s > 0.1 }
        return (好的.map { $0.s }.max().map { Double($0) * 3.6 }) ?? 0
    }

    func 时长文本() -> String {
        let 秒 = Int(有效毫秒() / 1000)
        let h = 秒 / 3600, m = (秒 % 3600) / 60, s = 秒 % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    // MARK: 存 / 读

    func 存(_ url: URL) {
        do {
            let 数据 = try JSONEncoder().encode(self)
            try 数据.write(to: url, options: .atomic)
        } catch {
            print("存不下：\(error)")
        }
    }

    static func 读(_ url: URL) -> 一趟? {
        guard let 数据 = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(一趟.self, from: 数据)
    }

    static var 轨迹目录: URL {
        let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("tracks", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    static func 所有轨迹() -> [URL] {
        let d = 轨迹目录
        let 们 = (try? FileManager.default.contentsOfDirectory(at: d, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        return 们.filter { $0.pathExtension == "json" }
            .sorted { a, b in
                let ta = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let tb = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                return ta > tb
            }
    }

    /// 断裂检测：最后一趟要是 recording 还是 true，说明上次没正常结束。
    @discardableResult
    static func 收拾断掉的() -> 一趟? {
        guard let 最后 = 所有轨迹().first else { return nil }
        guard let t = 读(最后), t.recording else { return nil }
        t.recording = false
        t.broken = true
        if t.end <= 0 {
            t.end = Int64(((try? 最后.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()).timeIntervalSince1970 * 1000)
        }
        t.存(最后)
        return t
    }
}

/// 两点距离（米），球面公式
func 两点距离(_ lat1: Double, _ lng1: Double, _ lat2: Double, _ lng2: Double) -> Double {
    let r = 6_371_000.0
    let φ1 = lat1 * .pi / 180, φ2 = lat2 * .pi / 180
    let dφ = (lat2 - lat1) * .pi / 180
    let dλ = (lng2 - lng1) * .pi / 180
    let a = sin(dφ / 2) * sin(dφ / 2) + cos(φ1) * cos(φ2) * sin(dλ / 2) * sin(dλ / 2)
    return 2 * r * atan2(a.squareRoot(), (1 - a).squareRoot())
}

/// 一条约好的路线。不用地图，也能算「偏了多少米」「还剩多远」。
final class 路线: Codable {
    var 名字: String = ""
    var 谁: String = ""
    var 哪天: String = ""
    var 点们: [[Double]] = []      // [[lat, lng], ...]

    enum CodingKeys: String, CodingKey {
        case 名字, 谁, 哪天, 点
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        名字 = try c.decodeIfPresent(String.self, forKey: .名字) ?? ""
        谁 = try c.decodeIfPresent(String.self, forKey: .谁) ?? ""
        哪天 = try c.decodeIfPresent(String.self, forKey: .哪天) ?? ""
        点们 = try c.decodeIfPresent([[Double]].self, forKey: .点) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(名字, forKey: .名字)
        try c.encode(谁, forKey: .谁)
        try c.encode(哪天, forKey: .哪天)
        try c.encode(点们, forKey: .点)
    }

    private var 平x: [Double]?
    private var 平y: [Double]?
    private var 缓存总长 = -1.0

    private func 平面() -> ([Double], [Double]) {
        if let x = 平x, let y = 平y { return (x, y) }
        let n = 点们.count
        var xs = [Double](repeating: 0, count: n)
        var ys = [Double](repeating: 0, count: n)
        guard n > 0 else { return (xs, ys) }
        let 纬0 = 点们[0][0]
        let k = 111_320.0 * cos(纬0 * .pi / 180)
        for i in 0..<n {
            xs[i] = (点们[i][1] - 点们[0][1]) * k
            ys[i] = (点们[i][0] - 纬0) * 111_320.0
        }
        平x = xs
        平y = ys
        return (xs, ys)
    }

    func 总长() -> Double {
        if 缓存总长 >= 0 { return 缓存总长 }
        let (xs, ys) = 平面()
        var 和 = 0.0
        for i in 0..<max(0, xs.count - 1) {
            和 += (pow(xs[i + 1] - xs[i], 2) + pow(ys[i + 1] - ys[i], 2)).squareRoot()
        }
        缓存总长 = 和
        return 和
    }

    /// 离线距离（米）、沿线已走（米）
    func 算(_ 纬度: Double, _ 经度: Double) -> (偏: Double, 走: Double) {
        let n = 点们.count
        guard n >= 2 else { return (0, 0) }
        let (xs, ys) = 平面()
        let 纬0 = 点们[0][0]
        let k = 111_320.0 * cos(纬0 * .pi / 180)
        let px = (经度 - 点们[0][1]) * k
        let py = (纬度 - 纬0) * 111_320.0

        var 最近 = Double.greatestFiniteMagnitude
        var 已走 = 0.0
        var 累计 = 0.0

        for i in 0..<n - 1 {
            let ax = xs[i], ay = ys[i], bx = xs[i + 1], by = ys[i + 1]
            let dx = bx - ax, dy = by - ay
            let 段2 = dx * dx + dy * dy
            let 段长 = 段2.squareRoot()
            if 段长 < 0.01 { continue }
            var t = ((px - ax) * dx + (py - ay) * dy) / 段2
            t = min(max(t, 0), 1)
            let 投x = ax + t * dx, 投y = ay + t * dy
            let d = ((px - 投x) * (px - 投x) + (py - 投y) * (py - 投y)).squareRoot()
            if d < 最近 {
                最近 = d
                已走 = 累计 + t * 段长
            }
            累计 += 段长
        }
        if 最近 == .greatestFiniteMagnitude { return (0, 0) }
        return (最近, 已走)
    }

    static func 从一趟(_ t: 一趟, 名字: String, 谁: String) -> 路线 {
        let r = 路线()
        r.名字 = 名字
        r.谁 = 谁
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        let 时 = t.start > 0 ? Date(timeIntervalSince1970: Double(t.start) / 1000) : Date()
        r.哪天 = f.string(from: 时)
        r.点们 = t.points.map { [$0.lat, $0.lng] }
        return r
    }

    func 存(_ url: URL) {
        do {
            let 数据 = try JSONEncoder().encode(self)
            try 数据.write(to: url, options: .atomic)
        } catch {
            print("路线存不下：\(error)")
        }
    }

    static func 读(_ url: URL) -> 路线? {
        guard let 数据 = try? Data(contentsOf: url) else { return nil }
        guard let r = try? JSONDecoder().decode(路线.self, from: 数据) else { return nil }
        return r.点们.count >= 2 ? r : nil
    }

    static var 目录: URL {
        let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("routes", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    static func 所有() -> [URL] {
        let d = 目录
        let 们 = (try? FileManager.default.contentsOfDirectory(at: d, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        return 们.filter { $0.pathExtension == "json" }
            .sorted { a, b in
                let ta = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let tb = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                return ta > tb
            }
    }
}
