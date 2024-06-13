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
            prev: ?*Node,
            next: ?*Node,
        };

        head: ?*Node = null,
        tail: ?*Node = null,
        allocator: *Allocator = undefined,

        pub fn init(self: *Self, allocator: *Allocator) void {
            self.allocator = allocator;
        }

        pub fn deinit(self: *Self) void {
            var node = self.head;
            while (node) |n| {
                const next = n.next;
                self.allocator.destroy(n);
                node = next;
            }
            self.head = null;
            self.tail = null;
        }

        pub fn get(self: *Self, index: u32) LinkedListError!T {
            if (self.head == null) {
                return LinkedListError.NodeNotFound;
            }
            var node = self.head;
            var i: u32 = 0;
            while (node != null and i < index) {
                node = node.?.next;
                i += 1;
            }
            if (node) |n| {
                return n.value;
            }
            return LinkedListError.NodeNotFound;
        }

        pub fn insert_front(self: *Self, value: T) LinkedListError!void {
            const node = self.allocator.create(Node) catch {
                return LinkedListError.MemoryAllocationFailed;
            };
            node.* = Node{ .value = value, .prev = null, .next = self.head };
            if (self.head) |head| {
                head.*.prev = node;
            }
            self.head = node;
            if (self.tail == null) {
                self.tail = node;
            }
        }

        pub fn insert_end(self: *Self, value: T) LinkedListError!void {
            const node = self.allocator.create(Node) catch {
                return LinkedListError.MemoryAllocationFailed;
            };
            node.* = Node{ .value = value, .prev = self.tail, .next = null };
            if (self.tail) |tail| {
                tail.*.next = node;
            }
            self.tail = node;
            if (self.head == null) {
                self.head = node;
            }
        }

        pub fn remove(self: *Self, index: u32) LinkedListError!void {
            if (self.head == null) {
                return LinkedListError.NodeNotFound;
            }
            var curr = self.head;
            var i: u32 = 0;
            while (curr != null and i < index) {
                curr = curr.?.next;
                i += 1;
            }
            if (i != index or curr == null) {
                return LinkedListError.NodeNotFound;
            }
            const prev = curr.?.prev;
            const next = curr.?.next;
            if (prev) |p| {
                p.next = next;
            } else {
                self.head = next;
            }
            if (next) |nx| {
                nx.prev = prev;
            } else {
                self.tail = prev;
            }
            self.allocator.destroy(curr.?);
        }

        pub fn remove_front(self: *Self) LinkedListError!void {
            if (self.head == null) {
                return LinkedListError.NodeNotFound;
            }
            const node = self.head;
            self.head = node.?.next;
            if (self.head == null) {
                self.tail = null;
            } else {
                self.head.?.prev = null;
            }
            self.allocator.destroy(node.?);
        }

        pub fn remove_end(self: *Self) LinkedListError!void {
            if (self.tail == null) {
                return LinkedListError.NodeNotFound;
            }
            const node = self.tail;
            self.tail = node.?.prev;
            if (self.tail == null) {
                self.head = null;
            } else {
                self.tail.?.next = null;
            }
            self.allocator.destroy(node.?);
        }

        pub fn get_length(self: *Self) u32 {
            var node = self.head;
            var len: u32 = 0;
            while (node != null) {
                node = node.?.next;
                len += 1;
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
                values[i] = node.?.value;
                node = node.?.next;
                i += 1;
            }
            return values;
        }
    };
}

test "expect LinkedList to initialize and deinitialize" {
    var allocator = @import("std").testing.allocator;
    const U32List = LinkedList(u32);
    var list = U32List{};
    list.init(&allocator);
    defer list.deinit();
}

test "expect LinkedList to insert and remove elements" {
    var allocator = @import("std").testing.allocator;
    const U32List = LinkedList(u32);
    var list = U32List{};
    list.init(&allocator);
    defer list.deinit();

    try list.insert_front(1);
    try list.insert_front(2);
    try list.insert_front(3);
    try list.insert_end(4);
    try list.insert_end(5);
    try list.insert_end(6);

    try expect(list.get_length() == 6);

    try list.remove(0);
    try list.remove(4);

    try expect(list.get_length() == 4);

    try list.remove_front();
    try list.remove_end();

    try expect(list.get_length() == 2);
}

test "expect LinkedList to get values" {
    var allocator = @import("std").testing.allocator;
    const U32List = LinkedList(u32);
    var list = U32List{};
    list.init(&allocator);
    defer list.deinit();

    try list.insert_front(1);
    try list.insert_front(2);
    try list.insert_front(3);
    try list.insert_end(4);
    try list.insert_end(5);
    try list.insert_end(6);

    try expect(list.get_length() == 6);

    const values = try list.get_values(&allocator);
    defer allocator.free(values);
    try expect(values[0] == 3);
    try expect(values[1] == 2);
    try expect(values[2] == 1);
    try expect(values[3] == 4);
    try expect(values[4] == 5);
    try expect(values[5] == 6);
}
