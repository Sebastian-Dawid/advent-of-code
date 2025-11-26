const std = @import("std");
const Allocator = std.mem.Allocator;

const Crane = struct {
    const Command = struct {
        count: usize,
        from: usize,
        to: usize,

        fn parse(cmd: []u8) !Command {
            var self: @This() = undefined;
            var it = std.mem.splitAny(u8, cmd, " ");

            _ = it.next();
            self.count = try std.fmt.parseUnsigned(usize, it.next() orelse unreachable, 10);
            _ = it.next();
            self.from = try std.fmt.parseUnsigned(usize, it.next() orelse unreachable, 10) - 1;
            _ = it.next();
            self.to = try std.fmt.parseUnsigned(usize, it.next() orelse unreachable, 10) - 1;

            return self;
        }
    };
    allocator: Allocator,
    stacks: []std.ArrayList(u8),
    count: usize,

    fn init(reader: *std.Io.Reader, allocator: Allocator) !Crane {
        const _head = try reader.takeDelimiterExclusive('1');
        const head = try allocator.dupe(u8, _head);
        defer allocator.free(head);

        const nums = try reader.takeDelimiterExclusive('\n');
        var it = std.mem.splitAny(u8, nums, " ");
        var i: usize = 0;
        while (it.next()) |v| {
            if (v.len != 0) i += 1;
        }

        _ = try reader.take(2);

        const stacks = try allocator.alloc(std.ArrayList(u8), i);
        for (stacks) |*stack| {
            stack.* = .empty;
        }

        it = std.mem.splitAny(u8, head, "\n");
        while (it.next()) |line| {
            var j: usize = 0;
            while (j+3 <= line.len) : (j += 4) {
                if (line[j+1] != ' ') try stacks[@divExact(j, 4)].insert(allocator, 0 ,line[j+1]);
            }
        }

        return .{
            .allocator = allocator,
            .stacks = stacks,
            .count = i,
        };
    }

    fn deinit(self: *const @This()) void {
        for (self.stacks) |*stack| stack.deinit(self.allocator);
        self.allocator.free(self.stacks);
    }

    fn execute(self: *@This(), command: Command, at_once: bool) !void {
        if (at_once) {
            const from = self.stacks[command.from].items;
            try self.stacks[command.to].appendSlice(
                self.allocator,
                from[from.len-command.count..from.len],
                );
            for (0..command.count) |_| _ = self.stacks[command.from].pop();
            return;
        }
        var i: usize = 0;
        while (i < command.count) : (i += 1) {
            if (self.stacks[command.from].pop()) |v| {
                try self.stacks[command.to].append(self.allocator, v);
            }
        }
    }
};

fn part1(reader: *std.Io.Reader, allocator: Allocator) ![]u8 {
    var crane = try Crane.init(reader, allocator);
    defer crane.deinit();

    while (reader.takeDelimiter('\n')) |line| {
        if (line) |str| {
            const command = try Crane.Command.parse(str);
            try crane.execute(command, false);
        } else break;
    } else |err| return err;

    const out = try allocator.alloc(u8, crane.count);
    for (0..out.len) |i| {
        out[i] = crane.stacks[i].getLast();
    }
    return out;
}

fn part2(reader: *std.Io.Reader, allocator: Allocator) ![]u8 {
    var crane = try Crane.init(reader, allocator);
    defer crane.deinit();

    while (reader.takeDelimiter('\n')) |line| {
        if (line) |str| {
            const command = try Crane.Command.parse(str);
            try crane.execute(command, true);
        } else break;
    } else |err| return err;

    const out = try allocator.alloc(u8, crane.count);
    for (0..out.len) |i| {
        out[i] = crane.stacks[i].getLast();
    }
    return out;
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

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const p1 = try part1(reader, allocator);
    defer allocator.free(p1);
    try stdout.print("Part 1: {s}\n", .{ p1 });

    try file_reader.seekTo(0);

    const p2 = try part2(reader, allocator);
    defer allocator.free(p2);
    try stdout.print("Part 2: {s}\n", .{ p2 });
    try stdout.flush();
}

test "Part 1" {
    const file = std.fs.cwd().openFile("../inputs/2022/day05-test", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;

    var buffer: [1024]u8 = undefined;
    var file_reader = file.reader(&buffer);
    const reader = &file_reader.interface;

    const out = try part1(reader, allocator);
    defer allocator.free(out);

    try std.testing.expectEqualSlices(u8, "CMZ", out);
}

test "Part 2" {
    const file = std.fs.cwd().openFile("../inputs/2022/day05-test", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;

    var buffer: [1024]u8 = undefined;
    var file_reader = file.reader(&buffer);
    const reader = &file_reader.interface;

    const out = try part2(reader, allocator);
    defer allocator.free(out);

    try std.testing.expectEqualSlices(u8, "MCD", out);
}
