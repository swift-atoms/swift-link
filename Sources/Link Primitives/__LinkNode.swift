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

import Index_Primitives
import Vector_Primitives

// MARK: - Hoisted Node Type (Module Level)
//
// A generic type (`Node<Element>`) cannot nest inside a value-generic carrier
// (`Link<let N: Int>`) without exposing a runtime generic-metadata crash — see
// swift-institute/Issues#105. Hoisted to module level per [API-EXC-001] (a
// value-generic type cannot nest in the generic carrier — swift-tree-n-primitives'
// `__TreeNChildSlot`) and surfaced via the `Link<N>.Node<Element>` nest alias on
// the carrier (see `Link.Node.swift`), preserving the end-user call-site spelling
// exactly.

/// Hoisted implementation of ``Link/Node``.
///
/// A linked list node containing `N` links and an element.
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
/// `@frozen` because cross-module partial consumption of ~Copyable
/// types requires known layout.
///
/// - Note: Use ``Link/Node`` in your code, not this type directly.
@frozen
public struct __LinkNode<let N: Int, Element: ~Copyable>: ~Copyable {
    /// Links to other nodes.
    ///
    /// `links[0]` = next, `links[1]` = prev (N >= 2).
    public var links: InlineArray<N, Index<__LinkNode<N, Element>>>

    /// The element value stored in this node.
    public var element: Element

    /// Creates a node with the given links and element.
    @inlinable
    // swiftlint:disable:next prefer_self_in_static_references - reason: deliberate phantom-tag idiom — links ARE `Index<__LinkNode<N, Element>>` values (see type doc above); the tag names the concept, so `Self` would obscure what the index indexes
    public init(links: InlineArray<N, Index<__LinkNode<N, Element>>>, element: consuming Element) {
        self.links = links
        self.element = element
    }
}

// MARK: - Conditional Conformances

extension __LinkNode: Copyable where Element: Copyable {}
extension __LinkNode: Sendable where Element: Sendable {}
