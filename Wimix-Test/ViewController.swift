import UIKit
import GoogleMaps
import Alamofire

class ViewController: UIViewController {
    
    // MARK: - Properties
    
    let defaultCameraZoom: Float = 17.0
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
            startCamera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: defaultCameraZoom)
        } else {
            startCamera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: defaultCameraZoom)
        }
        
        let mapView = GMSMapView.map(withFrame: .zero, camera: startCamera)
        
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        self.view = mapView
        
        self.navigationController?.isNavigationBarHidden = true
        
        searchPlaces()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func searchPlaces() {
        let urlRequest = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(currentLocation!.latitude),\(currentLocation!.longitude)&radius=\(searchRadius)&types=restaurant&key=\(gmsApiKey)"
        print(urlRequest)
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
                        if let responseName = responsePlace["name"] as? String {
                            print(responseName)
                        }
                    }
                }
            case .failure(_):
                print("Internet connection error")
            }
        }
    }

}

