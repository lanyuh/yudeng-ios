import UIKit

/// 主界面。安卓 MainActivity 那一页，一样的东西。
final class 主控制器: UIViewController {

    private let 灯 = AppDelegate.灯

    private let 人数字 = 皮.字(34, 色.主字)
    private let 名单字 = 皮.字(12)
    private let 提示字 = 皮.字(11)
    private let 点数行 = UIStackView()
    private let 耳机字 = 皮.字(11)
    private let 名字字 = 皮.字(11)
    private let 服务坏字 = 皮.字(11, 色.停)

    private var 主钮 = UIButton()
    private var 客钮 = UIButton()
    private var 计: Timer?
    private var 上次点 = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        皮.页(view)
        搭界面()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        灯.开起来()
        灯.刷耳机()
        AppDelegate.车.要授权()
        刷一次()
        计?.invalidate()
        计 = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.刷一次()
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

        let 内容 = UIStackView()
        内容.axis = .vertical
        内容.alignment = .center
        内容.spacing = 0
        内容.translatesAutoresizingMaskIntoConstraints = false
        滚动.addSubview(内容)

        let 标 = 皮.字(15)
        标.text = "屿 灯"
        标.attributedText = NSAttributedString(string: "屿 灯", attributes: [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: 色.次字,
            .kern: 4
        ])

        let 版本 = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let 版字 = 皮.字(11, 色.次字.withAlphaComponent(0.7))
        版字.text = "v\(版本)"

