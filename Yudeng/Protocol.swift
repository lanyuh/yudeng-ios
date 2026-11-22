import Foundation

/// 屿灯的线协议 —— 跟安卓原样对齐，一个字节都不改。
///
/// 音频包 643 字节：
///   [0] 谁在说（槽位 1..15，客户端发出去时填 0，服务端改写）
///   [1] 你是几号（让收到的人知道自己的槽位）
///   [2] 包序号（每 256 绕回，用来判断丢包）
///   [3..642] 640 字节 = 320 采样 = 20ms @ 16kHz 16bit mono
///
/// 名字包：0xFE + 槽位 + UTF-8 名字
/// 音乐包：0xFF 开头，总长 963（3 + 960），48k mono，20ms
enum 线 {
    static let 端口: UInt16 = 40000
    static let 发现口: UInt16 = 40001
    static let 采样率: Double = 16000
    static let 包采样 = 320
    static let 包字节 = 640
    static let 总包 = 643
    static let 音乐包字节 = 963
    static let 音乐段字节 = 960

    static let 问是谁 = "WALKIEWHO"
    static let 我在这 = "WALKIEHERE"

    /// 名字包首字节
    static let 名字头: UInt8 = 0xFE
    /// 音乐包首字节
    static let 音乐头: UInt8 = 0xFF

    /// 读一个音频包
    struct 音频包 {
        let 谁说: Int
        let 我是: Int
        let 序号: Int
        let 音: [UInt8]
    }

    static func 解音频包(_ data: [UInt8]) -> 音频包? {
        guard data.count >= 总包 else { return nil }
        return 音频包(
            谁说: Int(data[0]),
            我是: Int(data[1]),
            序号: Int(data[2]),
            音: Array(data[3..<总包])
        )
    }

    /// 读名字包
    static func 解名字包(_ data: [UInt8]) -> (槽: Int, 名: String)? {
        guard data.count >= 3, data[0] == 名字头 else { return nil }
        let 槽 = Int(data[1])
        let 名 = String(bytes: data[2...], encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard 槽 != 0, !名.isEmpty else { return nil }
        return (槽, 名)
    }

    /// 发出去的音频包（谁和我是 0，服务端填）
    static func 造音频包(音: [UInt8], 序号: UInt8) -> [UInt8] {
        var 包 = [UInt8](repeating: 0, count: 总包)
        包[0] = 0
        包[1] = 0
        包[2] = 序号
        let n = min(音.count, 包字节)
        for i in 0..<n { 包[3 + i] = 音[i] }
        return 包
    }

    /// 名字包
    static func 造名字包(名: String) -> [UInt8] {
        var 包: [UInt8] = [名字头, 0]
        包.append(contentsOf: Array(名.utf8))
        return 包
    }

    /// 算一段 PCM 的均方根（0..1）
    static func 音量(_ 音: [UInt8]) -> Double {
        guard 音.count >= 2 else { return 0 }
        var 和 = 0.0
        var i = 0
        while i + 1 < 音.count {
            let v = Int16(bitPattern: UInt16(音[i]) | (UInt16(音[i + 1]) << 8))
            let f = Double(v) / 32768.0
            和 += f * f
            i += 2
        }
        let n = Double(音.count / 2)
        guard n > 0 else { return 0 }
        return (和 / n).squareRoot()
    }
}

/// 十六进制的一小段，日志里用
func 料子(_ bytes: [UInt8], _ n: Int = 16) -> String {
    bytes.prefix(n).map { String(format: "%02x", $0) }.joined()
}
