//
// Created by Michael Vlasov on 13.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public protocol Execution {
	var cancelled: Bool { get }
	func continueOnUiQueue(_ action: @escaping () -> Void)
	func continueInBackground(_ action: @escaping () -> Void)
	func onCancel(_ handler: @escaping () -> Void)

	func reportComplete()
}
