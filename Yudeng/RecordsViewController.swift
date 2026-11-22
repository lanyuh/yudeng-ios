import UIKit

/// 记录页：这一趟趟都在这儿。
final class 记录控制器: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var 文件们: [URL] = []
    private let 表 = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()
        皮.页(view)

        let 顶 = UIStackView()
        顶.axis = .horizontal
        顶.translatesAutoresizingMaskIntoConstraints = false
        let 回 = 皮.按钮("回来", 号: 12, 宽: 66, 高: 32)
        回.addTarget(self, action: #selector(按回), for: .touchUpInside)
        let 题 = 皮.字(13)
        题.text = "记录"
        let 刷 = 皮.按钮("刷新", 号: 12, 宽: 66, 高: 32)
        刷.addTarget(self, action: #selector(重读), for: .touchUpInside)
        顶.addArrangedSubview(回)
        顶.addArrangedSubview(题)
        顶.addArrangedSubview(刷)

        表.backgroundColor = .clear
        表.separatorStyle = .none
        表.dataSource = self
        表.delegate = self
        表.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(顶)
        view.addSubview(表)

        NSLayoutConstraint.activate([
            顶.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            顶.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            顶.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),

            表.topAnchor.constraint(equalTo: 顶.bottomAnchor, constant: 10),
            表.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            表.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            表.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        重读()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    @objc private func 按回() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func 重读() {
        文件们 = 一趟.所有轨迹()
        表.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        文件们.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        62
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        表.deselectRow(at: indexPath, animated: true)
        guard let t = 一趟.读(文件们[indexPath.row]) else { return }
        present(详情控制器(t: t), animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let 号 = "行"
        let cell = tableView.dequeueReusableCell(withIdentifier: 号)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: 号)
        cell.backgroundColor = 色.面
        cell.textLabel?.textColor = 色.主字
        cell.textLabel?.font = UIFont.systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = 色.次字
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 11)
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator
        cell.accessoryView = nil

        let f = 文件们[indexPath.row]
        if let t = 一趟.读(f) {
            cell.textLabel?.text = 日期(t.start)
            let 断 = t.broken ? " · 中途断过" : ""
            cell.detailTextLabel?.text = String(format: "%.2f 公里 · %@ · 均速 %.1f%@",
                                                 t.距离公里(), t.时长文本(), t.均速Kmh(), 断)
        } else {
            cell.textLabel?.text = f.lastPathComponent
            cell.detailTextLabel?.text = "读不出来"
        }
        return cell
    }

    private func 日期(_ ms: Int64) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM-dd HH:mm"
        return f.string(from: Date(timeIntervalSince1970: Double(ms) / 1000))
    }
}

/// 一趟的详情
final class 详情控制器: UIViewController {

    private let t: 一趟
    private let 提示字 = 皮.字(11, 色.雾)

