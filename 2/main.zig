const std = @import("std");
const testing = std.testing;

const singly = @import("singly.zig");
const doubly = @import("doubly.zig");

pub fn main() !void {
    var allocator = std.heap.page_allocator;
    var stdout = std.io.getStdOut().writer();
    var stdin = std.io.getStdIn().reader();
    var doubly_list = doubly.List{};
    try stdout.print("Введите количество номеров: ", .{});
    var buffer: [10]u8 = undefined;
    const n: usize = if (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |input| try std.fmt.parseInt(usize, input, 10) else @as(usize, 0);
    try doubly_list.init(allocator, n);
    defer doubly_list.deinit(allocator);

    var singly_list = singly.List{};
    defer singly_list.deinit(allocator);
    var it = doubly_list.tail;
    var i: usize = 0;
    while (it) |doubly_node| : (i += 1) {
        if (i == doubly_list.lenght) break;
        if (doubly_node.data > 999_999) {
            var singly_node = try allocator.create(singly.List.Node);
            singly_node.data = doubly_node.data;
            singly_list.prepend(singly_node);
        }
        it = doubly_node.prev;
    }

    try stdout.print("Номера абонентов:{}", .{singly_list});
}
