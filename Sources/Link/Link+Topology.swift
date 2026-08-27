public import Cardinal
public import Index
public import Ordinal
public import Tagged

@usableFromInline
func _linkIndicesEqual<Tag: ~Copyable & ~Escapable>(
    _ lhs: borrowing Index<Tag>,
    _ rhs: borrowing Index<Tag>
) -> Bool {
    lhs.underlying.rawValue == rhs.underlying.rawValue
}

extension Link {

    @inlinable
    public static func append<Tag: ~Copyable & ~Escapable>(
        _ index: Index<Tag>,
        header: inout Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        setLink: (Index<Tag>, Int, Index<Tag>) -> Void
    ) {
        let sentinel = header.sentinel

        if !_linkIndicesEqual(header.tail, sentinel) {
            setLink(header.tail, 0, index)
            if N >= 2 {
                setLink(index, 1, header.tail)
            }
        } else {
            header.head = index
        }

        header.tail = index
        setLink(index, 0, sentinel)
        header.count += Cardinal(1)
    }

    @inlinable
    public static func prepend<Tag: ~Copyable & ~Escapable>(
        _ index: Index<Tag>,
        header: inout Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        setLink: (Index<Tag>, Int, Index<Tag>) -> Void
    ) {
        let sentinel = header.sentinel

        if !_linkIndicesEqual(header.head, sentinel) {
            setLink(index, 0, header.head)
            if N >= 2 {
                setLink(header.head, 1, index)
            }
        } else {
            header.tail = index
            setLink(index, 0, sentinel)
        }

        if N >= 2 {
            setLink(index, 1, sentinel)
        }

        header.head = index
        header.count += Cardinal(1)
    }

    @inlinable
    public static func unlink<Tag: ~Copyable & ~Escapable>(
        _ index: Index<Tag>,
        header: inout Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        setLink: (Index<Tag>, Int, Index<Tag>) -> Void
    ) {
        let sentinel = header.sentinel
        let prevIndex = getLink(index, 1)
        let nextIndex = getLink(index, 0)

        if !_linkIndicesEqual(prevIndex, sentinel) {
            setLink(prevIndex, 0, nextIndex)
        } else {
            header.head = nextIndex
        }

        if !_linkIndicesEqual(nextIndex, sentinel) {
            setLink(nextIndex, 1, prevIndex)
        } else {
            header.tail = prevIndex
        }

        setLink(index, 0, sentinel)
        setLink(index, 1, sentinel)

        header.count = Cardinal(header.count.rawValue == 0 ? 0 : header.count.rawValue - 1)
    }

    @inlinable
    public static func unlinkFirst<Tag: ~Copyable & ~Escapable>(
        header: inout Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        setLink: (Index<Tag>, Int, Index<Tag>) -> Void
    ) -> Index<Tag>? {
        let sentinel = header.sentinel
        guard !_linkIndicesEqual(header.head, sentinel) else { return nil }

        let slot = header.head
        let nextSlot = getLink(slot, 0)

        header.head = nextSlot
        if !_linkIndicesEqual(nextSlot, sentinel) {
            if N >= 2 {
                setLink(nextSlot, 1, sentinel)
            }
        } else {
            header.tail = sentinel
        }

        setLink(slot, 0, sentinel)
        if N >= 2 {
            setLink(slot, 1, sentinel)
        }

        header.count = Cardinal(header.count.rawValue == 0 ? 0 : header.count.rawValue - 1)
        return slot
    }

    @inlinable
    public static func unlinkLast<Tag: ~Copyable & ~Escapable>(
        header: inout Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        setLink: (Index<Tag>, Int, Index<Tag>) -> Void
    ) -> Index<Tag>? {
        let sentinel = header.sentinel
        guard !_linkIndicesEqual(header.tail, sentinel) else { return nil }

        let slot = header.tail

        if N >= 2 {
            let prevSlot = getLink(slot, 1)

            header.tail = prevSlot
            if !_linkIndicesEqual(prevSlot, sentinel) {
                setLink(prevSlot, 0, sentinel)
            } else {
                header.head = sentinel
            }

            setLink(slot, 0, sentinel)
            setLink(slot, 1, sentinel)
        } else {

            var prevSlot = sentinel
            if !_linkIndicesEqual(header.head, slot) {
                var current = header.head
                while !_linkIndicesEqual(current, sentinel) {
                    let nextSlot = getLink(current, 0)
                    if _linkIndicesEqual(nextSlot, slot) {
                        prevSlot = current
                        break
                    }
                    current = nextSlot
                }
            }

            header.tail = prevSlot
            if !_linkIndicesEqual(prevSlot, sentinel) {
                setLink(prevSlot, 0, sentinel)
            } else {
                header.head = sentinel
            }

            setLink(slot, 0, sentinel)
        }

        header.count = Cardinal(header.count.rawValue == 0 ? 0 : header.count.rawValue - 1)
        return slot
    }

    @inlinable
    public static func insert<Tag: ~Copyable & ~Escapable>(
        _ index: Index<Tag>,
        after position: Index<Tag>,
        header: inout Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        setLink: (Index<Tag>, Int, Index<Tag>) -> Void
    ) {
        let sentinel = header.sentinel
        let nextSlot = getLink(position, 0)

        setLink(position, 0, index)
        setLink(index, 0, nextSlot)

        if N >= 2 {
            setLink(index, 1, position)
            if !_linkIndicesEqual(nextSlot, sentinel) {
                setLink(nextSlot, 1, index)
            }
        }

        if _linkIndicesEqual(nextSlot, sentinel) {
            header.tail = index
        }

        header.count += Cardinal(1)
    }

    @inlinable
    public static func forEach<Tag: ~Copyable & ~Escapable>(
        header: Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        _ body: (Index<Tag>) -> Void
    ) {
        let sentinel = header.sentinel
        var current = header.head
        while !_linkIndicesEqual(current, sentinel) {
            let nextSlot = getLink(current, 0)
            body(current)
            current = nextSlot
        }
    }
}
