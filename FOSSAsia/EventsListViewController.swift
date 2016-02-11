//
//  EventsListViewController.swift
//  FOSSAsia
//
//  Created by Jurvis Tan on 10/2/16.
//  Copyright © 2016 FossAsia. All rights reserved.
//

import UIKit
import Pages

class EventsListViewController: UIViewController {
    weak var pagesVC: PagesController!
    var viewModel: EventsListViewModel? {
        didSet {
            viewModel?.allSchedules.observe {
                [unowned self] in
                let viewControllers = $0.map { viewModel in
                    return ScheduleViewController.scheduleViewControllerFor(viewModel)
                }
                self.pagesVC.add(viewControllers)
            }
        }
    }
    
    var currentViewController: ScheduleViewController!
    var searchController: UISearchController!
    var resultsTableController: EventsResultsViewController!
    var filterString: String? = nil {
        didSet {
            currentViewController.filterString = filterString
            resultsTableController.visibleEvents = currentViewController.filteredEvents
            resultsTableController.tableView.reloadData()
        }
    }
    @IBOutlet weak var pagingView: SchedulePagingView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = EventsListViewModel()
        pagingView.delegate = self
        
        resultsTableController = storyboard!.instantiateViewControllerWithIdentifier(EventsResultsViewController.StoryboardConstants.viewControllerId) as! EventsResultsViewController
        resultsTableController.allEvents = currentViewController.allEvents
        
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        
        // We want to be the delegate for our filtered table so didSelectRowAtIndexPath(_:) is called for both tables.
        // calling .view will force Storyboards to render the view hierarchy to make tableView accessible
        let _ = searchController.view
        resultsTableController.tableView.delegate = self
        
        searchController.searchBar.searchBarStyle = .Minimal
        searchController.searchBar.tintColor = Colors.creamTintColor
        searchController.searchBar.placeholder = "Search"
        if let textFieldInSearchBar = searchController.searchBar.valueForKey("searchField") as? UITextField {
            textFieldInSearchBar.textColor = Colors.creamTintColor
        }
        
        navigationItem.titleView = searchController.searchBar
        
        definesPresentationContext = true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "EventsPageViewController") {
            if let embeddedPageVC = segue.destinationViewController as? PagesController {
                self.pagesVC = embeddedPageVC
                self.pagesVC.enableSwipe = false
                self.pagesVC.pagesDelegate = self
            }
        }
    }
}

extension EventsListViewController: SchedulePagingViewDelegate {
    func nextButtonDidPress(sender: SchedulePagingView) {
        self.pagesVC.next()

    }
    func prevButtonDidPress(sender: SchedulePagingView) {
        self.pagesVC.previous()
    }
}

extension EventsListViewController: PagesControllerDelegate {
    func pageViewController(pageViewController: UIPageViewController, setViewController viewController: UIViewController, atPage page: Int) {
        guard let currentVC = viewController as? ScheduleViewController else {
            return
        }
        pagingView.dateLabel.text = currentVC.viewModel?.date.value.formattedDateWithFormat("EEEE, MMM dd")
        
        // Govern Previous Button
        if page == 0 {
            pagingView.prevButton.enabled = false
        } else {
            pagingView.prevButton.enabled = true
        }
        
        // Govern Next Button
        if let scheduleViewModels = viewModel {
            if page == scheduleViewModels.count.value - 1 {
                pagingView.nextButton.enabled = false
            } else {
                pagingView.nextButton.enabled = true
            }
        }
        
        self.currentViewController = currentVC
    }
}

extension EventsListViewController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        guard searchController.active else {
            return
        }
        filterString = searchController.searchBar.text
    }
}

extension EventsListViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedEventViewModel: EventViewModel

        selectedEventViewModel = resultsTableController.visibleEvents[indexPath.row]
        
        let eventViewController = EventViewController.eventViewControllerForEvent(selectedEventViewModel)
        
        navigationController?.pushViewController(eventViewController, animated: true)
    }
    
}