const std = @import("std");

fn part1(file: std.fs.File) !usize {
    var buffer: [1024]u8 = undefined;
    var reader = file.reader(&buffer);
    var result: usize = 0;
    while (reader.interface.takeDelimiter('\n')) |line| {
        if (line) |str| {
            var lut: [256]u8 = [_]u8{0} ** 256;
            for (str, 0..) |c, i| {
                if (i >= str.len/2) {
                    if (lut[@intCast(c)] == 0) continue;

                    result += switch (c) {
                        'a'...'z' => c - 'a' + 1,
                        'A'...'Z' => c - 'A' + 27,
                        else => unreachable,
                    };
                    break;
                }
                lut[@intCast(c)] += 1;
            }
        } else break;
    } else |err| return err;
    return result;
}

fn part2(file: std.fs.File) !usize {
    var buffer: [1024]u8 = undefined;
    var reader = file.reader(&buffer);
    var result: usize = 0;

    var lut: [256]u8 = [_]u8{0} ** 256;

    var li: u8 = 0;
    while (reader.interface.takeDelimiter('\n')) |line| {
        if (line) |str| {
            for (str) |c| {
                lut[@intCast(c)] += @intFromBool(lut[@intCast(c)] == li);
            }
        } else break;
        li = @rem(li + 1, 3);
        if (li == 0) {
            for (lut, 0..) |v, c| {
                if (v != 3) continue;
                result += switch (c) {
                    'a'...'z' => c - 'a' + 1,
                    'A'...'Z' => c - 'A' + 27,
                    else => unreachable,
                };
                break;
            }
            @memset(&lut, 0);
        }
    } else |err| return err;
    return result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next();
    const filename = args.next() orelse return error.NoInputFile;

    const file = std.fs.cwd().openFile(filename, .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Part 1: {}\n", .{ try part1(file) });
    try file.seekTo(0);
    try stdout.print("Part 2: {}\n", .{ try part2(file) });
    try stdout.flush();
}

test "Part 1" {
    const file = std.fs.cwd().openFile("../inputs/2022/day03-test", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    try std.testing.expectEqual(157, try part1(file));
}

test "Part 2" {
    const file = std.fs.cwd().openFile("../inputs/2022/day03-test", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    try std.testing.expectEqual(70, try part2(file));
}
