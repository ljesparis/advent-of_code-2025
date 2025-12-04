const std = @import("std");

fn parseInt(comptime T: type, val: []u8) !T {
    return try std.fmt.parseInt(T, std.mem.trim(u8, val, " \t\n\r"), 10);
}

fn part1(input: []const u8) !i64 {
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    var counter: i64 = 0;
    while (it.next()) |bank| {
        var first_max: u8 = 0;
        var index: usize = 0;
        for (0..bank.len - 1) |i| {
            const m = @max(first_max, bank[i]);
            if (m > first_max) {
                first_max = m;
                index = i;
            }
        }

        var second_max: u8 = 0;
        for (index + 1..bank.len) |i| {
            second_max = @max(second_max, bank[i]);
        }

        var buff: [3]u8 = undefined;
        const num = try std.fmt.bufPrint(&buff, "{c}{c}", .{ first_max, second_max });
        buff[buff.len - 1] = 0;

        counter += try parseInt(i64, num);
    }

    return counter;
}

fn part2(input: []const u8) !i64 {
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    var counter: i64 = 0;
    while (it.next()) |bank| {
        var bff: [1024]u8 = undefined;
        var batteries = std.ArrayList(u8).initBuffer(&bff);
        var current_index: usize = 0;

        for (0..11) |i| {
            var max_found: u8 = 0;
            var index_found: usize = 0;
            for (current_index..bank.len - 11 + i) |j| {
                const m = @max(max_found, bank[j]);
                if (m > max_found) {
                    max_found = m;
                    index_found = j;
                }
            }

            batteries.appendAssumeCapacity(max_found);
            current_index = index_found + 1;
        }

        var second_max: u8 = 0;
        for (current_index..bank.len) |i| {
            second_max = @max(second_max, bank[i]);
        }

        batteries.appendAssumeCapacity(second_max);
        counter += try parseInt(i64, batteries.items);
    }

    return counter;
}

pub fn main() !void {
    std.debug.print("day2 - part1: {}\n", .{try part1(@embedFile("./input.txt"))});
    std.debug.print("day2 - part2: {}\n", .{try part2(@embedFile("./input.txt"))});
}

test "part1" {
    const input =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ;

    try std.testing.expectEqual(357, part1(input));
}

test "part2" {
    const input =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ;

    try std.testing.expectEqual(3121910778619, part2(input));
}

test "part2.1" {
    const input =
        \\987654321111111
    ;

    try std.testing.expectEqual(987654321111, part2(input));
}

test "part2.2" {
    const input =
        \\811111111111119
    ;

    try std.testing.expectEqual(811111111119, part2(input));
}

test "part2.3" {
    const input =
        \\234234234234278
    ;

    try std.testing.expectEqual(434234234278, part2(input));
}

test "part2.4" {
    const input =
        \\818181911112111
    ;

    try std.testing.expectEqual(888911112111, part2(input));
}
