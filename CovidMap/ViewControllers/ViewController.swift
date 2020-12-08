//
//  ViewController.swift
//  CovidMap
//
//  Created by Fahad Jamal on 26/11/2020.
//

import UIKit
import Mapbox

class ViewController: UIViewController {
    @IBOutlet weak var containerMap: UIView!
    
    var mapView: MGLMapView!
    let layerIdentifier = "us-states"
    
    //MARK:- Default Init Method
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupMap()
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(sender:)))
        for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
            singleTap.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(singleTap)
    }
        
    @IBAction func onBackButtonPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension ViewController : MGLMapViewDelegate {
    private func setupMap() {
        self.mapView = MGLMapView(frame: self.containerMap.bounds)
        self.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.mapView.zoomLevel = 4
        self.mapView.setCenter(USER_DEFAULT_LOCATION, zoomLevel: 5, animated: false)
        self.mapView.showsUserLocation = true
        self.mapView.delegate = self
        self.containerMap.addSubview(mapView)
    }
    
    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        self.mapView.setCenter(userLocation!.coordinate, animated: false)
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        mapView.setCenter(USER_DEFAULT_LOCATION, animated: false)

        // Since we know this file exists within this project, we'll force unwrap its value.
        // If this data was coming from an external server, we would want to perform
        // proper error handling for a web request/response.
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "RKI_Corona_Landkreise", ofType: "geojson")!)
        // Create a shape source and register it with the map style.
        let source = MGLShapeSource(identifier: "transit", url: url, options: nil)
        style.addSource(source)
        
        let polygonLayer = MGLFillStyleLayer(identifier: "us-states", source: source)
        
        polygonLayer.fillColor = NSExpression(forConstantValue: UIColor(red: 135.0/255.0, green: 173.0/255.0, blue: 206.0/255.0, alpha: 0.6))
        polygonLayer.fillOutlineColor = NSExpression(forConstantValue: UIColor(red: 0.27, green: 0.41, blue: 0.97, alpha: 1.0))
        style.addLayer(polygonLayer)
        
//        style.addPolygons(from: source, riskDataList: self.riskDataList)
    }
    
    @objc @IBAction func handleMapTap(sender: UITapGestureRecognizer) {
        // Get the CGPoint where the user tapped.
        let spot = sender.location(in: mapView)
         
        // Access the features at that point within the state layer.
        let features = mapView.visibleFeatures(at: spot, styleLayerIdentifiers: Set([layerIdentifier]))
         
        // Get the name of the selected state.
        if let feature = features.first, let state = feature.attribute(forKey: "county") as? String {
            changeOpacity(name: state)
        } else {
            changeOpacity(name: "")
        }
    }
     
    func changeOpacity(name: String) {
        guard let layer = mapView.style?.layer(withIdentifier: layerIdentifier) as? MGLFillStyleLayer else {
            fatalError("Could not cast to specified MGLFillStyleLayer")
        }
        // Check if a state was selected, then change the opacity of the states that were not selected.
        if !name.isEmpty {
            layer.fillOpacity = NSExpression(format: "TERNARY(county = %@, 1, 0)", name)
        } else {
        // Reset the opacity for all states if the user did not tap on a state.
            layer.fillOpacity = NSExpression(forConstantValue: 1)
        }
    }
}
