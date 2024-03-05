const std = @import("std");
const testing = std.testing;

const SinglyList = struct {
    const Self = @This();

    pub const Node = struct { data: u7, next: ?*Node = null };
    head: ?*Node = null,
    lenght: usize = 0,

    pub fn prepend(self: *Self, node: *Node) void {
        node.next = self.head;
        self.head = node;
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
    var list = SinglyList{};
    var node1 = SinglyList.Node{ .data = 1 };
    var node2 = SinglyList.Node{ .data = 2 };
    list.prepend(&node1);
    list.prepend(&node2);
    try testing.expect(list.head.?.data == 2);
    try testing.expect(list.lenght == 2);
}

test "list to string" {
    const allocator = testing.allocator;
    var list = SinglyList{};
    var node3 = SinglyList.Node{ .data = 3 };
    var node2 = SinglyList.Node{ .data = 2 };
    var node1 = SinglyList.Node{ .data = 1 };
    list.prepend(&node3);
    list.prepend(&node2);
    list.prepend(&node1);
    const string = try std.fmt.allocPrint(allocator, "{}", .{list});
    defer allocator.free(string);
    try testing.expectEqualStrings("  1  2  3", string);
    try testing.expect(list.lenght == 3);
}
