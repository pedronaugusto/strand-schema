# strand_schema design

How strand_schema validates, and what it holds itself to. It was a module of strand
behind `-Dschema` until 0.1.0, when it became its own package.

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

