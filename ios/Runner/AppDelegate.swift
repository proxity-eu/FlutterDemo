import UIKit
import CoreLocation
import Flutter
import ProxityKit


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    var beaconProvider: BeaconProvider?
    var channel: FlutterMethodChannel!
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
    
        let controller = window?.rootViewController as! FlutterViewController
        channel = FlutterMethodChannel(
            name: "eu.proxity",
            binaryMessenger: controller.binaryMessenger
        )
        
        let locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
    
        let proxityClient = ProxityKit.Client(
            apiKey: YOUR_INTEGRATION_KEY,
            deviceId: UIDevice.current.identifierForVendor ?? UUID(),
            locationManager: locationManager,
            messageCallback: {
                self.channel.invokeMethod("messages", arguments: $1)
            },
            webhookCallback: { client, ids in
                let data = UIDevice.current.orientation.isPortrait ? "portrait" : "landscape"
                client.dispatchWebhooks(ids: ids, data: data)
                self.channel.invokeMethod("webhooks", arguments: ids)
            },
            logger: logger,
            recreateDatabase: true
        )

        if let client = proxityClient {
            beaconProvider = BeaconProvider(
                locationManager: locationManager,
                proxityClient: client
            )
        } else {
            print("Failed to initialize ProxityKit.Client")
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

class BeaconProvider: NSObject, CLLocationManagerDelegate {
    let locationManager: CLLocationManager
    let proxityClient: ProxityKit.Client

    init(
        locationManager: CLLocationManager,
        proxityClient: ProxityKit.Client
    ) {
        self.locationManager = locationManager
        self.proxityClient = proxityClient
        super.init()

        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.delegate = self
    }

    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        switch status {
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            proxityClient.start()
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            proxityClient.start()
        case .denied:
            print("Location: denied")
        case .notDetermined:
            print("Location: not determined")
            locationManager.requestAlwaysAuthorization()
        case .restricted:
            print("Location: restricted")
        @unknown default:
            print("Location: unknown")
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didRange beacons: [CLBeacon],
        satisfying beaconConstraint: CLBeaconIdentityConstraint
    ) {
        if beacons.isEmpty { return }
        proxityClient.processBeacons(beacons, location: manager.location)
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        proxityClient.updateLocation(locations.first)
    }
}

func logger(_ msg: String) -> Void {
    print(msg)
}
