const Allocator = @import("std").mem.Allocator;
const expect = @import("std").testing.expect;
const expectError = @import("std").testing.expectError;
const assert = @import("std").debug.assert;

pub const DynamicArrayError = error{
    OutOfBounds,
    Empty,
};

pub fn DynamicArray(comptime T: type) type {
    return struct {
        const Self = @This();
        length: u32 = undefined,
        capacity: u32 = undefined,
        items: []T = undefined,
        allocator: *Allocator = undefined,

        pub fn init(self: *Self, allocator: *Allocator, capacity: u32) !void {
            self.length = 0;
            self.capacity = capacity;
            self.allocator = allocator;
            self.items = try allocator.alloc(T, self.capacity);
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.items);
        }

        pub fn get(self: *Self, index: u32) DynamicArrayError!T {
            if (index < self.length) {
                return self.items[index];
            }
            return DynamicArrayError.OutOfBounds;
        }

        pub fn set(self: *Self, index: u32, value: T) bool {
            if (index < self.length) {
                self.items[index] = value;
                return true;
            }
            return false;
        }

        pub fn push(self: *Self, value: T) !void {
            if (self.length == self.capacity) {
                try self.resize();
            }
            self.items[self.length] = value;
            self.length += 1;
        }

        pub fn pop(self: *Self) DynamicArrayError!T {
            if (self.length == 0) {
                return DynamicArrayError.Empty;
            }
            self.length -= 1;
            return self.items[self.length];
        }

        pub fn get_length(self: *Self) u32 {
            return self.length;
        }

        pub fn get_capacity(self: *Self) u32 {
            return self.capacity;
        }

        fn resize(self: *Self) !void {
            self.capacity *= 2;
            self.items = try self.allocator.realloc(self.items, @sizeOf(T) * self.capacity);
        }
    };
}

test "expect a dynamic array to be created and initialized" {
    var allocator = @import("std").testing.allocator;
    const U32Array = DynamicArray(u32);
    var list: U32Array = undefined;
    try list.init(&allocator, 10);
    defer list.deinit();

    try expect(list.length == 0);
    try expect(list.capacity == 10);
}

test "expect push and pop operations to work correctly" {
    var allocator = @import("std").testing.allocator;
    const U32Array = DynamicArray(u32);
    var list: U32Array = undefined;
    try list.init(&allocator, 2);
    defer list.deinit();

    try list.push(1);
    try list.push(2);
    try expect(list.length == 2);
    try expect(list.capacity == 2);

    var popped_value = try list.pop();
    try expect(popped_value == 2);
    try expect(list.length == 1);

    popped_value = try list.pop();
    try expect(popped_value == 1);
    try expect(list.length == 0);

    const pop_error = list.pop();
    try expect(pop_error == DynamicArrayError.Empty);
}

test "expect dynamic array to resize correctly" {
    var allocator = @import("std").testing.allocator;
    const U32Array = DynamicArray(u32);
    var list: U32Array = undefined;
    try list.init(&allocator, 2);
    defer list.deinit();

    try list.push(1);
    try list.push(2);
    try list.push(3);

    try expect(list.length == 3);
    try expect(list.capacity == 4); // Expect capacity to double

    try expect(try list.get(0) == 1);
    try expect(try list.get(1) == 2);
    try expect(try list.get(2) == 3);
}

test "expect set and get operations to work correctly" {
    var allocator = @import("std").testing.allocator;
    const U32Array = DynamicArray(u32);
    var list: U32Array = undefined;
    try list.init(&allocator, 10);
    defer list.deinit();

    try list.push(1);
    try list.push(2);
    try list.push(3);

    try expect(try list.get(0) == 1);
    try expect(try list.get(1) == 2);
    try expect(try list.get(2) == 3);

    var result = list.set(1, 42);
    try expect(result == true);
    try expect(try list.get(1) == 42);

    result = list.set(5, 99);
    try expect(result == false);
}

test "expect get to return undefined for out of bounds access" {
    var allocator = @import("std").testing.allocator;
    const U32Array = DynamicArray(u32);
    var list: U32Array = undefined;
    try list.init(&allocator, 10);
    defer list.deinit();

    try list.push(1);

    const out_of_bounds_value = list.get(10);
    try expectError(DynamicArrayError.OutOfBounds, out_of_bounds_value);
}
