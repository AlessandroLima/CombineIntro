import Foundation
import UIKit
import Combine
final class BalanceViewModel {
    
    private(set) var state = BalanceViewState()
    private let service: BalanceService
    private var notificationCenter: NotificationCenter = .default
    private var cancellables = Set<AnyCancellable>()
    
    init(service: BalanceService){
        self.service = service
        
        notificationCenter.publisher(for: UIApplication.willResignActiveNotification)
              .sink { [weak self ] _ in
                self?.state.isRedacted = true
            }
            .store(in: &cancellables)
        
        notificationCenter.publisher(for: UIApplication.didBecomeActiveNotification)
             .sink{ [weak self] _ in
                 self?.state.isRedacted = false
             }
             .store(in: &cancellables)
        
        
    }
    
    func refreshBalance() {
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

}