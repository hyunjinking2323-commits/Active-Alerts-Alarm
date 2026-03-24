// SoundPickerViewController.swift
import UIKit
import Then
import SnapKit
import AVFoundation

final class SoundPickerViewController: UIViewController {

    private var selected: AlarmSound
    private let onDone: (AlarmSound) -> Void
    private let audio = AlarmViewModel()

    init(selected: AlarmSound, onDone: @escaping (AlarmSound) -> Void) {
        self.selected = selected
        self.onDone   = onDone
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    private lazy var tableView = UITableView(frame: .zero, style: .insetGrouped).then {
        $0.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        $0.dataSource      = self
        $0.delegate        = self
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "sound")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "사운드"
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
        audio.stopSound()
        onDone(selected)
    }
}

extension SoundPickerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        AlarmSound.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sound = AlarmSound.allCases[indexPath.row]
        return tableView.dequeueReusableCell(withIdentifier: "sound", for: indexPath).then {
            $0.textLabel?.text  = sound.displayName
            $0.textLabel?.textColor = .white
            $0.backgroundColor  = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
            $0.accessoryType    = selected == sound ? .checkmark : .none
            $0.tintColor        = UIColor(red: 1, green: 0.62, blue: 0.04, alpha: 1)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selected = AlarmSound.allCases[indexPath.row]
        audio.playSound(selected)
        tableView.reloadData()
    }
}
