@_exported public import Cardinal_Standard_Library_Integration
@_exported public import Link
@_exported public import Ordinal_Standard_Library_Integration
@_exported public import Tagged_Standard_Library_Integration
@_exported public import Ordinal
@_exported public import Tagged

@inlinable
public func == <Tag: ~Copyable & ~Escapable>(
    lhs: borrowing Index<Tag>,
    rhs: borrowing Index<Tag>
) -> Bool {
    lhs.underlying.rawValue == rhs.underlying.rawValue
}
