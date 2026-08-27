import Index

@frozen
public struct __LinkNode<let N: Int, Element: ~Copyable>: ~Copyable {

    public var links: InlineArray<N, Index<__LinkNode<N, Element>>>

    public var element: Element

    @inlinable

    public init(links: InlineArray<N, Index<__LinkNode<N, Element>>>, element: consuming Element) {
        self.links = links
        self.element = element
    }
}

extension __LinkNode: Copyable where Element: Copyable {}
extension __LinkNode: Sendable where Element: Sendable {}
