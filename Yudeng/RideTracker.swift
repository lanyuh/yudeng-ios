import Foundation
import CoreLocation
import AVFoundation

/// 骑行记录。安卓那边是前台服务，iOS 这边是 CoreLocation + 后台定位模式。
final class 骑手: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let 共享 = 骑手()

    @Published var 当前: 一趟?
    @Published var 暂停中 = false
    @Published var 速度Kmh = 0.0
    @Published var 上次断裂: 一趟?
    @Published var 授权 = CLAuthorizationStatus.notDetermined

    private let 管 = CLLocationManager()
    private var 文件: URL?
    private var 暂停起点: Int64 = 0
    private var 记着 = false

    private override init() {
        super.init()
        管.delegate = self
        管.desiredAccuracy = kCLLocationAccuracyBest
        管.distanceFilter = 3
        管.activityType = .fitness
        管.allowsBackgroundLocationUpdates = true
        管.pausesLocationUpdatesAutomatically = false
        授权 = 管.authorizationStatus
        上次断裂 = 一趟.收拾断掉的()
    }

    func 要授权() {
        管.requestAlwaysAuthorization()
    }

    func 开始() {
        if 当前 != nil, 当前?.recording == true {
            挂上()
            return
        }
        要授权()
        let t = 一趟()
        t.start = Int64(Date().timeIntervalSince1970 * 1000)
        t.recording = true
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        let 名 = f.string(from: Date())
        文件 = 一趟.轨迹目录.appendingPathComponent("\(名).json")
        t.存(文件!)
        当前 = t
        暂停中 = false
        上次断裂 = nil
        挂上()
    }

    func 暂停() {
        guard let t = 当前, !暂停中 else { return }
        暂停中 = true
        暂停起点 = Int64(Date().timeIntervalSince1970 * 1000)
        _ = t
        if let f = 文件 { 当前?.存(f) }
    }

    func 继续() {
        guard let t = 当前, 暂停中 else { return }
        暂停中 = false
        if 暂停起点 > 0 {
            t.pauseMs += Int64(Date().timeIntervalSince1970 * 1000) - 暂停起点
            暂停起点 = 0
        }
        if let f = 文件 { t.存(f) }
    }

    func 停止() {
        guard let t = 当前 else { return }
        t.end = Int64(Date().timeIntervalSince1970 * 1000)
        t.recording = false
        if 暂停中, 暂停起点 > 0 {
            t.pauseMs += Int64(Date().timeIntervalSince1970 * 1000) - 暂停起点
            暂停起点 = 0
        }
        暂停中 = false
        if let f = 文件 { t.存(f) }
        撤下()
    }

    private func 挂上() {
        guard !记着 else { return }
        记着 = true
        管.startUpdatingLocation()
    }

    private func 撤下() {
        记着 = false
        管.stopUpdatingLocation()
    }

    // MARK: - 代理

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        授权 = manager.authorizationStatus
        if 授权 == .authorizedAlways || 授权 == .authorizedWhenInUse {
            // 有授权才能开后台定位
            manager.allowsBackgroundLocationUpdates = true
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let t = 当前, let loc = locations.last else { return }
        let p = 点(
            t: Int64(loc.timestamp.timeIntervalSince1970 * 1000),
            lat: loc.coordinate.latitude,
            lng: loc.coordinate.longitude,
            s: Float(max(0, loc.speed)),
            a: Float(loc.horizontalAccuracy)
        )
        t.points.append(p)
        速度Kmh = max(0, loc.speed) * 3.6
        if let f = 文件 { t.存(f) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 定位失败不吭声，等下一个点
    }
}
