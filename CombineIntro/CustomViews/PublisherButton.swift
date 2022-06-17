import Combine
import UIKit
import CoreData

final class PublisherButton: UIButton {
    //Ele é Passthrough pq não armazena os eventos
    //<Void, Never> Void é o evento e Never é a falha ou never se nunca irá falhar
    private lazy var touchUpInsideSubject: PassthroughSubject<Void, Never> = {
        //Instancia o subject
        let subject = PassthroughSubject<Void, Never>()
        //o botão adiciona como target ele mesmo
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        return subject
    }()
    
    @objc private func handleTap(sender: UIButton, event: UIEvent) {
        //aqui você consegue enviar eventos para os subscribers
        //Quando acontece o tap vc manda eventos nesse publiser
        touchUpInsideSubject.send()
    }
    
    //vou me inscrever nesse cara e vou precisar de um subject
    var touchUpInsidePublisher: AnyPublisher<Void, Never> {
        
        touchUpInsideSubject.eraseToAnyPublisher()
    }
}
