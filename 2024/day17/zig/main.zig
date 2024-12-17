const std = @import("std");
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const Opcode = enum(u3) {
    ADV = 0,
    BXL = 1,
    BST = 2,
    JNZ = 3,
    BXC = 4,
    OUT = 5,
    BDV = 6,
    CDV = 7,
};

const OperandType = enum(u2) { LITERAL, COMBO, IGNORED };
const OPCODE_OPERAND_TYPES = [_]OperandType{ .COMBO, .LITERAL, .COMBO, .LITERAL, .IGNORED, .COMBO, .COMBO, .COMBO };

const ComboOperand = enum(u3) {
    @"0" = 0,
    @"1" = 1,
    @"2" = 2,
    @"3" = 3,
    A = 4,
    B = 5,
    C = 6,
    INVALID = 7,
};

const Operand = union(OperandType) {
    LITERAL: u3,
    COMBO: ComboOperand,
    IGNORED,
};

const Computer = struct {
    allocator: Allocator,
    ip: u64,
    A: u64,
    B: u64,
    C: u64,
    instructions: []u3,
    out: std.ArrayList(u3),

    fn init(file: File, allocator: Allocator) !@This() {
        var self: @This() = undefined;
        self.allocator = allocator;
        self.ip = 0;

        self.out = std.ArrayList(u3).init(self.allocator);

        var buffered_reader = std.io.bufferedReader(file.reader());
        const reader = buffered_reader.reader();
        const stat = try file.stat();

        const input = try reader.readAllAlloc(allocator, stat.size);
        defer allocator.free(input);
        var split = std.mem.splitAny(u8, input, "\n:");

        _ = split.next();
        const a = split.next() orelse return error.InvalidInputFormat;
        self.A = try std.fmt.parseInt(u64, a[1..], 10);
        _ = split.next();
        const b = split.next() orelse return error.InvalidInputFormat;
        self.B = try std.fmt.parseInt(u64, b[1..], 10);
        _ = split.next();
        const c = split.next() orelse return error.InvalidInputFormat;
        self.C = try std.fmt.parseInt(u64, c[1..], 10);
        _ = split.next();
        _ = split.next();
        const program = split.next() orelse return error.InvalidInputFormat;
        var prog = std.mem.splitAny(u8, program[1..], ",");

        var size: usize = 0;
        while (prog.next()) |_| size += 1;
        self.instructions = try self.allocator.alloc(u3, size);
        prog.reset();

        var i: usize = 0;
        while (prog.next()) |o| {
            self.instructions[i] = try std.fmt.parseInt(u3, o, 10);
            i += 1;
        }

        return self;
    }
    fn deinit(self: *const @This()) void {
        self.allocator.free(self.instructions);
        self.out.deinit();
    }

    fn reset(self: *@This()) void {
        self.A = 0;
        self.B = 0;
        self.C = 0;
        self.ip = 0;
        self.out.clearAndFree();
    }

    fn step(self: *@This()) !bool {
        if (self.ip >= self.instructions.len) return false;

        const opcode: Opcode = @enumFromInt(self.instructions[self.ip]);
        var operand: Operand = undefined;
        switch (OPCODE_OPERAND_TYPES[@intFromEnum(opcode)]) {
            .LITERAL => operand = .{ .LITERAL = self.instructions[self.ip + 1] },
            .COMBO => operand = .{ .COMBO = @enumFromInt(self.instructions[self.ip + 1]) },
            .IGNORED => {},
        }

        switch (opcode) {
            .ADV, .BDV, .CDV => {
                const denom: u64 = try std.math.powi(u64, 2, switch (operand.COMBO) {
                    .INVALID => return error.InvalidOperand,
                    .A => self.A,
                    .B => self.B,
                    .C => self.C,
                    else => @intFromEnum(operand.COMBO),
                });
                switch (opcode) {
                    .ADV => self.A = self.A / denom,
                    .BDV => self.B = self.A / denom,
                    .CDV => self.C = self.A / denom,
                    else => {},
                }
            },
            .BXL => self.B = self.B ^ operand.LITERAL,
            .BXC => self.B = self.B ^ self.C,
            .BST => {
                const op: u64 = switch (operand.COMBO) {
                    .INVALID => return error.InvalidOperand,
                    .A => self.A,
                    .B => self.B,
                    .C => self.C,
                    else => @intFromEnum(operand.COMBO),
                };
                self.B = op % 8;
            },
            .JNZ => {
                if (self.A != 0) {
                    self.ip = operand.LITERAL;
                    return true;
                }
            },
            .OUT => {
                const op: u64 = switch (operand.COMBO) {
                    .INVALID => return error.InvalidOperand,
                    .A => self.A,
                    .B => self.B,
                    .C => self.C,
                    else => @intFromEnum(operand.COMBO),
                };
                try self.out.append(@as(u3, @intCast(op % 8)));
            },
        }
        self.ip += 2;

        return true;
    }

    fn output(self: *const @This(), allocator: Allocator) !?[]u8 {
        if (self.out.items.len == 0) return null;

        const size = self.out.items.len * 2 - 1;
        var buffer = try allocator.alloc(u8, size);
        buffer[0] = @as(u8, self.out.items[0]) + 0x30;
        for (self.out.items[1..], 1..) |v, i| {
            buffer[(i - 1) * 2 + 1] = ',';
            buffer[i * 2] = @as(u8, v) + 0x30;
        }
        return buffer;
    }
};

