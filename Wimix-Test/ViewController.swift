import UIKit
import GoogleMaps
import Alamofire

class ViewController: UIViewController, GMSMapViewDelegate {
    
    // MARK: - Properties
    
    let defaultCameraZoom: Float = 15.0
    let gmsApiKey = "AIzaSyBEBXftMkVCe__-qxo5nWxNPfO906TkOec"
    let searchRadius = 1000
    var currentLocation: CLLocationCoordinate2D?
    let serverDateFormatter = DateFormatter()
    let serverDateFormat = "HHmm"
    let locationManager = CLLocationManager()
    let internetConnectionErrorMessage = "Internet connection error."
    let emptyWebsiteErrorMessage = "This place doesn't have a website."
    let wrongCurrentLocationErrorMessage = "We couldn't find your current location. Check your GPS connection and try again by pressing \"Current location\" button."
    
    
    // MARK: - UIViewController
    
    override func loadView() {
        
        
        locationManager.requestWhenInUseAuthorization()

        GMSServices.provideAPIKey(gmsApiKey)
        
        findCurrentLocation()
        
        let startCamera = GMSCameraPosition.camera(withLatitude: currentLocation!.latitude, longitude: currentLocation!.longitude, zoom: defaultCameraZoom)
        
        let mapView = GMSMapView.map(withFrame: .zero, camera: startCamera)
        
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        mapView.delegate = self
        self.view = mapView
        
        self.navigationController?.isNavigationBarHidden = true
        
        serverDateFormatter.dateFormat = serverDateFormat
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchPlaces(withUrlParams: "&location=\(currentLocation!.latitude),\(currentLocation!.longitude)&radius=\(searchRadius)&types=restaurant")
    }
    
    
    // MARK: - GMSMapViewDelegate
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if let path = marker.snippet {
            if !path.isEmpty {
                if let url = URL(string: path) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } else {
                showAlert(withErrorMessage: emptyWebsiteErrorMessage)
            }
        }
        
        return false
    }
    
    func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
        mapView.clear()
        findCurrentLocation()
        searchPlaces(withUrlParams: "&location=\(currentLocation!.latitude),\(currentLocation!.longitude)&radius=\(searchRadius)&types=restaurant")
        
        return false
    }
    
    
    // MARK: - Internal methods
    
    func searchPlaces(withUrlParams urlParams: String) {
        let urlRequest = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?key=\(gmsApiKey)" + urlParams
        Alamofire.request(urlRequest).validate().responseJSON { (response) in
            switch response.result {
            case .success(_):
                if let responseValue = response.result.value as! [String: Any]? {
                    if let nextPageToken = responseValue["next_page_token"] as? String {
                        self.searchPlaces(withUrlParams: "&pagetoken=\(nextPageToken)")
                    }
                    if let responsePlaces = responseValue["results"] as! [[String: Any]]? {
                        for currentPlace in responsePlaces {
                            if let placeId = currentPlace["place_id"] as? String {
                                self.makeMarkerById(placeId)
                            }
                        }
                    }
                }
            case .failure(_):
                self.showAlert(withErrorMessage: self.internetConnectionErrorMessage)
            }
        }
    }
    
    func makeMarkerById(_ id: String) {
        let urlRequest = "https://maps.googleapis.com/maps/api/place/details/json?placeid=\(id)&key=\(gmsApiKey)"
        Alamofire.request(urlRequest).validate().responseJSON { (response) in
            switch response.result {
            case .success(_):
                if let responseValue = response.result.value as! [String: Any]? {
                    if let place = responseValue["result"] as! [String: Any]? {
                        if let geometry = place["geometry"] as! [String: Any]? {
                            if let location = geometry["location"] as! [String: Any]? {
                                let latitude = location["lat"] as? Double ?? 0
                                let longitude = location["lng"] as? Double ?? 0
                                
                                let name = place["name"] as? String ?? ""
                                let website = place["website"] as? String ?? ""
                                
                                if let openingHours = place["opening_hours"] as! [String: Any]? {
                                    let isOpenNow = openingHours["open_now"] as? Bool ?? false
                                    if isOpenNow {
                                        let periods = openingHours["periods"] as! [[String: Any]]?
                                        if self.isPlaceOpenRoundTheClock(periods: periods) || self.isPlaceOpenNextHour(periods: periods) {
                                            self.instantiateMarkerWithPosition(CLLocationCoordinate2D(latitude: latitude, longitude: longitude), name: name, andWebsite: website)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            case .failure(_):
                self.showAlert(withErrorMessage: self.internetConnectionErrorMessage)
            }
        }
    }
    
    func instantiateMarkerWithPosition(_ position: CLLocationCoordinate2D, name: String, andWebsite website: String) {
        let marker = GMSMarker(position: position)
        marker.title = name
        marker.snippet = website
        marker.map = self.view as? GMSMapView
    }
    
    func showAlert(withErrorMessage message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func isPlaceOpenNextHour(periods: [[String: Any]]?) -> Bool {
        if let periods = periods {
            let currentDayComponents = Calendar.current.dateComponents([.weekday, .hour, .minute], from: Date())
            
            var requiredWeekday = currentDayComponents.weekday! - 1
            var requiredHour = currentDayComponents.hour! + 1
            let requiredMinute = currentDayComponents.minute!

            if requiredHour >= 24 {
                requiredWeekday += 1
                requiredHour %= 24
            }
            
            for currentPeriod in periods {
                if let close = currentPeriod["close"] as! [String: Any]? {
                    let closeWeekday = close["day"] as? Int
                    let closeTime = close["time"] as? String
                    if closeWeekday != nil && closeTime != nil {
                        let closeTimeComponents = Calendar.current.dateComponents([.hour, .minute], from: self.serverDateFormatter.date(from: closeTime!) ?? Date())
                        if requiredWeekday == closeWeekday! {
                            if requiredHour < closeTimeComponents.hour! {
                                return true
                            } else if requiredHour == closeTimeComponents.hour! && requiredMinute < closeTimeComponents.minute! {
                                return true
                            } else {
                                return false
                            }
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    func isPlaceOpenRoundTheClock(periods: [[String: Any]]?) -> Bool {
        if let periods = periods {
            let currentPeriod = periods[0]
            if let open = currentPeriod["open"] as! [String: Any]? {
                let day = open["day"] as? Int
                if day != nil && day == 0 {
                    let time = open["time"] as? String
                    if time != nil && time == "0000" {
                        let close = currentPeriod["close"] as! [String: Any]?
                        if close == nil {
                            return true
                        }
                    }
                }
            }
        }

        return false
    }
    
    func findCurrentLocation() {
        if let location = locationManager.location {
            currentLocation = location.coordinate
        } else {
            currentLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
            showAlert(withErrorMessage: wrongCurrentLocationErrorMessage)
        }
    }
}
