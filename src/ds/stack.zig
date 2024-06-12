const dyn_array = @import("dynamic_array.zig");
const assert = @import("std").debug.assert;
const expect = @import("std").testing.expect;
const Allocator = @import("std").mem.Allocator;
const DynamicArray = dyn_array.DynamicArray;

pub fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();
        data: DynamicArray(T) = DynamicArray(T),

        pub fn init(self: *Self, allocator: *Allocator, capacity: u32) !void {
            try self.data.init(allocator, capacity);
        }

        pub fn deinit(self: *Self) void {
            self.data.deinit();
        }

        pub fn push(self: *Self, value: T) !void {
            try self.data.push(value);
        }

        pub fn pop(self: *Self) !T {
            return self.data.pop();
        }

        pub fn peek(self: *Self) !T {
            return self.data.get(self.data.get_length() - 1);
        }
    };
}

test "expect stack to initialize" {
    var allocator = @import("std").testing.allocator;
    const U32Stack = Stack(u32);
    var stack: U32Stack = undefined;
    try stack.init(&allocator, 10);
    defer stack.deinit();
    try expect(stack.data.get_capacity() == 10);
    try expect(stack.data.get_length() == 0);
}
