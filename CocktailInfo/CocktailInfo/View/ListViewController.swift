//
//  ViewController.swift
//  CocktailInfo
//
//  Created by Fábio Maciel de Sousa on 05/02/21.
//

import UIKit
import Combine

class ListViewController: UIViewController {
    
    @IBOutlet weak private var tableView: UITableView!
    private let dataSource = CocktailDataSource()
    private let viewModel = ListViewModel()
    private var cancellables: Set<AnyCancellable> = []
    private let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = dataSource
        viewModel.fetchData()
        bindViewModel()
        setupSearchBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let row = tableView.indexPathForSelectedRow?.row {
            let selectedCocktail = dataSource.cocktails[row]
            let selectedImage = dataSource.thumbNails[row]
            guard let detailViewController = segue.destination as? DetailViewController else {
                return
            }
            detailViewController.selectedCocktail = selectedCocktail
            detailViewController.selectedImage = selectedImage
        }
    }
    
    private func setupSearchBar() {
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Cocktails"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func bindViewModel() {
        viewModel.$drinks.sink { [weak self] drinks in
            self?.dataSource.cocktails = drinks
            self?.tableView.reloadData()
        }.store(in: &cancellables)
        
        viewModel.$images.sink { [weak self] images in
            self?.dataSource.thumbNails = images
            self?.tableView.reloadData()
        }.store(in: &cancellables)
        
        viewModel.$errorDescription.sink { [weak self] description in
            if let message = description {
                self?.showAlert(title: "Error!", message: message)
            }
        }.store(in: &cancellables)
    }
    
    /// Method that presents an alert. It has two options and goes back to the previous screen.
    /// - Parameter title: A string to be presented on the alert view.
    private func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let tryAgainAction = UIAlertAction(title: "Try again", style: .default) { [weak self] _ in
            self?.viewModel.fetchData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(tryAgainAction)
        alert.addAction(cancelAction)
        
        DispatchQueue.main.async { [weak self] in
            self?.present(alert, animated: true)
        }
    }
}

extension ListViewController: UISearchBarDelegate {
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        let text = searchBar.text ?? ""
        viewModel.fetchData(By: text.formatted)
    }
}

extension String {
    var formatted: String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed.lowercased().replacingOccurrences(of: " ", with: "")
    }
}
