//
//  DetailsViewController.swift
//  NewsNetworkApp_Day6
//
//  Created by Rawan Elsayed on 29/04/2024.
//

import UIKit
import SDWebImage
import CoreData

class DetailsViewController: UIViewController {
    
    var newsItem: News?
    
    @IBOutlet weak var imgView: UIImageView!
    
    @IBOutlet weak var authorLabel: UILabel!
    
    @IBOutlet weak var titleTextField: UITextView!
    
    @IBOutlet weak var publishLabel: UILabel!
    
    @IBOutlet weak var descTextField: UITextView!
    
    @IBOutlet weak var favoriteBtn: UIButton!
    
    
    var isFavorite = false
    
    @IBAction func addToFavBtn(_ sender: UIButton) {
        
        isFavorite.toggle()
               
            if isFavorite {
                favoriteBtn.setImage(UIImage(systemName: "heart.fill"), for: .normal)
                saveToCoreData()
            } else {
                favoriteBtn.setImage(UIImage(systemName: "heart"), for: .normal)
                removeFromCoreData()
            }
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let news = newsItem {
            authorLabel.text = news.author
            titleTextField.text = news.title
            publishLabel.text = news.publishedAt
            descTextField.text = news.desription

            if (ViewController.cameFromCoreData == true){
                ViewController.cameFromCoreData = false
                if let imageUrlString = news.imageUrl,
                   let imageData = Data(base64Encoded: imageUrlString),
                       let image = UIImage(data: imageData) {
                           imgView.image = image
                   print("image is attached from core data")
               } else {
                   imgView.image = UIImage(named: "images.jpeg")
               }
            }else{
                if let imageUrlString = news.imageUrl {
                    let imageUrl = URL(string: imageUrlString)
                    // Image is provided as a URL
                    imgView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "images.jpeg")) { _, _, _, _ in
                        print("image is attached from internet")
                    }
                }
            }
                   
            isFavorite = isNewsSavedToCoreData(news: news)
            updateFavoriteButtonImage()
        }

    }
    
    func isNewsSavedToCoreData(news: News) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
           
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "NewsTable")
        fetchRequest.predicate = NSPredicate(format: "title == %@", news.title ?? "")
           
        do {
            let result = try context.fetch(fetchRequest)
            return !result.isEmpty
        } catch {
            print("Error fetching news: \(error.localizedDescription)")
            return false
        }
    }
    
    func saveToCoreData() {
           guard let news = newsItem else { return }
           
           let appDelegate = UIApplication.shared.delegate as! AppDelegate
           let context = appDelegate.persistentContainer.viewContext
           
           let entity = NSEntityDescription.entity(forEntityName: "NewsTable", in: context)
           let favNews = NSManagedObject(entity: entity!, insertInto: context)
           
           favNews.setValue(news.author, forKey: "author")
           favNews.setValue(news.title, forKey: "title")
           favNews.setValue(news.desription, forKey: "desription")
           favNews.setValue(news.publishedAt, forKey: "publishedAt")
           
           if let image = imgView.image, let imageData = image.pngData() {
               let base64String = imageData.base64EncodedString()
               favNews.setValue(base64String, forKey: "imageUrl")
           }
           
           do {
               try context.save()
               print("News saved to Core Data")
           } catch {
               print("Error saving news to Core Data: \(error.localizedDescription)")
           }
    }
    
    func removeFromCoreData() {
           guard let news = newsItem else { return }
           
           let appDelegate = UIApplication.shared.delegate as! AppDelegate
           let context = appDelegate.persistentContainer.viewContext
           
           let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "NewsTable")
           fetchRequest.predicate = NSPredicate(format: "title == %@", news.title ?? "")
           
           do {
               let result = try context.fetch(fetchRequest)
               guard let objectToDelete = result.first as? NSManagedObject else { return }
               context.delete(objectToDelete)
               
               try context.save()
               print("News removed from Core Data")
           } catch {
               print("Error removing news from Core Data: \(error.localizedDescription)")
           }
    }
    
    func updateFavoriteButtonImage() {
        if isFavorite {
            favoriteBtn.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        } else {
            favoriteBtn.setImage(UIImage(systemName: "heart"), for: .normal)
        }
    }

}
