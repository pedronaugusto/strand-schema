# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- strand_schema, its own package: JSON Schema validation over strand's core, as it was
  strand's `strand_schema` module behind `-Dschema` (strand a49e6c5). Its root is
  `src/strand_schema.zig`; its API is unchanged. It takes every dependency with its default
  options, so a program with strand_schema and another strand user builds one strand.
