//
//  Created by 张嘉夫 on 16/12/29.
//  Copyright © 2016年 张嘉夫. All rights reserved.
//

import UIKit
import SceneKit
import AVFoundation
import CoreLocation

protocol ARControllerDelegate {
	func viewController(controller: ViewController,tappedTarget: ARItem)
}
class ViewController: UIViewController {
  
  @IBOutlet weak var sceneView: SCNView!
  @IBOutlet weak var leftIndicator: UILabel!
  @IBOutlet weak var rightIndicator: UILabel!
	
	//使用 capture session 来连接到视频输入，比如摄像头，然后连接到输出，比如预览层。
	var cameraSession: AVCaptureSession?
	var cameraLayer: AVCaptureVideoPreviewLayer?
	
	var target: ARItem!
	//使用 CLLocationManager 来接收设备目前的朝向。朝向从真北或磁北极以度数测量
	var locationManager = CLLocationManager()
	var heading: Double = 0
	var userLocation = CLLocation()
	
	//创建了空的 SCNScene 和 SCNNode。targetNode 是一个包含小方块的 SCNNode
	let scene = SCNScene()
	let cameraNode = SCNNode()
	let targetNode = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0))
	
	var delegate: ARControllerDelegate?
  override func viewDidLoad() {
    super.viewDidLoad()
		
		loadCamera()
		self.cameraSession?.startRunning()
		
		//把 ViewController 设置为 CLLocationManager 的代理
		self.locationManager.delegate = self
		//调用本行后，就会获得朝向信息。默认情况下，朝向改变超过 1 度时就会通知代理。
		self.locationManager.startUpdatingHeading()
		
		sceneView.scene = scene
		cameraNode.camera = SCNCamera()
		cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
		scene.rootNode.addChildNode(cameraNode)
		
		setupTarget()
  }
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//		把触摸转换为场景里的坐标。
//		hitTest(_, options:) 发送光线跟踪到给定位置，并为光线跟踪线上的每个 node 返回一个 SCNHitTestResult 数组。
//		从SceneKit 的颗粒文件加载火球的颗粒系统。
//		然后将颗粒系统加载到空节点，并将其放在屏幕外面的底下。这使得后球看起来像来自玩家的位置。
//		如果检测到点击...
//		...等待一小段时间，然后删除包含敌人的 itemNode。同时把 发射器 node 移动到敌人的位置。
//		如果没有打中，火球只是移动到了固定的位置。
		
		//1
		let touch = touches.first!
		let location = touch.location(in: sceneView)
		
		//2
		let hitResult = sceneView.hitTest(location, options: nil)
		//3
		let fireBall = SCNParticleSystem(named: "Fireball.scnp", inDirectory: nil)
		
		//4
		let emitterNode = SCNNode()
		emitterNode.position = SCNVector3(x: 0, y: -5, z: 10)
		emitterNode.addParticleSystem(fireBall!)
		scene.rootNode.addChildNode(emitterNode)
		
		//5
		if hitResult.first != nil{
			//6
			target.itemNode?.runAction(SCNAction.sequence([SCNAction.wait(duration: 0.5), SCNAction.removeFromParentNode(), SCNAction.hide()]))
			
//			将发射器 node 的操作更改为序列，移动操作保持不变。
//			发射器移动后，暂停 3.5 秒。
//			然后通知代理目标被击中。
			//1
			let sequence = SCNAction.sequence(
				[SCNAction.move(to: target.itemNode!.position, duration: 0.5),
				 //2
					SCNAction.wait(duration: 3.5),
					//3
					SCNAction.run({_ in
						self.delegate?.viewController(controller: self, tappedTarget: self.target)
					})])
			emitterNode.runAction(sequence)
		
		} else {
			//7
			emitterNode.runAction(SCNAction.move(to: SCNVector3(x: 0, y: 0, z: -30), duration: 0.5))
		}
	}
	func setupTarget() {
//		首先把模型加载到场景里。target 的 itemDescription 用 .dae 文件的名字。
//		接下来，遍历场景，找到一个名为 itemDescription 的 node。只有一个具有此名称的 node，正好是模型的根 node。
//		然后调整位置，让两个模型出现在相同的位置上。如果这两个模型来自同一个设计器，可能不会需要这个步骤。然而，我使用了来自不同设计器的两个模型：狼来自 https://3dwarehouse.sketchup.com/，龙来自 https://clara.io 。
//		最后，将模型添加到空 node，然后把它分配给当前 target 的 itemNode 属性。这是一个小窍门，让下一节的触摸处理更简单一些
		
		//1
		let scene = SCNScene(named: "art.scnassets/\(target.itemDescription)")
		//2
		let enemy = scene?.rootNode.childNode(withName: target.itemDescription, recursively: true)
		//3
		if target.itemDescription == "dragon" {
			enemy?.position = SCNVector3(x: 0, y: -15, z: 0)
		}else {
			enemy?.position = SCNVector3(x: 0, y: 0, z: 0)
		}
		
		//4
		let node = SCNNode()
		node.addChildNode(enemy!)
		node.name = "敌人"

		self.target.itemNode = node
	}
	
	func repositionTarget() {
		
		//	1你会在下个步骤里实现这个方法，这就是用来计算当前位置到目标的朝向的。
		//	2然后计算设备当前朝向和位置朝向的增量值。如果增量小于 -15，显示左指示器 label。如果大于 15，显示右指示器 label。如果介于 -15 和 15 之间，把二者都隐藏，因为敌人应该在屏幕上了。
		//	3这里获取了设备位置到敌人的距离。
		//	4如果 item 已分配 node...
		//	5如果 node 没有 parent，使用 distance 设置位置，并且把 node 加到场景里。
		//	6否则，移除所有 action，然后创建一个新 action。
		
		//1
		let heading = getHeadingForDirectionFromCoordinate(from: userLocation, to: target.location)
		
		//2
		let delta = heading - self.heading
		
		if delta < -15.0 {
			leftIndicator.isHidden = false
			rightIndicator.isHidden = true
		} else if delta > 15 {
			leftIndicator.isHidden = true
			rightIndicator.isHidden = false
		} else {
			leftIndicator.isHidden = true
			rightIndicator.isHidden = true
		}
		
		//3
		let distance = userLocation.distance(from: target.location)
		
		//4
		if let node = target.itemNode {
			
			//5
			if node.parent == nil {
				node.position = SCNVector3(x: Float(delta), y: 0, z: Float(-distance))
				scene.rootNode.addChildNode(node)
			} else {
				//6
				node.removeAllActions()
				//SCNAction.move(to:, duration:) 创建了一个 action，把 node 移动到给定的位置，耗时也是给定的。runAction(_:) 是 SCNOde 的方法，执行了一个 action。你还可以创建 action 的组和/或序列。
				node.runAction(SCNAction.move(to: SCNVector3(x: Float(delta), y: 0, z: Float(-distance)), duration: 0.2))
			}
		}
	
	}
	func radiansToDegrees(_ radians: Double) -> Double {
		return (radians) * (180.0 / M_PI)
	}
	
	func degreesToRadians(_ degrees: Double) -> Double {
		return (degrees) * (M_PI / 180.0)
	}
	
	func getHeadingForDirectionFromCoordinate(from: CLLocation, to: CLLocation) -> Double {
		
//		首先，将经度和纬度的值转换为弧度。
//		使用这些值，计算朝向，然后将其转换回角度。
//		如果值为负，则添加 360 度使它为正。这没有错，因为 -90 度其实就是 270 度。
		
		//1
		let fLat = degreesToRadians(from.coordinate.latitude)
		let fLng = degreesToRadians(from.coordinate.longitude)
		let tLat = degreesToRadians(to.coordinate.latitude)
		let tLng = degreesToRadians(to.coordinate.longitude)
		
		//2
		let degree = radiansToDegrees(atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng)))
		
		//3
		if degree >= 0 {
			return degree
		} else {
			return degree + 360
		}
	}
	
	
	func loadCamera() {
		//	首先，调用上面创建的方法来获得 capture session。
		//	如果有错误，或者 captureSession 是 nil，就 return。再见了我的增强现实。
		//	如果一切正常，就在 cameraSession 里存储 capture session。
		//	这行尝试创建一个视频预览层；如果成功了，它会设置 videoGravity 以及把该层的 frame 设置为 view 的 bounds。这样会给用户一个全屏预览。
		//	最后，将该层添加为子图层，然后将其存储在 cameraLayer 中。
		//1
		let captureSessionResult = createCaptureSession()
		
		//2
		guard captureSessionResult.error == nil,let session = captureSessionResult.session else{
			print("Error creating capture session")
			return
		}
		
		//3
		self.cameraSession = session
		
		//4
		if let cameraLayer = AVCaptureVideoPreviewLayer(session: self.cameraSession) {
			cameraLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
			cameraLayer.frame = self.view.bounds
			
			//5
			self.view.layer.insertSublayer(cameraLayer, at: 0)
			self.cameraLayer = cameraLayer
		}
	}
	
	
