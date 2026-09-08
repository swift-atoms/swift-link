import Cardinal
import Index
import Link_Test_Support
import Ordinal
import Tagged
import Testing

private enum Tag {}

@Suite
struct `Link headers preserve sentinels endpoints and counts` {
    @Suite struct `Link header construction and mutation preserve their stored fields` {}
    @Suite struct `Link headers support zero sentinels and singly linked topology` {}
    @Suite struct `No link header integration cases are defined` {}
}

extension `Link headers preserve sentinels endpoints and counts`.`Link header construction and mutation preserve their stored fields` {

    @Test
    func `init sets head and tail to sentinel`() {
        let sentinel: Index<Tag> = 10
        let header = Link<2>.Header<Tag>(sentinel: sentinel)

        #expect(header.head == sentinel)
        #expect(header.tail == sentinel)
        #expect(header.sentinel == sentinel)
    }

    @Test
    func `init sets count to zero`() {
        let sentinel: Index<Tag> = 5
        let header = Link<2>.Header<Tag>(sentinel: sentinel)

        #expect(header.count == 0)
    }

    @Test
    func `sentinel is immutable`() {
        let sentinel: Index<Tag> = 8
        let header = Link<2>.Header<Tag>(sentinel: sentinel)

        #expect(header.sentinel == 8)
    }

    @Test
    func `head and tail are mutable`() {
        let sentinel: Index<Tag> = 10
        var header = Link<2>.Header<Tag>(sentinel: sentinel)

        header.head = 3
        header.tail = 7

        #expect(header.head == 3)
        #expect(header.tail == 7)
    }

    @Test
    func `count is mutable`() {
        let sentinel: Index<Tag> = 10
        var header = Link<2>.Header<Tag>(sentinel: sentinel)

        header.count += .one
        header.count += .one

        #expect(header.count == 2)
    }
}

extension `Link headers preserve sentinels endpoints and counts`.`Link headers support zero sentinels and singly linked topology` {

    @Test
    func `A zero sentinel initializes an empty link header`() {
        let header = Link<2>.Header<Tag>(sentinel: 0)

        #expect(header.head == 0)
        #expect(header.tail == 0)
        #expect(header.sentinel == 0)
        #expect(header.count == 0)
    }

    @Test
    func `A singly linked header starts with sentinel endpoints and zero count`() {
        let sentinel: Index<Tag> = 4
        let header = Link<1>.Header<Tag>(sentinel: sentinel)

        #expect(header.head == sentinel)
        #expect(header.tail == sentinel)
        #expect(header.count == 0)
    }
}
