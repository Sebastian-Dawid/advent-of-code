const std = @import("std");
const Allocator = std.mem.Allocator;

fn part1(file: std.fs.File, allocator: Allocator) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();

    const stat = try file.stat();

    const buffer = try reader.readAllAlloc(allocator, stat.size);
    defer allocator.free(buffer);

    const line_length = if (std.mem.indexOf(u8, buffer, "\n")) |len| len + 1 else buffer.len;
    const line_count = buffer.len / line_length;

    var sum: u64 = 0;
    for (buffer, 0..) |c, i| {
        if (c != 'S' and c != 'X')
            continue;

        if (line_length - (i % line_length) >= 4) {
            const slice = buffer[i..(i+4)];
            if (std.mem.eql(u8, slice, "XMAS") or std.mem.eql(u8, slice, "SAMX"))
                sum += 1;
        }

        const current_line = 1 + (i / line_length);
        if (line_count - current_line >= 3) {
            var slice: [4]u8 = undefined;
            slice[0] = buffer[i];
            slice[1] = buffer[i + line_length];
            slice[2] = buffer[i + 2 * line_length];
            slice[3] = buffer[i + 3 * line_length];
            if (std.mem.eql(u8, &slice, "XMAS") or std.mem.eql(u8, &slice, "SAMX"))
                sum += 1;
            if (line_length - (i % line_length) >= 4) {
                slice[0] = buffer[i];
                slice[1] = buffer[i + line_length + 1];
                slice[2] = buffer[i + 2 * line_length + 2];
                slice[3] = buffer[i + 3 * line_length + 3];
                if (std.mem.eql(u8, &slice, "XMAS") or std.mem.eql(u8, &slice, "SAMX"))
                    sum += 1;
            }
            if ((i % line_length) >= 3) {
                slice[0] = buffer[i];
                slice[1] = buffer[i + line_length - 1];
                slice[2] = buffer[i + 2 * line_length - 2];
                slice[3] = buffer[i + 3 * line_length - 3];
                if (std.mem.eql(u8, &slice, "XMAS") or std.mem.eql(u8, &slice, "SAMX"))
                    sum += 1;
            }
        }
    }

    return sum;
}

fn part2(file: std.fs.File, allocator: Allocator) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();

    const stat = try file.stat();

    const buffer = try reader.readAllAlloc(allocator, stat.size);
    defer allocator.free(buffer);

    const line_length = if (std.mem.indexOf(u8, buffer, "\n")) |len| len + 1 else buffer.len;
    const line_count = buffer.len / line_length;

    var sum: u64 = 0;
    var i: u64 = 1;
    while (i < line_count - 1) : (i += 1) {
        var j: u64 = 1;
        while (j < line_length - 2) : (j += 1) {
            if (buffer[i * line_length + j] == 'A') {
                var buf = [_]u8{ buffer[(i-1) * line_length + (j - 1)], buffer[(i + 1)*line_length + (j + 1)] };
                const first = (std.mem.eql(u8, &buf, "MS") or std.mem.eql(u8, &buf, "SM"));
                buf = [_]u8{ buffer[(i-1) * line_length + (j + 1)], buffer[(i + 1)*line_length + (j - 1)] };
                const second = (std.mem.eql(u8, &buf, "MS") or std.mem.eql(u8, &buf, "SM"));
                if (first and second)
                    sum += 1;
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
    {
        const file = std.fs.cwd().openFile(filename, .{ .mode = .read_only }) catch return error.FileNotFound;
        defer file.close();
        std.debug.print("Part 2: {}\n", .{try part2(file, allocator)});
    }
}

test "part 1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day04/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(18, result);
}

test "part 2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day04/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(9, result);
}
