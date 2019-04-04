//
//  Primitives.swift
//  Spherical
//
//  Created by Deirdre Saoirse Moen on 10/25/18.
//  Copyright © 2018 Deirdre Saoirse Moen. All rights reserved.
//

import Foundation
import SceneKit
import CoreData

class PrimitivesScene : SCNScene, SCNSceneRendererDelegate {
	
	// TODO: break this out where it makes sense to.

	var vc : ViewController?

	let mainSphereRadius : CGFloat = 2.0 // radius
	let littleSphereRadius : CGFloat = 0.075
	let favesSphereRadius : CGFloat = 0.000075
	let cameraNode = SCNNode()          // the camera
	private var shadowColors: [ShadowColor] = []
	let makerAnimationDuration : Double = 8.0
	
	var currentMaker = 0
	
	var prefsInfo = [ColorMeta]()

	override init() {
		super.init()
		
		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
			return
		}
		
		let moc = appDelegate.persistentContainer.viewContext
		
		
		let colorFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ShadowColor")
		let ratingSort = NSSortDescriptor(key: "predictedRating", ascending: false)
		colorFetchRequest.sortDescriptors = [ratingSort]
		
		do {
			shadowColors = try (moc.fetch(colorFetchRequest) as? [ShadowColor])!
		} catch let error as NSError {
			print("Could not fetch. \(error), \(error.userInfo)")
		}
		
		// make ten nodes for animating and titles
		
		for index in 0..<10 {

			let sphereGeometry = SCNSphere(radius: favesSphereRadius)
			sphereGeometry.firstMaterial!.diffuse.contents = UIColor.black
			let prefsNode = SCNNode(geometry: sphereGeometry)
			prefsNode.opacity = 0.0 // start transparent
			prefsNode.position = SCNVector3(x: 0.0, y: 0.0, z: 0.0)

			let startIndex = index * (shadowColors.count / 10)
			var endIndex = (index + 1) * (shadowColors.count / 10) - 1
			endIndex = endIndex >= shadowColors.count ? shadowColors.count - 1 : endIndex
			
			let percentFormatter = NumberFormatter()
			percentFormatter.numberStyle = NumberFormatter.Style.percent
			percentFormatter.minimumFractionDigits = 1
			percentFormatter.maximumFractionDigits = 1
			
			let higher = percentFormatter.string(for: shadowColors[startIndex].predictedRating/10.0)!
			let lower = percentFormatter.string(for: shadowColors[endIndex].predictedRating/10.0)!
			
			let title = "Predicted: \(lower) to \(higher)"
			
			// TODO: need better criteria for picking a readable text color.
			
			rootNode.addChildNode(prefsNode)
			let m = ColorMeta(title: title, mainNode: prefsNode, colorNodes: [], titleColor: UIColor.white, startIndex: startIndex)
			prefsInfo.append(m)
			
			for sIndex in startIndex...endIndex {
				attachColorToBucket(shadowColors[sIndex], prefsNode: prefsNode)
			}
		}
		
		rotateSphere() // Attach the animation to the node to start it.
		
		scheduleMakerAnimations()
	}

	// TODO: required initializer that should be fleshed out
	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func attachColorToBucket(_ shadowColor: ShadowColor, prefsNode: SCNNode) {

		// calculate geometry and position
		let sphereGeometry = SCNSphere(radius: littleSphereRadius)

		// add color
		
		sphereGeometry.firstMaterial!.diffuse.contents = UIColor.init(hue: CGFloat(shadowColor.hue), saturation: CGFloat(shadowColor.saturation), brightness: CGFloat(shadowColor.brightness), alpha: 1.0)
		sphereGeometry.firstMaterial!.lightingModel = .phong // TODO: pretty sure Phong isn't the right answer, but it's a first approximation
		
		// add geometry to sphere

		let sphereNode = SCNNode(geometry: sphereGeometry)
		sphereNode.position = calcPosition(shadowColor)
		
		// add to maker SCNNode
		
		prefsNode.addChildNode(sphereNode)
	}
	
	func calcPosition(_ shadowColor: ShadowColor) -> SCNVector3 {

		// precalculated when color was added to CoreData, but that could change if desired
		
		let vector = SCNVector3(x: Float(shadowColor.x), y: Float(shadowColor.y), z: Float(shadowColor.z))
		
		return vector
	}
	
	
	// MARK: Animation-fu

	func setMakerTitle() {
		
	}
	
	func animateMakerNode(makerNode: SCNNode, index: Int) {
		
		// TODO: make this into a transaction and add a repeat.
//		let _ = SCNTransaction()
		makerNode.runAction(SCNAction.wait(duration: makerAnimationDuration * Double(index)))

		makerNode.runAction(SCNAction.sequence([SCNAction.fadeIn(duration: makerAnimationDuration/4.0),
					SCNAction.wait(duration: makerAnimationDuration/2.0),
					SCNAction.fadeOut(duration: makerAnimationDuration/4.0),
					]))
	}


	func scheduleMakerAnimations() {

		for index in 0..<prefsInfo.count {

			let twinkleNode = prefsInfo[index].mainNode

			twinkleNode.runAction(SCNAction.sequence(
				[SCNAction.wait(duration: makerAnimationDuration * Double(index)),
				 SCNAction.run({ (node) in
		
					let titleText = (self.prefsInfo[index]).title
					let titleTextColor = (self.prefsInfo[index]).titleColor

					DispatchQueue.main.async {
						self.vc?.bucketNameLabel.text = titleText
						self.vc?.bucketNameLabel.textColor = titleTextColor
					}
				}),

				 SCNAction.fadeIn(duration: makerAnimationDuration/4.0),
				 SCNAction.wait(duration: makerAnimationDuration/2.0),
				 SCNAction.fadeOut(duration: makerAnimationDuration/4.0),
				 ]))

			twinkleNode.runAction(SCNAction.sequence(
				[SCNAction.wait(duration: makerAnimationDuration * Double(index)),

				 SCNAction.fadeIn(duration: makerAnimationDuration/4.0),
				 SCNAction.wait(duration: makerAnimationDuration/2.0),
				 SCNAction.fadeOut(duration: makerAnimationDuration/4.0),
				 ]))

		}
	}

	// spin the whole thing around
	fileprivate func rotateSphere() {
		// rotate the root node
		
		let action = SCNAction.repeatForever(SCNAction.rotate(by: -1*(.pi), around: SCNVector3(0, 1, 0), duration: makerAnimationDuration))
		rootNode.runAction(action)
	}
}
