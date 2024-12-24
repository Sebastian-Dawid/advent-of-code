const std = @import("std");
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const Solver = struct {
    const Gate = struct {
        const Type = enum { AND, OR, XOR };

        a: [3]u8,
        b: [3]u8,
        op: Type,
        out: [3]u8,
    };
    allocator: Allocator,
    values: std.AutoArrayHashMap([3]u8, ?u1),
    unprocessed: std.ArrayList(Gate),

    fn init(file: File, allocator: Allocator) !@This() {
        var self: @This() = undefined;
        self.allocator = allocator;
        self.values = std.AutoArrayHashMap([3]u8, ?u1).init(self.allocator);
        self.unprocessed = std.ArrayList(Gate).init(self.allocator);

        var buffered_reader = std.io.bufferedReader(file.reader());
        const reader = buffered_reader.reader();

        var buffer: [64]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
            if (line.len == 0) break;
            var split = std.mem.splitAny(u8, line, ": ");
            const identifier = if (split.next()) |s| [3]u8{ s[0], s[1], s[2] } else continue;
            _ = split.next() orelse continue;
            const v = if (split.next()) |s| @as(u1, @intCast(s[0] - 0x30)) else continue;

            try self.values.put(identifier, v);
        }

        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
            var split = std.mem.splitAny(u8, line, " ");

            const a = if (split.next()) |s| [3]u8{ s[0], s[1], s[2] } else continue;
            if (self.values.get(a) == null) try self.values.put(a, null);

            const op: Gate.Type = if (split.next()) |s|
                if (std.mem.eql(u8, "OR", s)) .OR
                else if (std.mem.eql(u8, "AND", s)) .AND
                else if (std.mem.eql(u8, "XOR", s)) .XOR
                else continue
            else continue;

            const b = if (split.next()) |s| [3]u8{ s[0], s[1], s[2] } else continue;
            if (self.values.get(b) == null) try self.values.put(b, null);

            _ = split.next() orelse continue;

            const out = if (split.next()) |s| [3]u8{ s[0], s[1], s[2] } else continue;
            if (self.values.get(out) == null) try self.values.put(out, null);
    
            try self.unprocessed.append(.{ .a = a, .b = b, .op = op, .out = out });
        }

        return self;
    }

    fn deinit(self: *@This()) void {
        self.values.deinit();
        self.unprocessed.deinit();
    }

    fn processGates(self: *@This()) !void {
        while (self.unprocessed.items.len > 0) {
            for (self.unprocessed.items, 0..) |gate, i| {
                if (try self.processGate(gate)) {
                    _ = self.unprocessed.swapRemove(i);
                    break;
                }
            }
        }
    }

    fn processGate(self: *@This(), gate: Gate) !bool {
        if (self.values.get(gate.a).? == null or self.values.get(gate.b).? == null) return false;
        const a = self.values.get(gate.a).?.?;
        const b = self.values.get(gate.b).?.?;
        const v = switch (gate.op) {
            .AND => a & b,
            .OR => a | b,
            .XOR => a ^ b,
        };
        try self.values.put(gate.out, v);
        return true;
    }
};

fn stringLessThan(_: void, lhs: [3]u8, rhs: [3]u8) bool {
    return std.mem.order(u8, &lhs, &rhs) == .lt;
}

fn part1(file: File, allocator: Allocator) !u64 {
    var solver = try Solver.init(file, allocator);
    defer solver.deinit();

    try solver.processGates();

    const keys = try allocator.dupe([3]u8, solver.values.keys());
    defer allocator.free(keys);

    std.mem.sort([3]u8, keys, {}, stringLessThan);

    var sum: usize = 0;
    var count: usize = 0;
    for (keys) |k| {
       if (k[0] != 'z') continue;
       sum += solver.values.get(k).?.? * try std.math.powi(usize, 2, count);
       count += 1;
    }

    return sum;
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

test "part 1.1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day24/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(4, result);
}

test "part 1.2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day24/test_2.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(2024, result);
}
