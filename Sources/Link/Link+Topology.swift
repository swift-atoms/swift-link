public import Cardinal_Carrier
public import Cardinal_Tagged
public import Index
public import Ordinal
public import Ordinal_Protocol
public import Tagged
public import Vector

extension Link {

    @inlinable
    public static func append<Tag: ~Copyable & ~Escapable>(
        _ index: Index<Tag>,
        header: inout Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        setLink: (Index<Tag>, Int, Index<Tag>) -> Void
    ) {
        let sentinel = header.sentinel

        if header.tail != sentinel {
            setLink(header.tail, 0, index)
            if N >= 2 {
                setLink(index, 1, header.tail)
            }
        } else {
            header.head = index
        }

        header.tail = index
        setLink(index, 0, sentinel)
        header.count += .one
    }

    @inlinable
    public static func prepend<Tag: ~Copyable & ~Escapable>(
        _ index: Index<Tag>,
        header: inout Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        setLink: (Index<Tag>, Int, Index<Tag>) -> Void
    ) {
        let sentinel = header.sentinel

        if header.head != sentinel {
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
        header.count += .one
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

        if prevIndex != sentinel {
            setLink(prevIndex, 0, nextIndex)
        } else {
            header.head = nextIndex
        }

        if nextIndex != sentinel {
            setLink(nextIndex, 1, prevIndex)
        } else {
            header.tail = prevIndex
        }

        setLink(index, 0, sentinel)
        setLink(index, 1, sentinel)

        header.count = header.count.subtract.saturating(.one)
    }

    @inlinable
    public static func unlinkFirst<Tag: ~Copyable & ~Escapable>(
        header: inout Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        setLink: (Index<Tag>, Int, Index<Tag>) -> Void
    ) -> Index<Tag>? {
        let sentinel = header.sentinel
        guard header.head != sentinel else { return nil }

        let slot = header.head
        let nextSlot = getLink(slot, 0)

        header.head = nextSlot
        if nextSlot != sentinel {
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

        header.count = header.count.subtract.saturating(.one)
        return slot
    }

    @inlinable
    public static func unlinkLast<Tag: ~Copyable & ~Escapable>(
        header: inout Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        setLink: (Index<Tag>, Int, Index<Tag>) -> Void
    ) -> Index<Tag>? {
        let sentinel = header.sentinel
        guard header.tail != sentinel else { return nil }

        let slot = header.tail

        if N >= 2 {
            let prevSlot = getLink(slot, 1)

            header.tail = prevSlot
            if prevSlot != sentinel {
                setLink(prevSlot, 0, sentinel)
            } else {
                header.head = sentinel
            }

            setLink(slot, 0, sentinel)
            setLink(slot, 1, sentinel)
        } else {

            var prevSlot = sentinel
            if header.head != slot {
                var current = header.head
                while current != sentinel {
                    let nextSlot = getLink(current, 0)
                    if nextSlot == slot {
                        prevSlot = current
                        break
                    }
                    current = nextSlot
                }
            }

            header.tail = prevSlot
            if prevSlot != sentinel {
                setLink(prevSlot, 0, sentinel)
            } else {
                header.head = sentinel
            }

            setLink(slot, 0, sentinel)
        }

        header.count = header.count.subtract.saturating(.one)
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
            if nextSlot != sentinel {
                setLink(nextSlot, 1, index)
            }
        }

        if nextSlot == sentinel {
            header.tail = index
        }

        header.count += .one
    }

    @inlinable
    public static func forEach<Tag: ~Copyable & ~Escapable>(
        header: Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        _ body: (Index<Tag>) -> Void
    ) {
        let sentinel = header.sentinel
        var current = header.head
        while current != sentinel {
            let nextSlot = getLink(current, 0)
            body(current)
            current = nextSlot
        }
    }
}
