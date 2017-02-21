//
//  MapViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 12/23/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit
import GoogleMaps

class MapViewController: TraxyTopLevelViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create a GMSCameraPosition that tells the map to display the
        // coordinate -33.86,151.20 at zoom level 6.
        let camera = GMSCameraPosition.camera(withLatitude: 40.381514,  longitude: -105.666874, zoom: 3.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        view = mapView
        
        // Creates a marker in the center of the map.
        var marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: 40.381514, longitude: -105.6668740)
        marker.title = "Camping Out West"
        marker.snippet = "Rocky Mountain National Park"
        marker.map = mapView
        
        marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: 35.966307,  longitude: -83.600158)
        marker.title = "Smokey Mountain National Park"
        marker.snippet = "Smokey Mountain Showcase"
        marker.map = mapView

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
