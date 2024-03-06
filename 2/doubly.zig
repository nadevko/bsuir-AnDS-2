const std = @import("std");
const testing = std.testing;

pub const List = struct {
    const Self = @This();

    pub const ReadError = error{ LessThan, InBetween, GreaterThan };

    pub const Node = struct { data: u24, prev: ?*Node = null, next: ?*Node = null };
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
            try writer.print(" {d: >7}", .{current.?.data});
            current = current.?.next;
        }
    }

    fn read(allocator: std.mem.Allocator) ReadError!*Node {
        const stdin = std.io.getStdIn().reader();
        var node = allocator.create(List.Node) catch @panic("out of memory");
        var buffer: [8]u8 = undefined;
        node.data = if (stdin.readUntilDelimiterOrEof(buffer[0..], '\n') catch @panic("error, idk")) |input|
            std.fmt.parseInt(u24, input, 10) catch @panic("error, idk")
        else
            @as(u24, 0);
        return if (node.data < 100) ReadError.LessThan else if (node.data > 999 and node.data < 1_000_000) ReadError.InBetween else if (node.data > 9_999_999) ReadError.GreaterThan else node;
    }

    pub fn init(self: *Self, allocator: std.mem.Allocator, n: usize) void {
        const stdout = std.io.getStdOut().writer();
        stdout.print("Введите номера на отдельных строках:\n", .{}) catch @panic("error, idk");
        var i: usize = n;
        while (i > 0) : (i -= 1) {
            self.prepend(read(allocator) catch |err| switch (err) {
                ReadError.LessThan => @panic("Номер спецслужбы должен состоять из 3 цифр"),
                ReadError.InBetween => @panic("Номера спецслужбы состоят из 3 цифр, а абонентов из 7"),
                ReadError.GreaterThan => @panic("Номер абонента должен состоять из 7 цифр"),
            }, null);
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
    var list = List{};
    var node1 = List.Node{ .data = 1 };
    var node2 = List.Node{ .data = 2 };
    list.prepend(&node1, null);
    list.prepend(&node2, &node1);
    try testing.expect(list.head.?.data == 2);
    try testing.expect(list.lenght == 2);
}

test "list to string" {
    const allocator = testing.allocator;
    var list = List{};
    var node3 = List.Node{ .data = 3 };
    var node2 = List.Node{ .data = 2 };
    var node1 = List.Node{ .data = 1 };
    list.prepend(&node2, null);
    list.prepend(&node1, &node2);
    list.append(&node3, &node2);
    const string = try std.fmt.allocPrint(allocator, "{}", .{list});
    defer allocator.free(string);
    try testing.expectEqualStrings("       1       2       3", string);
}
