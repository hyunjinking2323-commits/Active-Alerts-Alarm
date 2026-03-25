    // RepeatDayViewController.swift
import UIKit
import RxSwift
import RxCocoa
import Then
import SnapKit

final class RepeatDayViewController: UIViewController {

    private let dayNames = ["일요일","월요일","화요일","수요일","목요일","금요일","토요일"]
    private var selected: [Int]
    private let onDone: ([Int]) -> Void

    init(selected: [Int], onDone: @escaping ([Int]) -> Void) {
        self.selected = selected
        self.onDone   = onDone
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    private lazy var tableView = UITableView(frame: .zero, style: .insetGrouped).then {
        $0.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        $0.dataSource      = self
        $0.delegate        = self
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "day")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "반복"
        view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)

        let appearance = UINavigationBarAppearance().then {
            $0.configureWithOpaqueBackground()
            $0.backgroundColor     = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
            $0.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDone(selected)
    }
}

extension RepeatDayViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 7 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: "day", for: indexPath).then {
            $0.textLabel?.text  = dayNames[indexPath.row]
            $0.textLabel?.textColor = .white
            $0.backgroundColor  = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
            $0.accessoryType    = selected.contains(indexPath.row) ? .checkmark : .none
            $0.tintColor        = UIColor(red: 1, green: 0.62, blue: 0.04, alpha: 1)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let day = indexPath.row
        if let idx = selected.firstIndex(of: day) { selected.remove(at: idx) }
        else { selected.append(day) }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
