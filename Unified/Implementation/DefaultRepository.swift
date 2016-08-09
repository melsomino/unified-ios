// Created by Michael Vlasov on 20.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit
import Starscream





public class DefaultRepository: Repository, Dependent, WebSocketDelegate, CentralUIDependent {


	// MARK: - Repository

	public func load(repository name: String) throws -> [DeclarationElement] {
		return try load(repository: name, from: NSBundle.mainBundle())
	}

	public func load(repository name: String, forType type: Any.Type) throws -> [DeclarationElement] {
		return try load(repository: name, from: bundle(forType: type))
	}

	public func load(declarations name: String, fromModuleWithType type: Any.Type) throws -> [DeclarationElement] {
		let repositoryBundle = bundle(forType: type)
		var declarations = [DeclarationElement]()
		for uniPath in repositoryBundle.pathsForResourcesOfType(".uni", inDirectory: nil) {
			let elements = try DeclarationElement.load(uniPath)
			for declaration in elements.filter({ $0.name == name }) {
				declarations.append(declaration)
			}
		}
		return declarations
	}


	public func fragmentDefinition(forModelType modelType: Any.Type, name: String?) throws -> FragmentDefinition {
		let fragmentName = makeFragmentName(forModelType: modelType, name: name)

		lock.lock()
		defer {
			lock.unlock()
		}

		if let factory = fragmentDefinitionByName[fragmentName] {
			return factory
		}
		try loadRepositoriesInBundle(forType: modelType)
		if let factory = fragmentDefinitionByName[fragmentName] {
			return factory
		}
		fatalError("Repository does not contains fragment definition: \(fragmentName)")
	}


	public var devServerUrl: NSURL? {
		didSet {
			devServerConnection?.disconnect()
			devServerConnection = nil
			if let url = devServerUrl {
				devServerConnection = WebSocket(url: url)
				devServerConnection!.delegate = self
				devServerConnection!.connect()
			}
		}
	}

	public func addListener(listener: RepositoryListener) {
		listeners.add(listener)
	}


	public func removeListener(listener: RepositoryListener) {
		listeners.remove(listener)
	}


	public var dependency: DependencyResolver!


	// MARK: - DevServer WebSocket Delegate


	public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
		let parts = text.componentsSeparatedByString("`")
		switch parts[0] {
			case "repository-changed":
				socket.writeString("get-repository`\(parts[1])")
			case "repository":
				do {
					try loadRepositoryFromDevServer(parts[0], repositoryString: parts[1])
					notify()
				}
					catch let error {
					optionalCentralUI?.pushAlert(.error, message: String(error))
					print(error)
				}
			default:
				break
		}
	}


	public func websocketDidConnect(socket: WebSocket) {
		let device = UIDevice.currentDevice()
		socket.writeString("client-info`\(device.name), iOS \(device.systemVersion)")
		print("dev server connected")
	}


	public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
		print("dev server disconnected, trying to reconnet after 1 second...")
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_MSEC * 1000)), dispatch_get_main_queue()) {
			[weak self] in
			self?.devServerConnection?.connect()
		}
	}


	public func websocketDidReceiveData(socket: WebSocket, data: NSData) {
	}


	// MARK: - Internals

	private var devServerConnection: WebSocket?

	private var listeners = ListenerList<RepositoryListener>()
	private var loadedUniPaths = Set<String>()
	private var fragmentDefinitionByName = [String: FragmentDefinition]()
	private var lock = FastLock()


	private func makeTypeName(forType type: Any.Type) -> String {
		return String(reflecting: type)
	}


	private func makeFragmentName(forModelType modelType: Any.Type, name: String?) -> String {
		let modelTypeName = makeTypeName(forType: modelType)
		return name != nil ? "\(modelTypeName).\(name!)" : modelTypeName
	}


	private func notify() {
		for listener in listeners.getLive() {
			listener.repositoryChanged(self)
		}
	}


	private func loadRepositoryFromDevServer(repositoryName: String, repositoryString: String) throws {
		lock.lock()
		defer {
			lock.unlock()
		}
		var elements: [DeclarationElement]
		let context = DeclarationContext(repositoryName)
		do {
			elements = try DeclarationElement.parse(repositoryString)
		}
			catch let error as ParseError {
			throw DeclarationError(error, context)
		}
		try loadRepository(elements, context: context, overrideExisting: true)
	}


	func loadRepositoriesInBundle(forType type: Any.Type) throws {
		let typeName = makeTypeName(forType: type)
		let typeNameParts = typeName.componentsSeparatedByString(".")
		let bundle = typeNameParts.count > 1 ? NSBundle.fromModuleName(typeNameParts[0])! : NSBundle(forClass: type as! AnyClass)

		for uniPath in bundle.pathsForResourcesOfType(".uni", inDirectory: nil) {
			guard !loadedUniPaths.contains(uniPath) else {
				continue
			}
			loadedUniPaths.insert(uniPath)
			var elements: [DeclarationElement]
			let context = DeclarationContext((uniPath as NSString).lastPathComponent)
			do {
				elements = try DeclarationElement.load(uniPath)
			}
				catch let error as ParseError {
				throw DeclarationError(error, context)
			}
			try loadRepository(elements, context: context, overrideExisting: false)
		}
	}


	func loadRepository(elements: [DeclarationElement], context: DeclarationContext, overrideExisting: Bool) throws {
		for fragmentsSection in elements.filter({ $0.name == "ui" || $0.name == "fragment" }) {
			for fragment in fragmentsSection.children {
				if overrideExisting || fragmentDefinitionByName[fragment.name] == nil {
					let fragmentDefinition = try FragmentDefinition.fromDeclaration(fragment, context: context)
					fragmentDefinitionByName[fragment.name] = fragmentDefinition
				}
			}
		}

	}



	private func bundle(forType type: Any.Type) -> NSBundle {
		let typeName = makeTypeName(forType: type)
		let typeNameParts = typeName.componentsSeparatedByString(".")
		return typeNameParts.count > 1 ? NSBundle.fromModuleName(typeNameParts[0])! : NSBundle(forClass: type as! AnyClass)
	}




	private func load(repository name: String, from bundle: NSBundle) throws -> [DeclarationElement] {
		let context = DeclarationContext("[\(name).uni] in bundle [\(bundle.bundleIdentifier ?? "")]")
		guard let path = bundle.pathForResource(name, ofType: ".uni") else {
			throw DeclarationError("Unable to locate unified repository", context)
		}
		do {
			return try DeclarationElement.load(path)
		}
			catch let error as ParseError {
			throw DeclarationError(error, context)
		}
	}



}





extension DependencyContainer {
	public func createDefaultRepository() {
		register(RepositoryDependency, DefaultRepository())
	}
}