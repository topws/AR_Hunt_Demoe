//
//  Created by 张嘉夫 on 16/12/29.
//  Copyright © 2016年 张嘉夫. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {

  @IBOutlet weak var mapView: MKMapView!
	
	var targets = [ARItem]()
	let locationManager = CLLocationManager()
	var userLocation: CLLocation?
	
	var selectedAnnotation: MKAnnotation?
  override func viewDidLoad() {
    super.viewDidLoad()
    
    mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
		
		setupLocations()
		//索取所需的权限
		if CLLocationManager.authorizationStatus() == .notDetermined {
			locationManager.requestWhenInUseAuthorization()
		}
  }
	
	func setupLocations() {
		//硬编码的方式，创建三个敌人，
		let firstTarget = ARItem.init(itemDescription: "wolf", location: CLLocation(latitude: 31.1280202105, longitude: 121.3748610020), itemNode: nil)
		targets.append(firstTarget)
		let secondTarget = ARItem.init(itemDescription: "wolf", location: CLLocation(latitude: 31.2048869816, longitude: 121.4593881369), itemNode: nil)
		targets.append(secondTarget)
		let thirdTarget = ARItem.init(itemDescription: "dragon", location: CLLocation(latitude: 31.2047860391, longitude: 121.4593988657), itemNode: nil)
		targets.append(thirdTarget)
		
		for item in targets {
			let annotation = MapAnnotation(location: item.location.coordinate, item: item)
			self.mapView.addAnnotation(annotation)
		}
		
		
	}
}

//实时的更新用户的当前位置，使用extension的方式，让代码更简洁
extension MapViewController:MKMapViewDelegate {
	
	func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
		self.userLocation = userLocation.location
	}
	
	func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
		let coordinate = view.annotation!.coordinate
//		获取被选择的 annotation 的坐标。
//		确保可选值 userLocation 已分配。
//		确保被点击的对象在用户的位置范围以内。
//		从 storyboard 实例化 ARViewController。
//		这一行检查被点击的 annotation 是否是 MapAnnotation。
//		最后，显示 viewController。
		
		if let userCoordinate = userLocation {
			//目标距离和当前用户距离小于50
			if userCoordinate.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) < 50 {
				//获取到 ARViewController控制器
				let storyboard = UIStoryboard(name: "Main", bundle: nil)
				if let viewController = storyboard.instantiateViewController(withIdentifier: "ARViewController") as? ViewController {
					
					//1
					viewController.delegate = self
					
					if let mapAnnotation = view.annotation as? MapAnnotation {
						viewController.target = mapAnnotation.item
						viewController.userLocation = mapView.userLocation.location!
						
						//2
						selectedAnnotation = view.annotation
						self.present(viewController, animated: true, completion: nil)
					}
					
				}
				
			}
		}
	}
}

extension MapViewController: ARControllerDelegate {
//	1首先关闭了增强现实视图。
//	2然后从 target 列表中删除 target。
//	3最后从地图上移除 annotation。
	func viewController(controller: ViewController, tappedTarget: ARItem) {
		//1
		self.dismiss(animated: true, completion: nil)
		//2
		let index = self.targets.index(where: {$0.itemDescription == tappedTarget.itemDescription})
		self.targets.remove(at: index!)
		
		if selectedAnnotation != nil {
			//3
			mapView.removeAnnotation(selectedAnnotation!)
		}
	}
}

