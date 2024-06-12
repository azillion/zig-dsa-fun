const std = @import("std");
const hashmap = @import("ds/hashmap.zig");
const dynamic_arrays = @import("ds/dynamic_array.zig");
const stack = @import("ds/stack.zig");

pub fn main() !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
}

test "test all ds modules" {
    _ = hashmap;
    _ = dynamic_arrays;
    _ = stack;
}
