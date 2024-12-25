const std = @import("std");
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const Lock = [5]u3;
const Key = [5]u3;

fn part1(file: File, allocator: Allocator) !u64 {
    var bufferd_reader = std.io.bufferedReader(file.reader());
    const reader = bufferd_reader.reader();

    var keys = std.ArrayList(Key).init(allocator);
    defer keys.deinit();
    var locks = std.ArrayList(Lock).init(allocator);
    defer locks.deinit();

    const buffer = try reader.readAllAlloc(allocator, (try file.stat()).size);
    defer allocator.free(buffer);

    var current: usize = 0;
    while (current < buffer.len - 41) : (current += 43) {
        const block = buffer[current..(current + 42)];

        if (block[0] == '#') {
            var lock: Lock = undefined;
            var j: usize = 0;
            while (j < 5) : (j += 1) {
                var i: usize = 1;
                while (i < 7) : (i += 1) {
                    if (block[i * 6 + j] == '.') {
                        lock[j] = @as(u3, @intCast(i - 1));
                        break;
                    }
                }
            }
            try locks.append(lock);
            continue;
        }
        var key: Lock = undefined;
        var j: usize = 0;
        while (j < 5) : (j += 1) {
            var i: usize = 1;
            while (i < 7) : (i += 1) {
                if (block[i * 6 + j] == '#') {
                    key[j] = @as(u3, @intCast(6 - i));
                    break;
                }
            }
        }
        try keys.append(key);
    }

    var count: usize = 0;
    for (locks.items) |lock| {
        for (keys.items) |key| {
            inline for (lock, 0..) |p, i| {
                if (@as(u4, p) + @as(u4, key[i]) > 5) {
                    break;
                }
            } else {
                count += 1;
            }
        }
    }

    return count;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next();
    const filename = args.next() orelse return error.FailedToOpenFile;
    {
        const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
        defer file.close();
        std.debug.print("Part 1: {}\n", .{try part1(file, allocator)});
    }
}

test "part 1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day25/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(3, result);
}
