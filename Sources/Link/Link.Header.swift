public import Cardinal
public import Index

extension Link {

    public struct Header<Tag: ~Copyable & ~Escapable>: Copyable, Sendable {

        public var head: Index<Tag>

        public var tail: Index<Tag>

        public var count: Cardinal

        public let sentinel: Index<Tag>

        @inlinable
        public init(sentinel: Index<Tag>) {
            self.head = sentinel
            self.tail = sentinel
            self.count = Cardinal(0)
            self.sentinel = sentinel
        }
    }
}
