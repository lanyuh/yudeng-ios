import UIKit

/// 骑行页。速度、距离、时间、均速，开始/暂停/继续/结束，这一趟的折线，跟路线。
final class 骑行控制器: UIViewController {

    private let 车 = AppDelegate.车

    private let 速字 = UILabel()
    private let 单位字 = UILabel()
    private let 公里字 = 皮.字(19, 色.主字)
    private let 时长字 = 皮.字(19, 色.主字)
    private let 均速字 = 皮.字(19, 色.主字)
    private let 路由字 = 皮.字(12, 色.主字)
    private let 剩字 = 皮.字(13, 色.主字)
    private let 偏字 = 皮.字(13, 色.雾)
    private let 提示字 = 皮.字(11)
    private let 最高字 = 皮.字(10, 色.次字.withAlphaComponent(0.8))
    private let 折 = 折线()
    private let 路线块 = UIView()
    private let 选路钮 = 皮.按钮("选一条路线跟着走", 号: 12, 宽: 180, 高: 36)

    private var 开始钮 = UIButton()
    private var 副钮 = UIButton()
    private var 计: Timer?

    private var 选的路: 路线?
    private var 偏米 = 0.0
    private var 已走 = 0.0
    private var 上一震 = Date.distantPast
    private let 震动 = UINotificationFeedbackGenerator()

