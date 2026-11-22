import Foundation
import AVFoundation

/// 声音：录音 → 16k 单声道 PCM 20ms 一段；播放 → 单节点排队。
/// 页面上所有「按住说话」的底层就是这里。
final class 声音 {

    static let 共享 = 声音()

    private let 引擎 = AVAudioEngine()
    private var 播放器: AVAudioPlayerNode?
    private var 乐放: AVAudioPlayerNode?
    private var 垫: AVAudioPlayerNode?
    private var 转换器: AVAudioConverter?
    private(set) var 播格式: AVAudioFormat?
    private var 乐格式: AVAudioFormat?
    private var 余音: [UInt8] = []
    private let 锁 = NSLock()
    private(set) var 开着 = false

    /// 每凑够 640 字节（20ms）回调一次
    var 采到一段: (([UInt8]) -> Void)?

    private init() {}

    // MARK: - 起来 / 停下

    func 开() throws {
        let 会话 = AVAudioSession.sharedInstance()
        try 会话.setCategory(.playAndRecord,
                           mode: .voiceChat,
                           options: [.defaultToSpeaker, .allowBluetooth])
        try 会话.setActive(true)
        try? 会话.setPreferredSampleRate(48000)
        try? 会话.setPreferredIOBufferDuration(0.02)

        let 入口 = 引擎.inputNode
        if #available(iOS 13.0, *) {
            try? 入口.setVoiceProcessingEnabled(true)
        }

