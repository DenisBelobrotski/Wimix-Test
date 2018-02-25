import UIKit
import GoogleMaps
import GooglePlaces

class ViewController: UIViewController {
    
    // MARK: - Properties
    
    let defaultCameraZoom: Float = 17.0
    let gmsApiKey = "AIzaSyBV0Y4BpcxlDGJpagnzc4PjDGFAZtu5eOY"

    
    // MARK: - UIViewController
    
    override func loadView() {
        let locationManager = CLLocationManager()
        
        locationManager.requestWhenInUseAuthorization()

        GMSServices.provideAPIKey(gmsApiKey)
        GMSPlacesClient.provideAPIKey(gmsApiKey)
        
        var startCamera: GMSCameraPosition
        
        if let currentLocation = locationManager.location {
            startCamera = GMSCameraPosition.camera(withLatitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude, zoom: defaultCameraZoom)
        } else {
            startCamera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: defaultCameraZoom)
        }
        
        let mapView = GMSMapView.map(withFrame: .zero, camera: startCamera)
        
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        self.view = mapView
        
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

}