fn part1(file: File, allocator: Allocator) ![]u8 {
    var computer = try Computer.init(file, allocator);
    defer computer.deinit();

    while (try computer.step()) {}

    return try computer.output(allocator) orelse return error.NoOutput;
}

fn part2(file: File, allocator: Allocator) !u64 {
    var computer = try Computer.init(file, allocator);
    defer computer.deinit();
    var program: []u8 = try allocator.alloc(u8, computer.instructions.len * 2 - 1);
    defer allocator.free(program);
    program[0] = @as(u8, computer.instructions[0]) + 0x30;
    for (computer.instructions[1..], 1..) |v, i| {
        program[(i - 1) * 2 + 1] = ',';
        program[i * 2] = @as(u8, v) + 0x30;
    }

    var quines = std.AutoArrayHashMap(usize, void).init(allocator);
    defer quines.deinit();
    try quines.put(0, void{});

    var i: isize = @as(isize, @intCast(computer.instructions.len - 1));
    while (i >= 0) : (i -= 1) {
        const B = computer.instructions[@intCast(i)];
        var new_quine = std.AutoArrayHashMap(usize, void).init(allocator);
        defer new_quine.deinit();

        for (quines.keys()) |A| {
            var j: u4 = 0;
            while (j < 8) : (j += 1) {
                computer.reset();
                computer.A = (A << 3) + j;
                while (try computer.step()) {
                    if (@as(Opcode, @enumFromInt(computer.instructions[computer.ip])) == .JNZ) break;
                }
                if (computer.out.items[0] == B) {
                    try new_quine.put((A << 3) + j, void{});
                }
            }
        }

        quines.clearAndFree();
        quines = try new_quine.clone();
    }

    var min: usize = std.math.maxInt(usize);
    for (quines.keys()) |q| {
        if (q < min) min = q;
    }

    return min;
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
        const result = try part1(file, allocator);
        defer allocator.free(result);
        std.debug.print("Part 1: {s}\n", .{result});
    }
    {
        const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
        defer file.close();
        const result = try part2(file, allocator);
        std.debug.print("Part 2: {}\n", .{result});
    }
}

test "part 1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day17/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = try part1(file, allocator);
    defer allocator.free(result);
    try std.testing.expectEqualStrings("4,6,3,5,6,3,5,2,1,0", result);
}

test "part 2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day17/test_2.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = try part2(file, allocator);
    try std.testing.expectEqual(117_440, result);
}
