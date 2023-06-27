//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Ademola Fadumo on 23/06/2023.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionLoadingActivity: UIView!
    
    lazy var networkClient = NetworkClient()
    
    var dataController: DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    var selectedAnnotation: PinAnnotation!
    
    var annotations = [PinAnnotation]()
    
    var photos = [Photo]()
    
    var photosURL = [URL]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //
        setupCollectionViewDelegate()
        
        //
        setupMapDelegate()
        
        //
        setupUI()
        
        setupFetchedResultsController()
        
        // Persist last virtual tourist local data
        saveLastOpenedLocation()
    }
    
    private func setupUI() {
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let newCollection = UIBarButtonItem(title: "NEW COLLECTION", style: .plain, target: self, action: #selector(onNewCollectionTabBarButtonPressed))
        toolbarItems = [space, newCollection, space]
        navigationController?.setToolbarHidden(false, animated: false)
        
        guard let collectionView = collectionView, let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        flowLayout.minimumInteritemSpacing = 10
        flowLayout.minimumLineSpacing = 10
        flowLayout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    @objc private func onNewCollectionTabBarButtonPressed() {
        selectedAnnotation.pin.currentPage += 1
        photos.removeAll()
        photosURL.removeAll()
        
        fetchedResultsController.fetchedObjects?.forEach({ photo in
            dataController.viewContext.delete(photo)
            try? dataController.viewContext.save()
        })
        
        initializePhotosList()
        
        collectionView.reloadData()
    }
    
    private func setupCollectionViewDelegate() {
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    private func setupMapDelegate() {
        mapView.delegate = self
        
        mapView.setCenter(selectedAnnotation.coordinate, animated: true)
        
        mapView.addAnnotations(annotations)
    }
    
    private func initializePhotosList() {
        self.collectionLoadingActivity.isHidden = false
        let _ = networkClient.getPhotosForLocation(lat: selectedAnnotation.coordinate.latitude, lon: selectedAnnotation.coordinate.longitude, page: Int(selectedAnnotation.pin.currentPage)) { photosURL, error in
            print("Fetched images from remote \(photosURL)")
            
            self.photosURL = photosURL
            
            self.collectionLoadingActivity.isHidden = true
            
            self.collectionView.reloadData()
        }
    }
    
    fileprivate func setupFetchedResultsController() {
        self.collectionLoadingActivity.isHidden = true
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        
        let predicate = NSPredicate(format: "pin == %@", selectedAnnotation.pin)
        fetchRequest.predicate = predicate
        
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            
            if fetchedResultsController.fetchedObjects!.isEmpty {
                initializePhotosList()
            } else {
                print("Fetching images from local \(String(describing: fetchedResultsController.fetchedObjects))")
                photos = fetchedResultsController.fetchedObjects!
                print("Photos count \(photos.count)")
            }
            
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
        
    }
    
    private func saveLastOpenedLocation() {
        
        do {
            let data = try JSONEncoder().encode(VirtualTouristLocalData(lastOpenedLocation: LastOpenedLocation(latitude: selectedAnnotation.coordinate.latitude, longitude: selectedAnnotation.coordinate.longitude)))
            
            UserDefaults.standard.setValue(data, forKey: LocalStorageKeys.virtualTouristLocalData)
        } catch {
            print(error)
        }
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photosURL.isEmpty ? photos.count : photosURL.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCollectionViewCell
        
        cell.loadingActivityView.startAnimating()
        
        if photosURL.isEmpty, let imageData = photos[indexPath.row].image {
            cell.imageView.image = UIImage(data: imageData)
            cell.loadingActivityView.stopAnimating()
        } else {
            let url = photosURL[indexPath.row]
            let _ = self.networkClient.getImage(url: url) { data in
                if let data = data {
                    cell.imageView.image = UIImage(data: data)
                }
                cell.loadingActivityView.stopAnimating()
                
                // Save to local storage
                let photo = Photo(context: self.dataController.viewContext)
                photo.image = data
                photo.pin = self.selectedAnnotation.pin
                try? self.dataController.viewContext.save()
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let noOfCellsInRow = 2
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let totalSpace = flowLayout.sectionInset.left
        + flowLayout.sectionInset.right
        + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))
        
        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(noOfCellsInRow))
        return CGSize(width: size, height: size)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        photos.remove(at: indexPath.row)
        collectionView.deleteItems(at: [indexPath])
        
        let photo = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photo)
        try? dataController.viewContext.save()
    }
}

extension PhotoAlbumViewController: MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    // Here we create a view with a "right callout accessory view". You might choose to look into other
    // decoration alternatives. Notice the similarity between this method and the cellForRowAtIndexPath
    // method in TableViewDataSource.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.markerTintColor = .red
            pinView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
}