    init(t: 一趟) {
        self.t = t
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("没有 xib")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        皮.页(view)
        搭界面()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func 搭界面() {
        let 滚动 = UIScrollView()
        滚动.showsVerticalScrollIndicator = false
        滚动.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(滚动)

        let 竖 = UIStackView()
        竖.axis = .vertical
        竖.alignment = .center
        竖.spacing = 12
        竖.translatesAutoresizingMaskIntoConstraints = false
        滚动.addSubview(竖)

        let 顶 = UIStackView()
        顶.axis = .horizontal
        顶.translatesAutoresizingMaskIntoConstraints = false
        let 回 = 皮.按钮("回来", 号: 12, 宽: 66, 高: 32)
        回.addTarget(self, action: #selector(按回), for: .touchUpInside)
        let 题 = 皮.字(12)
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        题.text = f.string(from: Date(timeIntervalSince1970: Double(t.start) / 1000))
        let 空 = UIView()
        空.widthAnchor.constraint(equalToConstant: 66).isActive = true
        顶.addArrangedSubview(回)
        顶.addArrangedSubview(题)
        顶.addArrangedSubview(空)

        let 数行 = UIStackView()
        数行.axis = .horizontal
        数行.distribution = .fillEqually
        数行.translatesAutoresizingMaskIntoConstraints = false
        数行.addArrangedSubview(数块(String(format: "%.2f", t.距离公里()), "公里"))
        数行.addArrangedSubview(数块(t.时长文本(), "时长"))
        数行.addArrangedSubview(数块(String(format: "%.1f", t.均速Kmh()), "均速"))
        数行.addArrangedSubview(数块(String(format: "%.1f", t.最高Kmh()), "最高"))

        let 图 = 折线()
        图.点们 = t.points
        图.backgroundColor = 色.面
        图.layer.cornerRadius = 8
        图.layer.masksToBounds = true
        图.translatesAutoresizingMaskIntoConstraints = false
        图.heightAnchor.constraint(equalToConstant: 230).isActive = true

        if t.broken {
            let 断字 = 皮.字(11, 色.停.withAlphaComponent(0.9))
            断字.text = "这一趟中途断过（被杀 / 关机），点可能缺一段。"
            竖.addArrangedSubview(断字)
        }

        let 钮行 = UIStackView()
        钮行.axis = .horizontal
        钮行.spacing = 12
        钮行.translatesAutoresizingMaskIntoConstraints = false
        let 存钮 = 皮.按钮("存成路线", 字色: 色.夜, 底: 色.灯, 号: 12, 宽: 96, 高: 36)
        let 导钮 = 皮.按钮("导出去", 号: 12, 宽: 96, 高: 36)
        存钮.addTarget(self, action: #selector(按存路线), for: .touchUpInside)
        导钮.addTarget(self, action: #selector(按导出), for: .touchUpInside)
        钮行.addArrangedSubview(存钮)
        钮行.addArrangedSubview(导钮)

        竖.addArrangedSubview(顶)
        竖.addArrangedSubview(数行)
        竖.addArrangedSubview(图)
        竖.addArrangedSubview(钮行)
        竖.addArrangedSubview(提示字)

        let 脚 = 皮.字(10, 色.次字.withAlphaComponent(0.8))
        脚.text = "\(t.points.count) 个点，精度差于 30 米的点不算距离。"
        竖.addArrangedSubview(脚)

        NSLayoutConstraint.activate([
            滚动.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
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
            图.widthAnchor.constraint(equalTo: 竖.widthAnchor),
        ])
    }

    private func 数块(_ 值: String, _ 名: String) -> UIView {
        let 值字 = 皮.字(17, 色.主字)
        值字.text = 值
        let 名字 = 皮.字(10)
        名字.text = 名
        let 竖 = UIStackView(arrangedSubviews: [值字, 名字])
        竖.axis = .vertical
        竖.spacing = 3
        竖.alignment = .center
        return 竖
    }

    @objc private func 按回() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func 按存路线() {
        let f = DateFormatter()
        f.dateFormat = "MMdd_HHmm"
        let 名 = "\(f.string(from: Date(timeIntervalSince1970: Double(t.start) / 1000))) 的路"
        let r = 路线.从一趟(t, 名字: 名, 谁: UserDefaults.standard.string(forKey: "名字") ?? "")
        let 文件 = 路线.目录.appendingPathComponent("\(名.replacingOccurrences(of: " ", with: "_")).json")
        r.存(文件)
        提示字.text = "存好了，在骑行页「选一条路线」里"
    }

    @objc private func 按导出() {
        var 文本 = "屿灯骑行记录\n"
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        文本 += "开始：\(f.string(from: Date(timeIntervalSince1970: Double(t.start) / 1000)))\n"
        文本 += "距离：\(String(format: "%.2f", t.距离公里())) 公里\n"
        文本 += "时长：\(t.时长文本())\n均速：\(String(format: "%.1f", t.均速Kmh())) km/h\n"
        文本 += "最高：\(String(format: "%.1f", t.最高Kmh())) km/h\n"
        文本 += "点数：\(t.points.count)\n\n"
        for p in t.points {
            文本 += String(format: "%.6f,%.6f\n", p.lat, p.lng)
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("屿灯记录.txt")
        try? 文本.data(using: .utf8)?.write(to: url)
        分享.开([url], 从: self)
    }
}
