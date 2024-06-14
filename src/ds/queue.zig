const Allocator = @import("std").mem.Allocator;
const expect = @import("std").testing.expect;
const expectError = @import("std").testing.expectError;
const sll = @import("singly_linked_list.zig");

pub fn Queue(comptime T: type) type {
    return struct {
        const Self = @This();
        list: sll.LinkedList(T) = undefined,
        allocator: *Allocator = undefined,

        pub fn init(self: *Self, allocator: *Allocator) void {
            self.allocator = allocator;
            const LL = sll.LinkedList(T);
            self.list = LL{};
            self.list.init(allocator);
        }

        pub fn deinit(self: *Self) void {
            self.list.deinit();
        }

        pub fn enqueue(self: *Self, item: T) sll.LinkedListError!void {
            try self.list.insert_head(item);
        }

        pub fn dequeue(self: *Self) sll.LinkedListError!?T {
            return try self.list.remove(0);
        }

        pub fn get_length(self: *Self) usize {
            return self.list.get_length();
        }
    };
}

test "expect queue to initialize" {
    var allocator = @import("std").testing.allocator;
    const U32Queue = Queue(u32);
    var queue = U32Queue{};
    queue.init(&allocator);
    defer queue.deinit();

    try expect(queue.list.get_length() == 0);
}

test "expect queue to enqueue and dequeue" {
    var allocator = @import("std").testing.allocator;
    const U32Queue = Queue(u32);
    var queue = U32Queue{};
    queue.init(&allocator);
    defer queue.deinit();

    try queue.enqueue(1);
    try queue.enqueue(2);
    try queue.enqueue(3);

    try comptime expect(@typeInfo(@TypeOf(try queue.dequeue())).Optional.child == u32);
    try comptime expect(@typeInfo(@TypeOf(try queue.dequeue())).Optional.child == u32);
    try comptime expect(@typeInfo(@TypeOf(try queue.dequeue())).Optional.child == u32);
    try expect(try queue.dequeue() == 3);
    try expect(try queue.dequeue() == 2);
    try expect(try queue.dequeue() == 1);
    try expectError(sll.LinkedListError.NodeNotFound, queue.dequeue());
}

test "expect queue to get length" {
    var allocator = @import("std").testing.allocator;
    const U32Queue = Queue(u32);
    var queue = U32Queue{};
    queue.init(&allocator);
    defer queue.deinit();

    try queue.enqueue(1);
    try queue.enqueue(2);
    try queue.enqueue(3);

    try expect(queue.get_length() == 3);
}
