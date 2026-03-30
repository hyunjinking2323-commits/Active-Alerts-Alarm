//
//  RepeatIntvalViewController.swift
//  Check It NOW!
//
//  Created by t2025-m0239 on 2026.03.29.
//

import UIKit
import SnapKit
import Then
import RxSwift

    // MARK: - Delegate

protocol RepeatIntervalViewControllerDelegate: AnyObject {
    func didSelectInterval(_ minutes: Int)
}

    // MARK: - RepeatIntervalViewController

final class RepeatIntervalViewController: UIViewController {

        // MARK: - Properties

    private let disposeBag = DisposeBag()
    private let currentInterval: Int
    weak var delegate: RepeatIntervalViewControllerDelegate?

        /// 1~30분 선택 목록
    private let intervals: [Int] = Array(1...30)

        // MARK: - UI

    private let tableView = UITableView(frame: .zero, style: .insetGrouped).then {
        $0.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        $0.separatorColor  = UIColor(white: 0.25, alpha: 1)
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "IntervalCell")
    }

        // MARK: - Init

    init(currentInterval: Int = 5) {
        self.currentInterval = currentInterval
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

        // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        title = "반복 시간"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        tableView.delegate   = self
        tableView.dataSource = self
    }
}

    // MARK: - UITableViewDataSource

extension RepeatIntervalViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        intervals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell    = tableView.dequeueReusableCell(withIdentifier: "IntervalCell", for: indexPath)
        let minutes = intervals[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = "\(minutes)분"
        config.textProperties.color = .white
        cell.contentConfiguration = config

        cell.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
        cell.tintColor       = .systemOrange
        cell.accessoryType   = (minutes == currentInterval) ? .checkmark : .none

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "알람이 울린 후 반복 간격을 선택하세요"
    }
}

    // MARK: - UITableViewDelegate

extension RepeatIntervalViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.didSelectInterval(intervals[indexPath.row])
        navigationController?.popViewController(animated: true)
    }
}
