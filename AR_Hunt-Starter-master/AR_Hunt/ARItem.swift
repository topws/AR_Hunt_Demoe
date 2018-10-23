//
//  ARItem.swift
//  AR_Hunt
//
//  Created by Avazu Holding on 2018/10/19.
//  Copyright © 2018年 Razeware LLC. All rights reserved.
//

import Foundation
import CoreLocation
import SceneKit

struct ARItem {
	
	let itemDescription: String
	let location: CLLocation
	
	var itemNode: SCNNode?
}
