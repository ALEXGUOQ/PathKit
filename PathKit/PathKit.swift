// PathKit - Effortless path operations

import Foundation

/// Represents a filesystem path.
public struct Path : Equatable, Hashable, Printable, StringLiteralConvertible, ExtendedGraphemeClusterLiteralConvertible, UnicodeScalarLiteralConvertible {
    public static let separator = "/"

    private var path:String

    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public static func convertFromExtendedGraphemeClusterLiteral(value: ExtendedGraphemeClusterLiteralType) -> Path {
        return self(value)
    }

    public typealias UnicodeScalarLiteralType = StringLiteralType
    public static func convertFromUnicodeScalarLiteral(value: UnicodeScalarLiteralType) -> Path {
        return self(value)
    }

    public static func convertFromStringLiteral(value: StringLiteralType) -> Path {
        return self(value)
    }

    // Returns the current working directory
    public static var current:Path {
        get {
            return self(NSFileManager().currentDirectoryPath)
        }
        set {
            NSFileManager().changeCurrentDirectoryPath(newValue.description)
        }
    }

    // MARK: Init

    public init() {
        self.path = ""
    }

    public init(_ path:String) {
        self.path = path
    }

    public init(components:[String]) {
        path = join(Path.separator, components)
    }

    public init(stringLiteral value: StringLiteralType) {
        path = value
    }

    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        path = value
    }

    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        path = value
    }

    // MARK: Printable

    public var description:String {
        return self.path
    }

    public var hashValue:Int {
        return path.hashValue
    }

    /** Method for testing whether a path is absolute.
    :return: true if the pathname begings with a slash
    */
    public func isAbsolute() -> Bool {
        return path.hasPrefix(Path.separator)
    }

    public func isDirectory() -> Bool {
        var directory = ObjCBool(false)
        return NSFileManager().fileExistsAtPath(path, isDirectory: &directory) && directory.boolValue
    }

    /// Returns true if a path is relative (not absolute)
    public func isRelative() -> Bool {
        return !isAbsolute()
    }

    /// Returns the absolute path in the actual filesystem
    public func absolute() -> Path {
        if isAbsolute() {
            return normalize()
        }

        return (Path.current + self).normalize()
    }

    /// Normalizes the path, this clenas up redundant ".." and "." and double slashes
    public func normalize() -> Path {
        return Path(self.path.stringByStandardizingPath)
    }

    /// Returns whether a file or directory exists at a specified path
    public func exists() -> Bool {
        return NSFileManager().fileExistsAtPath(self.path)
    }

    public func delete() -> Bool {
        return NSFileManager().removeItemAtPath(self.path, error: nil)
    }

    public func move(destination:Path) -> Bool {
        return NSFileManager().moveItemAtPath(self.path, toPath: destination.path, error: nil)
    }

    public func chdir(block:(() -> ())) {
        let previous = Path.current
        Path.current = self
        block()
        Path.current = previous
    }

    // MARK: Contents

    public func read() -> NSData? {
        return NSFileManager.defaultManager().contentsAtPath(self.path)
    }

    public func read() -> String? {
        if let data:NSData = read() {
            return NSString(data:data, encoding: NSUTF8StringEncoding)
        }

        return nil
    }

    public func write(data:NSData) -> Bool {
        return data.writeToFile(path, atomically: true)
    }

    public func write(string:String) -> Bool {
        if let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) {
            return write(data)
        }

        return false
    }

    // MARK: Children

    public func children(directories:Bool = true) -> [Path] {
        let manager = NSFileManager()
        if let contents = manager.contentsOfDirectoryAtPath(path, error: nil) as? [String] {
            let paths = contents.map {
                self + Path($0)
            }

            if directories {
                return paths
            }

            return paths.filter { !$0.isDirectory() }
        }
        return []
    }

}

public func ==(lhs: Path, rhs: Path) -> Bool {
    return lhs.path == rhs.path
}

public func +(lhs: Path, rhs: Path) -> Path {
    switch (lhs.path.hasSuffix(Path.separator), rhs.path.hasPrefix(Path.separator)) {
        case (true, true):
            return Path("\(lhs.path)\(rhs.path.substringFromIndex(rhs.path.startIndex.successor()))")
        case (false, false):
            return Path("\(lhs.path)\(Path.separator)\(rhs.path)")
        default:
            return Path("\(lhs.path)\(rhs.path)")
    }
}

