# swift-link

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-atoms/swift-link/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-atoms/swift-link/actions/workflows/ci.yml)

Pure link topology for slot-backed linked lists — O(1) append, prepend, insert, and unlink over any storage, expressed through pointer-free `getLink` / `setLink` accessors. `Link<N>` factors out the link algebra common to every linked-list-like structure: the operations manipulate only prev/next indices and a cursor header, never allocating, deallocating, or touching element storage.

The link count is a type-level parameter: `Link<1>` is singly-linked, `Link<2>` is doubly-linked with O(1) arbitrary removal. End-of-list is a sentinel index (the pool's capacity), so node layout carries no Optional overhead, and `Link.Node` keeps its links first so topology stays independent of the element type.

---

## Key Features

- **Element-free topology** — `append`, `prepend`, `insert(after:)`, `unlink`, `unlinkFirst`, `unlinkLast`, and `forEach` manipulate only link slots and the header; allocation and element lifetime stay with the caller.
- **Pointer-free by construction** — link access goes through `getLink` / `setLink` accessors backed by your storage's typed subscript, never a raw pointer.
- **Singly or doubly linked at the type level** — `Link<1>` for next-only lists, `Link<2>` for O(1) unlink of arbitrary nodes.
- **Sentinel, not Optional** — end-of-list is a sentinel `Index`, keeping `Link.Node` a flat value of `N` indices plus the element.
- **Noncopyable elements** — `Link.Node<Element>` is `~Copyable`, becoming `Copyable` and `Sendable` exactly when its element is.

---

## Quick Start

```swift
import Link

// Nodes for a doubly-linked list (2 links: next and prev).
typealias Node = Link<2>.Node<String>

// Any slot storage works — here a plain Swift array.
// The sentinel (one past the last slot) marks end-of-list.
let capacity: UInt = 4
let sentinel = Index<Node>(_unchecked: Ordinal(capacity))
var slots: [Node] = ["alpha", "beta", "gamma", "delta"].map { name in
    Node(links: InlineArray(repeating: sentinel), element: name)
}

func index(_ value: UInt) -> Index<Node> {
    Index(_unchecked: Ordinal(value))
}

var header = Link<2>.Header<Node>(sentinel: sentinel)

// Pointer-free accessors: topology reads and writes link slots
// through your storage's subscript, never a raw pointer.
func getLink(_ index: Index<Node>, _ slot: Int) -> Index<Node> {
    slots[Int(index.underlying.rawValue)].links[slot]
}
func setLink(_ index: Index<Node>, _ slot: Int, _ value: Index<Node>) {
    slots[Int(index.underlying.rawValue)].links[slot] = value
}

Link<2>.append(index(0), header: &header, getLink: getLink, setLink: setLink)
Link<2>.append(index(1), header: &header, getLink: getLink, setLink: setLink)
Link<2>.prepend(index(2), header: &header, getLink: getLink, setLink: setLink)
// Order is now: gamma → alpha → beta.

// O(1) removal from the middle — no traversal, no element moves.
Link<2>.unlink(index(0), header: &header, getLink: getLink, setLink: setLink)

// Visit head → tail.
Link<2>.forEach(header: header, getLink: getLink) { index in
    print(slots[Int(index.underlying.rawValue)].element)
}
// Prints: gamma, beta
```

The same operations back pool- or arena-allocated structures — timer wheels, LRU caches, scheduler queues — wherever nodes live in slots and the list order must change in O(1) without moving elements.

---

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-atoms/swift-link.git", branch: "main")
]
```

Add a product to your target:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Link", package: "swift-link")
    ]
)
```

The package is pre-1.0 — depend on `branch: "main"` until `0.1.0` is tagged. Requires Swift 6.4 and macOS 27 / iOS 27 / tvOS 27 / watchOS 27 / visionOS 27 (or the corresponding Linux / Windows toolchain).

---

## Architecture

| Product | Contents | When to import |
|---------|----------|----------------|
| `Link` | `Link<N>`, `Link.Node`, `Link.Header`, and the topology operations; re-exports the current `Index` and `Cardinal` primitives and their representation modules | Most consumers |
| `Link Apple Foundation Integration` | Re-exports `Link` alongside Foundation | Apple-platform integration targets |
| `Link Test Support` | Re-exports the library plus the Cardinal, Ordinal, and Tagged standard-library integrations and Index equality support | Test targets exercising link topology |

Key types:

| Type | Purpose |
|------|---------|
| `Link<N>` | Namespace for N-link topology; `N` = links per node (1 = singly, 2 = doubly) |
| `Link<N>.Node<Element>` | A node: `InlineArray<N, Index<Node>>` of links (first) plus the element |
| `Link<N>.Header<Tag>` | Copyable cursor state: `Index<Tag>` head, tail, and sentinel plus a `Cardinal` count |

Foundation is confined to `Link Apple Foundation Integration`; the core and Test Support targets are Foundation-free.

---

## Platform Support

| Platform         | CI  | Status       |
|------------------|-----|--------------|
| macOS 27         | Yes | Full support |
| Linux            | Yes | Full support |
| Windows          | Yes | Full support |
| iOS/tvOS/watchOS | —   | Supported    |
| Swift Embedded   | —   | Targeted     |

---

## Related Packages

- [`swift-index`](https://github.com/swift-atoms/swift-index) — the phantom-typed `Index<Tag>` the link slots hold.
- [`swift-cardinal`](https://github.com/swift-atoms/swift-cardinal) — the nonnegative count stored in `Link.Header`.
- [`swift-ordinal`](https://github.com/swift-atoms/swift-ordinal) and [`swift-tagged`](https://github.com/swift-atoms/swift-tagged) — the current native representation of `Index<Tag>`.

---

## Community

<!-- BEGIN: discussion -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
