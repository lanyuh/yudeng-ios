import Foundation

/// 服务端：当主机那台跑的。跟安卓 服务端.kt 一样的规矩。
///
/// 收到谁的东西，就给他一个槽位（1..15，轮着来），转发的时候把
/// 「谁在说」写进第 0 字节，把「你是几号」写进第 1 字节。
/// 名字包的第二字节写「这是谁的名字」。不回给发的人。
final class 转发器 {

    private let 口: 哨
    private let 发现口: 哨
    private var 跑着 = true

    private let 锁 = NSLock()
    private var 人: [String: Date] = [:]       // "ip:port" -> 最后收到
    private var 槽位表: [String: Int] = [:]
    private var 下一个槽位 = 1

    /// 自己那台的地址，计数时剔掉
    private let 本机: String

    /// 每转发一包（界面拿它算流量，不用管）
    var 转了一次: (([UInt8], String) -> Void)?

    init?(本机: String) {
        guard let a = 哨(绑端口: 线.端口), let b = 哨(绑端口: 线.发现口) else { return nil }
        口 = a
        发现口 = b
        self.本机 = 本机
    }

    func 起() {
        口.收到 = { [weak self] data, ip, port in
            self?.收(data, ip, port)
        }
        口.开始收()

        发现口.收到 = { [weak self] data, ip, port in
            guard let self else { return }
            let 文 = String(bytes: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if 文 == 线.问是谁 {
                self.发现口.发(Array(线.我在这.utf8), 到: ip, 端口: port)
            }
        }
        发现口.开始收()
    }

    func 停() {
        跑着 = false
        口.关掉()
        发现口.关掉()
    }

    /// 清超时（10 秒没动静就走人）
    private func 清超时() {
        let 现在 = Date()
        let 过期 = 人.filter { 现在.timeIntervalSince($0.value) > 10 }.map { $0.key }
        for k in 过期 {
            人.removeValue(forKey: k)
            槽位表.removeValue(forKey: k)
        }
    }

    /// 在线槽位（剔掉主机自己）
    func 在线槽位() -> [Int] {
        锁.lock()
        清超时()
        let 结果 = 人.keys
            .filter { 本机.isEmpty || !$0.hasPrefix(本机 + ":") }
            .compactMap { 槽位表[$0] }
            .sorted()
        锁.unlock()
        return 结果
    }

    private func 收(_ data: [UInt8], _ ip: String, _ port: UInt16) {
        guard 跑着, data.count >= 3 else { return }
        let 是名字 = data[0] == 线.名字头
        if !是名字 && data.count < 线.总包 { return }

        // 安卓用 "ip:port" 认人，我们也一样 —— 同一个手机换端口就当新来的。
        let 从 = "\(ip):\(port)"

        锁.lock()
        人[从] = Date()
        if 槽位表[从] == nil {
            槽位表[从] = 下一个槽位
            下一个槽位 = 下一个槽位 >= 15 ? 1 : 下一个槽位 + 1
        }
        let 谁 = 槽位表[从] ?? 0
        var 收者们: [(String, Int)] = []
        for (k, v) in 槽位表 where k != 从 {
            收者们.append((k, v))
        }  // for 收者们

        锁.unlock()

        for (k, 他的号) in 收者们 {
            guard let 冒 = k.lastIndex(of: ":") else { continue }
            let 址 = String(k[k.startIndex..<冒])
            guard let 端 = UInt16(String(k[k.index(after: 冒)...])) else { continue }

            var 给 = data
            if 是名字 {
                if 给.count > 1 { 给[1] = UInt8(谁 & 0xFF) }
            } else {
                let 是音乐 = 给[0] == 线.音乐头
                if !是音乐 { 给[0] = UInt8(谁 & 0xFF) }
                if 给.count > 1 { 给[1] = UInt8(他的号 & 0xFF) }
            }
            口.发(给, 到: 址, 端口: 端)
        }
        转了一次?(data, 从)
    }
}

/// 找主机：广播一句 WALKIEWHO，等 WALKIEHERE。
enum 找人 {
    static func 找主机(自己: String, 等: TimeInterval = 2.5) -> String? {
        guard let 哨 = 哨(绑端口: 0) else { return nil }
        var 结果: String?
        let 锁 = NSLock()
        哨.收到 = { data, ip, _ in
            let 文 = String(bytes: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if 文 == 线.我在这 && !ip.hasPrefix("127.") && ip != 自己 {
                锁.lock()
                if 结果 == nil || 比大小(ip) < 比大小(结果!) { 结果 = ip }
                锁.unlock()
            }
        }
        哨.开始收()

        let 问 = Array(线.问是谁.utf8)
        var 目标 = ["255.255.255.255"]
        if let 子 = 本机地址.子网广播(自己) { 目标.append(子) }
        for _ in 0..<4 {
            for t in 目标 { 哨.广播(问, 端口: 线.发现口) }
            Thread.sleep(forTimeInterval: 0.25)
        }
        Thread.sleep(forTimeInterval: 等)
        哨.关掉()
        锁.lock()
        let 值 = 结果
        锁.unlock()
        return 值
    }

    /// IP 当数字比大小
    static func 比大小(_ ip: String) -> UInt64 {
        let 段 = ip.split(separator: ".").compactMap { UInt64($0) }
        guard 段.count == 4 else { return UInt64.max }
        return (段[0] << 24) | (段[1] << 16) | (段[2] << 8) | 段[3]
    }
}
