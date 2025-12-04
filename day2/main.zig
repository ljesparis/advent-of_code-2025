const std = @import("std");

const WHITESPACE: []const u8 = " \t\n\r";

fn parseInt(comptime T: type, val: []const u8) !T {
    return try std.fmt.parseInt(T, std.mem.trim(u8, val, WHITESPACE), 10);
}

fn parseRange(range: []const u8) !struct { start: usize, end: usize } {
    var it2 = std.mem.splitScalar(u8, range, '-');
    return .{
        .start = try parseInt(usize, it2.first()),
        .end = try parseInt(usize, it2.rest()),
    };
}

fn part1(input: []const u8) !i64 {
    var it = std.mem.tokenizeScalar(u8, input, ',');
    var counter: i64 = 0;
    while (it.next()) |line| {
        const range = try parseRange(line);
        for (range.start..range.end + 1) |i| {
            var buff: [1024]u8 = undefined;
            const num = try std.fmt.bufPrint(&buff, "{}", .{i});
            const mid = @divTrunc(num.len, 2);
            if (std.mem.eql(u8, num[0..mid], num[mid..])) {
                counter += @intCast(i);
            }
        }
    }
    return counter;
}

fn part2(input: []const u8) !i64 {
    var it = std.mem.tokenizeScalar(u8, input, ',');
    var counter: i64 = 0;
    while (it.next()) |line| {
        const range = try parseRange(line);
        for (range.start..range.end + 1) |i| {
            var buff: [1024]u8 = undefined;
            const num = try std.fmt.bufPrint(&buff, "{}", .{i});
            const mid = @divTrunc(num.len, 2);

            counter += blk: for (1..mid + 1) |j| {
                var it2 = std.mem.window(u8, num, j, j);
                const fist_slice: []const u8 = it2.next().?; // this is going to have something always
                const found_invalid_number: bool = invalid: while (it2.next()) |slice| {
                    if (!std.mem.eql(u8, slice, fist_slice)) {
                        break :invalid false;
                    }
                } else true;

                if (found_invalid_number) {
                    break :blk @intCast(i);
                }
            } else 0;
        }
    }
    return counter;
}

pub fn main() !void {
    const file = @embedFile("./input.txt");
    std.debug.print("day2 - part1: {}\n", .{try part1(file)});
    std.debug.print("day2 - part2: {}\n", .{try part2(file)});
}

// checking how this split works
test "splitScalar" {
    const input = "83706740-83939522";
    var it = std.mem.splitScalar(u8, input, '-');
    try std.testing.expect(std.mem.eql(u8, it.first(), "83706740"));
    try std.testing.expect(std.mem.eql(u8, it.rest(), "83939522"));
}

// checking how parsing numbers works
test "parseNumers" {
    try std.testing.expectEqual(83939522, try std.fmt.parseInt(i64, "83939522", 10));
    try std.testing.expectEqual(83706740, try std.fmt.parseInt(i64, "83706740", 10));
}

test "part1" {
    const input =
        \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124
    ;

    try std.testing.expectEqual(1227775554, part1(input));
}

test "part2" {
    const input =
        \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124
    ;

    try std.testing.expectEqual(4174379265, part2(input));
}
