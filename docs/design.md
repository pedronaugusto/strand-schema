# strand_schema design

How strand_schema validates, and what it holds itself to.

## Scope

In: draft 2020-12 with every vocabulary, and 2019-09 and draft-07 by `$schema` (the
dialects differ in the compiler's tables only; the evaluator is one); references by RFC
3986 against `$id`, anchors and JSON Pointer fragments, the official meta-schemas
built in, remote documents only through the caller's `Loader`; `flag` and `basic`
output; every format strand reads, and a Zig value through the core's encoder.

Out, by decision:

- Drafts 4 and 6: rare in current schemas, and their differences would be more
  compiler tables.
- Custom vocabularies and keywords: a meta-schema requiring a vocabulary strand_schema
  does not know is refused, as the specification asks.
- CDDL for CBOR, until a consumer asks; ZON, whose validation is decoding into its Zig
  type.
- Fetching remote schemas: the caller's loader does it.

`Limits` bound what a hostile schema or instance can buy: the schema's bytes and
subschemas, the reference chain, the depth, the evaluation's frames and state, a
number's exponent, and the errors kept.

## Validation

`strand_schema` compiles a schema once into a program and
validates an instance by streaming the core's events through it, with no tree.
The validator is a seed: `Schema.validate` parses the instance with
`parseLeakySeeded` and its `Read` seed, which reads one value through its access
carrying the validation's work, and hands each member and item a seed of its own,
so every format the core reads can be validated. At each value the schemas that apply there are slots, side
by side, each settled at the value's end from its checks and its children's.

A schema that can apply itself again at the same instance location, reading none
of the instance (a `$ref` back to itself, through `allOf`, `anyOf`, `oneOf`, `not`,
`if`, `then`, `else` or `dependentSchemas`, or a dynamic reference that could land
on it), is refused when it is compiled, with `ReferenceCycle`. At one location a
condition always comes out the same, so such a cycle either never runs or runs
forever on that instance; the specification leaves that undefined, and refusing it
at compile time means validation always finishes, with no check while it runs.

Formats are annotations unless `Options.formats = .assert` or a meta-schema turns
on 2020-12's format-assertion vocabulary; asserted, each is a strict recognizer of
its grammar: almanac's RFC 3339 checks for `date-time`, `date`, `time` and
`duration`, uplink's RFC 3986 and 3987 parser for the URI and IRI formats, spectra's
ECMA-262 reading for `regex`, and grammars of strand's own for the rest.
`idn-hostname` and `idn-email` check IDNA2008's validity of the name as written; a
caller who wants UTS #46's mapping of user input first applies xenoglyph's
`idna.toAscii`. `pattern` and `patternProperties` run on spectra's ECMAScript
dialect; one spectra cannot run in linear time is refused, or under
`unsupported_pattern = .downgrade` compiled as an annotation that every validation
passing through it reports. A validation checks its `Io` for cancellation once per
MiB of instance read.

