//
// Created by Власов М.Ю. on 15.06.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation
import UIKit




public class TableUi: NSObject, RepositoryDependent, RepositoryListener, UITableViewDataSource, UITableViewDelegate {


	public lazy var tableView: UITableView = {
		[unowned self] in return self.createTableView()
	}()





	public func registerModelUi<Model>(ui: () -> ModelUi<Model>) {
		let registration = ModelUiRegistration<Model>(dependency: dependency, uiFactory: ui)
		tableView.registerClass(LayoutTableCell.self, forCellReuseIdentifier: registration.cellReuseId)
		registrations.append(registration)
	}





	public func setModels(models: [Any]) {
		self.models = models
		tableView.reloadData()
	}


	public var dependency: DependencyResolver! {
		didSet {
			repository.addListener(self)
		}
	}

	public func repositoryChanged(repository: Repository) {
		tableView.reloadData()
	}


	// MARK: - Table View DataSource and Delegate


	public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return models.count
	}





	public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let model = models[indexPath.row]
		let registration = requiredRegistration(model)
		let cell = tableView.dequeueReusableCellWithIdentifier(registration.cellReuseId, forIndexPath: indexPath) as! LayoutTableCell
		if cell.ui == nil {
			cell.ui = registration.createUi(dependency)
			cell.ui.container = cell.contentView
		}
		registration.setModel(model, inUi: cell.ui)
		cell.ui.performLayout(inBounds: cell.contentView.bounds.size)
		return cell
	}





	public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		let model = models[indexPath.row]
		return requiredRegistration(model).heightFor(model, inWidth: tableView.bounds.width)
	}


	// MARK: - Internals


	private var registrations = [ModelUiRegistrationEntry]()
	private var models: [Any]!





	private func requiredRegistration(model: Any) -> ModelUiRegistrationEntry {
		for registration in registrations {
			if registration.supports(model) {
				return registration
			}
		}
		fatalError("Layout registration not found for type: \(model.dynamicType)")
	}





	private func createTableView() -> UITableView {
		let tableView = UITableView()
		tableView.dataSource = self
		tableView.delegate = self
		return tableView
	}
}





class LayoutTableCell: UITableViewCell {

	override func layoutSubviews() {
		super.layoutSubviews()
		ui?.performLayout(inBounds: contentView.bounds.size)
	}

	var ui: Ui!
}





private protocol ModelUiRegistrationEntry {
	var cellReuseId: String { get }


	func supports(model: Any) -> Bool
	func createUi(dependency: DependencyResolver) -> Ui
	func setModel(model: Any, inUi ui: Ui)
	func heightFor(model: Any, inWidth width: CGFloat) -> CGFloat
}





private class ModelUiRegistration<Model>: ModelUiRegistrationEntry {
	let uiFactory: () -> ModelUi<Model>
	let heightCalculator: ModelUi<Model>
	let cellReuseId: String


	init(dependency: DependencyResolver, uiFactory: () -> ModelUi<Model>) {
		cellReuseId = String(Model.Type)
		self.uiFactory = uiFactory
		heightCalculator = uiFactory()
		dependency.resolve(heightCalculator)
	}

	func supports(model: Any) -> Bool {
		return model is Model
	}


	func createUi(dependency: DependencyResolver) -> Ui {
		let ui = uiFactory()
		dependency.resolve(ui)
		return ui
	}


	func setModel(model: Any, inUi ui: Ui) {
		(ui as! ModelUi<Model>).model = (model as! Model)
	}


	func heightFor(model: Any, inWidth width: CGFloat) -> CGFloat {
		heightCalculator.model = model as? Model
		heightCalculator.performLayout(inWidth: width)
		return heightCalculator.frame.height
	}

}