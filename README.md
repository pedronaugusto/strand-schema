# strand_schema

JSON Schema validation for every format [strand](https://github.com/pedronaugusto/strand)
reads.

`strand_schema` validates any document strand reads against a JSON Schema: draft 2020-12
with every vocabulary, and 2019-09 and draft-07 by `$schema`. It reads through
strand's core, and through uplink's codecs for URIs, spectra for ECMAScript patterns and
almanac for RFC 3339 dates and times. `Schema.compile` reads a schema once into a program; `Schema.validate`
streams an instance through it with no tree in memory, every branch of `anyOf`, `oneOf`
and their kin read in the same pass. Numbers compare as exact decimals, so `1.0` equals
`1` and `multipleOf` is never rounded. An invalid instance is `false`, never an error;
`.basic` output gives each failing keyword with its instance location, its keyword
location and its absolute location.

References resolve by RFC 3986 against `$id`, anchors and JSON Pointers, the official
meta-schemas built in, remote documents only through a `Loader` the caller supplies.
`$dynamicRef`, `$recursiveRef`, `unevaluatedProperties` and `unevaluatedItems` follow the
specification. A schema that can apply itself again at the same place in an instance is
refused when it is compiled, so validation always finishes. Formats are annotations
unless `.formats = .assert`, and then each is a strict recognizer of its RFC's grammar;
`idn-hostname` and `idn-email` check IDNA2008 validity as written, and a caller who wants
UTS #46 mapping applies xenoglyph's `idna.toAscii` first. A pattern spectra cannot run
in linear time is refused, or with `.unsupported_pattern = .downgrade` compiled as an
annotation that every validation passing through it reports. Every bound is a
`schema.Limits` field: frames, per container state, errors, exponent, depth, schema size,
subschemas and reference chains.
[examples/validate.zig](examples/validate.zig) checks a tool's result.

```zig
const strand = @import("strand");
const strand_schema = @import("strand_schema");

var schema = try strand_schema.Schema.compile(gpa, io, strand.json, .init(
    \\{"type": "object", "required": ["city", "celsius"],
    \\ "properties": {"city": {"type": "string", "minLength": 1},
    \\   "celsius": {"type": "number", "minimum": -273.15},
    \\   "observed": {"type": "string", "format": "date-time"}},
    \\ "additionalProperties": false}
), .{ .formats = .assert });
defer schema.deinit();

var scratch: std.heap.ArenaAllocator = .init(gpa);
defer scratch.deinit();
const good = "{\"city\": \"Lisbon\", \"celsius\": 21.5, \"observed\": \"2026-10-14T09:30:00Z\"}";
std.debug.assert(try schema.validate(io, scratch.allocator(), strand.json, .init(good), .{ .flag = null }));

// An invalid result is `false`, never an error; `basic` says where and why.
var errors: strand_schema.Schema.Errors = .{};
const bad = "{\"city\": \"\", \"celsius\": -300, \"observed\": \"yesterday\"}";
std.debug.assert(!try schema.validate(io, scratch.allocator(), strand.json, .init(bad), .{ .basic = &errors }));
std.debug.assert(errors.records.len == 3);
std.debug.assert(std.mem.eql(u8, errors.records[0].instance_location, "/city"));

// The same schema reads the same result from YAML.
const yaml = "city: Porto\ncelsius: 18\n";
std.debug.assert(try schema.validate(io, scratch.allocator(), strand.yaml, .init(yaml), .{ .flag = null }));
```


## Using it

```zig
// build.zig.zon: strand_schema and strand, each pinned to a commit.
const strand_schema = b.dependency("strand_schema", .{ .target = target, .optimize = optimize });
const strand = b.dependency("strand", .{ .target = target, .optimize = optimize });
exe.root_module.addImport("strand_schema", strand_schema.module("strand_schema"));
exe.root_module.addImport("strand", strand.module("strand"));
```

strand_schema takes strand, uplink, spectra, almanac, aegis and xenoglyph with their
default options, as every library of the family takes its dependencies: options are the
application's to set. A program that reaches strand through another package as well builds
one strand, and nothing of uplink, spectra or almanac compiles unless validation reaches it.

## Stability

strand_schema is 0.x and tracks Zig 0.17.x. A breaking change comes only in a minor release,
with a CHANGELOG entry saying what changed and what to write instead.

## License

MIT; the meta-schemas under `src/strand_schema/metaschemas` are the JSON Schema organization's,
under their own licence (`src/strand_schema/metaschemas/LICENSE`).
