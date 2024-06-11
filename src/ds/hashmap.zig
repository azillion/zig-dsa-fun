const Allocator = @import("std").mem.Allocator;
const assert = @import("std").debug.assert;
const expect = @import("std").testing.expect;
const eql = @import("std").mem.eql;

pub fn HashMap(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Node = struct {
            key: *[]const u8,
            value: T,
            next: ?*Node,
        };
        capacity: u32,
        size: u32,
        buckets: []?*Node,
        allocator: *Allocator,

        pub fn init(self: *Self, allocator: *Allocator, capacity: u32) !void {
            assert(capacity > 0);
            self.size = 0;
            self.capacity = capacity;
            self.allocator = allocator;
            self.buckets = try allocator.alloc(?*Node, self.capacity);

            for (self.buckets) |*bucket| {
                bucket.* = null;
            }
        }

        pub fn deinit(self: *Self) void {
            for (self.buckets) |*bucket| {
                var node = bucket.*;
                while (node) |current_node| {
                    const next = current_node.next;
                    self.allocator.destroy(current_node);
                    node = next;
                }
            }
            self.allocator.free(self.buckets);
        }

        pub fn get_capacity(self: *Self) u32 {
            return self.capacity;
        }

        pub fn get_size(self: *Self) u32 {
            return self.size;
        }

        fn hash(self: *Self, key: *[]const u8) u32 {
            assert(key.len > 0);

            var hash_key: u32 = 0;
            for (key.*) |c| {
                hash_key = hash_key * 31 + c;
            }
            return hash_key % self.capacity;
        }

        pub fn get(self: *Self, key: *[]const u8) ?T {
            const hash_key = self.hash(key);
            var node = self.buckets[hash_key];
            while (node) |current_node| {
                if (eql(u8, current_node.key.*, key.*)) {
                    return current_node.value;
                }
                node = current_node.next;
            }
            return null;
        }

        pub fn insert(self: *Self, key: *[]const u8, value: T) !void {
            const hash_key = self.hash(key);
            var node = self.buckets[hash_key];
            while (node) |current_node| {
                if (eql(u8, current_node.key.*, key.*)) {
                    current_node.value = value;
                    return;
                }
                node = current_node.next;
            }

            const new_node = try self.allocator.create(Node);
            new_node.key = key;
            new_node.value = value;
            new_node.next = self.buckets[hash_key];
            self.buckets[hash_key] = new_node;
            self.size += 1;

            const size: f32 = @floatFromInt(self.size);
            const capacity: f32 = @floatFromInt(self.capacity);
            if (size / capacity > 0.75) {
                try self.resize();
            }
        }

        pub fn remove(self: *Self, key: *[]const u8) void {
            const hash_key = self.hash(key);
            const node: ?*Node = self.buckets[hash_key];
            if (node == null) {
                return;
            }

            // we know it's not null but the compiler doesn't
            if (node) |current_node| {
                if (eql(u8, current_node.key.*, key.*)) {
                    self.buckets[hash_key] = current_node.next;
                    self.allocator.destroy(current_node);
                    self.size -= 1;
                    return;
                } else {
                    var prev_node = current_node;
                    var n = current_node.next;
                    while (n) |c_node| {
                        if (eql(u8, c_node.key.*, key.*)) {
                            prev_node.next = c_node.next;
                            self.allocator.destroy(c_node);
                            self.size -= 1;
                            return;
                        }
                        prev_node = c_node;
                        n = c_node.next;
                    }
                }
            }
        }

        pub fn clear(self: *Self) void {
            for (self.buckets) |*bucket| {
                var node = bucket.*;
                while (node) |current_node| {
                    const next = current_node.next;
                    self.allocator.destroy(current_node);
                    node = next;
                }
                bucket.* = null;
            }
            self.size = 0;
        }

        fn resize(self: *Self) !void {
            const new_capacity = self.capacity * 2;
            const new_buckets = try self.allocator.alloc(?*Node, new_capacity);

            for (new_buckets) |*bucket| {
                bucket.* = null;
            }

            for (self.buckets) |*bucket| {
                var node = bucket.*;
                while (node) |current_node| {
                    const new_hash_key = self.hash(current_node.key) % new_capacity;
                    const next = current_node.next;
                    current_node.next = new_buckets[new_hash_key];
                    new_buckets[new_hash_key] = current_node;
                    node = next;
                }
            }

            self.allocator.free(self.buckets);
            self.buckets = new_buckets;
            self.capacity = new_capacity;
        }
    };
}

