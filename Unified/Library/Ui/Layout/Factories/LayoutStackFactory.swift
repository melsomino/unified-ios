//
// Created by Власов М.Ю. on 16.06.16.
// Copyright (c) 2016 melsomino. All rights reserved.
//

import Foundation


class LayoutStackFactory: LayoutItemFactory {
	let direction: LayoutStackDirection
	var along = LayoutAlignment.Fill
	var across = LayoutAlignment.Leading
	var spacing = CGFloat(0)


	init(direction: LayoutStackDirection) {
		self.direction = direction
		along = direction == .Horizontal ? .Fill : .Leading
		across = direction == .Horizontal ? .Leading : .Fill
	}


	override func create() -> LayoutItem {
		return LayoutStack()
	}

	override func apply(item: LayoutItem, _ content: [LayoutItem]) {
		let stack = item as! LayoutStack
		stack.direction = direction
		stack.along = along
		stack.across = across
		stack.spacing = spacing
		stack.content = content
	}


	override func applyMarkupAttributeWithName(name: String, value: MarkupValue) throws {
		switch name {
			case "along":
				along = try value.getEnum(LayoutItemFactory.alignments)
			case "across":
				across = try value.getEnum(LayoutItemFactory.alignments)
			case "spacing":
				spacing = try value.getFloat()
			default:
				try super.applyMarkupAttributeWithName(name, value: value)
		}
	}

}

