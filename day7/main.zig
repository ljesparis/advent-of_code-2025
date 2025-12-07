const std = @import("std");
const print = std.debug.print;

const WHITESPACE: []const u8 = " \t\n\r";
fn parseInt(comptime T: type, val: []const u8) !T {
    return try std.fmt.parseInt(T, std.mem.trim(u8, val, WHITESPACE), 10);
}

pub fn Matrix(comptime T: type) type {
    return struct {
        data: [][]T = undefined,
        width: usize,
        height: usize,

        const Self = @This();

        pub fn init(width: usize, height: usize, allocator: std.mem.Allocator) Self {
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

const Position = struct {
    y: usize,
    x: usize,
    weight: i64 = 0,
};

fn part1(input: []const u8, allocator: std.mem.Allocator) !i64 {
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    const width: usize = it.peek().?.len;
    const height: usize = try std.math.divCeil(usize, @intCast(input.len), @intCast(width + 1));

    var grid: Matrix(u8) = .init(width, height, allocator);
    defer grid.deinit(allocator);

    {
        // fill grid
        var y: usize = 0;
        while (it.next()) |row| : (y += 1) {
            for (row, 0..) |c, x| {
                grid.data[y][x] = c;
            }
        }
    }

    const s_position: Position = blk: {
        // find S
        for (0..height) |y| {
            for (0..width) |x| {
                if (grid.data[y][x] == 'S') {
                    break :blk .{ .y = y, .x = x };
                }
            }
        }

        // input isn't well forme
        unreachable;
    };

    var count: i64 = 0;
    {
        var positions: std.AutoHashMapUnmanaged(Position, void) = .empty;
        try positions.put(allocator, s_position, void{});
        defer positions.deinit(allocator);
        for (0..height - 1) |_| {
            var pos_it = positions.keyIterator();
            var pos_to_eliminate: std.ArrayListUnmanaged(Position) = .empty;
            var pos_to_add: std.ArrayListUnmanaged(Position) = .empty;
            defer {
                pos_to_eliminate.deinit(allocator);
                pos_to_add.deinit(allocator);
            }

            while (pos_it.next()) |pos| {
                const node = grid.data[pos.y + 1][pos.x];
                if (node == '^') {
                    count += 1;
                    try pos_to_add.append(allocator, .{ .y = pos.y + 1, .x = pos.x + 1 });
                    try pos_to_add.append(allocator, .{ .y = pos.y + 1, .x = pos.x - 1 });
                } else {
                    try pos_to_add.append(allocator, .{ .y = pos.y + 1, .x = pos.x });
                }

                try pos_to_eliminate.append(allocator, pos.*);
            }

            for (pos_to_eliminate.items) |pos| {
                _ = positions.remove(pos);
            }

            for (pos_to_add.items) |pos| {
                try positions.put(allocator, pos, void{});
            }
        }
    }

    return count;
}

fn part2(input: []const u8, allocator: std.mem.Allocator) !i64 {
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    const width: usize = it.peek().?.len;
    const height: usize = try std.math.divCeil(usize, @intCast(input.len), @intCast(width + 1));

    var grid: Matrix(u8) = .init(width, height, allocator);
    defer grid.deinit(allocator);

    {
        // fill grid
        var y: usize = 0;
        while (it.next()) |row| : (y += 1) {
            for (row, 0..) |c, x| {
                grid.data[y][x] = c;
            }
        }
    }

    const s_position: Position = blk: {
        // find S
        for (0..height) |y| {
            for (0..width) |x| {
                if (grid.data[y][x] == 'S') {
                    break :blk .{ .y = y, .x = x, .weight = 1 };
                }
            }
        }

        // input isn't well forme
        unreachable;
    };

    var c: i64 = 0;
    {
        var positions: std.AutoHashMapUnmanaged(usize, Position) = .empty;
        try positions.put(allocator, s_position.y + s_position.x, s_position);
        defer positions.deinit(allocator);
        for (0..height - 1) |y| {
            var entry_it = positions.iterator();
            var pos_to_eliminate: std.ArrayListUnmanaged(Position) = .empty;
            var pos_to_add: std.ArrayListUnmanaged(Position) = .empty;
            defer {
                pos_to_eliminate.deinit(allocator);
                pos_to_add.deinit(allocator);
            }

            while (entry_it.next()) |entry| {
                const pos = entry.value_ptr;
                const node = grid.data[pos.y + 1][pos.x];
                if (y + 1 == height - 1) {
                    c += pos.weight;
                }
                if (node == '^') {
                    try pos_to_add.append(allocator, .{ .y = pos.y + 1, .x = pos.x + 1, .weight = pos.weight });
                    try pos_to_add.append(allocator, .{ .y = pos.y + 1, .x = pos.x - 1, .weight = pos.weight });
                } else {
                    try pos_to_add.append(allocator, .{ .y = pos.y + 1, .x = pos.x, .weight = pos.weight });
                }

                try pos_to_eliminate.append(allocator, pos.*);
            }

            for (pos_to_eliminate.items) |pos| {
                _ = positions.remove(pos.y + pos.x);
            }

            for (pos_to_add.items) |pos| {
                const entry = positions.getEntry(pos.y + pos.x);
                if (entry) |e| {
                    e.value_ptr.weight += pos.weight;
                } else {
                    try positions.put(allocator, pos.y + pos.x, pos);
                }
            }
        }
    }

    return c;
}

pub fn main() !void {
    const file = @embedFile("./input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        std.debug.assert(gpa.deinit() == .ok);
    }
    const allocator = gpa.allocator();

    std.debug.print("day7 - part1: {}\n", .{try part1(file, allocator)});
    std.debug.print("day7 - part2: {}\n", .{try part2(file, allocator)});
}

test "part1" {
    const input =
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\...............
    ;

    try std.testing.expectEqual(21, part1(input, std.testing.allocator));
}

test "part2" {
    const input =
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\...............
    ;

    try std.testing.expectEqual(40, part2(input, std.testing.allocator));
}
