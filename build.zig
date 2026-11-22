const std = @import("std");

/// What a project that depends on strand_schema builds: the `strand_schema`
/// module, on strand's core. Every dependency is taken with its default
/// options, as a library takes them: a program that reaches strand, almanac
/// or uplink through another package as well builds one of each. Nothing of
/// uplink, spectra or almanac compiles unless the module reaches it.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    _ = b.addModule("strand_schema", moduleOptions(b, target, optimize));
}

/// The module's root and imports, as `build` adds it and the tests build it.
fn moduleOptions(p: *std.Build, target: std.Build.ResolvedTarget, optimize: std.lang.Optimize) std.Build.Module.CreateOptions {
    const args = .{ .target = target, .optimize = optimize };
    return .{
        .root_source_file = p.path("src/strand_schema.zig"),
        .target = target,
        .optimize = optimize,
        .imports = p.allocator.dupe(std.Build.Module.Import, &.{
            .{ .name = "strand", .module = p.dependency("strand", args).module("strand") },
            .{ .name = "aegis", .module = p.dependency("aegis", args).module("aegis") },
            .{ .name = "xenoglyph", .module = p.dependency("xenoglyph", args).module("xenoglyph") },
            .{ .name = "uplink.wire", .module = p.dependency("uplink", args).module("uplink.wire") },
            .{ .name = "spectra", .module = p.dependency("spectra", args).module("spectra") },
            .{ .name = "almanac", .module = p.dependency("almanac", args).module("almanac") },
        }) catch @panic("OOM"),
    };
}

/// strand_schema's development: its tests, its example and its
/// observations, under preflight's gate. Run through bay.
pub fn dev(b: *std.Build, tools: type) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const package = b.dependency("strand_schema", .{ .target = target, .optimize = optimize });
    const p = package.builder;
    const module = package.module("strand_schema");
    const strand = p.dependency("strand", .{ .target = target, .optimize = optimize }).module("strand");
    const shakedown = b.dependency("shakedown", .{ .target = target, .optimize = optimize }).module("shakedown");

    // The tests, an executable over the module's sources, with the
    // JSON-Schema-Test-Suite embedded where the build fetched it.
    const test_filter = b.option([]const u8, "test-filter", "Select tests by name");
    const tests_module = b.createModule(moduleOptions(p, target, optimize));
    tests_module.addImport("shakedown", shakedown);
    tests_module.addImport("json_schema_suite", jsonSchemaSuite(b));
    const tests = b.addTest(.{
        .name = "strand-schema-tests",
        .filters = if (test_filter) |filter| &.{filter} else &.{},
        .root_module = tests_module,
    });
    const test_step = b.step("test", "Run strand_schema's tests and its example");
    test_step.dependOn(&b.addRunArtifact(tests).step);
    const check_step = b.step("check", "Compile the tests, the example and the observations without running them");
    check_step.dependOn(&tests.step);

    const example = b.addExecutable(.{
        .name = "validate",
        .root_module = b.createModule(.{
            .root_source_file = p.path("examples/validate.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{ .{ .name = "strand", .module = strand }, .{ .name = "strand_schema", .module = module } },
        }),
    });
    const examples_step = b.step("examples", "Build and run the example");
    examples_step.dependOn(&b.addRunArtifact(example).step);
    test_step.dependOn(examples_step);
    check_step.dependOn(&example.step);

    // The observations, in the mode a benchmark builds in.
    const bench_mode: std.lang.Optimize = .fast;
    const timed = b.dependency("strand_schema", .{ .target = target, .optimize = bench_mode });
    const validate_bench = b.addExecutable(.{
        .name = "strand-validate-bench",
        .root_module = b.createModule(.{
            .root_source_file = p.path("bench/validate.zig"),
            .target = target,
            .optimize = bench_mode,
            .imports = &.{
                .{ .name = "strand", .module = timed.builder.dependency("strand", .{ .target = target, .optimize = bench_mode }).module("strand") },
                .{ .name = "strand_schema", .module = timed.module("strand_schema") },
                .{ .name = "shakedown", .module = b.dependency("shakedown", .{ .target = target, .optimize = bench_mode }).module("shakedown") },
            },
        }),
    });
    b.step("validate-bench-build", "Compile strand_schema's observations").dependOn(&b.addInstallArtifact(validate_bench, .{}).step);
    check_step.dependOn(&validate_bench.step);
    const validate_smoke = b.addRunArtifact(validate_bench);
    validate_smoke.addArg("--smoke");
    test_step.dependOn(&validate_smoke.step);

    tools.preflight.addCi(b, p, .{
        .tests = test_step,
        .hardened = .{ .fuzz_step = "test", .tsan_step = "test" },
        .portable_tests = true,
        // `bay bench` times the observations by hand; `bay test` runs each
        // row once as a smoke.
        .bench = .{
            .programs = &.{.{ .name = "strand-validate-bench", .source = "bench/validate.zig" }},
            .imports = tools.preflight.Bench.importsFrom(benchImports),
            .target = target,
            .optimize = optimize,
        },
    });
    // A project that depends on strand_schema by path, with only the packages
    // it needs: the build a consumer gets, strand reached through the module.
    tools.preflight.addConsumerCheck(b, p, .{
        .package = "strand_schema",
        .modules = &.{"strand_schema"},
        .program = p.path("ci/consumer.zig"),
        .packages = &.{ p.dependency("strand", .{}), p.dependency("aegis", .{}), p.dependency("xenoglyph", .{}), p.dependency("uplink", .{}), p.dependency("spectra", .{}), p.dependency("almanac", .{}) },
    });
}

