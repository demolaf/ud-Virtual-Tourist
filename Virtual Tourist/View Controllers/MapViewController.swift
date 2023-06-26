//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Ademola Fadumo on 23/06/2023.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFetchedResultsController()
        
        setupMapView()
        
        getLastOpenedLocation()
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    @objc func mapLongTapGesturePressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchLocation = sender.location(in: mapView)
            let locationCoordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
            
            self.addPin(coordinate: locationCoordinate)
        }
    }
    
    func addPin(coordinate: CLLocationCoordinate2D) {
        print("Tapped at latitude \(coordinate.latitude), longitude \(coordinate.longitude)")
        
        let newPin = Pin(context: dataController.viewContext)
        newPin.latitude = coordinate.latitude
        newPin.longitude = coordinate.longitude
        newPin.currentPage = 1
        try? dataController.viewContext.save()
        
        let annotation = PinAnnotation(pin: newPin)
        annotation.coordinate = coordinate
        self.mapView.addAnnotation(annotation)
    }
    
    func parsePinsToAnnotations(_ pins: [Pin]?) -> [PinAnnotation] {
        guard let pins = pins else {
            return []
        }
        
        var annotations = [PinAnnotation]()
        
        pins.forEach { pin in
            let annotation = PinAnnotation(pin: pin)
            annotations.append(annotation)
        }
        
        return annotations
    }
    
    private func getLastOpenedLocation() {
        // Fetch persisted virtual tourist local data
        do {
            let storedData = UserDefaults.standard.data(forKey: LocalStorageKeys.virtualTouristLocalData)
            
            if let storedData = storedData {
                let data = try JSONDecoder().decode(VirtualTouristLocalData.self, from: storedData)
                
                self.mapView.setCenter(CLLocationCoordinate2D(latitude: data.lastOpenedLocation.latitude, longitude: data.lastOpenedLocation.longitude), animated: false)
            }
        } catch {
            print(error)
        }
    }
    
    private func setupMapView() {
        mapView.delegate = self
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(mapLongTapGesturePressed))
        
        mapView.addGestureRecognizer(longTapGesture)
        
        let annotations = parsePinsToAnnotations(fetchedResultsController.fetchedObjects)
        
        self.mapView.addAnnotations(annotations)
    }
    
}

extension MapViewController: MKMapViewDelegate {
    
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
    
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        let photoAlbumVC = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        
        photoAlbumVC.selectedAnnotation = annotation as? PinAnnotation
        photoAlbumVC.annotations = mapView.annotations
        photoAlbumVC.dataController = dataController
        
        navigationController?.pushViewController(photoAlbumVC, animated: true)
    }
}

extension MapViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert, .update, .delete, .move:
            mapView.reloadInputViews()
            
        default:
            fatalError("Error in database")
            break;
        }
    }
}
