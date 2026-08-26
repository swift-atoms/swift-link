import Index

extension Link {

    public struct Header<Tag: ~Copyable & ~Escapable>: Copyable, Sendable {

        public var head: Index<Tag>

        public var tail: Index<Tag>

        public var count: Index<Tag>.Count

        public let sentinel: Index<Tag>

        @inlinable
        public init(sentinel: Index<Tag>) {
            self.head = sentinel
            self.tail = sentinel
            self.count = .zero
            self.sentinel = sentinel
        }
    }
}
