import Foundation
import UIKit
import Combine

@dynamicMemberLookup
class BalanceViewController: UIViewController {
    private let rootView = BalanceView()
    private let service: BalanceService
    private var state = BalanceViewState() {
        didSet {
            updateView()
        }
    }
    //private var notificationCenterTokens: [NSObjectProtocol] = []
    private let formatDate: (Date) -> String
    private var notificationCenter: NotificationCenter = .default
    
    
    private var butonCancellable: AnyCancellable?
    private var willResignActiveNotificationCancellable: AnyCancellable?
    private var didBecomeActiveNotificationCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    
    init(
        service: BalanceService,
        formatDate: @escaping (Date) -> String = BalanceViewState.relativeDateFormatter.string(from:)
    ) {
        self.service = service
        self.formatDate = formatDate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        rootView.refreshButton
            .touchUpInsidePublisher
            .sink{ [weak self ] _ in
            self?.refreshBalance()
        }
            .store(in: &cancellables)

        // isso foi refatorado abaixo para um publisher
        //        notificationCenterTokens.append(
        //            NotificationCenter.default.addObserver(
        //                forName: UIApplication.willResignActiveNotification,
        //                object: nil,
        //                queue: .main
        //            ) { [weak self ]_ in
        //                self?.state.isRedacted = true
        //            }
        //        )

        
        notificationCenter.publisher(for: UIApplication.willResignActiveNotification)
            //determino qual level irá receber a notification se tornando assincrono
            //.receive(on: DispatchQueue.main)
            .sink { [weak self ] _ in
                self?.state.isRedacted = true
            }
            .store(in: &cancellables)
        
        // isso foi refatorado abaixo para um publisher
//        notificationCenterTokens.append(
//            NotificationCenter.default.addObserver(
//                forName: UIApplication.didBecomeActiveNotification,
//                object: nil,
//                queue: .main
//            ) { [weak self ]_ in
//                self?.state.isRedacted = false
//            }
//        )
        
       notificationCenter.publisher(for: UIApplication.didBecomeActiveNotification)
        //determino qual level irá receber a notification se tornando assincrono
        //.receive(on: DispatchQueue.main)
            .sink{ [weak self] _ in
                self?.state.isRedacted = false
            }
            .store(in: &cancellables)

        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshBalance()
    }

    @objc private func refreshBalance() {
        state.didFail = false
        state.isRefreshing = true
        service.refreshBalance { [weak self] result in
            self?.handleResult(result)
        }
    }

    private func handleResult(_ result: Result<BalanceResponse, Error>) {
        state.isRefreshing = false
        do {
            state.lastResponse = try result.get()
        } catch {
            state.didFail = true
        }
    }

    private func updateView() {
        rootView.refreshButton.isHidden = state.isRefreshing
        if state.isRefreshing {
            rootView.activityIndicator.startAnimating()
        } else {
            rootView.activityIndicator.stopAnimating()
        }
        rootView.valueLabel.text = state.formattedBalance
        rootView.valueLabel.alpha = state.isRedacted
            ? BalanceView.alphaForRedactedValueLabel
            : 1
        rootView.infoLabel.text = state.infoText(formatDate: formatDate)
        rootView.infoLabel.textColor = state.infoColor
        rootView.redactedOverlay.isHidden = !state.isRedacted

        view.setNeedsLayout()
    }
}

#if DEBUG
import SwiftUI

struct BalanceViewController_Previews: PreviewProvider {
    static private func makePreview() -> some View {
        BalanceViewController(service: FakeBalanceService())
            .staticRepresentable
    }

    static var previews: some View {
        Group {
            makePreview()
                .preferredColorScheme(.dark)
            
            makePreview()
                .preferredColorScheme(.light)
        }
    }
}

// To help with tests
extension BalanceViewController {
    subscript<T>(dynamicMember keyPath: KeyPath<BalanceView, T>) -> T {
        rootView[keyPath: keyPath]
    }
}
#endif
