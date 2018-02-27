import UIKit
import GoogleMaps
import Alamofire

class ViewController: UIViewController, GMSMapViewDelegate {
    
    // MARK: - Properties
    
    let defaultCameraZoom: Float = 15.0
    let gmsApiKey = "AIzaSyBV0Y4BpcxlDGJpagnzc4PjDGFAZtu5eOY"
    let searchRadius = 1000
    var currentLocation: CLLocationCoordinate2D?

    
    // MARK: - UIViewController
    
    override func loadView() {
        let locationManager = CLLocationManager()
        
        locationManager.requestWhenInUseAuthorization()

        GMSServices.provideAPIKey(gmsApiKey)
        
        var startCamera: GMSCameraPosition
        
        if let location = locationManager.location {
            currentLocation = location.coordinate
        } else {
            currentLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
        startCamera = GMSCameraPosition.camera(withLatitude: currentLocation!.latitude, longitude: currentLocation!.longitude, zoom: defaultCameraZoom)
        
        let mapView = GMSMapView.map(withFrame: .zero, camera: startCamera)
        
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        mapView.delegate = self
        self.view = mapView
        
        self.navigationController?.isNavigationBarHidden = true
        
        searchPlaces()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    // MARK: - GMSMapViewDelegate
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if let path = marker.snippet {
            if !path.isEmpty {
                if let url = URL(string: path) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } else {
                showErrorMessage("This place doesn't hava a website.")
            }
        }
        
        return false
    }
    
    func searchPlaces() {
        let urlRequest = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(currentLocation!.latitude),\(currentLocation!.longitude)&radius=\(searchRadius)&types=restaurant&key=\(gmsApiKey)"
        Alamofire.request(urlRequest).validate().responseJSON { (response) in
            switch response.result {
            case .success(_):
                if let responseValue = response.result.value as! [String: Any]? {
                    if let responsePlaces = responseValue["results"] as! [[String: Any]]? {
                        for currentPlace in responsePlaces {
                            if let placeId = currentPlace["place_id"] as? String {
                                self.makeMarkerById(placeId)
                            }
                        }
                    }
                }
            case .failure(_):
                print("Internet connection error")
            }
        }
    }
    
    func makeMarkerById(_ id: String) {
        let urlRequest = "https://maps.googleapis.com/maps/api/place/details/json?placeid=\(id)&key=\(gmsApiKey)"
        Alamofire.request(urlRequest).validate().responseJSON { (response) in
            switch response.result {
            case .success(_):
                if let responseValue = response.result.value as! [String: Any]? {
                    if let responsePlace = responseValue["result"] as! [String: Any]? {
                        if let responseGeometry = responsePlace["geometry"] as! [String: Any]? {
                            if let responseLocation = responseGeometry["location"] as! [String: Any]? {
                                let responseLatitude = responseLocation["lat"] as? Double ?? 0
                                let responseLongitude = responseLocation["lng"] as? Double ?? 0
                                let responseName = responsePlace["name"] as? String ?? ""
                                let responseWebsite = responsePlace["website"] as? String ?? ""
                                self.instantiateMarkerWithPosition(CLLocationCoordinate2D(latitude: responseLatitude, longitude: responseLongitude), name: responseName, andWebsite: responseWebsite)
                            }
                        }
                    }
                }
            case .failure(_):
                print("Internet connection error")
            }
        }
    }
    
    func instantiateMarkerWithPosition(_ position: CLLocationCoordinate2D, name: String, andWebsite website: String) {
        let marker = GMSMarker(position: position)
        marker.title = name
        marker.snippet = website
        marker.map = self.view as? GMSMapView
    }
    
    func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

}

