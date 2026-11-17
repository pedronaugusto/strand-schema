//! JSON Schema validation over strand's core: a schema compiled once into a
//! program, an instance validated by streaming the core's events through it,
//! with no tree. Its own package beside strand, on strand's core.
/// strand, the instance this module reads through: its API takes strand's
/// formats and hands out strand's types, so a consumer works through this one.
/// A program that pins strand itself gets the same instance when the pins agree.
pub const strand = @import("strand");
pub const Limits = @import("strand_schema/Limits.zig");
pub const Location = @import("strand_schema/Location.zig");
pub const Decimal = @import("strand_schema/Decimal.zig");
pub const Schema = @import("strand_schema/Schema.zig");
pub const Program = @import("strand_schema/Program.zig");
pub const Dialect = dialect.Dialect;
pub const dialect = @import("strand_schema/dialect.zig");
pub const canonical = @import("strand_schema/canonical.zig");
pub const Loader = @import("strand_schema/Loader.zig");
pub const metaschemas = @import("strand_schema/metaschemas.zig");
pub const registry = @import("strand_schema/registry.zig");

test {
    _ = Limits;
    _ = Location;
    _ = Decimal;
    _ = Loader;
    _ = metaschemas;
    _ = registry;
    _ = dialect;
    _ = canonical;
    _ = Program;
    _ = Schema;
    _ = @import("strand_schema/compile.zig");
    _ = @import("strand_schema/evaluate.zig");
    _ = @import("strand_schema/formats.zig");
    _ = @import("strand_schema/formats_test.zig");
    _ = @import("strand_schema/fuzz_test.zig");
    _ = @import("strand_schema/generated_test.zig");
    _ = @import("strand_schema/suite_test.zig");
    _ = @import("strand_schema/evaluate_test.zig");
}
