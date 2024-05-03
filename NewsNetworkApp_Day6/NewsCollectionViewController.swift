//
//  NewsCollectionViewController.swift
//  NewsNetworkApp_Day6
//
//  Created by Rawan Elsayed on 29/04/2024.
//

import UIKit
import SDWebImage
import Reachability
import CoreData

class NewsCollectionViewController: UICollectionViewController , UICollectionViewDelegateFlowLayout {
    
    static var cameFromCoreData = false
    
    //For Checking Connection to internet
    let reachability = try! Reachability()
    
    var indicator : UIActivityIndicatorView?
    
    var newsArray: [News] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        startMonitoringReachability()
        
        //indicator (loading)
        indicator = UIActivityIndicatorView(style: .medium)
        indicator!.center = view.center
        indicator!.startAnimating()
        view.addSubview(indicator!)
        
//        loadNewsData { [weak self] newsArray in
//            print(newsArray)
//        }
    }
    
    deinit {
        // Stop observing network reachability
        reachability.stopNotifier()
    }
    
    func startMonitoringReachability() {
           reachability.whenReachable = { reachability in
               if reachability.connection == .wifi {
                 //  self.deleteAllDataFromCoreData()
                   NewsCollectionViewController.cameFromCoreData = false
                   print("Connected via WiFi")
                   self.loadNewsData { [weak self] newsArray in
                       print(newsArray)
                   }
               } else {
                   print("Connected via Cellular")
               }
           }
           reachability.whenUnreachable = { _ in
               print("Disconnected from the internet")
               self.indicator?.stopAnimating()
               self.fetchStoredDataFromCoreData()
               NewsCollectionViewController.cameFromCoreData = true
           }
            do {
               try reachability.startNotifier()
           } catch {
               print("Unable to start reachability notifier")
           }
       }
    
    func loadNewsData(completion: @escaping ([News]) -> Void) {
        deleteAllDataFromCoreData()
        let url = URL(string: "https://raw.githubusercontent.com/DevTides/NewsApi/master/news.json")
        guard let url = url else {
            return
        }
        
        let request = URLRequest(url: url)
        let session = URLSession(configuration: .default)
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data else {
                print("No data")
                return
            }
            
            do {
                let results = try JSONDecoder().decode([News].self, from: data)
                self?.newsArray = results
                
                //Store data to CoreData
                self?.storeAllNewsToCoreData(newsArray: results)
                
                DispatchQueue.main.async {
                    self?.indicator?.stopAnimating()
                    self?.collectionView.reloadData()
                    completion(results) 
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        
        task.resume()
    }
    
    func storeNewsToCoreData(news: News) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "NewsOffline", in: context)
        let favNews = NSManagedObject(entity: entity!, insertInto: context)
        
        favNews.setValue(news.author, forKey: "author")
        favNews.setValue(news.title, forKey: "title")
        favNews.setValue(news.desription, forKey: "desription")
        favNews.setValue(news.publishedAt, forKey: "publishedAt")
        
        favNews.setValue(news.imageUrl, forKey: "imageUrl")
        
        do {
            try context.save()
            print("News saved to Core Data")
        } catch {
            print("Error saving news to Core Data: \(error.localizedDescription)")
        }
        
    }
    
    func storeAllNewsToCoreData(newsArray: [News]) {
        for newsItem in newsArray {
            storeNewsToCoreData(news: newsItem)
        }
    }

    func fetchStoredDataFromCoreData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "NewsOffline")
            
        do {
            let fetchedData = try context.fetch(fetchRequest)
            newsArray = fetchedData.compactMap { managedObject in
                guard let author = managedObject.value(forKey: "author") as? String else {
                    print("No author")
                    return nil
                }
                
                guard let title = managedObject.value(forKey: "title") as? String,
                      let publishedAt = managedObject.value(forKey: "publishedAt") as? String else {
                    print("No publishedAt")
                    return nil
                }
                
                let description = managedObject.value(forKey: "desription") as? String ?? "No description"
                let imageUrl = managedObject.value(forKey: "imageUrl") as? String ?? ""
                
                let news = News()
                news.author = author
                news.title = title
                news.desription = description
                news.publishedAt = publishedAt
                news.imageUrl = imageUrl
                return news
            }
            collectionView.reloadData()
        } catch let error {
            print("Error fetching data: \(error.localizedDescription)")
        }
    }

    func deleteAllDataFromCoreData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "NewsOffline")
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(batchDeleteRequest)
            print("All data deleted from Core Data")
        } catch {
            print("Error deleting data from Core Data: \(error.localizedDescription)")
        }
    }


    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return newsArray.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell             
    
        let newsItem = newsArray[indexPath.item]
        
        cell.titleInCell.text = newsItem.author
        
        if let imageUrl = URL(string: newsItem.imageUrl ?? "no image") {
            cell.imgInCell.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "images.jpeg"), completed: nil)
        } else {
            cell.imgInCell.image = UIImage(named: "images.jpeg")
        }
                   
        print(cell.titleInCell.text ?? "no text")
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        return CGSize(width: view.frame.width, height: view.frame.width/2)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedNews = newsArray[indexPath.item]
        showDetailsViewController(with: selectedNews)
    }

    func showDetailsViewController(with newsItem: News) {
        if let detailsVC = storyboard?.instantiateViewController(withIdentifier: "DetailsViewController") as? DetailsViewController {
                detailsVC.newsItem = newsItem
                navigationController?.pushViewController(detailsVC, animated: true)
        }
    }
      

}
