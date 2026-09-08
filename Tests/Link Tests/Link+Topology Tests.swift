import Affine
import Cardinal
import Index
import Link_Test_Support
import Ordinal
import Tagged
import Testing

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(ucrt)
import ucrt
#endif

@safe
private final class Pool {
    let base: UnsafeMutablePointer<N>
    let capacity: UInt

    init(capacity: UInt) {
        self.capacity = capacity
        unsafe (self.base = .allocate(capacity: Int(capacity)))
    }

    deinit {
        unsafe base.deallocate()
    }
}

extension Pool {
    typealias N = Link<2>.Node<Int>

    var sentinel: Index<N> { Index(_unchecked: Ordinal(capacity)) }

    func initializeNode(at rawIndex: UInt, element: Int) {
        let s = sentinel
        let links = InlineArray<2, Index<N>>(repeating: s)
        unsafe (base + Int(rawIndex)).initialize(to: Link<2>.Node(links: links, element: element))
    }

    func getLink(_ index: Index<N>, _ slot: Int) -> Index<N> {
        unsafe (base + Int(index.position.rawValue)).pointee.links[slot]
    }

    func setLink(_ index: Index<N>, _ slot: Int, _ value: Index<N>) {
        unsafe (base + Int(index.position.rawValue)).pointee.links[slot] = value
    }

    func element(at rawIndex: UInt) -> Int {
        unsafe (base + Int(rawIndex)).pointee.element
    }

    func collect(_ header: Link<2>.Header<N>) -> [UInt] {
        var result: [UInt] = []
        Link<2>.forEach(header: header, getLink: self.getLink) { index in

            result.append(index.position.rawValue)
        }
        return result
    }

    func makeHeader() -> Link<2>.Header<N> {
        Link<2>.Header<N>(sentinel: sentinel)
    }
}

@Suite
struct `Linked topology operations preserve ordered nodes and header state` {
    @Suite struct `Linked insertion and removal preserve node order and endpoints` {}
    @Suite struct `Linked topology operations preserve empty states and allow reuse after draining` {}
    @Suite struct `Mixed linked operations preserve traversal order and reusable slots` {}
}

extension `Linked topology operations preserve ordered nodes and header state`.`Linked insertion and removal preserve node order and endpoints` {

