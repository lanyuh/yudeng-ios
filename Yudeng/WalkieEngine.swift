import Foundation

enum 分工型: String {
    case 主机 = "主机"
    case 客户端 = "客户端"
}

/// 屿灯的脑子：连谁、谁在说、几个人、名字。
/// 安卓那边 MainActivity.kt 里那套逻辑，一条一条搬过来。
/// 界面自己定时来读，这里不带 Combine（iOS 12 没有）。
final class 引擎 {

    // 界面来读的（主线程读；后台只改 状态锁 护着的那几个）
    var 人数文 = "没人"
    var 名单文 = ""
    var 提示文 = ""
    var 点们: [点状态] = []
    var 分工: 分工型 = .主机
    var 主机地址 = ""
    var 我叫 = ""
    var 耳机文 = "耳机：看下面"
    var 麦克风好 = false
    var 服务好 = true

    // 内部
    private let 声 = 声音.共享
    private var 客户端口: 哨?
    private var 服务: 转发器?

    private let 状态锁 = NSLock()
    private var 我的槽位 = 0
    private var 谁在说: [Int: Date] = [:]
    private var 名字表: [Int: String] = [:]

    private let 发锁 = NSLock()
    private var 发序号: UInt8 = 0
    private var 主机快照 = ""

    private let 收锁 = NSLock()
    private var 收序号表: [Int: Int] = [:]
    private var 目标包数 = 3
    private var 连顺 = 0
    private var 播放队列: [[UInt8]] = []
    private var 最后收包 = Date.distantPast

    private var 自己地址 = ""
    private var 计: Timer?
    private var 重连计: Timer?
    private var 看门狗: Timer?
    private var 报名计: Timer?
    private var 起来过 = false

    let 存档 = UserDefaults.standard

    init() {
        主机地址 = 存档.string(forKey: "主机") ?? ""
        我叫 = 存档.string(forKey: "名字") ?? ""
    }

    // MARK: - 开