    override func viewDidLoad() {
        super.viewDidLoad()
        皮.页(view)
        搭界面()
        震动.prepare()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        刷一次()
        计?.invalidate()
        计 = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.刷一次()
            self?.跟路线()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        计?.invalidate()
        计 = nil
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - 搭

    private func 搭界面() {
        let 滚动 = UIScrollView()
        滚动.showsVerticalScrollIndicator = false
        滚动.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(滚动)

        let 竖 = UIStackView()
        竖.axis = .vertical
        竖.alignment = .center
        竖.spacing = 0
        竖.translatesAutoresizingMaskIntoConstraints = false
        滚动.addSubview(竖)

        let 顶 = UIStackView()
        顶.axis = .horizontal
        顶.translatesAutoresizingMaskIntoConstraints = false
        let 回 = 皮.按钮("回来", 号: 12, 宽: 66, 高: 32)
        回.addTarget(self, action: #selector(按回), for: .touchUpInside)
        let 题 = 皮.字(13)
        题.text = "骑行"
        let 空 = UIView()
        空.widthAnchor.constraint(equalToConstant: 66).isActive = true
        顶.addArrangedSubview(回)
        顶.addArrangedSubview(题)
        顶.addArrangedSubview(空)

        速字.font = UIFont.systemFont(ofSize: 62, weight: .light)
        速字.textColor = 色.灯
        速字.text = "0.0"
        速字.textAlignment = .right
        单位字.font = UIFont.systemFont(ofSize: 12)
        单位字.textColor = 色.雾
        单位字.text = "km/h"

        let 速行 = UIStackView(arrangedSubviews: [速字, 单位字])
        速行.axis = .horizontal
        速行.alignment = .lastBaseline
        速行.spacing = 6
        速行.translatesAutoresizingMaskIntoConstraints = false

        let 数行 = UIStackView()
        数行.axis = .horizontal
        数行.distribution = .fillEqually
        数行.translatesAutoresizingMaskIntoConstraints = false
        数行.addArrangedSubview(数块(公里字, "公里"))
        数行.addArrangedSubview(数块(时长字, "时长"))
        数行.addArrangedSubview(数块(均速字, "均速"))

        路线块.translatesAutoresizingMaskIntoConstraints = false
        路线块.backgroundColor = 色.面
        路线块.layer.cornerRadius = 8
        路线块.layer.masksToBounds = true
        let 路竖 = UIStackView()
        路竖.axis = .vertical
        路竖.spacing = 6
        路竖.translatesAutoresizingMaskIntoConstraints = false
        路线块.addSubview(路竖)
        剩字.textAlignment = .left
        偏字.textAlignment = .right
        let 路行 = UIStackView(arrangedSubviews: [剩字, 偏字])
        路行.axis = .horizontal
        路行.distribution = .fillEqually
        路行.translatesAutoresizingMaskIntoConstraints = false
        路由字.textAlignment = .left
        路竖.addArrangedSubview(路由字)
        路竖.addArrangedSubview(路行)
        NSLayoutConstraint.activate([
            路竖.topAnchor.constraint(equalTo: 路线块.topAnchor, constant: 12),
            路竖.bottomAnchor.constraint(equalTo: 路线块.bottomAnchor, constant: -12),
            路竖.leadingAnchor.constraint(equalTo: 路线块.leadingAnchor, constant: 14),
            路竖.trailingAnchor.constraint(equalTo: 路线块.trailingAnchor, constant: -14),
        ])
        路线块.isHidden = true

        选路钮.addTarget(self, action: #selector(按选路), for: .touchUpInside)

        折.translatesAutoresizingMaskIntoConstraints = false
        折.heightAnchor.constraint(equalToConstant: 170).isActive = true

        let 控制行 = UIStackView()
        控制行.axis = .horizontal
        控制行.spacing = 12
        控制行.translatesAutoresizingMaskIntoConstraints = false
        开始钮 = 皮.按钮("开始", 字色: 色.夜, 底: 色.灯, 号: 15, 宽: 110, 高: 46)
        副钮 = 皮.按钮("结束", 号: 15, 宽: 110, 高: 46)
        开始钮.addTarget(self, action: #selector(按开始), for: .touchUpInside)
        副钮.addTarget(self, action: #selector(按副), for: .touchUpInside)
        控制行.addArrangedSubview(开始钮)
        控制行.addArrangedSubview(副钮)

        最高字.text = ""

        竖.addArrangedSubview(sp(14))
        竖.addArrangedSubview(顶)
        竖.addArrangedSubview(sp(20))
        竖.addArrangedSubview(速行)
        竖.addArrangedSubview(sp(18))
        竖.addArrangedSubview(数行)
        竖.addArrangedSubview(sp(18))
        竖.addArrangedSubview(路线块)
        竖.addArrangedSubview(选路钮)
        竖.addArrangedSubview(sp(14))
        竖.addArrangedSubview(折)
        竖.addArrangedSubview(sp(20))
        竖.addArrangedSubview(控制行)
        竖.addArrangedSubview(sp(10))
        竖.addArrangedSubview(提示字)
        竖.addArrangedSubview(sp(8))
        竖.addArrangedSubview(最高字)
        竖.addArrangedSubview(sp(30))

        NSLayoutConstraint.activate([
            滚动.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            滚动.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            滚动.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            滚动.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            竖.topAnchor.constraint(equalTo: 滚动.contentLayoutGuide.topAnchor),
            竖.bottomAnchor.constraint(equalTo: 滚动.contentLayoutGuide.bottomAnchor),
            竖.leadingAnchor.constraint(equalTo: 滚动.contentLayoutGuide.leadingAnchor, constant: 22),
            竖.trailingAnchor.constraint(equalTo: 滚动.contentLayoutGuide.trailingAnchor, constant: -22),
            竖.widthAnchor.constraint(equalTo: 滚动.frameLayoutGuide.widthAnchor, constant: -44),

            顶.widthAnchor.constraint(equalTo: 竖.widthAnchor),
            数行.widthAnchor.constraint(equalTo: 竖.widthAnchor),
            路线块.widthAnchor.constraint(equalTo: 竖.widthAnchor),
            折.widthAnchor.constraint(equalTo: 竖.widthAnchor),
        ])
    }

    private func sp(_ 高: CGFloat) -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 高).isActive = true
        return v
    }

    private func 数块(_ 值: UILabel, _ 名: String) -> UIView {
        值.text = "0"
        值.textAlignment = .center
        let 标签 = 皮.字(10)
        标签.text = 名
        let 竖 = UIStackView(arrangedSubviews: [值, 标签])
        竖.axis = .vertical
        竖.spacing = 4
        竖.alignment = .center
        return 竖
    }

    // MARK: - 刷

    private func 刷一次() {
        速字.text = String(format: "%.1f", 车.速度Kmh)
        let t = 车.当前
        公里字.text = String(format: "%.2f", t?.距离公里() ?? 0)
        时长字.text = t?.时长文本() ?? "00:00"
        均速字.text = String(format: "%.1f", t?.均速Kmh() ?? 0)
        折.点们 = t?.points ?? []

        if let t, t.points.count > 0 {
            最高字.text = "最高 \(String(format: "%.1f", t.最高Kmh())) km/h · \(t.points.count) 个点"
        } else {
            最高字.text = ""
        }

        let 在记 = (t?.recording == true)
        if !在记 {
            开始钮.setTitle("开始", for: .normal)
            开始钮.backgroundColor = 色.灯
            开始钮.setTitleColor(色.夜, for: .normal)
            副钮.isHidden = true
        } else if 车.暂停中 {
            开始钮.setTitle("继续", for: .normal)
            开始钮.backgroundColor = 色.灯
            开始钮.setTitleColor(色.夜, for: .normal)
            副钮.isHidden = false
            副钮.setTitle("结束", for: .normal)
        } else {
            开始钮.setTitle("暂停", for: .normal)
            开始钮.backgroundColor = 色.面
            开始钮.setTitleColor(色.主字, for: .normal)
            副钮.isHidden = false
            副钮.setTitle("结束", for: .normal)
        }
    }

    private func 跟路线() {
        guard let r = 选的路, let t = 车.当前, let p = t.points.last else { return }
        let 结 = r.算(p.lat, p.lng)
        偏米 = 结.偏
        已走 = 结.走
        路由字.text = r.名字.isEmpty ? "这条路线" : r.名字
        剩字.text = String(format: "还剩 %.1f 公里", max(0, r.总长() - 已走) / 1000)
        偏字.text = 偏米 > 60 ? "偏了 \(Int(偏米)) 米" : "在路上"
        偏字.textColor = 偏米 > 60 ? 色.停 : 色.雾
        if 偏米 > 60, Date().timeIntervalSince(上一震) > 20 {
            上一震 = Date()
            震动.notificationOccurred(.warning)
            提示字.text = "偏了 \(Int(偏米)) 米"
        } else if 偏米 <= 60 {
            提示字.text = ""
        }
    }

    // MARK: - 动作

    @objc private func 按回() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func 按开始() {
        let 在记 = (车.当前?.recording == true)
        if !在记 {
            车.开始()
        } else if 车.暂停中 {
            车.继续()
        } else {
            车.暂停()
        }
        刷一次()
    }

    @objc private func 按副() {
        车.停止()
        刷一次()
    }

    @objc private func 按选路() {
        let 们 = 路线.所有().compactMap { 路线.读($0) }
        if 们.isEmpty {
            let 框 = UIAlertController(title: "还没有路线",
                                     message: "骑完一趟，去记录里点「存成路线」。",
                                     preferredStyle: .alert)
            框.addAction(UIAlertAction(title: "知道了", style: .default, handler: nil))
            present(框, animated: true, completion: nil)
            return
        }
        let 框 = UIAlertController(title: "跟着哪条路", message: nil, preferredStyle: .actionSheet)
        for r in 们 {
            let 名 = (r.名字.isEmpty ? "没名字的路线" : r.名字) + String(format: " · %.1f 公里", r.总长() / 1000)
            框.addAction(UIAlertAction(title: 名, style: .default) { [weak self] _ in
                self?.选的路 = r
                self?.偏米 = 0
                self?.已走 = 0
                self?.路线块.isHidden = false
                self?.选路钮.isHidden = true
            })
        }
        框.addAction(UIAlertAction(title: "不跟了", style: .destructive) { [weak self] _ in
            self?.选的路 = nil
            self?.路线块.isHidden = true
            self?.选路钮.isHidden = false
        })
        框.addAction(UIAlertAction(title: "算了", style: .cancel, handler: nil))
        if let 弹 = 框.popoverPresentationController {
            弹.sourceView = 选路钮
            弹.sourceRect = 选路钮.bounds
        }
        present(框, animated: true, completion: nil)
    }
}
