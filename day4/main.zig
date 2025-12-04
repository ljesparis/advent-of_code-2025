const std = @import("std");

// i took it from https://www.reddit.com/r/Zig/comments/i8p2cd/trying_to_make_a_generic_matrix_type/
// and i did add a few changes to release memory and build the matrix from input
pub fn Matrix(comptime T: type) type {
    return struct {
        data: [][]T = undefined,
        width: u32,
        height: u32,

        const Self = @This();

        pub fn init(width: u32, height: u32, allocator: std.mem.Allocator) Self {
            const data = allocator.alloc([]T, width) catch unreachable;

            var i: usize = 0;
            while (i < width) {
                data[i] = allocator.alloc(T, height) catch unreachable;
                i += 1;
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

        pub fn buildFromInput(input: []const u8, allocator: std.mem.Allocator) !Self {
            var it = std.mem.tokenizeScalar(u8, input, '\n');
            const width: usize = it.peek().?.len;
            const height: usize = try std.math.divCeil(usize, @intCast(input.len), @intCast(width + 1));
            var matrix: Matrix(T) = .init(@intCast(width), @intCast(height), allocator);

            var y: usize = 0;
            while (it.next()) |row| : (y += 1) {
                for (0..row.len) |x| {
                    matrix.data[y][x] = row[x];
                }
            }
            return matrix;
        }
    };
}

fn isRollOfPaper(c: u8) bool {
    return c == '@';
}

var DIRECTIONS: [8][2]i8 = .{
    // y , x
    .{ -1, -1 },
    .{ -1, 0 },
    .{ -1, 1 },
    .{ 0, -1 },
    .{ 0, 1 },
    .{ 1, -1 },
    .{ 1, 0 },
    .{ 1, 1 },
};

fn countAdjacentRollOfPapers(comptime T: type, y: i16, x: i16, matrix: *const Matrix(T)) u8 {
    var roll_of_paper_counter: u8 = 0;
    const max_y: i16 = @intCast(matrix.height);
    const max_x: i16 = @intCast(matrix.width);
    for (0..DIRECTIONS.len) |i| {
        const dir_y: i16 = DIRECTIONS[i][0];
        const dir_x: i16 = DIRECTIONS[i][1];
        const coordinate_y: i16 = y + dir_y;
        const coordinate_x: i16 = x + dir_x;

        if (coordinate_y < 0 or coordinate_y >= max_y) continue;
        if (coordinate_x < 0 or coordinate_x >= max_x) continue;

        const node = matrix.data[@intCast(coordinate_y)][@intCast(coordinate_x)];

        if (isRollOfPaper(node)) {
            roll_of_paper_counter += 1;
        }
    }

    // we need to take into account the current node
    // in the positions y and x passed as parameters
    return roll_of_paper_counter + 1;
}

fn part1(input: []const u8, allocator: std.mem.Allocator) !i64 {
    var matrix: Matrix(u8) = try .buildFromInput(input, allocator);
    defer matrix.deinit(allocator);
    var counter: i64 = 0;
    for (0..matrix.height) |y| {
        for (0..matrix.width) |x| {
            if (isRollOfPaper(matrix.data[y][x]) and countAdjacentRollOfPapers(
                u8,
                @intCast(y),
                @intCast(x),
                &matrix,
            ) <= 4) {
                counter += 1;
            }
        }
    }

    return counter;
}

fn part2(input: []const u8, allocator: std.mem.Allocator) !i64 {
    var matrix: Matrix(u8) = try .buildFromInput(input, allocator);
    defer matrix.deinit(allocator);

    var counter: i64 = 0;
    while (true) {
        var counter_by_cicly: i64 = 0;
        for (0..matrix.height) |y| {
            for (0..matrix.width) |x| {
                if (isRollOfPaper(matrix.data[y][x]) and countAdjacentRollOfPapers(
                    u8,
                    @intCast(y),
                    @intCast(x),
                    &matrix,
                ) <= 4) {
                    counter_by_cicly += 1;
                    matrix.data[y][x] = '.';
                }
            }
        }

        if (counter_by_cicly == 0) break;
        counter += counter_by_cicly;
    }

    return counter;
}

pub fn main() !void {
    const file = @embedFile("./input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        std.debug.assert(gpa.deinit() == .ok);
    }
    const allocator = gpa.allocator();
    std.debug.print("day4 - part1: {}\n", .{try part1(file, allocator)});
    std.debug.print("day4 - part2: {}\n", .{try part2(file, allocator)});
}

test "part1" {
    const input =
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
    ;

    try std.testing.expectEqual(13, part1(input, std.testing.allocator));
}

test "part2" {
    const input =
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
    ;

    try std.testing.expectEqual(43, part2(input, std.testing.allocator));
}
