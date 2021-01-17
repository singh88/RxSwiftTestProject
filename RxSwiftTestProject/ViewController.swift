//
//  ViewController.swift
//  RxSwiftTestProject
//
//  Created by Manish Singh on 1/16/21.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    let disposeBag = DisposeBag()
    let urlString = "https://api.flickr.com/services/feeds/photos_public.gne?tags=garden&;tagmode=any&format=json&nojsoncallback=1"

    private var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        activityIndicator.startAnimating()

        let fetchDataObservable = fetchData(url: urlString)

        fetchDataObservable.asDriver(onErrorJustReturn: .error).drive(onNext: { [weak self] item in
            switch item {
            case.loading:
                print("Animation is in progress")
            case .data(let data):
                print("Activity Indicator is going to be stopped now....")
                self?.activityIndicator.stopAnimating()
                print("*** Data is downloaded from Network **** \(data)")
                let alertview = UIAlertController(title: "Success", message: "Success", preferredStyle: .alert)
                self?.present(alertview, animated: true, completion: nil)
            case .error:
                let alertview = UIAlertController(title: "Error", message: "Error", preferredStyle: .alert)
                self?.present(alertview, animated: true, completion: nil)
            }
        }).disposed(by: disposeBag)
    }

    func configureUI() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .red
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    func fetchData(url: String) -> Observable<ItemState> {
        // first observable, which actuall fetches data from an API or any async operation
        let dataFetch =  Observable<ItemState>.create { observer in
            guard let request = URL(string: url) else {
                return Disposables.create()
            }

            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                do {
                    let model = try JSONDecoder().decode(ItemDetails.self, from: data ?? Data())
                    observer.onNext( .data(model))
                } catch let error {
                    observer.onError(error)
                }
                observer.onCompleted()
            }

            task.resume()

            return Disposables.create {
                task.cancel()
            }
        }

        // second observable for the loading state.
        let loading = Observable<Int>
            .timer(RxTimeInterval.milliseconds(1), scheduler: MainScheduler.instance)
                .map { _ in ItemState.loading }

        let loadingThenData = loading.concat(dataFetch)

        return Observable.amb([dataFetch, loadingThenData])
    }
}

// MARK: - Different Data States
enum ItemState {
    case data(ItemDetails)
    case loading
    case error
}

// MARK: - Model
struct ItemDetails: Decodable {
    var items: [PhotoDetails]
}

struct PhotoDetails: Decodable {
    var title: String
    var link: String
    var media: Media
    var description: String
    var tags: String
}

struct Media: Decodable {
    var m: String
}

