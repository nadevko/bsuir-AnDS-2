const std = @import("std");
const testing = std.testing;

pub const List = struct {
    const Self = @This();

    pub const Err = error{ LessThan, GreaterThan, NotFound };

    pub const Node = struct {
        const SelfNode = @This();
        name: struct {
            last: []u8,
            first: []u8,
            patronym: []u8,
        },
        number: u24,
        next: ?*Node = null,
        pub fn format(
            self: SelfNode,
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = options;
            if (fmt.len < 1) {
                try writer.print("{s} {s} {s}: +{d}", .{ self.name.last, self.name.first, self.name.patronym, self.number });
                return;
            }
            switch (fmt[0]) {
                'n' => try writer.print("{s}", .{self.name.last}),
                else => try writer.print("+{d}", .{self.number}),
            }
        }
    };
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
        _ = options;

        var i: usize = 0;
        var current = self.head;
        while (i < self.lenght) : (i += 1) {
            try writer.print("{" ++ fmt ++ "}\n", .{current.?});
            current = current.?.next;
        }
    }

    pub fn joinName(self: *Self, node: *List.Node) ![]u8 {
        _ = self;
        const allocator = std.heap.page_allocator;
        const len1 = node.name.last.len;
        const len2 = node.name.first.len;
        const len3 = node.name.patronym.len;
        var str = try allocator.alloc(u8, len1 + len2 + len3 + 2);
        std.mem.copyForwards(u8, str[0..], node.name.last);
        str[len1] = ' ';
        std.mem.copyForwards(u8, str[(len1 + 1)..], node.name.first);
        str[len1 + len2 + 1] = ' ';
        std.mem.copyForwards(u8, str[(len1 + len2 + 2)..], node.name.patronym);
        return str;
    }

    fn comparator(context: void, lhs: *List.Node, rhs: *List.Node) bool {
        _ = context;
        const list = std.heap.page_allocator.create(List) catch @panic("error, idk");
        defer std.heap.page_allocator.destroy(list);
        const left = joinName(list, lhs) catch @panic("error, idk");
        const right = joinName(list, rhs) catch @panic("error, idk");
        const len = if (left.len <= right.len) left.len else right.len;
        var i: usize = 0;
        while (i < len) : (i += 1) if (left[i] != right[i]) return left[i] < right[i];
        return if (left.len == right.len) lhs.number < rhs.number else left.len < right.len;
    }

    fn toArray(self: *const Self, allocator: std.mem.Allocator) ![]*List.Node {
        var array = try allocator.alloc(*List.Node, self.lenght);
        var current = self.head;
        var i: usize = 0;
        while (current != null) : ({
            current = current.?.next;
            i += 1;
        }) array[i] = current.?;
        return array;
    }

    pub fn initArr(self: *Self, array: []*List.Node) void {
        self.lenght = array.len;
        self.head = array[0];
        var head = self.head;
        var i: usize = 1;
        while (i < array.len) : (i += 1) {
            head.?.next = array[i];
            head = head.?.next;
        }
    }

    pub fn sort(self: *Self, allocator: std.mem.Allocator) !void {
        var array = try self.toArray(allocator);
        defer allocator.free(array);
        std.sort.block(*List.Node, array[0..], {}, comparator);
        self.initArr(array);
    }

    pub fn readNumber(self: *const Self, allocator: std.mem.Allocator) Err!u24 {
        _ = self;
        var stdin = std.io.getStdIn().reader();
        var buffer: [8]u8 = undefined;
        const number = allocator.create(u24) catch @panic("out of memery");
        number.* = if (stdin.readUntilDelimiterOrEof(buffer[0..], '\n') catch @panic("error, idk")) |input| std.fmt.parseInt(u24, input, 10) catch @panic("error,idk") else @as(u24, 0);
        const min: u24 = 1_000_000;
        const max: u24 = 9_999_999;
        return if (min > number.*) Err.LessThan else if (number.* > max) Err.GreaterThan else number.*;
    }

    fn findName(self: *Self, number: u24) Err![]u8 {
        var it = self.head;
        while (it) |node| : (it = node.next) {
            if (node.number == number) return node.name.last;
        }
        return Err.NotFound;
    }

    fn findNumbers(self: *Self, allocator: std.mem.Allocator, name: []u8) Err!List {
        var it = self.head;
        var list = List{};
        while (it) |elem| : (it = elem.next)
            if (std.mem.eql(u8, elem.name.last, name)) {
                var node = allocator.create(Node) catch @panic("error, idk");
                node.number = elem.number;
                list.prepend(node);
            };
        return if (list.lenght == 0) Err.NotFound else list;
    }

    pub fn init(self: *Self, allocator: std.mem.Allocator, n: usize) !void {
        var stdout = std.io.getStdOut().writer();
        var stdin = std.io.getStdIn().reader();
        var i: usize = 1;
        while (i <= n) : (i += 1) {
            var node = try allocator.create(List.Node);
            try stdout.print("Абонент №{}\n\tФамилия: ", .{i});
            if (try stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', 50)) |input| node.name.last = input;
            try stdout.print("\tИмя: ", .{});
            if (try stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', 50)) |input| node.name.first = input;
            try stdout.print("\tОтчество: ", .{});
            if (try stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', 50)) |input| node.name.patronym = input;
            try stdout.print("\tНомер: ", .{});
            node.number = self.readNumber(allocator) catch @panic("Номер абонента должен состоять из 7 цифр");
            self.prepend(node);
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
        self.lenght = 0;
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var stdout = std.io.getStdOut().writer();
    var stdin = std.io.getStdIn().reader();
    var buffer: [10]u8 = undefined;
    var list = List{};
    defer list.deinit(allocator);

    try stdout.print("Введите количество абонентов: ", .{});
    const n: usize = if (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |input| try std.fmt.parseInt(usize, input, 10) else @as(usize, 0);
    try list.init(allocator, n);
    try stdout.print("Абоненты:\n{}", .{list});
    try list.sort(allocator);
    try stdout.print("Отсортированные:\n{}Фамилия по номеру: ", .{list});
    const number: u24 = list.readNumber(allocator) catch @panic("Номер абонента должен состоять из 7 цифр");
    try stdout.print("{s}\nНомера по фамилии: ", .{list.findName(number) catch "Абонент не найден"});
    const name: []u8 = if (try stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', 50)) |input| input else "";
    list = list.findNumbers(allocator, name) catch {
        try stdout.print("Номера не найдены\n", .{});
        return;
    };
    var it = list.head;
    while (it) |node| : (it = node.next)
        try stdout.print("{}\n", .{node.number});
}
