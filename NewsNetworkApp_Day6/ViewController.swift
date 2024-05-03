//
//  ViewController.swift
//  NewsNetworkApp_Day6
//
//  Created by Rawan Elsayed on 29/04/2024.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var newsItems: [NSManagedObject] = []
    
    static var cameFromCoreData = false
    
    @IBOutlet weak var FavoriteTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FavoriteTableView.delegate = self
        FavoriteTableView.dataSource = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchDataFromCoreData()
    }
    
    func fetchDataFromCoreData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "NewsTable")
            
        do {
            newsItems = try context.fetch(fetchRequest)
            FavoriteTableView.reloadData()
        } catch let error {
            print("Error fetching data: \(error.localizedDescription)")
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "favCell", for: indexPath)
        
        let newsItem = newsItems[indexPath.row]
        if let author = newsItem.value(forKey: "author") as? String {
            cell.textLabel?.text = author
        }
        
        if let imageUrlString = newsItem.value(forKey: "imageUrl") as? String,
            let imageData = Data(base64Encoded: imageUrlString),
                let image = UIImage(data: imageData) {
            cell.imageView?.image = image
        } else {
            cell.imageView?.image = UIImage(named: "images.jpeg")
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let detailsVC = storyboard?.instantiateViewController(withIdentifier: "DetailsViewController") as? DetailsViewController else {
            return
        }
        
        let selectedNewsItem = newsItems[indexPath.row]

        let news = convertToNewsObject(newsManagedObject: selectedNewsItem)
        detailsVC.newsItem = news
        
        ViewController.cameFromCoreData = true
        
        navigationController?.pushViewController(detailsVC, animated: true)
    }

    func convertToNewsObject(newsManagedObject: NSManagedObject) -> News? {
        // Convert NSManagedObject to News object 
        let news = News()
        news.author = newsManagedObject.value(forKey: "author") as? String
        news.title = newsManagedObject.value(forKey: "title") as? String
        news.desription = newsManagedObject.value(forKey: "desription") as? String
        news.publishedAt = newsManagedObject.value(forKey: "publishedAt") as? String

        news.imageUrl = newsManagedObject.value(forKey: "imageUrl") as? String
        
        return news
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
               removeFromCoreData(at: indexPath)
           }
    }
       
    func removeFromCoreData(at indexPath: IndexPath) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
           
        let newsItemToRemove = newsItems[indexPath.row]
        context.delete(newsItemToRemove)
           
        do {
            try context.save()
            newsItems.remove(at: indexPath.row)
            FavoriteTableView.deleteRows(at: [indexPath], with: .fade)
            print("News removed from Core Data and table view")
           } catch {
               print("Error removing news from Core Data: \(error.localizedDescription)")
        }
    }
    
}

