//
//  SymbolicLinks.swift
//  FileSmith
//
//  Created by Kåre Morstøl on 10/01/2017.
//  Copyright © 2017 FileSmith. All rights reserved.
//

import Foundation

extension File {

	/// Creates a symbolic link at 'newlink' pointing to the file at 'target'.
	///
	/// - Parameters:
	///   - newlink: The path to the new symbolic link.
	///   - target: The file the new link should point to.
	///   - ifExists: What to do if there already is something at newlink: open, throw error or replace.
	/// - Throws: FileSystemError.isDirectory, .alreadyExists, .outsideSandbox, .invalidAccess.
	public init<TargetFile:File>(createSymbolicLink newlink: FilePath, to target: TargetFile, ifExists: AlreadyExistsOptions) throws {
		if let newlinktype = FileType(newlink) {
			guard newlinktype != .directory else { throw FileSystemError.isDirectory(path: DirectoryPath(newlink)) }
			switch ifExists {
			case .throwError:
				throw FileSystemError.alreadyExists(path: newlink)
			case .replace:
				try newlink.verifyIsInSandbox()
				try FileManager().removeItem(atPath: newlink.absoluteString)
			case .open:
				let currenttarget = try FilePath(FileManager().destinationOfSymbolicLink(atPath: newlink.absoluteString))
				// if currenttarget is relative, its base is the directory of newlink.
				let currenttargetabsolutepath = currenttarget.relativeComponents.map(newlink.parent().append) ?? currenttarget
				guard target.path.absolute == currenttargetabsolutepath else {
					throw FileSystemError.invalidAccess(path: newlink, writing: true)
				}
				try self.init(open: newlink)
				return
			}
		}
		try newlink.verifyIsInSandbox()
		try FileManager().createSymbolicLink(atPath: newlink.absoluteString, withDestinationPath: target.path.absoluteString)
		try self.init(open: newlink)
	}
}

extension Directory {

	/// Creates a symbolic link at 'newlink' pointing to the directory at 'target'.
	///
	/// - Parameters:
	///   - newlink: The path to the new symbolic link.
	///   - target: The directory the new link should point to.
	///   - ifExists: What to do if there already is something at newlink: open, throw error or replace.
	/// - Throws: FileSystemError.notDirectory, .alreadyExists, .outsideSandbox, .invalidAccess.
	public convenience init(createSymbolicLink newlink: DirectoryPath, to target: Directory, ifExists: AlreadyExistsOptions) throws {
		if let newlinktype = FileType(newlink) {
			guard newlinktype == .directory else { throw FileSystemError.notDirectory(path: FilePath(newlink)) }
			switch ifExists {
			case .throwError:
				throw FileSystemError.alreadyExists(path: newlink)
			case .replace:
				try newlink.verifyIsInSandbox()
				try FileManager().removeItem(atPath: newlink.absoluteString)
			case .open:
				let currenttarget = try DirectoryPath(FileManager().destinationOfSymbolicLink(atPath: newlink.absoluteString))
				// if currenttarget is relative, its base is the directory of newlink.
				let currenttargetabsolutepath = currenttarget.relativeComponents.map(newlink.parent().append) ?? currenttarget
				guard target.path.absolute == currenttargetabsolutepath else {
					throw FileSystemError.invalidAccess(path: newlink, writing: true)
				}
				try self.init(open: newlink)
				return
			}
		}
		try newlink.verifyIsInSandbox()
		try FileManager().createSymbolicLink(atPath: newlink.absoluteString, withDestinationPath: target.path.absoluteString)
		try self.init(open: newlink)
	}
}

extension Directory {

	/// Creates a symbolic link at 'newlink' pointing to the directory at 'target'.
	///
	/// - Parameters:
	///   - newlink: The path to the new symbolic link, relative to this directory.
	///   - target: The directory the new link should point to.
	///   - ifExists: What to do if there already is something at newlink: open, throw error or replace.
	/// - Throws: FileSystemError.notDirectory, .alreadyExists, .outsideSandbox, .invalidAccess.
	@discardableResult
	public func create(symbolicLink newlink: String, to target: Directory, ifExists: AlreadyExistsOptions) throws -> Directory {
		let newpath = self.path.append(directory: newlink)
		return try Directory(createSymbolicLink: newpath, to: target, ifExists: ifExists)
	}

	/// Creates a symbolic link at 'newlink' pointing to the file at 'target'.
	///
	/// - Parameters:
	///   - newlink: The path to the new symbolic link, relative to this directory.
	///   - target: The file the new link should point to.
	///   - ifExists: What to do if there already is something at newlink: open, throw error or replace.
	/// - Throws: FileSystemError.isDirectory, .alreadyExists, .outsideSandbox, .invalidAccess.
	@discardableResult
	public func create<NewFile:File, TargetFile:File>(symbolicLink newlink: String, to target: TargetFile, ifExists: AlreadyExistsOptions) throws -> NewFile {
		let newpath = self.path.append(file: newlink)
		return try NewFile(createSymbolicLink: newpath, to: target, ifExists: ifExists)
	}
}
