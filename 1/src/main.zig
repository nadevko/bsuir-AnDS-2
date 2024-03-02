const std = @import("std");
const testing = std.testing;

/// number of rounds
const N = 64;

const List = struct {
    const Self = @This();

    pub const Node = struct { data: u7, next: ?*Node = null };
    head: ?*Node = null,

    pub fn prepend(self: *Self, node: *Node) void {
        node.next = self.head;
        self.head = node;
    }

    pub fn remove(self: *Self, node: *Node) void {
        if (self.head == node) {
            self.head = node.next;
            return;
        }
        var current = self.head.?;
        while (current.next != node)
            current = current.next.?;
        current.next = node.next;
    }

    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        var current = self.head;
        while (current) |node| : (current = node.next)
            try writer.print(" {d: >3}", .{node.data});
    }
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var i: u7 = 0;
    while (i < N) : (i += 1) {
        try stdout.print("{d: >3} | {s}\n", .{ i, "5454" });
    }
}

test "push to list" {
    var list = List{};
    var node = List.Node{ .data = 0 };
    list.prepend(&node);
    try testing.expect(list.head.?.data == 0);
}

test "remove from list" {
    var list = List{};
    var node3 = List.Node{ .data = 3 };
    var node2 = List.Node{ .data = 2 };
    var node1 = List.Node{ .data = 1 };
    list.prepend(&node3);
    list.prepend(&node2);
    list.prepend(&node1);
    list.remove(&node2);
    try testing.expect(list.head.?.next.?.data == 3);
}

test "list to string" {
    const allocator = testing.allocator;
    var list = List{};
    var node3 = List.Node{ .data = 3 };
    var node2 = List.Node{ .data = 2 };
    var node1 = List.Node{ .data = 1 };
    list.prepend(&node3);
    list.prepend(&node2);
    list.prepend(&node1);
    const string = try std.fmt.allocPrint(allocator, "{}", .{list});
    defer allocator.free(string);
    try testing.expectEqualStrings("   1   2   3", string);
}
