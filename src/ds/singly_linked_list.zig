const Allocator = @import("std").mem.Allocator;
const expect = @import("std").testing.expect;
const expectError = @import("std").testing.expectError;

pub const LinkedListError = error{
    NodeNotFound,
    MemoryAllocationFailed,
};

pub fn LinkedList(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Node = struct {
            value: T,
            next: ?*Node,
        };

        head: ?*Node = null,
        tail: ?*Node = null,
        allocator: *Allocator = undefined,

        pub fn init(self: *Self, allocator: *Allocator) void {
            self.allocator = allocator;
            self.head = null;
            self.tail = null;
        }

        pub fn deinit(self: *Self) void {
            var node = self.head;
            while (node != null) {
                if (node) |n| {
                    const next = n.next;
                    self.allocator.destroy(n);
                    node = next;
                }
            }
        }

        pub fn get(self: *Self, index: u32) LinkedListError!T {
            if (self.head == null) {
                return LinkedListError.NodeNotFound;
            }
            var node = self.head;
            var i: u32 = 0;
            while (node != null and i < index) {
                if (node) |n| {
                    node = n.next;
                    i += 1;
                }
            }
            if (node) |n| {
                return n.value;
            }
            return LinkedListError.NodeNotFound;
        }

        pub fn insert_head(self: *Self, value: T) LinkedListError!void {
            const node = self.allocator.create(Node) catch {
                return LinkedListError.MemoryAllocationFailed;
            };
            node.* = Node{ .value = value, .next = self.head };
            self.head = node;
            if (self.tail == null) {
                self.tail = node;
            }
        }

        pub fn insert_tail(self: *Self, value: T) LinkedListError!void {
            const node = self.allocator.create(Node) catch {
                return LinkedListError.MemoryAllocationFailed;
            };
            node.* = Node{ .value = value, .next = null };
            if (self.tail) |tail| {
                tail.*.next = node;
            }
            self.tail = node;
            if (self.head == null) {
                self.head = node;
            }
        }

        pub fn remove(self: *Self, index: u32) LinkedListError!?T {
            var result: ?T = null;
            if (self.head == null) {
                return LinkedListError.NodeNotFound;
            }
            if (index == 0) {
                if (self.head) |head| {
                    self.head = head.next;
                    result = head.value;
                    self.allocator.destroy(head);
                    if (self.head == null) {
                        self.tail = null;
                    }
                }
                return result;
            }
            var node = self.head;
            var i: u32 = 0;
            while (node != null and i + 1 < index) {
                if (node) |n| {
                    node = n.next;
                    i += 1;
                }
            }
            if (i + 1 != index or node == null) {
                return LinkedListError.NodeNotFound;
            }
            if (node) |n| {
                if (n.next) |next| {
                    n.next = next.next;
                    result = next.value;
                    self.allocator.destroy(next);
                    return result;
                }
            }
            return LinkedListError.NodeNotFound;
        }

        pub fn get_length(self: *Self) u32 {
            var node = self.head;
            var len: u32 = 0;
            while (node != null) {
                if (node) |n| {
                    node = n.next;
                    len += 1;
                }
            }
            return len;
        }

        pub fn get_values(self: *Self, allocator: *Allocator) LinkedListError![]T {
            var values: []T = undefined;
            values = allocator.alloc(T, self.get_length()) catch {
                return LinkedListError.MemoryAllocationFailed;
            };
            var node = self.head;
            var i: u32 = 0;
            while (node != null) {
                if (node) |n| {
                    values[i] = n.value;
                    node = n.next;
                    i += 1;
                }
            }
            return values;
        }
    };
}

test "expect LinkedList to initialize and deinitialize" {
    var allocator = @import("std").testing.allocator;
    const U32List = LinkedList(u32);
    var list: U32List = undefined;
    list.init(&allocator);
    defer list.deinit();
}

test "expect LinkedList to insert to the head and get values" {
    var allocator = @import("std").testing.allocator;
    const U32List = LinkedList(u32);
    var list: U32List = undefined;
    list.init(&allocator);
    defer list.deinit();

    const value1: u32 = 1;
    try list.insert_head(value1);
    const value2: u32 = 2;
    try list.insert_head(value2);
    const value3: u32 = 3;
    try list.insert_head(value3);

    try expect(try list.get(0) == value3);
    try expect(try list.get(1) == value2);
    try expect(try list.get(2) == value1);
}

test "expect LinkedList to insert to the tail and get values" {
    var allocator = @import("std").testing.allocator;
    const U32List = LinkedList(u32);
    var list: U32List = undefined;
    list.init(&allocator);
    defer list.deinit();

    const value1: u32 = 1;
    try list.insert_tail(value1);
    const value2: u32 = 2;
    try list.insert_tail(value2);
    const value3: u32 = 3;
    try list.insert_tail(value3);

    try expect(try list.get(0) == value1);
    try expect(try list.get(1) == value2);
    try expect(try list.get(2) == value3);
}

test "expect LinkedList to remove values" {
    var allocator = @import("std").testing.allocator;
    const U32List = LinkedList(u32);
    var list: U32List = undefined;
    list.init(&allocator);
    defer list.deinit();

    const value1: u32 = 1;
    try list.insert_tail(value1);
    const value2: u32 = 2;
    try list.insert_tail(value2);
    const value3: u32 = 3;
    try list.insert_tail(value3);

    const val = try list.remove(1);
    try expect(val == value2);

    try expect(try list.get(0) == value1);
    try expect(try list.get(1) == value3);
}

test "expect LinkedList to return error when removing non-existing value" {
    var allocator = @import("std").testing.allocator;
    const U32List = LinkedList(u32);
    var list: U32List = undefined;
    list.init(&allocator);
    defer list.deinit();

    const value1: u32 = 1;
    try list.insert_tail(value1);
    const value2: u32 = 2;
    try list.insert_tail(value2);
    const value3: u32 = 3;
    try list.insert_tail(value3);

    try expectError(LinkedListError.NodeNotFound, list.remove(3));
}

test "expect LinkedList to return the correct length" {
    var allocator = @import("std").testing.allocator;
    const U32List = LinkedList(u32);
    var list: U32List = undefined;
    list.init(&allocator);
    defer list.deinit();

    const value1: u32 = 1;
    try list.insert_tail(value1);
    const value2: u32 = 2;
    try list.insert_tail(value2);
    const value3: u32 = 3;
    try list.insert_tail(value3);

    try expect(list.get_length() == 3);
}

test "expect LinkedList to return values" {
    var allocator = @import("std").testing.allocator;
    const U32List = LinkedList(u32);
    var list: U32List = undefined;
    list.init(&allocator);
    defer list.deinit();

    const value1: u32 = 1;
    try list.insert_tail(value1);
    const value2: u32 = 2;
    try list.insert_tail(value2);
    const value3: u32 = 3;
    try list.insert_tail(value3);

    const values = try list.get_values(&allocator);
    defer allocator.free(values);
    try expect(values[0] == value1);
    try expect(values[1] == value2);
    try expect(values[2] == value3);
}
