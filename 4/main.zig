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
                'n' => {
                    try writer.print("{s}", .{self.name.last});
                },
                else => {
                    try writer.print("+{d}", .{self.number});
                },
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

    pub fn joinName(self: *Self, node: *List.Node) []u8 {
        _ = self;
        const allocator = std.heap.page_allocator;
        var len1 = node.name.last.len;
        var len2 = node.name.first.len;
        var len3 = node.name.patronym.len;
        var str = allocator.alloc(u8, len1 + len2 + len3 + 2) catch @panic("out of memory");
        std.mem.copy(u8, str[0..], node.name.last);
        str[len1] = ' ';
        std.mem.copy(u8, str[(len1 + 1)..], node.name.first);
        str[len1 + len2 + 1] = ' ';
        std.mem.copy(u8, str[(len1 + len2 + 2)..], node.name.patronym);
        return str;
    }

    fn comparator(context: void, lhs: *List.Node, rhs: *List.Node) bool {
        _ = context;
        var list = std.heap.page_allocator.create(List) catch @panic("out of memory");
        defer std.heap.page_allocator.destroy(list);
        var left = joinName(list, lhs);
        var right = joinName(list, rhs);
        var len = if (left.len <= right.len) left.len else right.len;
        var i: usize = 0;
        while (i < len) : (i += 1) if (left[i] != right[i]) return left[i] < right[i];
        return if (left.len == right.len) lhs.number < rhs.number else left.len < right.len;
    }

    fn toArray(self: *const Self, allocator: std.mem.Allocator) []*List.Node {
        var array = allocator.alloc(*List.Node, self.lenght) catch @panic("out of memory");
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

    fn concat(allocator: std.mem.Allocator, str1: []u24, str2: []u24) []u24 {
        var result = allocator.alloc(u24, str1.len + str2.len) catch @panic("out of memory");
        std.mem.copy(u24, result[0..], str1);
        std.mem.copy(u24, result[str1.len..], str2);
        return result;
    }

    pub fn sort(self: *Self, allocator: std.mem.Allocator) void {
        var array = self.toArray(allocator);
        defer allocator.free(array);
        std.sort.block(*List.Node, array[0..], {}, comparator);
        self.initArr(array);
    }

    pub fn readNumber(self: *const Self, allocator: std.mem.Allocator) Err!u24 {
        _ = self;
        var stdin = std.io.getStdIn().reader();
        var buffer: [8]u8 = undefined;
        var number = allocator.create(u24) catch @panic("out of memery");
        number.* = if (stdin.readUntilDelimiterOrEof(buffer[0..], '\n') catch @panic("error, idk")) |input| std.fmt.parseInt(u24, input, 10) catch @panic("error,idk") else @as(u24, 0);
        var min: u24 = 1_000_000;
        var max: u24 = 9_999_999;
        return if (min > number.*) Err.LessThan else if (number.* > max) Err.GreaterThan else number.*;
    }

    fn findName(self: *Self, number: u24) Err![]u8 {
        var it = self.head;
        while (it) |node| : (it = node.next) {
            if (node.number == number) return node.name.last;
        }
        return Err.NotFound;
    }

    // fn findNumbers(self: *Self, name: []u8) Err!List {
    fn findNumbers(self: *Self, name: []u8) void {
        var stdout = std.io.getStdOut().writer();
        var it = self.head;
        var prev: u24 = 0;
        // why always only one element in result if create sublist?
        // var list = List{};
        while (it) |node| : ({
            prev = node.number;
            it = node.next;
        })
            if (std.mem.eql(u8, node.name.last, name) and node.number != prev)
                stdout.print("{d}\n", .{node}) catch @panic("error, idk");
        // list.prepend(node);
        // return if (list.lenght == 0) Err.NotFound else list;
    }

    pub fn init(self: *Self, allocator: std.mem.Allocator, n: usize) void {
        var stdout = std.io.getStdOut().writer();
        var stdin = std.io.getStdIn().reader();
        var i: usize = 1;
        while (i <= n) : (i += 1) {
            var node = allocator.create(List.Node) catch @panic("out of memory");
            stdout.print("Абонент №{}\n", .{i}) catch @panic("error, idk");
            stdout.print("\tФамилия: ", .{}) catch @panic("error, idk");
            if (stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', 50) catch @panic("error, idk")) |input| node.name.last = input;
            stdout.print("\tИмя: ", .{}) catch @panic("error, idk");
            if (stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', 50) catch @panic("error, idk")) |input| node.name.first = input;
            stdout.print("\tОтчество: ", .{}) catch @panic("error, idk");
            if (stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', 50) catch @panic("error, idk")) |input| node.name.patronym = input;
            stdout.print("\tНомер: ", .{}) catch @panic("error, idk");
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
    var allocator = std.heap.page_allocator;
    var stdout = std.io.getStdOut().writer();
    var stdin = std.io.getStdIn().reader();
    var buffer: [10]u8 = undefined;
    var list = List{};
    defer list.deinit(allocator);

    try stdout.print("Введите количество абонентов: ", .{});
    var n: usize = if (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |input| try std.fmt.parseInt(usize, input, 10) else @as(usize, 0);
    list.init(allocator, n);
    try stdout.print("Абоненты:\n{}", .{list});
    list.sort(allocator);
    try stdout.print("Отсортированные:\n{}Фамилия по номеру: ", .{list});
    var number: u24 = list.readNumber(allocator) catch @panic("Номер абонента должен состоять из 7 цифр");
    try stdout.print("{s}\nНомера по фамилии: ", .{list.findName(number) catch "Абонент не найден"});
    var name: []u8 = if (stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', 50) catch @panic("error, idk")) |input| input else "";
    list.findNumbers(name);
    // if (list.findNumbers(name)) |found| {
    //     try stdout.print("{d}\n", .{found});
    // } else |_| {
    //     try stdout.print("Номера не найдены\n", .{});
    // }
}

test "reverse array" {
    var allocator = std.testing.allocator;
    var list = List{};
    defer list.deinit(allocator);

    var node1 = allocator.create(List.Node) catch @panic("out of memory");
    var last1 = [_]u8{'1'};
    var first1 = [_]u8{'1'};
    var patronym1 = [_]u8{'1'};
    var number1: u24 = 1_111_111;
    node1.name = .{ .last = &last1, .first = &first1, .patronym = &patronym1 };
    node1.number = number1;
    list.prepend(node1);

    var node2 = allocator.create(List.Node) catch @panic("out of memory");
    var last2 = [_]u8{ '2', '2', '2' };
    var first2 = [_]u8{ '2', '2', '2' };
    var patronym2 = [_]u8{ '2', '2', '2' };
    var number2: u24 = 2_222_222;
    node2.name = .{ .last = &last2, .first = &first2, .patronym = &patronym2 };
    node2.number = number2;
    list.prepend(node2);

    var node3 = allocator.create(List.Node) catch @panic("out of memory");
    var last3 = [_]u8{ '3', '3' };
    var first3 = [_]u8{ '3', '3' };
    var patronym3 = [_]u8{ '3', '3' };
    var number3: u24 = 3_333_333;
    node3.name = .{ .last = &last3, .first = &first3, .patronym = &patronym3 };
    node3.number = number3;
    list.prepend(node3);

    const str_join = try std.fmt.allocPrint(allocator, "{s}", .{list.joinName(node3)});
    defer allocator.free(str_join);
    try std.testing.expectEqualStrings("33 33 33", str_join);

    var array = list.toArray(allocator);
    defer allocator.free(array);
    const str1 = try std.fmt.allocPrint(allocator, "{any}", .{array});
    defer allocator.free(str1);
    try std.testing.expectEqualStrings("{ 33 33 33: +3333333, 222 222 222: +2222222, 1 1 1: +1111111 }", str1);

    list.initArr(array);
    const str2 = try std.fmt.allocPrint(allocator, "{}", .{list});
    defer allocator.free(str2);
    try std.testing.expectEqualStrings("33 33 33: +3333333\n222 222 222: +2222222\n1 1 1: +1111111\n", str2);

    var node4 = allocator.create(List.Node) catch @panic("out of memory");
    node4.name = .{ .last = &last3, .first = &first3, .patronym = &patronym3 };
    node4.number = number3;
    list.prepend(node4);

    var node5 = allocator.create(List.Node) catch @panic("out of memory");
    node5.name = .{ .last = &last3, .first = &first3, .patronym = &patronym3 };
    var number5: u24 = 2_232_222;
    node5.number = number5;
    list.prepend(node5);

    list.sort(allocator);
    const str3 = try std.fmt.allocPrint(allocator, "{}", .{list});
    defer allocator.free(str3);
    try std.testing.expectEqualStrings("1 1 1: +1111111\n222 222 222: +2222222\n33 33 33: +2232222\n33 33 33: +3333333\n33 33 33: +3333333\n", str3);
}
