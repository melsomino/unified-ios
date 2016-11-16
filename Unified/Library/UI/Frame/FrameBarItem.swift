//
// Created by Власов М.Ю. on 16.11.16.
//

import Foundation
import UIKit


class FrameBarItem {
	func create(frame: FrameBuilder) -> UIBarButtonItem {
		return UIBarButtonItem()
	}



	static func from(element: DeclarationElement, context: DeclarationContext) throws -> FrameBarItem {
		switch element.name {
			case "menu":
				return FrameBarMenuItem()
			case "system":
				return try FrameBarSystemItem(element: element, context: context)
			case "button":
				return try FrameBarButtonItem(element: element, context: context)
			case "fragment":
				return try FrameBarFragmentItem(element: element, context: context)
			default:
				break
		}
		throw DeclarationError("Invalid navigation bar item definition", element, context)
	}
}



class FrameBarMenuItem: FrameBarItem {
	override func create(frame: FrameBuilder) -> UIBarButtonItem {
		if let centralUi = frame.optionalCentralUI {
			return centralUi.createMenuIntegrationBarButtonItem()
		}
		return super.create(frame: frame)
	}
}



class FrameBarButtonItem: FrameBarItem {
	let action: DynamicBindings.Expression?
	let image: UIImage?
	let title: DynamicBindings.Expression?

	init(element: DeclarationElement, context: DeclarationContext) throws {
		var image: UIImage?
		var action: DynamicBindings.Expression?
		var title: DynamicBindings.Expression?
		for attribute in element.attributes[1 ..< element.attributes.count] {
			switch attribute.name {
				case "action":
					action = try context.getExpression(attribute)
				case "image":
					image = try context.getImage(attribute)
				case "title":
					title = try context.getExpression(attribute)
				default:
					break
			}
		}
		self.action = action
		self.image = image
		self.title = title
	}



	override func create(frame: FrameBuilder) -> UIBarButtonItem {
		let target = frame.target(action: action)
		if let image = image {
			return UIBarButtonItem(image: image, style: .plain, target: target, action: frame.action)
		}
		return UIBarButtonItem(title: frame.evaluate(title), style: .plain, target: target, action: frame.action)
	}
}



class FrameBarFragmentItem: FrameBarItem {

	init(element: DeclarationElement, context: DeclarationContext) throws {
	}



	override func create(frame: FrameBuilder) -> UIBarButtonItem {
		return UIBarButtonItem(barButtonSystemItem: .action, target: nil, action: nil)
	}
}



class FrameBarSystemItem: FrameBarItem {
	let systemItem: UIBarButtonSystemItem
	let action: DynamicBindings.Expression?

	init(element: DeclarationElement, context: DeclarationContext) throws {
		var systemItem: UIBarButtonSystemItem?
		var action: DynamicBindings.Expression?
		for attribute in element.attributes[1 ..< element.attributes.count] {
			if attribute.value.isMissing, let item = FrameBarSystemItem.systemItemByName[attribute.name] {
				systemItem = item
			}
			else if attribute.name == "action" {
				action = try context.getExpression(attribute)
			}
		}
		guard systemItem != nil else {
			throw DeclarationError("Invalid navigation bar item definition", element, context)
		}
		self.systemItem = systemItem!
		self.action = action
	}



	override func create(frame: FrameBuilder) -> UIBarButtonItem {
		return UIBarButtonItem(barButtonSystemItem: systemItem, target: frame.target(action: action), action: frame.action)
	}



	static let systemItemByName: [String: UIBarButtonSystemItem] = [
		"done": .done,
		"cancel": .cancel,
		"edit": .edit,
		"save": .save,
		"add": .add,
		"flexible-space": .flexibleSpace,
		"fixed-space": .fixedSpace,
		"compose": .compose,
		"reply": .reply,
		"action": .action,
		"organize": .organize,
		"bookmarks": .bookmarks,
		"search": .search,
		"refresh": .refresh,
		"stop": .stop,
		"camera": .camera,
		"trash": .trash,
		"play": .play,
		"pause": .pause,
		"rewind": .rewind,
		"fast-forward": .fastForward,
		"undo": .undo,
		"redo": .redo,
		"page-curl": .pageCurl,
	]
}

