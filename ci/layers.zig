//! Source layers, lowest first. Every source has one explicit place.
const gantry = @import("gantry");

pub const layers: []const gantry.rules.Layer = &.{
    .{ .name = "vocabulary", .patterns = &.{ "src/strand_schema/Limits.zig", "src/strand_schema/Location.zig", "src/strand_schema/Decimal.zig", "src/strand_schema/dialect.zig" } },
    .{ .name = "values", .patterns = &.{"src/strand_schema/canonical.zig"} },
    .{ .name = "format grammars", .patterns = &.{ "src/strand_schema/formats/net.zig", "src/strand_schema/formats/text.zig" } },
    .{ .name = "formats", .patterns = &.{"src/strand_schema/formats.zig"} },
    .{ .name = "resolve", .patterns = &.{ "src/strand_schema/Loader.zig", "src/strand_schema/metaschemas.zig", "src/strand_schema/registry.zig" } },
    .{ .name = "program", .patterns = &.{"src/strand_schema/Program.zig"} },
    .{ .name = "compile", .patterns = &.{"src/strand_schema/compile.zig"} },
    .{ .name = "evaluate", .patterns = &.{"src/strand_schema/evaluate.zig"} },
    .{ .name = "public", .patterns = &.{"src/strand_schema/Schema.zig"} },
    .{ .name = "module", .patterns = &.{"src/strand_schema.zig"} },
};

pub const entries: []const []const u8 = &.{};

pub const required = [_][]const u8{
    "src/strand_schema.zig",
    "src/strand_schema/Schema.zig",
};

pub const modules: []const gantry.NamedModule = &.{
    .{ .name = "strand_schema", .path = "src/strand_schema.zig" },
};
pub const references: []const gantry.rules.ReferenceRule = &.{
    .{
        .name = "named dependencies",
        .unresolved_only = true,
        .except_targets = &.{
            "aegis",
            "almanac",
            "builtin",
            "json_schema_suite",
            "shakedown",
            "spectra",
            "std",
            "strand",
            "uplink.wire",
            "xenoglyph",
        },
    },
    .{ .name = "source siblings", .suffix = ".zig", .relative = true, .except_targets = &.{"src/**"} },
};
