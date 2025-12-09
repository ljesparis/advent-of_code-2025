const std = @import("std");
const print = std.debug.print;
const pow = std.math.pow;

const WHITESPACE: []const u8 = " \t\n\r";
fn parseInt(comptime T: type, val: []const u8) !T {
    return try std.fmt.parseInt(T, std.mem.trim(u8, val, WHITESPACE), 10);
}

pub fn arePointsDiagonal(p1: Point, p2: Point) bool {
    return p1.x != p2.x and p1.y != p2.y;
}

const Point = struct {
    x: i32,
    y: i32,
};

const Rect = struct {
    point: Point,
    width: i64,
    height: i64,

    const Self = @This();

    fn getRectangle(p1: Point, p2: Point) Self {
        const left = @min(p1.x, p2.x);
        const right = @max(p1.x, p2.x) + 1;
        const top = @min(p1.y, p2.y);
        const bottom = @max(p1.y, p2.y) + 1;
        const width = right - left;
        const height = bottom - top;
        return .{
            .point = p1,
            .width = width,
            .height = height,
        };
    }

    fn area(self: *const Self) i64 {
        return self.width * self.height;
    }
};

fn parseInput(input: []const u8, allocator: std.mem.Allocator, points: *std.ArrayListUnmanaged(Point)) !void {
    // parsing input
    var it = std.mem.splitScalar(u8, input, '\n');
    while (it.next()) |row| {
        if (row.len < 1) break;
        var it2 = std.mem.splitScalar(u8, row, ',');
        try points.append(allocator, .{
            .x = try parseInt(i32, it2.next().?),
            .y = try parseInt(i32, it2.next().?),
        });
    }
}

fn part1(input: []const u8, allocator: std.mem.Allocator) !i64 {
    var polygon: std.ArrayListUnmanaged(Point) = .empty;
    defer polygon.deinit(allocator);
    try parseInput(input, allocator, &polygon);

    var max_v: i64 = 0;
    for (polygon.items, 0..) |p1, i| {
        for (polygon.items[i + 1 ..]) |p2| {
            // i can find bigger rectangles
            // with diagonal points
            if (!arePointsDiagonal(p1, p2)) {
                continue;
            }

            max_v = @max(max_v, Rect.getRectangle(p1, p2).area());
        }
    }

    return max_v;
}

fn part2(input: []const u8, allocator: std.mem.Allocator) !i64 {
    _ = input;
    _ = allocator;
    return 0;
}

pub fn main() !void {
    const file = @embedFile("./input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        std.debug.assert(gpa.deinit() == .ok);
    }
    const allocator = gpa.allocator();

    std.debug.print("day9 - part1: {}\n", .{try part1(file, allocator)});
    std.debug.print("day9 - part2: {}\n", .{try part2(file, allocator)});
}

test "part1" {
    const input =
        \\7,1
        \\11,1
        \\11,7
        \\9,7
        \\9,5
        \\2,5
        \\2,3
        \\7,3
    ;

    try std.testing.expectEqual(50, part1(input, std.testing.allocator));
}

test "part2" {
    const input =
        \\7,1
        \\11,1
        \\11,7
        \\9,7
        \\9,5
        \\2,5
        \\2,3
        \\7,3
    ;

    try std.testing.expectEqual(0, part2(input, std.testing.allocator));
}
