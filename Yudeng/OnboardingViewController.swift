import UIKit
import AVFoundation

/// 第一次进来那一页。
final class 引导控制器: UIViewController {

    var 看完: (() -> Void)?

    private let 麦克风字 = 皮.字(10)
    private var 好了 = false

    override func viewDidLoad() {
        super.viewDidLoad()
        皮.页(view)
        搭界面()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func 搭界面() {
        let 竖 = UIStackView()
        竖.axis = .vertical
        竖.alignment = .center
        竖.spacing = 0
        竖.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(竖)

        let 标 = UILabel()
        标.attributedText = NSAttributedString(string: "屿 灯", attributes: [
            .font: UIFont.systemFont(ofSize: 30, weight: .light),
            .foregroundColor: 色.主字,
            .kern: 10
        ])

        let 副 = 皮.字(12)
        副.text = "队里的对讲，同一个 Wi-Fi 就能喊"

        func 条(_ 号: String, _ 文: String) -> UIView {
            let 号字 = UILabel()
            号字.text = 号
            号字.font = UIFont.systemFont(ofSize: 11)
            号字.textColor = 色.灯
            号字.translatesAutoresizingMaskIntoConstraints = false
            号字.widthAnchor.constraint(equalToConstant: 16).isActive = true

            let 文字 = UILabel()
            文字.text = 文
            文字.font = UIFont.systemFont(ofSize: 12)
            文字.textColor = 色.次字
            文字.numberOfLines = 0
            文字.translatesAutoresizingMaskIntoConstraints = false

            let 行 = UIStackView(arrangedSubviews: [号字, 文字])
            行.axis = .horizontal
            行.alignment = .top
            行.spacing = 10
            行.translatesAutoresizingMaskIntoConstraints = false
            return 行
        }

        let 条们 = UIStackView()
        条们.axis = .vertical
        条们.spacing = 12
        条们.alignment = .leading
        条们.translatesAutoresizingMaskIntoConstraints = false
        条们.addArrangedSubview(条("一", "不用账号、不用服务器。一台当主机，别人填它的地址。"))
        条们.addArrangedSubview(条("二", "按住说话。谁在说，那一排圆点会亮。"))
        条们.addArrangedSubview(条("三", "骑行能记路线，偏了会震一下。"))
        条们.addArrangedSubview(条("四", "声音只在你们自己的网里走，不出门。"))

        let 开 = 皮.按钮("给两个权限", 字色: 色.夜, 底: 色.灯, 号: 15, 宽: 220, 高: 48)
        开.addTarget(self, action: #selector(按开), for: .touchUpInside)
        麦克风字.text = "麦克风：还没给"

        竖.addArrangedSubview(标)
        竖.addArrangedSubview(皮.间距(14))
        竖.addArrangedSubview(副)
        竖.addArrangedSubview(皮.间距(34))
        竖.addArrangedSubview(条们)
        竖.addArrangedSubview(皮.间距(30))
        竖.addArrangedSubview(开)
        竖.addArrangedSubview(皮.间距(10))
        竖.addArrangedSubview(麦克风字)

        NSLayoutConstraint.activate([
            竖.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            竖.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 34),
            竖.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -34),
            条们.widthAnchor.constraint(equalTo: 竖.widthAnchor, constant: -34),
        ])
    }

    @objc private func 按开() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] ok in
            DispatchQueue.main.async {
                guard let self else { return }
                self.好了 = ok
                self.麦克风字.text = ok ? "麦克风：好了" : "麦克风：没给"
                if ok {
                    self.看完?()
                }
            }
        }
    }
}