    @Test
    func `Appending a single node sets both endpoints and count one`() {
        let pool = Pool(capacity: 4)
        pool.initializeNode(at: 0, element: 10)
        var header = pool.makeHeader()

        Link<2>.append(0, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        #expect(header.head == 0)
        #expect(header.tail == 0)
        #expect(header.count == 1)
    }

    @Test
    func `Appending two nodes preserves insertion order and endpoint counts`() {
        let pool = Pool(capacity: 4)
        pool.initializeNode(at: 0, element: 10)
        pool.initializeNode(at: 1, element: 20)
        var header = pool.makeHeader()

        Link<2>.append(0, header: &header, getLink: pool.getLink, setLink: pool.setLink)
        Link<2>.append(1, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        #expect(header.head == 0)
        #expect(header.tail == 1)
        #expect(header.count == 2)
        #expect(pool.collect(header) == [0, 1])
    }

    @Test
    func `append three nodes preserves order`() {
        let pool = Pool(capacity: 4)
        (0..<3 as Range<UInt>).forEach { i in pool.initializeNode(at: i, element: Int(i) * 10) }
        var header = pool.makeHeader()

        Link<2>.append(0, header: &header, getLink: pool.getLink, setLink: pool.setLink)
        Link<2>.append(1, header: &header, getLink: pool.getLink, setLink: pool.setLink)
        Link<2>.append(2, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        #expect(pool.collect(header) == [0, 1, 2])
        #expect(header.count == 3)
    }
}

extension `Linked topology operations preserve ordered nodes and header state`.`Linked insertion and removal preserve node order and endpoints` {

    @Test
    func `Prepending a single node sets both endpoints and count one`() {
        let pool = Pool(capacity: 4)
        pool.initializeNode(at: 0, element: 10)
        var header = pool.makeHeader()

        Link<2>.prepend(0, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        #expect(header.head == 0)
        #expect(header.tail == 0)
        #expect(header.count == 1)
    }

    @Test
    func `prepend reverses insertion order`() {
        let pool = Pool(capacity: 4)
        (0..<3 as Range<UInt>).forEach { i in pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        Link<2>.prepend(0, header: &header, getLink: pool.getLink, setLink: pool.setLink)
        Link<2>.prepend(1, header: &header, getLink: pool.getLink, setLink: pool.setLink)
        Link<2>.prepend(2, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        #expect(pool.collect(header) == [2, 1, 0])
        #expect(header.head == 2)
        #expect(header.tail == 0)
        #expect(header.count == 3)
    }
}

extension `Linked topology operations preserve ordered nodes and header state`.`Linked insertion and removal preserve node order and endpoints` {

    @Test
    func `Unlinking a middle node preserves its neighbors and decrements the count`() {
        let pool = Pool(capacity: 4)
        (0..<3 as Range<UInt>).forEach { i in pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        Link<2>.append(0, header: &header, getLink: pool.getLink, setLink: pool.setLink)
        Link<2>.append(1, header: &header, getLink: pool.getLink, setLink: pool.setLink)
        Link<2>.append(2, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        Link<2>.unlink(1, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        #expect(pool.collect(header) == [0, 2])
        #expect(header.count == 2)
    }

    @Test
    func `Unlinking the head advances the first endpoint`() {
        let pool = Pool(capacity: 4)
        (0..<3 as Range<UInt>).forEach { i in pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        (0..<3 as Range<UInt>).forEach { i in
            Link<2>.append(
                Index(_unchecked: Ordinal(i)),
                header: &header,
                getLink: pool.getLink,
                setLink: pool.setLink
            )
        }

        Link<2>.unlink(0, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        #expect(header.head == 1)
        #expect(pool.collect(header) == [1, 2])
        #expect(header.count == 2)
    }

    @Test
    func `Unlinking the tail retreats the last endpoint`() {
        let pool = Pool(capacity: 4)
        (0..<3 as Range<UInt>).forEach { i in pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        (0..<3 as Range<UInt>).forEach { i in
            Link<2>.append(
                Index(_unchecked: Ordinal(i)),
                header: &header,
                getLink: pool.getLink,
                setLink: pool.setLink
            )
        }

        Link<2>.unlink(2, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        #expect(header.tail == 1)
        #expect(pool.collect(header) == [0, 1])
        #expect(header.count == 2)
    }
}

extension `Linked topology operations preserve ordered nodes and header state`.`Linked insertion and removal preserve node order and endpoints` {

    @Test
    func `unlinkFirst returns head index`() {
        let pool = Pool(capacity: 4)
        (0..<3 as Range<UInt>).forEach { i in pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        (0..<3 as Range<UInt>).forEach { i in
            Link<2>.append(
                Index(_unchecked: Ordinal(i)),
                header: &header,
                getLink: pool.getLink,
                setLink: pool.setLink
            )
        }

        let slot = Link<2>.unlinkFirst(
            header: &header,
            getLink: pool.getLink,
            setLink: pool.setLink
        )

        #expect(slot == 0)
        #expect(header.head == 1)
        #expect(header.count == 2)
        #expect(pool.collect(header) == [1, 2])
    }

    @Test
    func `Unlinking the first singleton node restores the empty header`() {
        let pool = Pool(capacity: 4)
        pool.initializeNode(at: 0, element: 10)
        var header = pool.makeHeader()

        Link<2>.append(0, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        let slot = Link<2>.unlinkFirst(
            header: &header,
            getLink: pool.getLink,
            setLink: pool.setLink
        )

        #expect(slot == 0)
        #expect(header.head == header.sentinel)
        #expect(header.tail == header.sentinel)
        #expect(header.count == 0)
    }
}

extension `Linked topology operations preserve ordered nodes and header state`.`Linked insertion and removal preserve node order and endpoints` {

    @Test
    func `unlinkLast returns tail index`() {
        let pool = Pool(capacity: 4)
        (0..<3 as Range<UInt>).forEach { i in pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        (0..<3 as Range<UInt>).forEach { i in
            Link<2>.append(
                Index(_unchecked: Ordinal(i)),
                header: &header,
                getLink: pool.getLink,
                setLink: pool.setLink
            )
        }

        let slot = Link<2>.unlinkLast(header: &header, getLink: pool.getLink, setLink: pool.setLink)

        #expect(slot == 2)
        #expect(header.tail == 1)
        #expect(header.count == 2)
        #expect(pool.collect(header) == [0, 1])
    }

    @Test
    func `Unlinking the last singleton node restores the empty header`() {
        let pool = Pool(capacity: 4)
        pool.initializeNode(at: 0, element: 10)
        var header = pool.makeHeader()

        Link<2>.append(0, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        let slot = Link<2>.unlinkLast(header: &header, getLink: pool.getLink, setLink: pool.setLink)

        #expect(slot == 0)
        #expect(header.head == header.sentinel)
        #expect(header.tail == header.sentinel)
        #expect(header.count == 0)
    }
}

extension `Linked topology operations preserve ordered nodes and header state`.`Linked insertion and removal preserve node order and endpoints` {

    @Test
    func `Inserting after the head preserves the remaining node order`() {
        let pool = Pool(capacity: 4)
        (0..<3 as Range<UInt>).forEach { i in pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        Link<2>.append(0, header: &header, getLink: pool.getLink, setLink: pool.setLink)
        Link<2>.append(2, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        Link<2>.insert(1, after: 0, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        #expect(pool.collect(header) == [0, 1, 2])
        #expect(header.count == 3)
    }

    @Test
    func `insert after tail updates tail`() {
        let pool = Pool(capacity: 4)
        (0..<2 as Range<UInt>).forEach { i in pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        Link<2>.append(0, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        Link<2>.insert(1, after: 0, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        #expect(header.tail == 1)
        #expect(pool.collect(header) == [0, 1])
        #expect(header.count == 2)
    }
}

extension `Linked topology operations preserve ordered nodes and header state`.`Linked insertion and removal preserve node order and endpoints` {

    @Test
    func `forEach visits all nodes in order`() {
        let pool = Pool(capacity: 4)
        (0..<3 as Range<UInt>).forEach { i in pool.initializeNode(at: i, element: Int(i) * 10) }
        var header = pool.makeHeader()

        (0..<3 as Range<UInt>).forEach { i in
            Link<2>.append(
                Index(_unchecked: Ordinal(i)),
                header: &header,
                getLink: pool.getLink,
                setLink: pool.setLink
            )
        }

        var elements: [Int] = []
        Link<2>.forEach(header: header, getLink: pool.getLink) { index in

            elements.append(pool.element(at: index.position.rawValue))
        }

        #expect(elements == [0, 10, 20])
    }

    @Test
    func `forEach on empty list does nothing`() {
        let pool = Pool(capacity: 4)
        let header = pool.makeHeader()

        var visited = false
        Link<2>.forEach(header: header, getLink: pool.getLink) { _ in
            visited = true
        }

        #expect(!visited)
    }
}

extension `Linked topology operations preserve ordered nodes and header state`.`Linked topology operations preserve empty states and allow reuse after draining` {

    @Test
    func `unlinkFirst from empty list returns nil`() {
        let pool = Pool(capacity: 4)
        var header = pool.makeHeader()

        let slot = Link<2>.unlinkFirst(
            header: &header,
            getLink: pool.getLink,
            setLink: pool.setLink
        )

        #expect(slot == nil)
        #expect(header.count == 0)
    }

    @Test
    func `unlinkLast from empty list returns nil`() {
        let pool = Pool(capacity: 4)
        var header = pool.makeHeader()

        let slot = Link<2>.unlinkLast(header: &header, getLink: pool.getLink, setLink: pool.setLink)

        #expect(slot == nil)
        #expect(header.count == 0)
    }

    @Test
    func `unlink all nodes leaves empty list`() {
        let pool = Pool(capacity: 4)
        (0..<3 as Range<UInt>).forEach { i in pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        (0..<3 as Range<UInt>).forEach { i in
            Link<2>.append(
                Index(_unchecked: Ordinal(i)),
                header: &header,
                getLink: pool.getLink,
                setLink: pool.setLink
            )
        }

        _ = Link<2>.unlinkFirst(header: &header, getLink: pool.getLink, setLink: pool.setLink)
        _ = Link<2>.unlinkFirst(header: &header, getLink: pool.getLink, setLink: pool.setLink)
        _ = Link<2>.unlinkFirst(header: &header, getLink: pool.getLink, setLink: pool.setLink)

        #expect(header.head == header.sentinel)
        #expect(header.tail == header.sentinel)
        #expect(header.count == 0)
        #expect(pool.collect(header) == [])
    }

    @Test
    func `Appending after draining reuses the empty linked header`() {
        let pool = Pool(capacity: 4)
        (0..<2 as Range<UInt>).forEach { i in pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        Link<2>.append(0, header: &header, getLink: pool.getLink, setLink: pool.setLink)
        _ = Link<2>.unlinkFirst(header: &header, getLink: pool.getLink, setLink: pool.setLink)

        pool.initializeNode(at: 0, element: 99)
        Link<2>.append(0, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        #expect(header.head == 0)
        #expect(header.tail == 0)
        #expect(header.count == 1)
    }
}

extension `Linked topology operations preserve ordered nodes and header state`.`Mixed linked operations preserve traversal order and reusable slots` {

    @Test
    func `mixed append prepend insert produces correct order`() {
        let pool = Pool(capacity: 8)
        (0..<5 as Range<UInt>).forEach { i in pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        Link<2>.append(0, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        Link<2>.append(1, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        Link<2>.prepend(2, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        Link<2>.insert(3, after: 0, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        Link<2>.prepend(4, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        #expect(pool.collect(header) == [4, 2, 0, 3, 1])
        #expect(header.head == 4)
        #expect(header.tail == 1)
        #expect(header.count == 5)
    }

    @Test
    func `Draining from the front visits nodes in forward order`() {
        let pool = Pool(capacity: 8)
        (0..<4 as Range<UInt>).forEach { i in pool.initializeNode(at: i, element: Int(i) * 10) }
        var header = pool.makeHeader()

        (0..<4 as Range<UInt>).forEach { i in
            Link<2>.append(
                Index(_unchecked: Ordinal(i)),
                header: &header,
                getLink: pool.getLink,
                setLink: pool.setLink
            )
        }

        var drained: [Int] = []
        while let slot = Link<2>.unlinkFirst(
            header: &header,
            getLink: pool.getLink,
            setLink: pool.setLink
        ) {

            drained.append(pool.element(at: slot.position.rawValue))
        }

        #expect(drained == [0, 10, 20, 30])
        #expect(header.count == 0)
    }

    @Test
    func `Draining from the back visits nodes in reverse order`() {
        let pool = Pool(capacity: 8)
        (0..<4 as Range<UInt>).forEach { i in pool.initializeNode(at: i, element: Int(i) * 10) }
        var header = pool.makeHeader()

        (0..<4 as Range<UInt>).forEach { i in
            Link<2>.append(
                Index(_unchecked: Ordinal(i)),
                header: &header,
                getLink: pool.getLink,
                setLink: pool.setLink
            )
        }

        var drained: [Int] = []
        while let slot = Link<2>.unlinkLast(
            header: &header,
            getLink: pool.getLink,
            setLink: pool.setLink
        ) {

            drained.append(pool.element(at: slot.position.rawValue))
        }

        #expect(drained == [30, 20, 10, 0])
        #expect(header.count == 0)
    }

    @Test
    func `unlink middle then append reuses slot`() {
        let pool = Pool(capacity: 8)
        (0..<4 as Range<UInt>).forEach { i in pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        (0..<3 as Range<UInt>).forEach { i in
            Link<2>.append(
                Index(_unchecked: Ordinal(i)),
                header: &header,
                getLink: pool.getLink,
                setLink: pool.setLink
            )
        }

        Link<2>.unlink(1, header: &header, getLink: pool.getLink, setLink: pool.setLink)
        #expect(pool.collect(header) == [0, 2])

        pool.initializeNode(at: 3, element: 99)
        Link<2>.append(3, header: &header, getLink: pool.getLink, setLink: pool.setLink)
        #expect(pool.collect(header) == [0, 2, 3])
        #expect(header.count == 3)
    }
}

private final class TopologyStorage<let N: Int> {
    typealias Node = Link<N>.Node<Int>

    let sentinel: Index<Node>
    var nodes: [Node]

    init(capacity: Int) {
        let sentinel = Index<Node>(_unchecked: Ordinal(UInt(capacity)))
        self.sentinel = sentinel
        self.nodes = (0..<capacity).map {
            Node(links: InlineArray(repeating: sentinel), element: $0 * 10)
        }
    }

    func getLink(_ index: Index<Node>, _ slot: Int) -> Index<Node> {
        nodes[Int(index.position.rawValue)].links[slot]
    }

    func setLink(_ index: Index<Node>, _ slot: Int, _ value: Index<Node>) {
        nodes[Int(index.position.rawValue)].links[slot] = value
    }

    func expectState(_ header: Link<N>.Header<Node>, order: [UInt]) {
        let indices = order.map { Index<Node>(_unchecked: Ordinal($0)) }
        #expect(header.head == (indices.first ?? sentinel))
        #expect(header.tail == (indices.last ?? sentinel))
        #expect(header.count.underlying.rawValue == UInt(order.count))
        #expect(header.sentinel == sentinel)
        for (offset, index) in indices.enumerated() {
            #expect(getLink(index, 0) == (offset + 1 < indices.count ? indices[offset + 1] : sentinel))
            if N >= 2 {
                #expect(getLink(index, 1) == (offset > 0 ? indices[offset - 1] : sentinel))
            }
        }
        var visited: [Index<Node>] = []
        Link<N>.forEach(header: header, getLink: getLink) { visited.append($0) }
        #expect(visited == indices)
    }

    func expectCleared(_ index: Index<Node>) {
        #expect(getLink(index, 0) == sentinel)
        if N >= 2 {
            #expect(getLink(index, 1) == sentinel)
        }
    }
}

private enum TopologyContractTag {}

private func exerciseRejectedTopology<let N: Int>(_ operation: String, _: Link<N>.Type) {
    typealias Position = Index<TopologyContractTag>
    var header = Link<N>.Header<TopologyContractTag>(sentinel: 99)
    let getLink: (Position, Int) -> Position = { _, _ in exit(0) }
    let setLink: (Position, Int, Position) -> Void = { _, _, _ in exit(0) }
    switch operation {
    case "append":
        Link<N>.append(0, header: &header, getLink: getLink, setLink: setLink)
    case "prepend":
        Link<N>.prepend(0, header: &header, getLink: getLink, setLink: setLink)
    case "insert":
        Link<N>.insert(0, after: 1, header: &header, getLink: getLink, setLink: setLink)
    case "unlink":
        header.head = 0
        header.tail = 0
        header.count = 1
        Link<N>.unlink(0, header: &header, getLink: getLink, setLink: setLink)
    case "unlinkFirst":
        _ = Link<N>.unlinkFirst(header: &header, getLink: getLink, setLink: setLink)
    case "unlinkLast":
        _ = Link<N>.unlinkLast(header: &header, getLink: getLink, setLink: setLink)
    case "forEach":
        Link<N>.forEach(header: header, getLink: getLink) { _ in exit(0) }
    default:
        exit(0)
    }
}

@Suite(.timeLimit(.minutes(1)))
struct `Link topology enforces arity and preserves caller storage` {
    @Test(arguments: ["append", "prepend", "insert", "unlink", "unlinkFirst", "unlinkLast", "forEach"])
    func `Zero link topology is rejected before storage callbacks`(operation: String) async {
        await #expect(processExitsWith: .failure) { [operation = operation as String] in
            exerciseRejectedTopology(operation, Link<0>.self)
        }
    }

    @Test
    func `Arbitrary singly linked removal is rejected before storage callbacks`() async {
        await #expect(processExitsWith: .failure) {
            exerciseRejectedTopology("unlink", Link<1>.self)
        }
    }

    @Test
    func `Empty singly linked traversal and removal do not access storage`() {
        let storage = TopologyStorage<1>(capacity: 0)
        var header = Link<1>.Header<TopologyStorage<1>.Node>(sentinel: storage.sentinel)
        #expect(Link<1>.unlinkFirst(header: &header, getLink: storage.getLink, setLink: storage.setLink) == nil)
        #expect(Link<1>.unlinkLast(header: &header, getLink: storage.getLink, setLink: storage.setLink) == nil)
        storage.expectState(header, order: [])
    }

    @Test
    func `Singly linked mutations preserve forward links and allow cleared slot reuse`() {
        let storage = TopologyStorage<1>(capacity: 5)
        var header = Link<1>.Header<TopologyStorage<1>.Node>(sentinel: storage.sentinel)

        Link<1>.append(0, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        storage.expectState(header, order: [0])
        Link<1>.prepend(1, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        Link<1>.insert(2, after: 0, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        storage.expectState(header, order: [1, 0, 2])
        #expect(Link<1>.unlinkLast(header: &header, getLink: storage.getLink, setLink: storage.setLink) == 2)
        storage.expectState(header, order: [1, 0])
        storage.expectCleared(2)
        Link<1>.append(2, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        #expect(Link<1>.unlinkFirst(header: &header, getLink: storage.getLink, setLink: storage.setLink) == 1)
        storage.expectState(header, order: [0, 2])
        storage.expectCleared(1)
        #expect(Link<1>.unlinkLast(header: &header, getLink: storage.getLink, setLink: storage.setLink) == 2)
        #expect(Link<1>.unlinkLast(header: &header, getLink: storage.getLink, setLink: storage.setLink) == 0)
        storage.expectState(header, order: [])
        storage.expectCleared(0)
        storage.expectCleared(2)

        Link<1>.prepend(0, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        storage.expectState(header, order: [0])
        #expect(Link<1>.unlinkFirst(header: &header, getLink: storage.getLink, setLink: storage.setLink) == 0)
        storage.expectState(header, order: [])
        storage.expectCleared(0)
        storage.expectCleared(3)
        storage.expectCleared(4)
        #expect(storage.nodes.map(\.element) == [0, 10, 20, 30, 40])
    }

    @Test
    func `Doubly linked mutations preserve reciprocal links and unrelated nodes`() {
        let storage = TopologyStorage<2>(capacity: 5)
        var header = Link<2>.Header<TopologyStorage<2>.Node>(sentinel: storage.sentinel)
        storage.setLink(4, 0, 4)
        storage.setLink(4, 1, 4)

        Link<2>.append(0, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        Link<2>.append(2, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        Link<2>.prepend(1, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        Link<2>.insert(3, after: 0, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        storage.expectState(header, order: [1, 0, 3, 2])
        Link<2>.unlink(3, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        storage.expectState(header, order: [1, 0, 2])
        storage.expectCleared(3)
        Link<2>.append(3, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        storage.expectState(header, order: [1, 0, 2, 3])
        #expect(Link<2>.unlinkFirst(header: &header, getLink: storage.getLink, setLink: storage.setLink) == 1)
        storage.expectState(header, order: [0, 2, 3])
        storage.expectCleared(1)
        #expect(Link<2>.unlinkLast(header: &header, getLink: storage.getLink, setLink: storage.setLink) == 3)
        storage.expectState(header, order: [0, 2])
        storage.expectCleared(3)
        Link<2>.unlink(0, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        storage.expectState(header, order: [2])
        storage.expectCleared(0)
        Link<2>.unlink(2, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        storage.expectState(header, order: [])
        storage.expectCleared(2)
        #expect(storage.getLink(4, 0) == 4)
        #expect(storage.getLink(4, 1) == 4)
        #expect(storage.nodes.map(\.element) == [0, 10, 20, 30, 40])
    }

    @Test
    func `A drained doubly linked slot can be reused without initialization`() {
        let storage = TopologyStorage<2>(capacity: 1)
        var header = Link<2>.Header<TopologyStorage<2>.Node>(sentinel: storage.sentinel)

        Link<2>.append(0, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        storage.expectState(header, order: [0])
        #expect(Link<2>.unlinkLast(header: &header, getLink: storage.getLink, setLink: storage.setLink) == 0)
        storage.expectState(header, order: [])
        storage.expectCleared(0)
        Link<2>.append(0, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        storage.expectState(header, order: [0])
        #expect(Link<2>.unlinkFirst(header: &header, getLink: storage.getLink, setLink: storage.setLink) == 0)
        storage.expectState(header, order: [])
        storage.expectCleared(0)
        Link<2>.prepend(0, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        storage.expectState(header, order: [0])
        Link<2>.unlink(0, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        storage.expectState(header, order: [])
        storage.expectCleared(0)
        #expect(storage.nodes[0].element == 0)
    }

    @Test
    func `Three link topology preserves opaque slots throughout rewiring and removal`() {
        let storage = TopologyStorage<3>(capacity: 5)
        var header = Link<3>.Header<TopologyStorage<3>.Node>(sentinel: storage.sentinel)
        storage.setLink(4, 2, 104)

        Link<3>.append(0, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        storage.setLink(0, 2, 100)
        Link<3>.prepend(1, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        storage.setLink(1, 2, 101)
        Link<3>.insert(2, after: 0, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        storage.setLink(2, 2, 102)
        Link<3>.append(3, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        storage.setLink(3, 2, 103)
        storage.expectState(header, order: [1, 0, 2, 3])
        Link<3>.unlink(2, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        storage.expectState(header, order: [1, 0, 3])
        storage.expectCleared(2)
        #expect(Link<3>.unlinkFirst(header: &header, getLink: storage.getLink, setLink: storage.setLink) == 1)
        storage.expectState(header, order: [0, 3])
        storage.expectCleared(1)
        #expect(Link<3>.unlinkLast(header: &header, getLink: storage.getLink, setLink: storage.setLink) == 3)
        storage.expectState(header, order: [0])
        storage.expectCleared(3)
        Link<3>.unlink(0, header: &header, getLink: storage.getLink, setLink: storage.setLink)
        storage.expectState(header, order: [])
        storage.expectCleared(0)
        storage.expectCleared(4)
        #expect(storage.nodes.map { $0.links[2].position.rawValue } == [100, 101, 102, 103, 104])
        #expect(storage.nodes.map(\.element) == [0, 10, 20, 30, 40])
    }
}
