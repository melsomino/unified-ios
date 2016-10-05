//
// Created by Michael Vlasov on 17.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import GRDB

open class DefaultDatabaseSelectStatement : DefaultDatabaseStatement, DatabaseSelectStatement {


	init(_ platformStatement: SelectStatement) {
		super.init(platformStatement)
	}

	// MARK: - DatabaseSelectStatement

	open func execute() throws -> DatabaseReader {
		return DefaultDatabaseReader(try executeSelect())
	}



}
