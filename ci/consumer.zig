//! What a project that depends on strand_schema and nothing else writes.
//! Built with only the packages strand_schema itself needs: compiling and
//! validating are analyzed whole, every format's recognizer among them, as a
//! consumer's build analyzes them with its own copies of the dependencies.
const std = @import("std");
const strand_schema = @import("strand_schema");
const strand = strand_schema.strand;

pub fn main() void {
    _ = strand_schema.Limits;
    _ = &strand_schema.Decimal.parse;
    _ = &validateOnce;
}

fn validateOnce(gpa: std.mem.Allocator, io: std.Io) !bool {
    var s = try strand_schema.Schema.compile(gpa, io, strand.json, .init("{\"type\": \"string\", \"format\": \"uri\", \"pattern\": \"^h\"}"), .{ .formats = .assert });
    defer s.deinit();
    var errors: strand_schema.Schema.Errors = .{};
    return s.validate(io, gpa, strand.yaml, .init("http://example.com"), .{ .basic = &errors });
}
