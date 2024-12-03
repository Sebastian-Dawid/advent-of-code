const std = @import("std");
const Allocator = std.mem.Allocator;

fn part1(file: std.fs.File, allocator: Allocator) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    const stat = try file.stat();

    var sum: u64 = 0;
    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) |line| {
        defer allocator.free(line);

        var i: u64 = 0;
        outer: while (i < line.len - 7) : (i += 1) {
            const possible_length = if (line.len - i < 12) line.len - i else 12;
            const slice = line[i..(i + possible_length)];

            if (!std.mem.eql(u8, slice[0..4], "mul("))
                continue;
            var closing_index: ?u64 = null;
            for (slice, 0..) |c, j| {
                if (c == ')') {
                    closing_index = j;
                    break;
                }
            }
            if (closing_index) |j| {
                var args = std.mem.splitAny(u8, slice[4..j], ",");
                const xs = args.next() orelse continue :outer;
                if (xs.len == 0 or xs.len > 3) continue :outer;
                const x = try std.fmt.parseInt(u64, xs, 10);

                const ys = args.next() orelse continue :outer;
                if (ys.len == 0 or ys.len > 3) continue :outer;
                const y = try std.fmt.parseInt(u64, ys, 10);

                if (args.next()) |_| continue :outer;

                sum += x * y;
            }
        }
    }
    return sum;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next();
    const filename = args.next() orelse return error.NoFileGiven;
    {
        const file = std.fs.cwd().openFile(filename, .{ .mode = .read_only }) catch return error.FileNotFound;
        defer file.close();
        std.debug.print("Part 1: {}\n", .{try part1(file, allocator)});
    }
}

test "part 1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day03/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(161, result);
}
