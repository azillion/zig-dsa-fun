const Allocator = @import("std").mem.Allocator;
const expect = @import("std").testing.expect;
const assert = @import("std").debug.assert;

pub fn DynamicArray(comptime T: type) type {
    return struct {
        const Self = @This();
        length: u32 = undefined,
        capacity: u32 = undefined,
        items: []T = undefined,
        allocator: *Allocator = undefined,

        pub fn init(self: *Self, allocator: *Allocator, capacity: u32) void {
            assert(capacity > 0);
            self.length = 0;
            self.capacity = capacity;
            self.allocator = allocator;
        }
    };
}

test "expect a dynamic array to be created" {
    var allocator = @import("std").testing.allocator;
    const U32Array = DynamicArray(u32);
    var list: U32Array = undefined;
    list.init(&allocator, 10);

    try expect(list.length == 0);
    try expect(list.capacity == 10);
}
