import ComposableArchitecture
import UIKit

@Reducer
struct BugSample {

    @Reducer
    struct Destination {

        // Try the following two cases
        // 1. Do not annotate this state with `@ObservableState`
        //    -> launch the app > Bug sample > Navigate > Hit noop
        //    -> The following is printed (even though nothing in the state has been changed):
        //       Noop button tapped
        //       observe triggered
        //
        // 2. Annotate this state with `@ObservableState`
        //    -> launch the app > Bug sample > Navigate > Hit noop
        //    -> The following is printed (expected behaviour)
        //       Noop button tapped

        // @ObservableState
        enum State: Equatable {
            case path0(BugSampleChild.State)
        }

        enum Action {
            case path0(BugSampleChild.Action)
        }

        init() {}

        var body: some ReducerOf<Self> {
            Scope(state: \.path0, action: \.path0) {
                BugSampleChild()
            }
        }
    }

    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
    }

    enum Action {
        case destination(PresentationAction<Destination.Action>)
        case navigateToChild
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .destination:
                return .none

            case .navigateToChild:
                state.destination = .path0(BugSampleChild.State())
                return .none
            }
        }.ifLet(\.$destination, action: \.destination) {
            Destination()
        }
    }
}

final class BugSampleViewController: UIViewController {

    let store: StoreOf<BugSample>

    weak var childViewController: UIViewController?

    init(store: StoreOf<BugSample>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        let navigateButton = UIButton(type: .system)
        navigateButton.addTarget(self, action: #selector(navigateButtonTapped), for: .touchUpInside)
        navigateButton.setTitle("Navigate", for: .normal)

        navigateButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigateButton)

        NSLayoutConstraint.activate([
            navigateButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            navigateButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
        ])

        observe { [weak self] in
            guard let self else { return }

            if let store = store.scope(state: \.destination?.path0, action: \.destination.path0), childViewController == nil {
                let vc = BugSampleChildViewController(store: store)
                childViewController = vc

                DispatchQueue.main.async { [weak self] in
                    self?.present(vc, animated: true)
                }
            }
        }
    }

    @objc func navigateButtonTapped() {
        store.send(.navigateToChild)
    }
}

// MARK: - Child

@Reducer
struct BugSampleChild {

    @ObservableState
    struct State: Equatable {
        var count: Int = 0
    }

    enum Action {
        case incrementButtonTapped
        case noopButtonTapped
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .incrementButtonTapped:
                state.count += 1
                return .none

            case .noopButtonTapped:
                return .none
            }
        }
    }
}

final class BugSampleChildViewController: UIViewController {

    let store: StoreOf<BugSampleChild>

    init(store: StoreOf<BugSampleChild>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        let countLabel = UILabel()
        countLabel.font = .monospacedDigitSystemFont(ofSize: 17, weight: .regular)

        let incrementButton = UIButton(type: .system)
        incrementButton.addTarget(self, action: #selector(incrementButtonTapped), for: .touchUpInside)
        incrementButton.setTitle("+", for: .normal)

        let noopButton = UIButton(type: .system)
        noopButton.addTarget(self, action: #selector(noopButtonTapped), for: .touchUpInside)
        noopButton.setTitle("Noop", for: .normal)

        let rootStackView = UIStackView(arrangedSubviews: [
            countLabel,
            incrementButton,
            noopButton,
        ])
        rootStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStackView)

        NSLayoutConstraint.activate([
            rootStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            rootStackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
        ])

        observe { [weak self] in
            guard let self else { return }
            countLabel.text = "\(store.count)"
            print("observe triggered")
        }
    }

    @objc func incrementButtonTapped() {
        store.send(.incrementButtonTapped)
    }

    @objc func noopButtonTapped() {
        store.send(.noopButtonTapped)
        print("Noop button tapped")
    }
}
