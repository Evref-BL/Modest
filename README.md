# Modest

Modular unit test generation using models.  
Tests are generated using application traces, represented by [Famix-OpenTelemetry](https://github.com/moosetechnology/Famix-OpenTelemetry), and the serialized values they contain, represented by [Famix-Value](https://github.com/moosetechnology/Famix-Value), to generate a unit test model, represented by [Famix-UnitTest](https://github.com/moosetechnology/Famix-UnitTest).
This model is then exported into ASTs, usually using the [FAST](https://github.com/moosetechnology/FAST) family of models, which are finally exported into actual unit tests that can be integrated into a codebase.

## Installation

```st
Metacello new
  githubUser: 'Evref-BL' project: 'Modest' commitish: 'main' path: 'src';
  baseline: 'Modest';
  onConflictUseIncoming;
  load
```