        let 入格式 = 入口.outputFormat(forBus: 0)
        guard 入格式.sampleRate > 0 else {
            throw NSError(domain: "yudeng", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "麦克风拿不到格式"])
        }
        guard let 出格式 = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                       sampleRate: 16000,
                                       channels: 1,
                                       interleaved: true) else {
            throw NSError(domain: "yudeng", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "16k 格式建不起来"])
        }
        guard let 转 = AVAudioConverter(from: 入格式, to: 出格式) else {
            throw NSError(domain: "yudeng", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "重采样器建不起来"])
        }
        转.sampleRateConverterQuality = .max
        转换器 = 转
        播格式 = 出格式

        let 放 = AVAudioPlayerNode()
        播放器 = 放
        引擎.attach(放)
        引擎.connect(放, to: 引擎.mainMixerNode, format: 出格式)
        放.play()

        // 放歌那一路：安卓发的是 48k 单声道，单独一个节点
        if let 乐式 = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                   sampleRate: 48000,
                                   channels: 1,
                                   interleaved: true) {
            乐格式 = 乐式
            let 乐 = AVAudioPlayerNode()
            乐放 = 乐
            引擎.attach(乐)
            引擎.connect(乐, to: 引擎.mainMixerNode, format: 乐式)
            乐.play()
        }

        入口.installTap(onBus: 0, bufferSize: 1024, format: 入格式) { [weak self] buf, _ in
            self?.转(buf)
        }

        引擎.prepare()
        try 引擎.start()
        开着 = true

        // 静音垫：iOS 只认「正在发声」的 App，锁屏后才不把它掐掉。
        // 放一段 100ms 的静音循环，不占耳朵，只占一条音频会话。
        起静音垫()
    }

    private func 起静音垫() {
        guard let 格式 = 播格式 else { return }
        let 垫 = AVAudioPlayerNode()
        self.垫 = 垫
        引擎.attach(垫)
        引擎.connect(垫, to: 引擎.mainMixerNode, format: 格式)
        let 帧 = AVAudioFrameCount(1600)   // 100ms @16k
        guard let buf = AVAudioPCMBuffer(pcmFormat: 格式, frameCapacity: 帧) else { return }
        buf.frameLength = 帧
        if let 道 = buf.int16ChannelData {
            for i in 0..<Int(帧) { 道[0][i] = 0 }
        }
        垫.scheduleBuffer(buf, at: nil, options: .loops, completionHandler: nil)
        垫.play()
    }

    func 关() {
        开着 = false
        引擎.inputNode.removeTap(onBus: 0)
        if let 放 = 播放器 {
            放.stop()
            引擎.detach(放)
        }
        播放器 = nil
        if let 乐 = 乐放 {
            乐.stop()
            引擎.detach(乐)
        }
        乐放 = nil
        if let 垫 = 垫 {
            垫.stop()
            引擎.detach(垫)
        }
        self.垫 = nil
        引擎.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    /// 来电/别的 App 抢了麦克风之后，看门狗用它拉回来
    func 重开() -> Bool {
        关()
        do {
            try 开()
            return true
        } catch {
            return false
        }
    }

    // MARK: - 录音

    private func 转(_ buf: AVAudioPCMBuffer) {
        guard let 转器 = 转换器, let 出格式 = 播格式 else { return }
        let 比 = 16000.0 / buf.format.sampleRate
        let 容 = AVAudioFrameCount(Double(buf.frameLength) * 比) + 64
        guard let 出 = AVAudioPCMBuffer(pcmFormat: 出格式, frameCapacity: 容) else { return }

        var 给过 = false
        var 错: NSError?
        let 状态 = 转器.convert(to: 出, error: &错) { _, 问 in
            if 给过 {
                问.pointee = .noDataNow
                return nil
            }
            给过 = true
            问.pointee = .haveData
            return buf
        }
        guard 状态 != .error, let 道 = 出.int16ChannelData else { return }

        let n = Int(出.frameLength)
        guard n > 0 else { return }
        var 段 = [UInt8](repeating: 0, count: n * 2)
        let src = 道[0]
        for i in 0..<n {
            let v = src[i]
            段[i * 2] = UInt8(UInt16(bitPattern: v) & 0xFF)
            段[i * 2 + 1] = UInt8((UInt16(bitPattern: v) >> 8) & 0xFF)
        }

        锁.lock()
        余音.append(contentsOf: 段)
        var 要发: [[UInt8]] = []
        while 余音.count >= 线.包字节 {
            let 一 = Array(余音[0..<线.包字节])
            余音.removeFirst(线.包字节)
            要发.append(一)
        }
        锁.unlock()

        for 一 in 要发 {
            采到一段?(一)
        }
    }

    // MARK: - 播放

    func 放(_ 音: [UInt8]) {
        guard let 放器 = 播放器, let 格式 = 播格式 else { return }
        播(音, 放器: 放器, 格式: 格式)
    }

    /// 主机放的歌：48k 单声道，一包 10ms
    func 放音乐(_ 音: [UInt8]) {
        guard let 放器 = 乐放, let 格式 = 乐格式 else { return }
        播(音, 放器: 放器, 格式: 格式)
    }

    private func 播(_ 音: [UInt8], 放器: AVAudioPlayerNode, 格式: AVAudioFormat) {
        let 采样 = 音.count / 2
        guard 采样 > 0 else { return }
        guard let buf = AVAudioPCMBuffer(pcmFormat: 格式,
                                         frameCapacity: AVAudioFrameCount(采样)) else { return }
        buf.frameLength = AVAudioFrameCount(采样)
        guard let 道 = buf.int16ChannelData else { return }
        let dst = 道[0]
        for i in 0..<采样 {
            let lo = UInt16(音[i * 2])
            let hi = UInt16(音[i * 2 + 1]) << 8
            dst[i] = Int16(bitPattern: lo | hi)
        }
        if !放器.isPlaying { 放器.play() }
        放器.scheduleBuffer(buf, completionHandler: nil)
    }

    /// 当前输出走在哪（外放/耳机/蓝牙），界面上那行小字用
    func 输出去处() -> (名: String, 是蓝牙: Bool) {        let 路 = AVAudioSession.sharedInstance().currentRoute
        guard let 口 = 路.outputs.first else { return ("没连", false) }
        switch 口.portType {
        case .bluetoothA2DP, .bluetoothLE, .bluetoothHFP:
            return (口.portName, true)
        case .headphones, .headsetMic:
            return (口.portName, false)
        case .builtInSpeaker:
            return ("外放", false)
        case .builtInReceiver:
            return ("听筒", false)
        default:
            return (口.portName, false)
        }
    }
}
