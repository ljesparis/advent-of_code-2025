const std = @import("std");
const print = std.debug.print;
const pow = std.math.pow;

pub fn distance3D(p1: Point3D, p2: Point3D) f32 {
    const dx: f32 = @floatFromInt(p2.x - p1.x);
    const dy: f32 = @floatFromInt(p2.y - p1.y);
    const dz: f32 = @floatFromInt(p2.z - p1.z);
    return @sqrt(pow(f32, dx, 2) + pow(f32, dy, 2) + pow(f32, dz, 2));
}

const WHITESPACE: []const u8 = " \t\n\r";
fn parseInt(comptime T: type, val: []const u8) !T {
    return try std.fmt.parseInt(T, std.mem.trim(u8, val, WHITESPACE), 10);
}

const Point3D = struct {
    x: i32,
    y: i32,
    z: i32,
};

// structure to store distance
// between the index of two points
const PointsAB = struct {
    i: usize, // point a index
    j: usize, // point b index
    distance: f32,
};

fn UnionFind(comptime T: type) type {
    return struct {
        parent: []T,

        const Self = @This();

        fn init(size: usize, allocator: std.mem.Allocator) !Self {
            var parent: []T = try allocator.alloc(T, size);
            for (0..size) |i| {
                parent[@intCast(i)] = i;
            }

            return .{
                .parent = parent,
            };
        }

        fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            allocator.free(self.parent);
        }

        fn find(self: *Self, x: T) T {
            if (self.parent[@intCast(x)] != x) {
                self.parent[@intCast(x)] = self.find(
                    self.parent[@intCast(x)],
                );
            }

            return self.parent[@intCast(x)];
        }

        fn @"union"(self: *Self, a: T, b: T) bool {
            const root_a = self.find(a);
            const root_b = self.find(b);
            if (root_a != root_b) {
                self.parent[@intCast(root_b)] = root_a;
                return true;
            }
            return false;
        }

        fn Print(self: *Self) void {
            for (0..self.parent.len) |i| {
                print("node: {}, parent: {}\n", .{ i, self.parent[i] });
            }
        }
    };
}

fn parseInput(
    input: []const u8,
    points: *std.ArrayListUnmanaged(Point3D),
    allocator: std.mem.Allocator,
) !void {
    // parsing
    var it = std.mem.splitScalar(u8, input, '\n');
    while (it.next()) |row| {
        if (row.len < 1) break;
        var it2 = std.mem.splitScalar(u8, row, ',');
        const x: i32 = try parseInt(i32, it2.next().?);
        const y: i32 = try parseInt(i32, it2.next().?);
        const z: i32 = try parseInt(i32, it2.next().?);
        try points.append(allocator, .{ .x = x, .y = y, .z = z });
    }
}

fn combinations(
    points: *const std.ArrayListUnmanaged(Point3D),
    points_ab: *std.ArrayListUnmanaged(PointsAB),
    allocator: std.mem.Allocator,
) !void {
    // combinations of all points and its distance
    for (points.items, 0..) |point_a, i| {
        for (points.items[i + 1 ..], i + 1..) |point_b, j| {
            try points_ab.append(allocator, .{
                .i = i,
                .j = j,
                .distance = distance3D(point_a, point_b),
            });
        }
    }

    // keep the combinations with
    // the shortest distance at the top
    std.mem.sort(PointsAB, points_ab.items, {}, struct {
        fn cmp(_: void, p1: PointsAB, p2: PointsAB) bool {
            return p1.distance < p2.distance;
        }
    }.cmp);
}

fn part1(input: []const u8, connections: usize, allocator: std.mem.Allocator) !i64 {
    var points: std.ArrayListUnmanaged(Point3D) = .empty;
    defer points.deinit(allocator);
    try parseInput(input, &points, allocator);

    var count: i32 = 0;
    // 2 possible combinations
    var points_combinations: std.ArrayListUnmanaged(PointsAB) = .empty;
    defer points_combinations.deinit(allocator);
    try combinations(&points, &points_combinations, allocator);

    // Union Find
    var unionFind = try UnionFind(usize).init(points_combinations.items.len, allocator);
    defer unionFind.deinit(allocator);

    // connections is a variable defined by the problem
    for (0..connections) |i| {
        const point_ab = points_combinations.items[i];
        _ = unionFind.@"union"(point_ab.i, point_ab.j);
    }

    // count how many nodes has the same parent
    var counter: std.AutoArrayHashMapUnmanaged(usize, i32) = .empty;
    defer counter.deinit(allocator);
    for (0..points_combinations.items.len) |i| {
        const root = unionFind.find(i);
        const entry = counter.getEntry(root);
        if (entry) |e| {
            e.value_ptr.* += 1;
        } else {
            try counter.put(allocator, root, 1);
        }
    }

    // pick the first 3 with the bigger values
    const values = counter.values();
    std.mem.sort(i32, values, {}, struct {
        fn cmp(_: void, a: i32, b: i32) bool {
            return a > b;
        }
    }.cmp);
    count = values[0] * values[1] * values[2];

    return count;
}

fn part2(input: []const u8, allocator: std.mem.Allocator) !i64 {
    var points: std.ArrayListUnmanaged(Point3D) = .empty;
    defer points.deinit(allocator);
    try parseInput(input, &points, allocator);

    var count: i64 = 0;
    // 2 possible combinations
    var points_combinations: std.ArrayListUnmanaged(PointsAB) = .empty;
    defer points_combinations.deinit(allocator);
    try combinations(&points, &points_combinations, allocator);

    // Union Find
    var unionFind = try UnionFind(usize).init(points_combinations.items.len, allocator);
    defer unionFind.deinit(allocator);

    var point_ab: PointsAB = undefined;
    var cmp = points.items.len;
    var i: usize = 0;
    while (cmp > 1) : (i += 1) {
        point_ab = points_combinations.items[i];
        if (unionFind.@"union"(point_ab.i, point_ab.j)) {
            cmp -= 1;
        }
    }
    const ax: i64 = @intCast(points.items[point_ab.i].x);
    const bx: i64 = @intCast(points.items[point_ab.j].x);
    count = ax * bx;

    return count;
}

pub fn main() !void {
    const file = @embedFile("./input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        std.debug.assert(gpa.deinit() == .ok);
    }
    const allocator = gpa.allocator();

    std.debug.print("day8 - part1: {}\n", .{try part1(file, 1000, allocator)});
    std.debug.print("day8 - part2: {}\n", .{try part2(file, allocator)});
}

test "part1" {
    const input =
        \\162,817,812
        \\57,618,57
        \\906,360,560
        \\592,479,940
        \\352,342,300
        \\466,668,158
        \\542,29,236
        \\431,825,988
        \\739,650,466
        \\52,470,668
        \\216,146,977
        \\819,987,18
        \\117,168,530
        \\805,96,715
        \\346,949,466
        \\970,615,88
        \\941,993,340
        \\862,61,35
        \\984,92,344
        \\425,690,689
    ;

    try std.testing.expectEqual(40, part1(input, 10, std.testing.allocator));
}

test "part2" {
    const input =
        \\162,817,812
        \\57,618,57
        \\906,360,560
        \\592,479,940
        \\352,342,300
        \\466,668,158
        \\542,29,236
        \\431,825,988
        \\739,650,466
        \\52,470,668
        \\216,146,977
        \\819,987,18
        \\117,168,530
        \\805,96,715
        \\346,949,466
        \\970,615,88
        \\941,993,340
        \\862,61,35
        \\984,92,344
        \\425,690,689
    ;

    try std.testing.expectEqual(25272, part2(input, std.testing.allocator));
}
