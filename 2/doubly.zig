const std = @import("std");
const testing = std.testing;

const DoublyList = struct {
    const Self = @This();

    pub const Node = struct { data: u7, prev: ?*Node = null, next: ?*Node = null };
    head: ?*Node = null,
    tail: ?*Node = null,
    lenght: usize = 0,

    pub fn prepend(self: *Self, node: *Node, before: ?*Node) void {
        node.next = before orelse self.head;
        node.prev = if (before == null) null else before.?.prev;
        (if (node.next != null) node.next.?.prev else self.tail) = node;
        (if (node.prev != null) node.prev.?.next else self.head) = node;
        self.lenght += 1;
    }

    pub fn append(self: *Self, node: *Node, after: ?*Node) void {
        node.prev = after orelse self.tail;
        node.next = if (after == null) null else after.?.next;
        (if (node.prev != null) node.prev.?.next else self.head) = node;
        (if (node.next != null) node.next.?.prev else self.tail) = node;
        self.lenght += 1;
    }

    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        var i: usize = 0;
        var current = self.head;
        while (i < self.lenght) : (i += 1) {
            try writer.print(" {d: >2}", .{current.?.data});
            current = current.?.next;
        }
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        var it = self.head;
        var i: usize = 0;
        while (it) |node| : (i += 1) {
            if (i == self.lenght) break;
            it = node.next;
            allocator.destroy(node);
        }
    }
};

test "prepend to list" {
    var list = DoublyList{};
    var node1 = DoublyList.Node{ .data = 1 };
    var node2 = DoublyList.Node{ .data = 2 };
    list.prepend(&node1, null);
    list.prepend(&node2, &node1);
    try testing.expect(list.head.?.data == 2);
    try testing.expect(list.lenght == 2);
}

test "append to list" {
    var list = DoublyList{};
    var node1 = DoublyList.Node{ .data = 1 };
    var node2 = DoublyList.Node{ .data = 2 };
    list.append(&node1, null);
    list.append(&node2, &node1);
    try testing.expect(list.head.?.data == 1);
    try testing.expect(list.lenght == 2);
}

test "list to string" {
    const allocator = testing.allocator;
    var list = DoublyList{};
    var node3 = DoublyList.Node{ .data = 3 };
    var node2 = DoublyList.Node{ .data = 2 };
    var node1 = DoublyList.Node{ .data = 1 };
    list.prepend(&node2, null);
    list.prepend(&node1, &node2);
    list.append(&node3, &node2);
    const string = try std.fmt.allocPrint(allocator, "{}", .{list});
    defer allocator.free(string);
    try testing.expectEqualStrings("  1  2  3", string);
    try testing.expect(list.lenght == 3);
}
