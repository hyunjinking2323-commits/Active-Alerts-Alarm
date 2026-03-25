 
    // SoundPickerViewController.swift
import UIKit
import Then
import SnapKit
import AVFoundation
import RxSwift
import RxCocoa

    // MARK: - [BaseViewController 상속]
    // Base에서 배경색(.black), disposeBag, 기본 생명주기를 관리함
final class SoundPickerViewController: BaseViewController {

        // MARK: - [데이터 및 상태 관리]
    private var selected: AlarmSound
    private let onDone: (AlarmSound) -> Void
    private var player: AVAudioPlayer? // 사운드 재생용 플레이어

        // MARK: - [초기화]
    init(selected: AlarmSound, onDone: @escaping (AlarmSound) -> Void) {
        self.selected = selected
        self.onDone   = onDone
        super.init() // BaseViewController의 init 호출
    }

    required init?(coder: NSCoder) { fatalError() }

        // MARK: - [UI 컴포넌트 선언]
    private lazy var tableView = UITableView(frame: .zero, style: .insetGrouped).then {
        $0.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        $0.dataSource      = self
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "sound")
    }

        // MARK: - [계층 구조 설정]
    override func setupHierarchy() {
        view.addSubview(tableView)
    }

        // MARK: - [레이아웃 설정]
    override func setupLayout() {
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

        // MARK: - [RxSwift 바인딩 및 UI 초기 설정]
    override func bind() {
        setupNavigationBar()

            // 테이블뷰 아이템 선택 시 사운드 재생 및 체크마크 갱신
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                self.tableView.deselectRow(at: indexPath, animated: true)

                    // 선택된 사운드 업데이트 및 재생
                self.selected = AlarmSound.allCases[indexPath.row]
                self.playSound(self.selected)

                    // 체크마크 업데이트를 위해 테이블뷰 리로드
                self.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }

        // MARK: - [네비게이션 설정]
    private func setupNavigationBar() {
        title = "사운드"
        let appearance = UINavigationBarAppearance().then {
            $0.configureWithOpaqueBackground()
            $0.backgroundColor     = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
            $0.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

        // MARK: - [화면 종료 처리]
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSound()      // 소리 정지
        onDone(selected) // 선택된 사운드 전달
    }

        // MARK: - [오디오 재생 로직]
    private func playSound(_ sound: AlarmSound) {
        stopSound()
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }

    private func stopSound() {
        player?.stop()
        player = nil
    }
}

    // MARK: - [UITableViewDataSource]
extension SoundPickerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AlarmSound.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sound = AlarmSound.allCases[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "sound", for: indexPath)

        cell.textLabel?.text      = sound.displayName
        cell.textLabel?.textColor = .white
        cell.backgroundColor      = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
        cell.tintColor            = UIColor(red: 1, green: 0.62, blue: 0.04, alpha: 1)

            // 현재 선택된 사운드와 같으면 체크마크 표시
        cell.accessoryType = (selected == sound) ? .checkmark : .none

        return cell
    }
}
