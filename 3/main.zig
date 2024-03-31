const std = @import("std");
const testing = std.testing;

pub const List = struct {
    const Self = @This();

    pub const Node = struct { n: u31, a: i32, next: ?*Node = null };
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
        if (current == null) {
            try writer.print("0", .{});
            return;
        }
        if (i < self.lenght) {
            i += 1;
            if (current.?.n == 0)
                try writer.print("{d}", .{current.?.a})
            else
                try writer.print("{d}x^{d}", .{ current.?.a, current.?.n });
            current = current.?.next;
        }
        while (i < self.lenght) : (i += 1) {
            if (current.?.n == 0)
                try writer.print("{d: >2}", .{current.?.a})
            else
                try writer.print("{d: >2}x^{d}", .{ current.?.a, current.?.n });
            current = current.?.next;
        }
    }

    pub fn toArray(self: *const Self, allocator: std.mem.Allocator) []i32 {
        if (self.lenght == 0) return &[_]i32{};
        var len = self.head.?.n + 1;
        var array = allocator.alloc(i32, len) catch @panic("out of memory");
        var current = self.head;
        while (current != null) : (current = current.?.next) array[current.?.n] = current.?.a;
        return array;
    }

    pub fn init(self: *Self, allocator: std.mem.Allocator, data: []i32) void {
        var n: u31 = 0;
        while (n < data.len) : (n += 1) if (data[n] != 0) {
            var node = allocator.create(List.Node) catch @panic("out of memory");
            node.*.n = n;
            node.*.a = data[n];
            self.prepend(node);
        };
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        var it = self.head;
        var i: usize = 0;
        while (it) |node| : (i += 1) {
            if (i == self.lenght) break;
            it = node.next;
            allocator.destroy(node);
        }
        self.lenght = 0;
    }
};

pub fn readList(allocator: std.mem.Allocator) List {
    var stdout = std.io.getStdOut().writer();
    var stdin = std.io.getStdIn().reader();
    stdout.print("Введите длину листа: ", .{}) catch @panic("error, idk");
    var buffer: [10]u8 = undefined;
    var n: usize = if (stdin.readUntilDelimiterOrEof(buffer[0..], '\n') catch @panic("error, idk")) |input| std.fmt.parseInt(usize, input, 10) catch @panic("error, idk") else @as(usize, 0);
    var data = allocator.alloc(i32, n) catch @panic("out of memory");
    defer allocator.free(data);
    var i: u31 = 0;
    while (i < n) : (i += 1) {
        stdout.print("\tx^{} * ", .{i}) catch @panic("error, idk");
        data[i] = if (stdin.readUntilDelimiterOrEof(buffer[0..], '\n') catch @panic("error, idk")) |input| std.fmt.parseInt(i32, input, 10) catch @panic("error, idk") else @as(i32, 0);
    }
    var list = List{};
    list.init(allocator, data);
    return list;
}

pub fn Equality(p: List, q: List) bool {
    var phead = p.head;
    var qhead = q.head;
    while (phead != null and qhead != null) : ({
        phead = phead.?.next;
        qhead = qhead.?.next;
    }) if (phead.?.a != qhead.?.a or phead.?.n != qhead.?.n) return false;
    return phead == null and qhead == null;
}

pub fn Meaning(p: List, x: i32) i32 {
    var phead = p.head;
    var sum: i32 = 0;
    while (phead != null) : (phead = phead.?.next) sum += phead.?.a * std.math.pow(i32, x, phead.?.n);
    return sum;
}

pub fn Add(allocator: std.mem.Allocator, p: List, q: List) List {
    var parr = p.toArray(allocator);
    defer allocator.free(parr);
    var qarr = q.toArray(allocator);
    defer allocator.free(qarr);
    var i: usize = 0;
    var base = if (parr.len >= qarr.len) &parr else &qarr;
    var add = if (parr.len < qarr.len) &parr else &qarr;
    while (i < add.len) : (i += 1) base.*[i] += add.*[i];
    var sum = List{};
    sum.init(allocator, base.*);
    return sum;
}

pub fn main() !void {
    var allocator = std.heap.page_allocator;
    var stdout = std.io.getStdOut().writer();
    var stdin = std.io.getStdIn().reader();
    var buffer: [10]u8 = undefined;
    var p = readList(allocator);
    defer p.deinit(allocator);
    var q = readList(allocator);
    defer q.deinit(allocator);
    try stdout.print("x_p = ", .{});
    var px: i32 = if (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |input| try std.fmt.parseInt(i32, input, 10) else @as(i32, 0);
    try stdout.print("x_q= ", .{});
    var qx: i32 = if (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |input| try std.fmt.parseInt(i32, input, 10) else @as(i32, 0);
    try stdout.print("p(x) = {}\nq(x) = {}\np {s}= q\np({}) = {}\nq({}) = {}\np + q = {}", .{ p, q, if (Equality(p, q)) "=" else "!", px, Meaning(p, px), qx, Meaning(q, qx), Add(allocator, p, q) });
}
