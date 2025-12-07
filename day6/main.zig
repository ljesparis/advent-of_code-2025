const std = @import("std");

const WHITESPACE: []const u8 = " \t\n\r";
fn parseInt(comptime T: type, val: []const u8) !T {
    return try std.fmt.parseInt(T, std.mem.trim(u8, val, WHITESPACE), 10);
}

fn isSymbol(c: []const u8) bool {
    return std.mem.eql(u8, c, "+") or std.mem.eql(u8, c, "*");
}

fn part1(input: []const u8, allocator: std.mem.Allocator) !i64 {
    const Column = std.ArrayListUnmanaged(i64);
    var indexed_columns: std.AutoHashMapUnmanaged(usize, Column) = .empty;
    var symbols: std.ArrayListUnmanaged(u8) = .empty;
    defer {
        var it = indexed_columns.valueIterator();
        while (it.next()) |column| {
            column.deinit(allocator);
        }

        indexed_columns.deinit(allocator);
        symbols.deinit(allocator);
    }

    // parsing
    {
        var it = std.mem.tokenizeScalar(u8, input, '\n');
        while (it.next()) |row| {
            var it2 = std.mem.tokenizeScalar(u8, row, ' ');
            var i: usize = 0;
            while (it2.next()) |el| : (i += 1) {
                if (!isSymbol(el)) {
                    if (indexed_columns.contains(i)) {
                        var entry = indexed_columns.getEntry(i).?;
                        try entry.value_ptr.append(allocator, try parseInt(i64, el));
                    } else {
                        var column: Column = .empty;
                        try column.append(allocator, try parseInt(i64, el));
                        try indexed_columns.put(allocator, i, column);
                    }
                } else {
                    try symbols.append(allocator, el[0]);
                }
            }
        }
    }

    // compute total
    var total: i64 = 0;
    {
        var it = indexed_columns.iterator();
        while (it.next()) |entry| {
            var value: i64 = 0;
            const symbol = symbols.items[entry.key_ptr.*];
            if (symbol == '+') {
                for (entry.value_ptr.items) |n| {
                    value += n;
                }
            } else {
                value = entry.value_ptr.items[0];
                for (entry.value_ptr.items[1..]) |n| {
                    value *= n;
                }
            }

            total += value;
        }
    }

    return total;
}

pub fn Matrix(comptime T: type) type {
    return struct {
        data: [][]T = undefined,
        width: u32,
        height: u32,

        const Self = @This();

        pub fn init(width: u32, height: u32, allocator: std.mem.Allocator) Self {
            const data = allocator.alloc([]T, height) catch unreachable;

            var i: usize = 0;
            while (i < height) : (i += 1) {
                data[i] = allocator.alloc(T, width) catch unreachable;
            }

            return .{
                .width = width,
                .height = height,
                .data = data,
            };
        }

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            for (0..self.height) |y| {
                allocator.free(self.data[y]);
            }

            allocator.free(self.data);
        }
    };
}

fn part2(input: []const u8, allocator: std.mem.Allocator) !i64 {
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    const width: usize = it.peek().?.len;
    const height: usize = try std.math.divCeil(usize, @intCast(input.len), @intCast(width + 1));

    var matrix = Matrix(u8).init(@intCast(width), @intCast(height), allocator);
    defer matrix.deinit(allocator);
    {
        var y: usize = 0;
        while (it.next()) |row| : (y += 1) {
            for (0..row.len) |x| {
                matrix.data[y][x] = row[x];
            }
        }
    }

    var total: i64 = 0;
    {
        var numbers: std.ArrayListUnmanaged(i64) = .empty;
        var symbols: std.ArrayListUnmanaged(u8) = .empty;
        defer {
            numbers.deinit(allocator);
            symbols.deinit(allocator);
        }

        var x: i64 = @intCast(width - 1);
        while (x >= 0) : (x -= 1) {
            var number_as_str: std.ArrayListUnmanaged(u8) = .empty;
            defer number_as_str.deinit(allocator);
            var y: i64 = @intCast(height - 1);
            while (y >= 0) : (y -= 1) {
                const el = matrix.data[@intCast(y)][@intCast(x)];
                if (el == '+' or el == '*') {
                    try symbols.append(allocator, el);
                } else if (el >= '1' and el <= '9') {
                    try number_as_str.insert(allocator, 0, el);
                }
            }

            if (number_as_str.items.len > 0) {
                try numbers.append(allocator, try parseInt(i64, number_as_str.items));
            }

            const symbol = symbols.pop();
            if (symbol) |sym| {
                var value: i64 = 0;
                if (sym == '+') {
                    for (numbers.items) |n| {
                        value += n;
                    }
                } else {
                    value = numbers.items[0];
                    for (numbers.items[1..]) |n| {
                        value *= n;
                    }
                }

                total += value;
                numbers.clearAndFree(allocator);
            }
        }
    }

    return total;
}

pub fn main() !void {
    const file = @embedFile("./input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        std.debug.assert(gpa.deinit() == .ok);
    }
    const allocator = gpa.allocator();

    std.debug.print("day6 - part1: {}\n", .{try part1(file, allocator)});
    std.debug.print("day6 - part2: {}\n", .{try part2(file, allocator)});
}

test "part1" {
    const input =
        \\123 328  51 64 
        \\ 45 64  387 23 
        \\  6 98  215 314
        \\*   +   *   +  
    ;

    try std.testing.expectEqual(4277556, part1(input, std.testing.allocator));
}

test "part2" {
    const input =
        \\123 328  51 64 
        \\ 45 64  387 23 
        \\  6 98  215 314
        \\*   +   *   +  
    ;

    try std.testing.expectEqual(3263827, part2(input, std.testing.allocator));
}
