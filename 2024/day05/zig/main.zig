const std = @import("std");
const Allocator = std.mem.Allocator;

const PageConstraints = struct {
    allocator: Allocator,
    before: std.ArrayList(u64),
    after: std.ArrayList(u64),

    pub fn init(allocator: Allocator) @This() {
        var self: @This() = undefined;
        self.allocator = allocator;
        self.before = std.ArrayList(u64).init(allocator);
        self.after = std.ArrayList(u64).init(allocator);
        return self;
    }
    pub fn deinit(self: *@This()) void {
        self.before.deinit();
        self.after.deinit();
    }
};
const PageMap = std.AutoHashMap(u64, PageConstraints);

fn part1(file: std.fs.File, allocator: Allocator) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();

    const stat = try file.stat();

    var page_map = PageMap.init(allocator);
    defer {
        var it = page_map.valueIterator();
        while (it.next()) |value| {
            value.deinit();
        }
        page_map.deinit();
    }

    var first_section: bool = true;
    var sum: u64 = 0;
    outer: while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) |line| {
        defer allocator.free(line);

        if (line.len == 0) {
            first_section = false;
            continue;
        }

        if (first_section) {
            var pair = std.mem.splitAny(u8, line, "|");
            const first: u64 = if (pair.next()) |num| try std.fmt.parseInt(u64, num, 10) else 0;
            const second: u64 = if (pair.next()) |num| try std.fmt.parseInt(u64, num, 10) else 0;

            if (page_map.getPtr(first)) |v| {
                try v.after.append(second);
            } else {
                var constraint = PageConstraints.init(allocator);
                try constraint.after.append(second);
                try page_map.put(first, constraint);
            }
            if (page_map.getPtr(second)) |v| {
                try v.before.append(first);
            } else {
                var constraint = PageConstraints.init(allocator);
                try constraint.before.append(first);
                try page_map.put(second, constraint);
            }

            continue;
        }

        var pages_split = std.mem.splitAny(u8, line, ",");
        var pages = std.ArrayList(u64).init(allocator);
        defer pages.deinit();
        while (pages_split.next()) |page| {
            try pages.append(try std.fmt.parseInt(u64, page, 10));
        }
        for (pages.items, 0..) |p, i| {
            const before = pages.items[0..i];
            const constraint = page_map.get(p) orelse return error.InvalidPageRules;
            for (before) |b| {
                if (cond: {
                    for (constraint.after.items) |a| {
                        if (b == a) break :cond true;
                    }
                    break :cond false;
                }) {
                    continue :outer;
                }
            }

            const after = pages.items[(i + 1)..];
            for (after) |a| {
                if (cond: {
                    for (constraint.before.items) |b| {
                        if (b == a) break :cond true;
                    }
                    break :cond false;
                }) {
                    continue :outer;
                }
            }
        }
        // if the page setup is invalid we will continue the outer loop therefore never getting here.
        sum += pages.items[(pages.items.len / 2)];
    }
    return sum;
}

fn part2(file: std.fs.File, allocator: Allocator) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();

    const stat = try file.stat();

    var page_map = PageMap.init(allocator);
    defer {
        var it = page_map.valueIterator();
        while (it.next()) |value| {
            value.deinit();
        }
        page_map.deinit();
    }

    var first_section: bool = true;
    var sum: u64 = 0;
    outer: while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) |line| {
        defer allocator.free(line);

        if (line.len == 0) {
            first_section = false;
            continue;
        }

        if (first_section) {
            var pair = std.mem.splitAny(u8, line, "|");
            const first: u64 = if (pair.next()) |num| try std.fmt.parseInt(u64, num, 10) else 0;
            const second: u64 = if (pair.next()) |num| try std.fmt.parseInt(u64, num, 10) else 0;

            if (page_map.getPtr(first)) |v| {
                try v.after.append(second);
            } else {
                var constraint = PageConstraints.init(allocator);
                try constraint.after.append(second);
                try page_map.put(first, constraint);
            }
            if (page_map.getPtr(second)) |v| {
                try v.before.append(first);
            } else {
                var constraint = PageConstraints.init(allocator);
                try constraint.before.append(first);
                try page_map.put(second, constraint);
            }

            continue;
        }

        var pages_split = std.mem.splitAny(u8, line, ",");
        var pages = std.ArrayList(u64).init(allocator);
        defer pages.deinit();
        while (pages_split.next()) |page| {
            try pages.append(try std.fmt.parseInt(u64, page, 10));
        }

        inner: for (pages.items, 0..) |p, i| {
            const before = pages.items[0..i];
            const constraint = page_map.get(p) orelse return error.InvalidPageRules;
            for (before) |b| {
                if (cond: {
                    for (constraint.after.items) |a| {
                        if (b == a) break :cond true;
                    }
                    break :cond false;
                }) {
                    break :inner;
                }
            }

            const after = pages.items[(i + 1)..];
            for (after) |a| {
                if (cond: {
                    for (constraint.before.items) |b| {
                        if (b == a) break :cond true;
                    }
                    break :cond false;
                }) {
                    break :inner;
                }
            }
        } else {
            continue :outer;
        }

        std.debug.print("{any}\n", .{pages.items});
        for (pages.items) |p| {
            std.debug.print("{}:\n", .{p});
            const constraint = page_map.get(p) orelse return error.InvalidPageRules;
            std.debug.print("\tbefore: {any}\n", .{constraint.before.items});
            std.debug.print("\tafter: {any}\n", .{constraint.after.items});
        }

        // if the page setup is valid we will continue the outer loop therefore never getting here.
        sum += pages.items[(pages.items.len / 2)];
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
    const file = std.fs.cwd().openFile("../../../inputs/2024/day05/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(143, result);
}

test "part 2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day05/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(123, result);
}