    func 开起来() {
        if 起来过 { return }
        起来过 = true

        自己地址 = 本机地址.找() ?? ""
        if 主机地址.isEmpty {
            let 存 = 存档.string(forKey: "主机") ?? ""
            主机地址 = 存.isEmpty ? 自己地址 : 存
        }
        设主机快照(主机地址)

        do {
            try 声.开()
            麦克风好 = true
            提示文 = "麦克风好了"
        } catch {
            麦克风好 = false
            提示文 = "麦克风开不起来：\(error.localizedDescription)"
        }

        起服务端()
        起客户端口()
        开循环()

        if !自己地址.isEmpty {
            let 自己 = 自己地址
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self else { return }
                let 别 = 找人.找主机(自己: 自己)
                DispatchQueue.main.async {
                    if let 别, 别 != self.主机地址 {
                        self.主机地址 = 别
                        self.分工 = .客户端
                        self.设主机快照(别)
                        // 别人当主机了，自己那台服务端得让开
                        self.服务?.停()
                        self.服务 = nil
                    } else if 别 == nil {
                        self.主机地址 = 自己
                        self.分工 = .主机
                        self.设主机快照(自己)
                        self.起服务端()
                    }
                }
            }
        }
        刷耳机()
    }

    private func 起服务端() {
        服务?.停()
        服务 = 转发器(本机: 自己地址)
        服务?.起()
        服务好 = (服务 != nil)
    }

    private func 起客户端口() {
        客户端口?.关掉()
        let 口 = 哨(绑端口: 0)
        客户端口 = 口
        口?.收到 = { [weak self] data, _, _ in
            self?.收(data)
        }
        口?.开始收()

        声.采到一段 = { [weak self] 段 in
            self?.发一整包(段)
        }
    }

    private func 开循环() {
        计?.invalidate()
        计 = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.刷界面()
        }

        报名计?.invalidate()
        报名计 = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            guard let self, !self.我叫.isEmpty else { return }
            self.发名字()
        }

        看门狗?.invalidate()
        看门狗 = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            guard let self else { return }
            if !self.声.开着 {
                _ = self.声.重开()
            }
        }

        重连计?.invalidate()
        重连计 = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard let self, self.分工 == .客户端, !self.自己地址.isEmpty else { return }
            self.收锁.lock()
            let 静 = Date().timeIntervalSince(self.最后收包)
            self.收锁.unlock()
            guard 静 > 8 else { return }
            let 自己 = self.自己地址
            DispatchQueue.global(qos: .utility).async { [weak self] in
                let 谁 = 找人.找主机(自己: 自己, 等: 1.0)
                DispatchQueue.main.async {
                    guard let self, let 谁, 谁 != self.主机地址 else { return }
                    self.主机地址 = 谁
                    self.存档.set(谁, forKey: "主机")
                    self.设主机快照(谁)
                }
            }
        }
    }

    // MARK: - 发

    private func 设主机快照(_ v: String) {
        发锁.lock()
        主机快照 = v
        发锁.unlock()
    }

    private func 发一整包(_ 音: [UInt8]) {
        发锁.lock()
        let 主 = 主机快照
        let 序 = 发序号
        发序号 = 发序号 &+ 1
        let 口 = 客户端口
        发锁.unlock()

        guard !主.isEmpty, let 口 else { return }
        let 包 = 线.造音频包(音: 音, 序号: 序)
        口.发(包, 到: 主, 端口: 线.端口)
    }

    private func 发名字() {
        发锁.lock()
        let 主 = 主机快照
        let 口 = 客户端口
        发锁.unlock()
        guard !主.isEmpty, let 口, !我叫.isEmpty else { return }
        口.发(线.造名字包(名: 我叫), 到: 主, 端口: 线.端口)
    }

    // MARK: - 收

    private func 收(_ data: [UInt8]) {
        收锁.lock()
        最后收包 = Date()
        收锁.unlock()

        if let 名 = 线.解名字包(data) {
            状态锁.lock()
            名字表[名.槽] = 名.名
            状态锁.unlock()
            return
        }

        // 音乐包：0xFF 开头，963 字节，48k 单声道（主机放的歌）
        if data.count >= 线.音乐包字节 {
            let 乐 = Array(data[3..<线.音乐包字节])
            声.放音乐(乐)
            return
        }

        guard let 包 = 线.解音频包(data) else { return }

        状态锁.lock()
        if 包.我是 != 0 {
            我的槽位 = 包.我是
            if !我叫.isEmpty { 名字表[包.我是] = 我叫 }
        }
        let 声 = 线.音量(包.音)
        if 声 > 0.02 {
            谁在说[包.谁说] = Date()
        }
        状态锁.unlock()

        if 包.我是 != 0 && 包.谁说 == 包.我是 { return }

        收锁.lock()
        if let 上 = 收序号表[包.谁说] {
            let 差 = (包.序号 - 上 + 256) % 256
            if 差 > 1 {
                目标包数 = min(目标包数 + 1, 9)
                连顺 = 0
            } else if 差 == 1 {
                连顺 += 1
                if 连顺 > 300 {
                    目标包数 = max(目标包数 - 1, 3)
                    连顺 = 0
                }
            }
        }
        收序号表[包.谁说] = 包.序号

        播放队列.append(包.音)
        if 播放队列.count > 12 { 播放队列.removeFirst() }

        var 要放: [[UInt8]] = []
        while 播放队列.count >= 目标包数 {
            要放.append(播放队列.removeFirst())
        }
        收锁.unlock()

        for 一 in 要放 {
            声.放(一)
        }
    }

    // MARK: - 界面

    private func 刷界面() {
        let 现在 = Date()
        let 在线 = 分工 == .主机 ? (服务?.在线槽位() ?? []) : []

        状态锁.lock()
        let 说表 = 谁在说.filter { 现在.timeIntervalSince($0.value) < 3 }
        let 名表 = 名字表
        let 我的 = 我的槽位
        状态锁.unlock()

        let 在说的 = 说表.keys.sorted()
        let 总 = 在线.count + 1

        if let 头 = 在说的.first {
            人数文 = (名表[头] ?? "\(头) 号") + "在说"
        } else if 分工 == .客户端 {
            人数文 = "客户端"
        } else if 在线.isEmpty {
            人数文 = "就我一个"
        } else {
            人数文 = "\(总) 人"
        }

        if 分工 == .客户端 {
            名单文 = 主机地址.isEmpty ? "" : "连着 \(主机地址)"
        } else if 在线.isEmpty {
            名单文 = "还没别人进来"
        } else {
            名单文 = "在线：" + 在线.map { 名表[$0] ?? "\($0) 号" }.joined(separator: "、")
        }

        if 分工 == .客户端 {
            提示文 = 主机地址.isEmpty ? "没找到主机" : "连主机 \(主机地址)"
        } else if 主机地址.isEmpty {
            提示文 = "没填地址，点下面那行"
        } else {
            提示文 = "主机 \(主机地址)"
        }

        var 新点: [点状态] = []
        let 全部 = ([我的] + 在线).filter { $0 != 0 }
        for 号 in 全部 {
            let 说 = (说表[号].map { 现在.timeIntervalSince($0) < 0.9 }) ?? false
            新点.append(点状态(id: 号, 在说: 说, 是我: 号 == 我的))
        }
        点们 = 新点
    }

    // MARK: - 动作

    func 设分工(_ 新: 分工型) {
        guard 新 != 分工 else { return }
        分工 = 新
        if 新 == .主机 {
            let 自己 = 本机地址.找() ?? ""
            if !自己.isEmpty {
                自己地址 = 自己
                主机地址 = 自己
                设主机快照(自己)
            }
            起服务端()
        } else {
            服务?.停()
            服务 = nil
            起客户端口()
            let 自己 = 自己地址
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self else { return }
                let 谁 = 找人.找主机(自己: 自己)
                DispatchQueue.main.async {
                    if let 谁 {
                        self.主机地址 = 谁
                        self.存档.set(谁, forKey: "主机")
                        self.设主机快照(谁)
                    } else {
                        self.主机地址 = ""
                        self.设主机快照("")
                    }
                }
            }
        }
    }

    func 改主机(_ 新: String) {
        let v = 新.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !v.isEmpty else { return }
        主机地址 = v
        存档.set(v, forKey: "主机")
        设主机快照(v)
    }

    func 改名字(_ 新: String) {
        let v = String(新.trimmingCharacters(in: .whitespacesAndNewlines).prefix(12))
        guard !v.isEmpty else { return }
        我叫 = v
        存档.set(v, forKey: "名字")
        发名字()
    }

    func 刷耳机() {
        let 路 = 声音.共享.输出去处()
        if 路.名 == "外放" {
            耳机文 = "耳机：外放"
        } else if 路.是蓝牙 {
            耳机文 = "耳机：\(路.名)"
        } else {
            耳机文 = "耳机：\(路.名)"
        }
    }

    func 收拾() {
        计?.invalidate()
        报名计?.invalidate()
        看门狗?.invalidate()
        重连计?.invalidate()
        服务?.停()
        客户端口?.关掉()
        客户端口 = nil
        声.关()
    }
}

struct 点状态 {
    let id: Int
    var 在说: Bool
    var 是我: Bool
}
