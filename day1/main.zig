const std = @import("std");

const Direction = enum { LEFT, RIGHT };
const P = struct {
    dir: Direction,
    rotation: i32,

    const Self = @This();

    pub fn init(token: []const u8) !Self {
        return .{
            .dir = blk: {
                const raw_dir: u8 = token[0];
                var dir: Direction = .RIGHT;
                if (raw_dir == 'L') {
                    dir = .LEFT;
                }
                break :blk dir;
            },
            .rotation = try std.fmt.parseInt(i16, token[1..token.len], 10),
        };
    }

    pub fn getRotation(self: *const Self) i32 {
        return switch (self.dir) {
            .LEFT => -self.rotation,
            .RIGHT => self.rotation,
        };
    }
};

fn part1(input: []const u8, start_point: u8) !i32 {
    var sp: i32 = start_point;
    var password: i32 = 0;
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |token| {
        const p = try P.init(token);
        const rot = p.getRotation();
        sp += rot;
        if (@mod(sp, 100) == 0) password += 1;
    }

    return password;
}

fn part2(input: []const u8, start_point: u8) !i32 {
    var sp: i32 = start_point;
    var password: i32 = 0;
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |token| {
        const p = try P.init(token);
        const rot = p.getRotation();
        const sp_plus_rot = sp + rot;
        var rev: i32 = @intCast(@abs(@divTrunc(sp_plus_rot, 100)));
        if (sp != 0 and sp_plus_rot <= 0) {
            rev += 1;
        }

        sp = @mod(sp_plus_rot, 100);
        password += rev;
    }

    return password;
}

pub fn main() !void {
    std.debug.print("day1 - part1: {}\n", .{try part1(@embedFile("./input.txt"), 50)});
    std.debug.print("day1 - part2: {}\n", .{try part2(@embedFile("./input.txt"), 50)});
}

test "part1" {
    const input =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;

    try std.testing.expectEqual(3, part1(input, 50));
}

test "part2.1" {
    const input =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;

    try std.testing.expectEqual(6, part2(input, 50));
}