        人数字.text = "没人"
        名单字.text = ""
        提示字.text = ""
        提示字.isUserInteractionEnabled = true
        提示字.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(点提示)))
        服务坏字.text = "发现服务没起来（40001 被占？换一台或重启试试）"
        服务坏字.isHidden = true

        点数行.axis = .horizontal
        点数行.spacing = 20
        点数行.alignment = .center
        点数行.distribution = .equalCentering
        点数行.translatesAutoresizingMaskIntoConstraints = false

        let 分工行 = UIStackView()
        分工行.axis = .horizontal
        分工行.spacing = 14
        分工行.translatesAutoresizingMaskIntoConstraints = false

        主钮 = 皮.按钮("主机", 字色: 色.夜, 底: 色.灯, 号: 12, 宽: 96, 高: 38)
        客钮 = 皮.按钮("客户端", 号: 12, 宽: 96, 高: 38)
        主钮.addTarget(self, action: #selector(按主机), for: .touchUpInside)
        客钮.addTarget(self, action: #selector(按客户端), for: .touchUpInside)
        分工行.addArrangedSubview(主钮)
        分工行.addArrangedSubview(客钮)

        let 小字行 = UIStackView()
        小字行.axis = .horizontal
        小字行.translatesAutoresizingMaskIntoConstraints = false
        小字行.distribution = .fillEqually
        耳机字.text = "耳机：看下面"
        名字字.text = "我叫：点这里改"
        耳机字.isUserInteractionEnabled = true
        名字字.isUserInteractionEnabled = true
        耳机字.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(点耳机)))
        名字字.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(点名字)))
        小字行.addArrangedSubview(耳机字)
        小字行.addArrangedSubview(名字字)

        let 骑行行 = UIStackView()
        骑行行.axis = .horizontal
        骑行行.spacing = 12
        骑行行.translatesAutoresizingMaskIntoConstraints = false
        let 骑钮 = 皮.按钮("骑行", 号: 12, 宽: 88, 高: 38)
        let 记钮 = 皮.按钮("记录", 号: 12, 宽: 88, 高: 38)
        骑钮.addTarget(self, action: #selector(按骑行), for: .touchUpInside)
        记钮.addTarget(self, action: #selector(按记录), for: .touchUpInside)
        骑行行.addArrangedSubview(骑钮)
        骑行行.addArrangedSubview(记钮)

        let 歌钮 = 皮.按钮("放歌", 字色: 色.次字.withAlphaComponent(0.5),
                        底: 色.面.withAlphaComponent(0.5), 号: 12, 宽: 88, 高: 38)
        歌钮.isEnabled = false
        let 歌说 = 皮.字(10, 色.次字.withAlphaComponent(0.8))
        歌说.text = "别人放歌你能听见；你自己放不了——iOS 不让 App 抓别的软件的声音"

        let 说明钮 = UIButton(type: .custom)
        说明钮.setTitle("跟安卓哪里不一样？", for: .normal)
        说明钮.setTitleColor(色.雾, for: .normal)
        说明钮.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        说明钮.addTarget(self, action: #selector(按说明), for: .touchUpInside)
        说明钮.translatesAutoresizingMaskIntoConstraints = false

        内容.addArrangedSubview(spacer(30))
        内容.addArrangedSubview(标)
        内容.addArrangedSubview(spacer(4))
        内容.addArrangedSubview(版字)
        内容.addArrangedSubview(spacer(22))
        内容.addArrangedSubview(人数字)
        内容.addArrangedSubview(spacer(4))
        内容.addArrangedSubview(名单字)
        内容.addArrangedSubview(spacer(4))
        内容.addArrangedSubview(提示字)
        内容.addArrangedSubview(spacer(6))
        内容.addArrangedSubview(服务坏字)
        内容.addArrangedSubview(spacer(24))
        内容.addArrangedSubview(点数行)
        内容.addArrangedSubview(spacer(30))
        内容.addArrangedSubview(分工行)
        内容.addArrangedSubview(spacer(14))
        内容.addArrangedSubview(小字行)
        内容.addArrangedSubview(spacer(18))
        内容.addArrangedSubview(骑行行)
        内容.addArrangedSubview(spacer(14))
        内容.addArrangedSubview(歌钮)
        内容.addArrangedSubview(spacer(4))
        内容.addArrangedSubview(歌说)
        内容.addArrangedSubview(spacer(10))
        内容.addArrangedSubview(说明钮)
        内容.addArrangedSubview(spacer(40))

        NSLayoutConstraint.activate([
            滚动.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            滚动.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            滚动.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            滚动.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            内容.topAnchor.constraint(equalTo: 滚动.topAnchor),
            内容.bottomAnchor.constraint(equalTo: 滚动.bottomAnchor),
            内容.leadingAnchor.constraint(equalTo: 滚动.leadingAnchor, constant: 24),
            内容.trailingAnchor.constraint(equalTo: 滚动.trailingAnchor, constant: -24),
            内容.widthAnchor.constraint(equalTo: 滚动.widthAnchor, constant: -48),

            点数行.widthAnchor.constraint(equalTo: 内容.widthAnchor),
            小字行.widthAnchor.constraint(equalTo: 内容.widthAnchor),
            歌说.widthAnchor.constraint(lessThanOrEqualTo: 内容.widthAnchor, constant: -20),
        ])
    }

    private func spacer(_ 高: CGFloat) -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 高).isActive = true
        return v
    }

    // MARK: - 刷

    private func 刷一次() {
        人数字.text = 灯.人数文
        名单字.text = 灯.名单文
        提示字.text = 灯.提示文
        耳机字.text = 灯.耳机文
        名字字.text = 灯.我叫.isEmpty ? "我叫：点这里改" : "我叫：\(灯.我叫)"
        服务坏字.isHidden = 灯.服务好

        // 按钮亮暗
        let 主 = (灯.分工 == .主机)
        主钮.backgroundColor = 主 ? 色.灯 : 色.面
        主钮.setTitleColor(主 ? 色.夜 : 色.主字, for: .normal)
        客钮.backgroundColor = 主 ? 色.面 : 色.灯
        客钮.setTitleColor(主 ? 色.主字 : 色.夜, for: .normal)

        // 点
        let 签名 = 点们.map { "\($0.id):\($0.在说):\($0.是我)" }.joined(separator: ",")
        if 签名 != 上次点 {
            上次点 = 签名
            点数行.arrangedSubviews.forEach { $0.removeFromSuperview() }
            if 点们.isEmpty {
                let 空 = 皮.字(11)
                空.text = "等有人进来，这里会亮"
                点数行.addArrangedSubview(空)
            } else {
                for 点 in 点们 {
                    let v = 点视图()
                    v.在说 = 点.在说
                    v.是我 = 点.是我
                    v.translatesAutoresizingMaskIntoConstraints = false
                    let 边 = 点.在说 ? 30.0 : 24.0
                    v.widthAnchor.constraint(equalToConstant: 边).isActive = true
                    v.heightAnchor.constraint(equalToConstant: 边).isActive = true
                    点数行.addArrangedSubview(v)
                }
            }
        }
    }

    // MARK: - 动作

    @objc private func 按主机() {
        灯.设分工(.主机)
        刷一次()
    }

    @objc private func 按客户端() {
        灯.设分工(.客户端)
        刷一次()
    }

    @objc private func 点耳机() {
        灯.刷耳机()
        刷一次()
    }

    @objc private func 点提示() {
        改地址()
    }

    private func 改地址() {
        let 框 = UIAlertController(title: "主机地址", message: "填当主机那台的地址", preferredStyle: .alert)
        框.addTextField { [weak self] t in
            t.text = self?.灯.主机地址
            t.placeholder = "比如 192.168.31.5"
            t.keyboardType = .numbersAndPunctuation
        }
        框.addAction(UIAlertAction(title: "用这个", style: .default) { [weak self, weak 框] _ in
            if let v = 框?.textFields?.first?.text {
                self?.灯.改主机(v)
                self?.刷一次()
            }
        })
        框.addAction(UIAlertAction(title: "找一下", style: .default) { [weak self] _ in
            self?.找主机()
        })
        框.addAction(UIAlertAction(title: "算了", style: .cancel, handler: nil))
        present(框, animated: true, completion: nil)
    }

    private func 找主机() {
        guard let 自己 = 本机地址.找() else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let 谁 = 找人.找主机(自己: 自己)
            DispatchQueue.main.async {
                guard let self, let 谁 else { return }
                self.灯.改主机(谁)
                self.刷一次()
            }
        }
    }

    @objc private func 点名字() {
        let 框 = UIAlertController(title: "你叫什么", message: "最多 12 个字", preferredStyle: .alert)
        框.addTextField { [weak self] t in
            t.text = self?.灯.我叫
            t.placeholder = "比如：阿禹"
        }
        框.addAction(UIAlertAction(title: "好", style: .default) { [weak self, weak 框] _ in
            if let v = 框?.textFields?.first?.text {
                self?.灯.改名字(v)
                self?.刷一次()
            }
        })
        框.addAction(UIAlertAction(title: "算了", style: .cancel, handler: nil))
        present(框, animated: true, completion: nil)
    }

    @objc private func 按骑行() {
        let 控 = 骑行控制器()
        let 包 = UINavigationController(rootViewController: 控)
        包.navigationBar.isHidden = true
        present(包, animated: true, completion: nil)
    }

    @objc private func 按记录() {
        let 控 = 记录控制器()
        let 包 = UINavigationController(rootViewController: 控)
        包.navigationBar.isHidden = true
        present(包, animated: true, completion: nil)
    }

    @objc private func 按说明() {
        present(说明控制器(), animated: true, completion: nil)
    }
}

