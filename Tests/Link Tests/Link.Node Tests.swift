import Cardinal
import Index
import Link_Test_Support
import Ordinal
import Tagged
import Testing

@Suite
struct `Link nodes retain mutable links and element payloads` {
    @Suite struct `Link node construction and mutation preserve links and payloads` {}
    @Suite struct `Link nodes preserve string payloads` {}
    @Suite struct `No link node integration cases are defined` {}
}

extension `Link nodes retain mutable links and element payloads`.`Link node construction and mutation preserve links and payloads` {

    @Test
    func `init stores links and element`() {
        let sentinel: Index<Link<2>.Node<Int>> = 99
        let links = InlineArray<2, Index<Link<2>.Node<Int>>>(repeating: sentinel)
        let node = Link<2>.Node(links: links, element: 42)

        #expect(node.element == 42)
        #expect(node.links[0] == sentinel)
        #expect(node.links[1] == sentinel)
    }

    @Test
    func `links are mutable`() {
        let sentinel: Index<Link<2>.Node<Int>> = 99
        let links = InlineArray<2, Index<Link<2>.Node<Int>>>(repeating: sentinel)
        var node = Link<2>.Node(links: links, element: 10)

        node.links[0] = 1
        node.links[1] = 2

        #expect(node.links[0] == 1)
        #expect(node.links[1] == 2)
    }

    @Test
    func `element is mutable`() {
        let sentinel: Index<Link<2>.Node<Int>> = 99
        let links = InlineArray<2, Index<Link<2>.Node<Int>>>(repeating: sentinel)
        var node = Link<2>.Node(links: links, element: 0)

        node.element = 77

        #expect(node.element == 77)
    }

    @Test
    func `A singly linked node preserves its link and element`() {
        let sentinel: Index<Link<1>.Node<Int>> = 99
        let links = InlineArray<1, Index<Link<1>.Node<Int>>>(repeating: sentinel)
        let node = Link<1>.Node(links: links, element: 5)

        #expect(node.element == 5)
        #expect(node.links[0] == sentinel)
    }
}

extension `Link nodes retain mutable links and element payloads`.`Link node construction and mutation preserve links and payloads` {

    @Test
    func `Link N Node Element spelling constructs and behaves identically after hoist`() {
        let sentinel: Index<Link<2>.Node<Int>> = 7
        let links = InlineArray<2, Index<Link<2>.Node<Int>>>(repeating: sentinel)
        var node: Link<2>.Node<Int> = Link<2>.Node(links: links, element: 3)

        #expect(node.element == 3)
        #expect(node.links[0] == sentinel)

        node.links[0] = 1
        node.element = 9

        #expect(node.links[0] == 1)
        #expect(node.element == 9)
        #expect(_typeName(Link<2>.Node<Int>.self) == _typeName(__LinkNode<2, Int>.self))
    }
}

extension `Link nodes retain mutable links and element payloads`.`Link nodes preserve string payloads` {

    @Test
    func `A link node preserves its supplied string element`() {
        let sentinel: Index<Link<2>.Node<String>> = 99
        let links = InlineArray<2, Index<Link<2>.Node<String>>>(repeating: sentinel)
        let node = Link<2>.Node(links: links, element: "hello")

        #expect(node.element == "hello")
    }
}
