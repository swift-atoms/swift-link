// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

// MARK: - Node Nest Alias
//
// `Node<Element>` is hoisted to module level as `__LinkNode` per [API-EXC-001]
// (a value-generic type cannot nest in the generic carrier — see #105 and
// `__LinkNode.swift`). This typealias preserves the end-user call-site spelling
// `Link<N>.Node<Element>` exactly — construction, storage, and generic
// substitution are unaffected.

extension Link {

    /// A linked list node containing N links and an element.
    ///
    /// Nodes are stored in pool or arena slots. Links are
    /// `Index<Node>` values pointing to other slots in the same pool.
    /// Convention: `links[0]` = next, `links[1]` = prev (when N >= 2).
    /// The pool's sentinel marks end-of-list.
    ///
    /// ## Links-First Layout
    ///
    /// Links are the first field so that a links view sits at offset 0,
    /// independent of `Element`. Topology operations are element-free —
    /// they read and write link slots through the `getLink` / `setLink`
    /// accessors, never touching element storage.
    ///
    /// - Note: The underlying storage is ``__LinkNode``, hoisted to module
    ///   level to avoid nesting a generic type inside the value-generic
    ///   `Link<N>` carrier (see #105). This alias preserves the
    ///   `Link<N>.Node<Element>` spelling exactly.
    public typealias Node<Element: ~Copyable> = __LinkNode<N, Element>
}