/// strand_schema and strand again, in the mode a benchmark builds in: an
/// imported module keeps its own mode. preflight adds shakedown.
fn benchImports(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.lang.Optimize) []const std.Build.Module.Import {
    const package = b.dependency("strand_schema", .{ .target = target, .optimize = optimize });
    return b.allocator.dupe(std.Build.Module.Import, &.{
        .{ .name = "strand_schema", .module = package.module("strand_schema") },
        .{ .name = "strand", .module = package.builder.dependency("strand", .{ .target = target, .optimize = optimize }).module("strand") },
    }) catch @panic("OOM");
}

/// The JSON-Schema-Test-Suite's validation tests, each file embedded from where
/// the build fetched them (`null` when it runs without lazy dependencies).
fn jsonSchemaSuite(b: *std.Build) *std.Build.Module {
    const files = b.addWriteFiles();
    var source: std.ArrayList(u8) = .empty;
    if (b.dependencyLazy("json_schema_test_suite", .{})) |suite| {
        source.appendSlice(b.allocator, "pub const File = struct { name: []const u8, text: []const u8 };\npub const files: ?[]const File = &.{\n") catch @panic("OOM");
        for (json_schema_suite_files) |name| {
            _ = files.addCopyFile(suite.path(b.fmt("validation/tests/{s}", .{name})), b.fmt("suite/{s}", .{name}));
            source.print(b.allocator, "    .{{ .name = \"{s}\", .text = @embedFile(\"suite/{s}\") }},\n", .{ name, name }) catch @panic("OOM");
        }
        source.appendSlice(b.allocator, "};\n") catch @panic("OOM");
    } else |_| source.appendSlice(b.allocator, "pub const File = struct { name: []const u8, text: []const u8 };\npub const files: ?[]const File = null;\n") catch @panic("OOM");
    return b.createModule(.{ .root_source_file = files.add("suite.zig", source.items) });
}

/// The suite's validation test files, listed rather than globbed: the
/// required ones and `optional/`, not `proposals/`.
const json_schema_suite_files = [_][]const u8{
    "additionalProperties.json",
    "allOf.json",
    "anchor-legacy.json",
    "anchor.json",
    "anyOf.json",
    "boolean_schema.json",
    "const.json",
    "contains.json",
    "content.json",
    "default.json",
    "dependentRequired.json",
    "dependentSchemas.json",
    "disallow.json",
    "dynamicRef.json",
    "enum.json",
    "extends.json",
    "format-color.json",
    "format-date-time.json",
    "format-date.json",
    "format-duration.json",
    "format-email.json",
    "format-host-name.json",
    "format-hostname.json",
    "format-idn-email.json",
    "format-idn-hostname.json",
    "format-ip-address.json",
    "format-ipv4.json",
    "format-ipv6.json",
    "format-iri-reference.json",
    "format-iri.json",
    "format-json-pointer.json",
    "format-regex.json",
    "format-relative-json-pointer.json",
    "format-time.json",
    "format-unknown.json",
    "format-uri-reference.json",
    "format-uri-template.json",
    "format-uri.json",
    "format-uuid.json",
    "id-legacy.json",
    "id.json",
    "if-then-else.json",
    "infinite-loop-detection-legacy.json",
    "infinite-loop-detection.json",
    "items.json",
    "maximum.json",
    "maxItems.json",
    "maxLength.json",
    "maxProperties.json",
    "minimum.json",
    "minItems.json",
    "minLength.json",
    "minProperties.json",
    "multipleOf.json",
    "not.json",
    "oneOf.json",
    "pattern.json",
    "patternProperties.json",
    "properties.json",
    "propertyNames.json",
    "recursiveRef.json",
    "ref-legacy.json",
    "ref.json",
    "required.json",
    "type.json",
    "unevaluatedItems.json",
    "unevaluatedProperties.json",
    "uniqueItems.json",
    "vocabulary.json",
    "optional/bignum.json",
    "optional/content.json",
    "optional/cross-draft.json",
    "optional/dependencies-compatibility.json",
    "optional/dynamicRef.json",
    "optional/ecmascript-regex.json",
    "optional/float-overflow.json",
    "optional/format-assertion.json",
    "optional/format-regex.json",
    "optional/format-time.json",
    "optional/non-bmp-regex.json",
    "optional/non-schemas.json",
    "optional/zero-terminated-floats.json",
};