//	1创建了几个变量，用于方法返回。
//	2获取设备的后置摄像头。
//	3如果摄像头存在，获取它的输入。
//	4创建 AVCaptureSession 的实例。
//	5将视频设备加为输入。
//	6返回一个元组，包含 captureSession 或是 error。
	func createCaptureSession() -> (session: AVCaptureSession?,error: NSError?) {
		//1
		var error: NSError?
		var captureSession:AVCaptureSession?
		
		//2
		let backVideoDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back)
		//3
		if backVideoDevice != nil {
			var videoInput: AVCaptureDeviceInput!
			do {
				videoInput = try AVCaptureDeviceInput(device: backVideoDevice)
			} catch let error1 as NSError {
				error = error1
				videoInput = nil
			}
			
			//4
			if error == nil {
				captureSession = AVCaptureSession()
				
				//5
				if captureSession!.canAddInput(videoInput) {
					captureSession!.addInput(videoInput)
				} else {
					error = NSError(domain: "", code: 0, userInfo: ["description": "Error adding video input."])
				}
			}else {
				error = NSError(domain: "", code: 1, userInfo: ["description": "Error creating capture device input."])
			}
			
		}else {
			error = NSError(domain: "", code: 2, userInfo: ["description": "Back video device not found."])
		}
		//6
		return (session: captureSession, error: error)
		
	 }
}
extension ViewController: CLLocationManagerDelegate {
	func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
		
		//fmod 是 double 值的模数函数，确保朝向在 0 到 359 内
		self.heading = fmod(newHeading.trueHeading, 360.0)
		
		repositionTarget()
	}
}
