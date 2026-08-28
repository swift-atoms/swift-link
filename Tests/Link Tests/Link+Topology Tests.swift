import Link_Test_Support
import Testing

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
        unsafe (base + Index<N>.Offset(fromZero: index)).pointee.links[slot]
    }

    func setLink(_ index: Index<N>, _ slot: Int, _ value: Index<N>) {
        unsafe (base + Index<N>.Offset(fromZero: index)).pointee.links[slot] = value
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
struct `Link Topology Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Link Topology Tests`.Unit {

    @Test
    func `append single node`() {
        let pool = Pool(capacity: 4)
        pool.initializeNode(at: 0, element: 10)
        var header = pool.makeHeader()

        Link<2>.append(0, header: &header, getLink: pool.getLink, setLink: pool.setLink)

        #expect(header.head == 0)
        #expect(header.tail == 0)
        #expect(header.count == 1)
    }

    @Test
    func `append two nodes`() {
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

extension `Link Topology Tests`.Unit {

    @Test
    func `prepend single node`() {
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

extension `Link Topology Tests`.Unit {

    @Test
    func `unlink middle node`() {
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
    func `unlink head node`() {
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
    func `unlink tail node`() {
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

extension `Link Topology Tests`.Unit {

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
    func `unlinkFirst from single-element list`() {
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

extension `Link Topology Tests`.Unit {

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
    func `unlinkLast from single-element list`() {
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

extension `Link Topology Tests`.Unit {

    @Test
    func `insert after head`() {
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

extension `Link Topology Tests`.Unit {

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

extension `Link Topology Tests`.`Edge Case` {

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
    func `append after drain`() {
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

extension `Link Topology Tests`.Integration {

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
    func `drain from front one by one`() {
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
    func `drain from back one by one`() {
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
