const std = @import("std");

const WHITESPACE: []const u8 = " \t\n\r";

fn parseInt(comptime T: type, val: []const u8) !T {
    return try std.fmt.parseInt(T, std.mem.trim(u8, val, WHITESPACE), 10);
}

const Range = struct { start: i64, end: i64 };

fn part1(input: []const u8, allocator: std.mem.Allocator) !i64 {
    var ranges: std.ArrayListUnmanaged(Range) = .empty;
    var valid_ids: std.ArrayListUnmanaged(i64) = .empty;

    defer {
        ranges.deinit(allocator);
        valid_ids.deinit(allocator);
    }

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    var counter: i64 = 0;
    while (it.next()) |tmp| {
        if (std.mem.containsAtLeastScalar(u8, tmp, 1, '-')) {
            var ranges_it = std.mem.tokenizeScalar(u8, tmp, '-');
            const start = try parseInt(i64, ranges_it.next().?);
            const end = try parseInt(i64, ranges_it.next().?);
            try ranges.append(allocator, .{ .start = start, .end = end });
        } else {
            try valid_ids.append(allocator, try parseInt(i64, tmp));
        }
    }

    for (valid_ids.items) |id| {
        for (ranges.items) |range| {
            if (id >= range.start and id <= range.end) {
                counter += 1;
                break;
            }
        }
    }
    return counter;
}

fn part2(input: []const u8, allocator: std.mem.Allocator) !i64 {
    var ranges: std.ArrayListUnmanaged(Range) = .empty;
    defer ranges.deinit(allocator);
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |tmp| {
        if (!std.mem.containsAtLeastScalar(u8, tmp, 1, '-')) break;

        var ranges_it = std.mem.tokenizeScalar(u8, tmp, '-');
        const start = try parseInt(i64, ranges_it.next().?);
        const end = try parseInt(i64, ranges_it.next().?);
        try ranges.append(allocator, .{ .start = start, .end = end });
    }

    std.mem.sort(Range, ranges.items, {}, struct {
        pub fn inner(_: void, a: Range, b: Range) bool {
            return a.start < b.start;
        }
    }.inner);

    var seen_ranges: std.ArrayListUnmanaged(Range) = .empty;
    defer seen_ranges.deinit(allocator);
    for (ranges.items) |current_range| {
        var i: usize = 0;
        var overlap: bool = false;
        while (i < seen_ranges.items.len) : (i += 1) {
            var seen_range: *Range = &seen_ranges.items[i];
            // current range already seen
            if (seen_range.start <= current_range.start and seen_range.end >= current_range.end) {
                overlap = true;
            } else if (current_range.start >= seen_range.start and current_range.start <= seen_range.end and current_range.end > seen_range.end) {
                seen_range.end = current_range.end;
                overlap = true;
            } else if (current_range.end >= seen_range.start and current_range.end <= seen_range.end and current_range.start < seen_range.start) {
                seen_range.start = current_range.start;
                overlap = true;
            }
        }

        if (!overlap) {
            try seen_ranges.append(allocator, current_range);
        }
    }

    var valid_ids: i64 = 0;
    for (seen_ranges.items) |range| {
        valid_ids += range.end - range.start + 1;
    }

    return valid_ids;
}

pub fn main() !void {
    const file = @embedFile("./input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        std.debug.assert(gpa.deinit() == .ok);
    }
    const allocator = gpa.allocator();

    std.debug.print("day5 - part1: {}\n", .{try part1(file, allocator)});
    std.debug.print("day5 - part2: {}\n", .{try part2(file, allocator)});
}

test "part1" {
    const input =
        \\3-5
        \\10-14
        \\16-20
        \\12-18
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
    ;

    try std.testing.expectEqual(3, part1(input, std.testing.allocator));
}

test "part2" {
    const input =
        \\3-5
        \\10-14
        \\16-20
        \\12-18
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
    ;

    try std.testing.expectEqual(14, part2(input, std.testing.allocator));
}

test "part2.1" {
    const input =
        \\3-5
        \\10-14
        \\9-20
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
    ;

    try std.testing.expectEqual(15, part2(input, std.testing.allocator));
}
