import Foundation
import Darwin

/// 一个 UDP 口子。收和发都在后台队列，回调回主线程。
final class 哨 {

    private(set) var fd: Int32 = -1
    private var 跑着 = true
    private let 收队列 = DispatchQueue(label: "yudeng.socket.recv")
    private var 收线程: Thread?

    /// 每收到一包：(数据, 来源IP, 来源端口)
    var 收到: (([UInt8], String, UInt16) -> Void)?

    init?(绑端口: UInt16, 广播: Bool = true) {
        let s = socket(AF_INET, SOCK_DGRAM, 0)
        guard s >= 0 else { return nil }
        fd = s

        var yes: Int32 = 1
        setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(MemoryLayout<Int32>.size))
        if 广播 {
            setsockopt(s, SOL_SOCKET, SO_BROADCAST, &yes, socklen_t(MemoryLayout<Int32>.size))
        }
        var 大: Int32 = 256 * 1024
        setsockopt(s, SOL_SOCKET, SO_RCVBUF, &大, socklen_t(MemoryLayout<Int32>.size))
        setsockopt(s, SOL_SOCKET, SO_SNDBUF, &大, socklen_t(MemoryLayout<Int32>.size))

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = 绑端口.bigEndian
        addr.sin_addr.s_addr = INADDR_ANY

        let r = withUnsafePointer(to: &addr) { p in
            p.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(s, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        if r != 0 {
            close(s)
            fd = -1
            return nil
        }
    }

    /// 一个不绑端口的临时口子（发广播用）
    static func 临时() -> 哨? {
        return 哨(绑端口: 0, 广播: true)
    }

    func 开始收() {
        guard fd >= 0 else { return }
        let t = Thread { [weak self] in
            guard let self else { return }
            var 缓 = [UInt8](repeating: 0, count: 4096)
            while self.跑着 {
                var 从 = sockaddr_in()
                var 长 = socklen_t(MemoryLayout<sockaddr_in>.size)
                let n = 缓.withUnsafeMutableBytes { (buf: UnsafeMutableRawBufferPointer) -> Int in
                    guard let base = buf.baseAddress else { return -1 }
                    return withUnsafeMutablePointer(to: &从) { p in
                        p.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                            recvfrom(self.fd, base, buf.count, 0, sa, &长)
                        }
                    }
                }
                if n <= 0 { continue }
                var host = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                var 址 = 从.sin_addr
                inet_ntop(AF_INET, &址, &host, socklen_t(INET_ADDRSTRLEN))
                let ip = String(cString: host)
                let 端口 = UInt16(bigEndian: 从.sin_port)
                let data = Array(缓[0..<n])
                self.收到?(data, ip, 端口)
            }
        }
        t.name = "收"
        t.start()
        收线程 = t
    }

    func 发(_ bytes: [UInt8], 到 host: String, 端口: UInt16) {
        guard fd >= 0 else { return }
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = 端口.bigEndian
        if inet_pton(AF_INET, host, &addr.sin_addr) != 1 { return }
        bytes.withUnsafeBytes { (buf: UnsafeRawBufferPointer) in
            guard let base = buf.baseAddress else { return }
            withUnsafePointer(to: &addr) { p in
                p.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                    _ = sendto(fd, base, buf.count, 0, sa, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }
    }

    func 广播(_ bytes: [UInt8], 端口: UInt16) {
        发(bytes, 到: "255.255.255.255", 端口: 端口)
    }

    func 关掉() {
        跑着 = false
        if fd >= 0 { close(fd) }
        fd = -1
    }

    deinit { 关掉() }
}

/// 本机在 Wi-Fi 上的地址（挑一个 IPv4）
enum 本机地址 {
    static func 找() -> String? {
        var 候选: [String] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let 首 = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        var p = 首
        while true {
            let ifa = p.pointee
            if let sa = ifa.ifa_addr, sa.pointee.sa_family == sa_family_t(AF_INET) {
                let name = String(cString: ifa.ifa_name)
                let 是流量 = name.hasPrefix("rmnet") || name.hasPrefix("pdp") || name.hasPrefix("ccmni")
                if !是流量 && (ifa.ifa_flags & UInt32(IFF_UP)) != 0 && (ifa.ifa_flags & UInt32(IFF_LOOPBACK)) == 0 {
                    var host = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                    var addr = sa.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee.sin_addr }
                    inet_ntop(AF_INET, &addr, &host, socklen_t(INET_ADDRSTRLEN))
                    let ip = String(cString: host)
                    if !ip.hasPrefix("127.") && !ip.isEmpty {
                        候选.append(ip)
                    }
                }
            }
            guard let next = ifa.ifa_next else { break }
            p = next
        }
        // 优先 192.168 / 10. / 172.16-31
        func 分(_ ip: String) -> Int {
            let 段 = ip.split(separator: ".").compactMap { Int($0) }
            return 段.count == 4 ? 段[0] * 1000000 + 段[1] * 1000 + 段[2] : 0
        }
        let 好 = 候选.filter { ip in
            ip.hasPrefix("192.168.") || ip.hasPrefix("10.") ||
            (ip.hasPrefix("172.") && (分(ip) / 1000 % 1000) >= 16 && (分(ip) / 1000 % 1000) <= 31)
        }
        return 好.first ?? 候选.first
    }

    /// 按本机地址算子网广播地址
    static func 子网广播(_ ip: String) -> String? {
        let 段 = ip.split(separator: ".").compactMap { Int($0) }
        guard 段.count == 4 else { return nil }
        return "\(段[0]).\(段[1]).\(段[2]).255"
    }
}
