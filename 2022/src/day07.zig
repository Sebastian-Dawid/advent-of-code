const std = @import("std");
const Allocator = std.mem.Allocator;

const FileSystem = struct {
    const Directory = struct {
        parent: ?*Directory,
        subdirectories: std.ArrayList(Directory),
        size: usize,
        name: ?[]u8,

        fn totalSize(self: *const @This()) usize {
            var total: usize = self.size;
            for (self.subdirectories.items) |sub| {
                total += sub.totalSize();
            }
            return total;
        }

        fn deinit(self: *@This(), allocator: Allocator) void {
            for (self.subdirectories.items) |*dir| dir.deinit(allocator);
            self.subdirectories.deinit(allocator);
            if (self.name) |name| allocator.free(name);
        }
    };

    allocator: Allocator,
    root: Directory,

    fn parse(reader: *std.Io.Reader, allocator: Allocator) !FileSystem {
        var fs: FileSystem = undefined;
        fs.allocator = allocator;
        fs.root = .{
            .parent = null,
            .subdirectories = .empty,
            .size = 0,
            .name = null,
        };

        var dir: *Directory = undefined;
        while (reader.takeDelimiter('\n')) |line| {
            if (line) |str| {
                switch (str[0]) {
                    '$' => {
                        var it = std.mem.splitAny(u8, str[2..str.len], " ");
                        const cmd = it.next().?;
                        if (!std.mem.eql(u8, cmd, "cd")) continue;
                        const target = it.next().?;
                        if (target[0] == '/') {
                            dir = &fs.root;
                            continue;
                        }
                        if (std.mem.eql(u8, target, "..")) {
                            dir = dir.parent orelse return error.RootHasNoParent;
                            continue;
                        }
                        for (dir.subdirectories.items) |*sub| {
                            if (std.mem.eql(u8, sub.name.?, target)) {
                                dir = sub;
                                break;
                            }
                        } else return error.DirectoryDoesNotExist;
                    },
                    'd' => {
                        var it = std.mem.splitAny(u8, str, " ");
                        _ = it.next();
                        const name = it.next().?;
                        try dir.subdirectories.append(allocator, .{
                            .parent = dir,
                            .subdirectories = .empty,
                            .size = 0,
                            .name = try allocator.dupe(u8, name),
                        });
                    },
                    '0'...'9' => {
                        var it = std.mem.splitAny(u8, str, " ");
                        const sz = it.next().?;
                        dir.size += try std.fmt.parseUnsigned(usize, sz, 10);
                    },
                    else => unreachable,
                }
            } else break;
        } else |err| return err;

        return fs;
    }

    fn deinit(self: *@This()) void {
        self.root.deinit(self.allocator);
    }
};

fn part1(dir: *const FileSystem.Directory) usize {
    var total: usize = 0;
    const sz = dir.totalSize();
    if (sz <= 100_000) total += sz;
    for (dir.subdirectories.items) |*sub| {
        total += part1(sub);
    }
    return total;
}

fn part2Impl(dir: *const FileSystem.Directory, required: usize) ?usize {
    if (dir.totalSize() < required) return null;
    var total = dir.totalSize();
    for (dir.subdirectories.items) |*sub| {
        if (part2Impl(sub, required)) |result| total = @min(total, result);
    }
    return total;
}

fn part2(fs: *const FileSystem) usize {
    const total: usize = 70_000_000;
    const required: usize = 30_000_000;
    const available: usize = total - fs.root.totalSize();
    return part2Impl(&fs.root, required - available) orelse unreachable;
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

    var buffer: [1024]u8 = undefined;
    var file_reader = file.reader(&buffer);
    const reader = &file_reader.interface;

    var fs = try FileSystem.parse(reader, allocator);
    defer fs.deinit();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Part 1: {}\n", .{ part1(&fs.root) });
    try stdout.print("Part 2: {}\n", .{ part2(&fs) });
    try stdout.flush();
}

test "Part 1" {
    const file = std.fs.cwd().openFile("../inputs/2022/day07-test", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;

    var buffer: [1024]u8 = undefined;
    var file_reader = file.reader(&buffer);
    const reader = &file_reader.interface;

    var fs = try FileSystem.parse(reader, allocator);
    defer fs.deinit();

    try std.testing.expectEqual(95437, part1(&fs.root));
}

test "Part 2" {
    const file = std.fs.cwd().openFile("../inputs/2022/day07-test", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;

    var buffer: [1024]u8 = undefined;
    var file_reader = file.reader(&buffer);
    const reader = &file_reader.interface;

    var fs = try FileSystem.parse(reader, allocator);
    defer fs.deinit();

    try std.testing.expectEqual(24933642, part2(&fs));
}
