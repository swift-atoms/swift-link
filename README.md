# swift-link

Use this package when you build a linked structure (a list, queue or recency order) over storage you already own, such as a pool or array of nodes addressed by `Index<Tag>` rather than by references. It holds no nodes itself: `Link<N>` supplies the rewiring operations, `N` is the number of link slots per node (1 for singly linked, 2 for doubly linked), `Link<N>.Header<Tag>` holds the endpoints and count, and `Link<N>.Node<Element>` is an optional node layout whose `links` you can hand to the operations through `getLink` and `setLink`.

## Laws

- Link slot 0 is the forward (next) link and slot 1 the backward (previous) link. Slots 2 and higher are never read or written by any operation.
- The operations touch only the `Link<N>.Header<Tag>` and the link slots of the nodes being rewired, through `getLink` and `setLink`. Elements and unrelated nodes are left as they were.
- `sentinel` stands for "no node". An empty header has `head` and `tail` equal to `sentinel` and a `count` of zero, and every removal that empties the list returns it to exactly that state.
- With `N` below 1 every operation traps before calling `getLink` or `setLink`. `unlink` of an arbitrary node traps the same way unless `N` is at least 2.
- `unlink`, `unlinkFirst` and `unlinkLast` reset the removed node's slot 0, and slot 1 when `N` is at least 2, to `sentinel`. A removed node can therefore be inserted again without re-initializing it.
- `unlinkFirst` and `unlinkLast` return `nil` on an empty header without touching storage.
- With `N` equal to 1, `unlinkLast` walks from `head` to find the new tail, so it costs time proportional to `count`. Every other operation rewires a fixed number of links.
- `forEach` visits nodes from `head` to `tail` along slot 0.
- Nothing checks membership. The node passed to `append`, `prepend` or `insert` must not be in the list, the position passed to `insert` and the node passed to `unlink` must be in this list, and every index other than `sentinel` must address a node in the caller's storage. `count` changes by one per operation and is never recomputed from the links.
- `append` on an empty header does not write slot 1 of the new node. When `N` is at least 2, that slot must already be `sentinel`, either from initialization or from an earlier removal.
