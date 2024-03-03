const std = @import("std");
const testing = std.testing;

/// number of rounds
const N = 64;

const CircularList = struct {
    const Self = @This();

    pub const Node = struct { data: u7, next: ?*Node = null };
    head: ?*Node = null,
    tail: ?*Node = null,
    lenght: usize = 0,

    pub fn prepend(self: *Self, node: *Node) void {
        node.next = self.head orelse node;
        self.head = node;
        self.tail = self.tail orelse node;
        self.tail.?.next = self.head;
        self.lenght += 1;
    }

    pub fn append(self: *Self, node: *Node) void {
        node.next = self.head orelse node;
        self.head = self.head orelse node;
        (self.tail orelse node).next = node;
        self.tail = node;
        self.lenght += 1;
    }

    pub fn remove(self: *Self, node: *Node) void {
        if (self.head == node) {
            self.head = node.next;
            self.tail.?.next = self.head;
            return;
        }
        var current = self.head.?;
        while (current.next != node)
            current = current.next.?;
        current.next = node.next;
        self.lenght -= 1;
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
        while (current) |node| : (current = node.next) {
            try writer.print(" {d: >2}", .{node.data});
            if (node.next == self.head) break;
        }
    }

    pub fn init(self: *Self, allocator: std.mem.Allocator, n: u7) void {
        var i = n;
        while (i > 0) {
            var node = allocator.create(CircularList.Node) catch @panic("out of memory");
            node.*.data = i;
            self.prepend(node);
            i -= 1;
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

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const allocator = std.heap.page_allocator;
    var i: u7 = 1;
    while (i <= N) : (i += 1) {
        var game = CircularList{};
        game.init(allocator, i);
        defer game.deinit();
        var result = CircularList{};
        try stdout.print("{d: >2} |{s}\n", .{ i, result });
    }
}

test "prepend to list" {
    var list = CircularList{};
    var node1 = CircularList.Node{ .data = 1 };
    var node2 = CircularList.Node{ .data = 2 };
    list.prepend(&node1);
    list.prepend(&node2);
    try testing.expect(list.head.?.next.?.next.?.data == 2);
    try testing.expect(list.lenght == 2);
}

test "append to list" {
    var list = CircularList{};
    var node1 = CircularList.Node{ .data = 1 };
    var node2 = CircularList.Node{ .data = 2 };
    list.append(&node1);
    list.append(&node2);
    try testing.expect(list.head.?.next.?.next.?.data == 1);
    try testing.expect(list.lenght == 2);
}

test "remove from list" {
    var list = CircularList{};
    var node3 = CircularList.Node{ .data = 3 };
    var node2 = CircularList.Node{ .data = 2 };
    var node1 = CircularList.Node{ .data = 1 };
    list.prepend(&node3);
    list.prepend(&node2);
    list.prepend(&node1);
    list.remove(&node2);
    try testing.expect(list.head.?.next.?.next.?.next.?.data == 3);
    try testing.expect(list.lenght == 2);
}

test "list to string" {
    const allocator = testing.allocator;
    var list = CircularList{};
    var node3 = CircularList.Node{ .data = 3 };
    var node2 = CircularList.Node{ .data = 2 };
    var node1 = CircularList.Node{ .data = 1 };
    list.prepend(&node3);
    list.prepend(&node2);
    list.prepend(&node1);
    const string = try std.fmt.allocPrint(allocator, "{}", .{list});
    defer allocator.free(string);
    try testing.expectEqualStrings("  1  2  3", string);
    try testing.expect(list.lenght == 3);
}

test "filling the list" {
    const allocator = testing.allocator;
    var list = CircularList{};
    list.init(allocator, 3);
    defer list.deinit(allocator);
    const string = try std.fmt.allocPrint(allocator, "{}", .{list});
    defer allocator.free(string);
    try testing.expectEqualStrings("  1  2  3", string);
}