test "expect hashmap to be initialized" {
    var allocator = @import("std").testing.allocator;
    const U32HashMap = HashMap(u32);
    var map: U32HashMap = undefined;
    const capacity: u32 = 16;
    try map.init(&allocator, capacity);
    defer map.deinit();
    try expect(map.capacity == capacity);
    try expect(map.size == 0);
    try expect(map.buckets[0] == null);
}

test "expect hashmap to insert and get value" {
    var allocator = @import("std").testing.allocator;
    const U32HashMap = HashMap(u32);
    var map: U32HashMap = undefined;
    const capacity: u32 = 16;
    try map.init(&allocator, capacity);
    defer map.deinit();
    var key: []const u8 = "hello";
    const value: u32 = 42;
    try map.insert(&key, value);
    try expect(map.get(&key) == value);
}

test "expect hashmap to insert duplicate keys and update value" {
    var allocator = @import("std").testing.allocator;
    const U32HashMap = HashMap(u32);
    var map: U32HashMap = undefined;
    const capacity: u32 = 16;
    try map.init(&allocator, capacity);
    defer map.deinit();
    var key: []const u8 = "hello";
    const value1: u32 = 42;
    const value2: u32 = 100;
    try map.insert(&key, value1);
    try expect(map.get(&key) == value1);
    try map.insert(&key, value2);
    try expect(map.get(&key) == value2);
}

test "expect hashmap to remove a key" {
    var allocator = @import("std").testing.allocator;
    const U32HashMap = HashMap(u32);
    var map: U32HashMap = undefined;
    const capacity: u32 = 16;
    try map.init(&allocator, capacity);
    defer map.deinit();
    var key: []const u8 = "hello";
    const value: u32 = 42;
    try map.insert(&key, value);
    try expect(map.get(&key) == value);
    map.remove(&key);
    try expect(map.get(&key) == null);
}

test "expect hashmap to clear all keys" {
    var allocator = @import("std").testing.allocator;
    const U32HashMap = HashMap(u32);
    var map: U32HashMap = undefined;
    const capacity: u32 = 16;
    try map.init(&allocator, capacity);
    defer map.deinit();
    var key1: []const u8 = "hello";
    var key2: []const u8 = "world";
    const value: u32 = 42;
    try map.insert(&key1, value);
    try map.insert(&key2, value);
    try expect(map.get(&key1) == value);
    try expect(map.get(&key2) == value);
    map.clear();
    try expect(map.get(&key1) == null);
    try expect(map.get(&key2) == null);
    try expect(map.size == 0);
}

test "expect hashmap to resize when load factor exceeds 0.75" {
    var allocator = @import("std").testing.allocator;
    const U32HashMap = HashMap(u32);
    var map: U32HashMap = undefined;
    const initial_capacity: u32 = 4;
    try map.init(&allocator, initial_capacity);
    defer map.deinit();
    const keys = &[_][]const u8{ "key1", "key2", "key3", "key4" };
    for (keys[0..]) |key| {
        var k = key; // need the key to be mutable
        try map.insert(&k, 42);
    }
    try expect(map.capacity > initial_capacity);
}

test "expect hashmap to return null for non-existent key" {
    var allocator = @import("std").testing.allocator;
    const U32HashMap = HashMap(u32);
    var map: U32HashMap = undefined;
    const capacity: u32 = 16;
    try map.init(&allocator, capacity);
    defer map.deinit();
    var key: []const u8 = "hello";
    try expect(map.get(&key) == null);
}

test "expect hashmap to insert and get string values" {
    var allocator = @import("std").testing.allocator;
    const StringHashMap = HashMap([]const u8);
    var map: StringHashMap = undefined;
    const capacity: u32 = 16;
    try map.init(&allocator, capacity);
    defer map.deinit();
    var key: []const u8 = "hello";
    const value: []const u8 = "world";
    try map.insert(&key, value);
    try expect(eql(u8, map.get(&key).?, value));
}
