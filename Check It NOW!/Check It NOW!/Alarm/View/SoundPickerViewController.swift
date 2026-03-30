    //
    //  SoundPickerViewController.swift
    //  Check It NOW!
    //

import UIKit
import Then
import SnapKit
import AVFoundation
import RxSwift
import RxCocoa

final class SoundPickerViewController: UIViewController {

        // MARK: - Properties

    private let disposeBag = DisposeBag()
    private var selected: AlarmSound
    private let onDone: (AlarmSound) -> Void
    private var player: AVAudioPlayer?

        // MARK: - Init

    init(selected: AlarmSound, onDone: @escaping (AlarmSound) -> Void) {
        self.selected = selected
        self.onDone   = onDone
        super.init(nibName: nil, bundle: nil)
    }

    init(selectedSoundID: Int, onDone: @escaping (AlarmSound) -> Void) {
        self.selected = AlarmSound.from(soundID: selectedSoundID)
        self.onDone   = onDone
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

        // MARK: - UI

    private lazy var tableView = UITableView(frame: .zero, style: .insetGrouped).then {
        $0.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        $0.dataSource      = self
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "sound")
    }

        // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        title = "사운드"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        bind()
    }

        /// 화면 이탈 시 사운드 중지 + 선택 결과 콜백
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSound()
        onDone(selected)
    }

        // MARK: - Bind

    private func bind() {
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self else { return }
                tableView.deselectRow(at: indexPath, animated: true)
                selected = AlarmSound.allCases[indexPath.row]
                playSound(selected)
                tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }

        // MARK: - Audio

    private func playSound(_ sound: AlarmSound) {
        stopSound()
        if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.play()
        } else {
            AudioServicesPlaySystemSound(SystemSoundID(sound.systemSoundID))
        }
    }

    private func stopSound() {
        player?.stop()
        player = nil
    }
}

    // MARK: - UITableViewDataSource

extension SoundPickerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        AlarmSound.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sound = AlarmSound.allCases[indexPath.row]
        let cell  = tableView.dequeueReusableCell(withIdentifier: "sound", for: indexPath)
        cell.textLabel?.text      = sound.displayName
        cell.textLabel?.textColor = .white
        cell.backgroundColor      = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
        cell.tintColor            = UIColor(red: 1, green: 0.62, blue: 0.04, alpha: 1)
        cell.accessoryType        = (selected == sound) ? .checkmark : .none
        return cell
    }
}