/// 说明页：iOS 上哪几样跟安卓不一样，写在明面上。
final class 说明控制器: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        皮.页(view)

        let 滚动 = UIScrollView()
        滚动.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(滚动)

        let 竖 = UIStackView()
        竖.axis = .vertical
        竖.alignment = .leading
        竖.spacing = 14
        竖.translatesAutoresizingMaskIntoConstraints = false
        滚动.addSubview(竖)

        func 头(_ 文: String) -> UILabel {
            let l = 皮.字(15, 色.主字)
            l.textAlignment = .left
            l.text = 文
            return l
        }
        func 文(_ 文: String) -> UILabel {
            let l = 皮.字(13)
            l.textAlignment = .left
            l.text = 文
            return l
        }

        竖.addArrangedSubview(头("跟安卓版一样的地方"))
        竖.addArrangedSubview(文("对讲（同一个 Wi-Fi，不连外网）、谁在说话那一排点、在线人数和名单、昵称、主机/客户端、骑行记录、路线导航、偏了震一下、导出。"))
        竖.addArrangedSubview(头("iOS 上做不到的两样"))
        竖.addArrangedSubview(文("一、放歌。安卓能抓手机里别的 App 正在放的声音再发出去，iOS 系统不允许，没有公开接口。别人放歌，你能听见。\n二、蓝牙耳机电量。iOS 不给 App 读这个数，只显示连的是哪个耳机。"))
        竖.addArrangedSubview(头("锁屏"))
        竖.addArrangedSubview(文("只要对讲开着，锁屏也继续收。系统要是把它掐了，回到 App 会自己拉回来。"))

        let 关 = 皮.按钮("知道了", 字色: 色.夜, 底: 色.灯, 号: 13, 宽: 120, 高: 40)
        关.addTarget(self, action: #selector(按关), for: .touchUpInside)
        关.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(关)

        NSLayoutConstraint.activate([
            滚动.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            滚动.bottomAnchor.constraint(equalTo: 关.topAnchor, constant: -16),
            滚动.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            滚动.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            竖.topAnchor.constraint(equalTo: 滚动.topAnchor),
            竖.bottomAnchor.constraint(equalTo: 滚动.bottomAnchor),
            竖.leadingAnchor.constraint(equalTo: 滚动.leadingAnchor, constant: 22),
            竖.trailingAnchor.constraint(equalTo: 滚动.trailingAnchor, constant: -22),
            竖.widthAnchor.constraint(equalTo: 滚动.widthAnchor, constant: -44),

            关.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            关.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
    }

    @objc private func 按关() {
        dismiss(animated: true, completion: nil)
    }
}
