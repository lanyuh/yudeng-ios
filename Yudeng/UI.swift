import UIKit

/// 屿灯的色。夜海 + 一盏灯。
enum 色 {
    static let 夜    = UIColor(rgb: 0x0B1118)
    static let 面    = UIColor(rgb: 0x121A24)
    static let 灰    = UIColor(rgb: 0x2A3540)
    static let 灯    = UIColor(rgb: 0xFFB45C)
    static let 灯暗  = UIColor(rgb: 0x8A5A28)
    static let 雾    = UIColor(rgb: 0x7FA8C9)
    static let 主字  = UIColor(rgb: 0xF2F5F7)
    static let 次字  = UIColor(rgb: 0x6E8090)
    static let 停    = UIColor(rgb: 0xC4453A)
    static let 起点  = UIColor(rgb: 0x3FB36B)
}

extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: 1
        )
    }
}

enum 皮 {
    /// 一页的底
    static func 页(_ v: UIView) {
        v.backgroundColor = 色.夜
    }

    static func 字(_ 号: CGFloat, _ 色: UIColor = 色.次字) -> UILabel {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 号)
        l.textColor = 色
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }

    static func 按钮(_ 字: String,
                  字色: UIColor = 色.主字,
                  底: UIColor = 色.面,
                  号: CGFloat = 12,
                  宽: CGFloat = 0,
                  高: CGFloat = 38) -> UIButton {
        let b = UIButton(type: .custom)
        b.setTitle(字, for: .normal)
        b.setTitleColor(字色, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 号)
        b.backgroundColor = 底
        b.layer.cornerRadius = 8
        if 宽 > 0 {
            b.translatesAutoresizingMaskIntoConstraints = false
            b.widthAnchor.constraint(equalToConstant: 宽).isActive = true
        }
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 高).isActive = true
        b.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return b
    }

    /// 一列竖着排
    static func 竖(_ 们: [UIView], 距: CGFloat = 0, 边: CGFloat = 0) -> UIStackView {
        let s = UIStackView(arrangedSubviews: 们)
        s.axis = .vertical
        s.spacing = 距
        s.alignment = .center
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }

    /// 一行横着排
    static func 横(_ 们: [UIView], 距: CGFloat = 10) -> UIStackView {
        let s = UIStackView(arrangedSubviews: 们)
        s.axis = .horizontal
        s.spacing = 距
        s.alignment = .center
        s.distribution = .equalSpacing
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }

    /// 一条空的竖缝
    static func 间距(_ 高: CGFloat) -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 高).isActive = true
        return v
    }
}

/// 一个点：没说话是灰的，说话亮起来，自己的那个描一圈
final class 点视图: UIView {
    var 在说 = false {
        didSet { 更新() }
    }
    var 是我 = false {
        didSet { 更新() }
    }

    private var 大小: CGFloat = 24

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        layer.cornerRadius = 大小 / 2
        更新()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func 更新() {
        大小 = 在说 ? 30 : 24
        layer.cornerRadius = 大小 / 2
        backgroundColor = 在说 ? 色.灯 : 色.灰
        layer.borderWidth = 是我 ? 2 : 0
        layer.borderColor = 色.灯.cgColor
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 大小, height: 大小)
    }
}

/// 折线：不用地图，把一串点画成一条线
final class 折线: UIView {
    var 点们: [点] = [] {
        didSet { setNeedsDisplay() }
    }
    var 线色: UIColor = 色.灯

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isOpaque = false
    }

    override func draw(_ rect: CGRect) {
        guard let 上 = UIGraphicsGetCurrentContext() else { return }
        let ps = 点们.filter { $0.lat != 0 && $0.lng != 0 }
        if ps.count < 2 { return }

        let pad: CGFloat = 22
        let w = max(1, bounds.width - pad * 2)
        let h = max(1, bounds.height - pad * 2)

        let minLat = ps.map { $0.lat }.min()!
        let maxLat = ps.map { $0.lat }.max()!
        let minLng = ps.map { $0.lng }.min()!
        let maxLng = ps.map { $0.lng }.max()!

        let 中纬 = (minLat + maxLat) / 2
        let kx = cos(中纬 * .pi / 180)
        let 跨经 = max(1e-9, (maxLng - minLng) * kx)
        let 跨纬 = max(1e-9, maxLat - minLat)
        let 比例 = min(w / 跨经, h / 跨纬)
        let 实际宽 = 跨经 * 比例
        let 实际高 = 跨纬 * 比例
        let 偏x = pad + (w - 实际宽) / 2
        let 偏y = pad + (h - 实际高) / 2

        func 映X(_ p: 点) -> CGFloat { CGFloat(偏x + ((p.lng - minLng) * kx * 比例)) }
        func 映Y(_ p: 点) -> CGFloat { CGFloat(偏y + ((maxLat - p.lat) * 比例)) }

        // 先画一层淡的，再画实的
        for 粗 in [true, false] {
            上.setStrokeColor(粗 ? 线色.withAlphaComponent(0.3).cgColor : 线色.cgColor)
            上.setLineWidth(粗 ? 4 : 1.6)
            上.setLineCap(.round)
            上.setLineJoin(.round)
            上.beginPath()
            上.move(to: CGPoint(x: 映X(ps[0]), y: 映Y(ps[0])))
            for i in 1..<ps.count {
                上.addLine(to: CGPoint(x: 映X(ps[i]), y: 映Y(ps[i])))
            }
            上.strokePath()
        }

        // 起点绿、终点红
        let 起点 = 映X(ps[0]), 起y = 映Y(ps[0])
        let 终x = 映X(ps[ps.count - 1]), 终y = 映Y(ps[ps.count - 1])
        上.setFillColor(色.起点.cgColor)
        上.fillEllipse(in: CGRect(x: 起点 - 3.5, y: 起y - 3.5, width: 7, height: 7))
        上.setFillColor(色.停.cgColor)
        上.fillEllipse(in: CGRect(x: 终x - 3.5, y: 终y - 3.5, width: 7, height: 7))
    }
}

/// 分享面板（导出记录用）
struct 分享 {
    static func 开(_ 项: [Any], 从 谁: UIViewController) {
        let 控 = UIActivityViewController(activityItems: 项, applicationActivities: nil)
        if let 弹 = 控.popoverPresentationController {
            弹.sourceView = 谁.view
            弹.sourceRect = CGRect(x: 谁.view.bounds.midX, y: 谁.view.bounds.maxY - 40, width: 1, height: 1)
        }
        谁.present(控, animated: true, completion: nil)
    }
}
