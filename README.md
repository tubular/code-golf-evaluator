[![Actions Status](https://github.com/tubular/code-golf-evaluator/actions/workflows/test.yml/badge.svg)](https://github.com/tubular/code-golf-evaluator/actions)

# Code Golf

> *"A game where one attempts to write the shortest program to accomplish some
> goal."* — inspired by [Perl Golf](https://wiki.c2.com/?PerlGolf), here played
> in any language.

Each round we pick a small task. You solve it in **as few bytes as possible**.
At the deadline every solution is run against a hidden test set and a results
page crowns the overall winner and the winner in each language.

## Rules

**It's about short, not fast or clever.** The only thing that scores is the byte
count of your program. A solution can be hilariously slow, brute-force, or
unreadable — if it's correct and shorter, it wins. Do **not** optimize for
performance or polish; optimize for size.

- **Correctness is pass/fail.** A solution must pass **all** test cases to be
  ranked. There are no points for partial output. This is olympiad-style: only a
  basic example is published with the task — the full set of (hidden) tests is
  revealed only when the round is finalized, so solve the *general* task, not
  just the example.
- **Ranking is by code size in bytes**, smallest wins. The shebang interpreter
  line is free (declaring `#!/usr/bin/env -S perl` costs nothing); your program
  body — including any interpreter flags — is what counts.
- **Whitespace counts too** — spaces, tabs, and newlines are bytes like any
  other, so you can't hide logic in "free" whitespace. For a deliberately absurd
  demonstration, see
  [`claude-01.pl`](competition/000-hello/solutions/claude-01.pl): its real
  program lives entirely in the blank-looking lines after `__DATA__`, where each
  line's *number of spaces* is one character code. A single line above
  `__DATA__` slurps the block and rebuilds the source in one expression —
  `pack "C*", map length, split "\n", do{local $/; <DATA>}` — then `eval`s it.
  It runs correctly — and tips the scales at ~1,900 bytes, landing dead last.
  That's the whole point: if spaces were free, this would look "tiny".
- **Any language goes**, as long as it's available in the competition Docker
  image (run `make versions` to see what's installed: Perl, Python, Raku,
  Scala/Java, Node.js, sed, bash, …). There's an **overall winner** and a
  **winner per language**.
- **There is a timeout.** Slow is fine, but not infinite: each test run is sent
  `SIGHUP` after **10s** and `SIGKILL` **2s** later. A solution that exceeds it
  is recorded as `timeout` and does not rank. That's the only nod to
  performance — everything within the budget is fair game.
- **LLMs are allowed, but please don't.** Using an LLM isn't prohibited, but
  this is a *fun* competition — you'll get far more out of it (and so will
  everyone reading the solutions) if you golf it yourself. Even better, reach for
  a language you don't normally use: `perl`, `raku`, and `sed` are unreasonably
  good at golf, so picking one up is half the fun.

### How a task is prepared

Each round lives in `competition/<NNN>-<name>/` (e.g. `competition/000-hello/`):

```
competition/000-hello/
├── README.md            # the announcement: task description + one basic example
├── solutions/           # your solutions go here
└── tests/
    ├── example.in       # the single visible test case
    └── example.ex
```

When a round is announced (by email), the folder ships with only the task
`README.md` and the **example** test pair. The remaining test cases are kept
out of the repo until the deadline.

### Test cases: `.in` / `.ex`

A test case is a pair of files sharing a base name:

- `<name>.in` — the bytes fed to your program on **stdin**.
- `<name>.ex` — the **exact** stdout your program is expected to produce.

Evaluation is literally `cat <name>.in | your-solution | diff - <name>.ex`. If
`diff` reports no difference (exit 0), the case passes. The published example is
`example.in` / `example.ex`; at finalization more hidden pairs are added.

### What happens at the deadline

1. The organizer merges the competition PRs into `master`.
2. The full, hidden test cases are merged into each task's `tests/`.
3. The merge commit is **tagged with the task folder name** (e.g. `000-hello`).
4. That tag triggers a GitHub Action that evaluates every solution against the
   full test set and publishes a **release page** with the leaderboards.

Forgot to merge in time? The organizer can move the tag and the release
regenerates — but don't count on it.

> 💡 **Submit with a pull request.** Don't merge to `master` yourself — open a PR
> and the organizer will merge the entries at the deadline. Title it
> `[<tag>] <your name>` (e.g. `[000-hello] alex`) so the organizer can tell at a
> glance which PRs are competition entries. And on your honour: please **don't
> peek at other people's open PRs** until the round is finalized — figuring it
> out yourself is the whole point, and comparing notes afterwards is half the fun.

## Competitor workflow

1. **Clone** the repo:

   ```sh
   git clone https://github.com/tubular/code-golf-evaluator.git
   cd code-golf-evaluator
   ```

2. **Branch** — do your work on your own branch:

   ```sh
   git checkout -b golf/<your-name>
   ```

3. **Read the task** in `competition/<NNN>-<name>/README.md`.

4. **Write your solution** in that round's `solutions/` folder, named
   `<your-name>-<NN>.<ext>` (bump `NN` for each new attempt), starting with a
   shebang so the evaluator knows how to run it:

   ```
   competition/000-hello/solutions/alex-01.pl
   ```

   ```perl
   #!/usr/bin/env -S perl -p
   s/^/hello, /
   ```

   The interpreter line is free; only the body below it counts toward your size.

5. **Build the image** (first time, or after the base changes):

   ```sh
   make            # builds the app image (needs the base image; see `make base`)
   make versions   # list the languages/versions available to you
   ```

6. **Test against the example.** The simplest way is to run the evaluator over
   the whole competition tree inside the container — it has every interpreter:

   ```sh
   make evaluate   # runs `code-golf evaluate` over competition/ in Docker
   ```

   Your row shows `success` when your output matches `example.ex`. To iterate
   quickly on a single file you can also run the pipeline by hand:

   ```sh
   cat competition/000-hello/tests/example.in \
     | ./competition/000-hello/solutions/alex-01.pl \
     | diff - competition/000-hello/tests/example.ex && echo PASS
   ```

7. **Shrink it.** Trim bytes, try another language, repeat. Remember: a correct
   but slow/ugly solution that's shorter beats a fast, pretty, longer one.

8. **Open a pull request** titled `[<tag>] <your name>` (e.g. `[000-hello] alex`).
   No need to merge it yourself — the organizer merges the entries at the
   deadline. And please don't peek at others' open PRs until then.

---

## Developer Guide

Want to extend the evaluator — add a language, a new output format, or another
pipeline stage? Here's the lay of the land. The code is **Raku**; if you've
never read it, the quick primer below is enough to follow along.

### A 60-second Raku primer

- Sigils tag variables by shape: `$x` scalar, `@x` array, `%x` hash, `&x` a
  callable. `my $x = …` declares one.
- `class Foo does Bar { method baz($arg) { … } }` — a class composing a role
  `Bar` (a role is an interface/mixin) and defining a method.
- `-> $x { … }` is a lambda. `:foo` / `:$bar` are named arguments
  (`:$bar` is shorthand for `bar => $bar`).
- The async bits you'll see: a **`Supply`** is an asynchronous stream of values.
  `supply { … }` builds one, `emit $v` pushes a value into it, and
  `whenever $stream -> $v { … }` reacts to each value as it arrives. That's the
  whole reactive vocabulary used here.

### Entry point

```
bin/code-golf  →  Tubular::CodeGolf::CLI (MAIN)  →  Tubular::CodeGolf::Runner.run
```

`bin/code-golf` just loads `CLI.rakumod`, whose `MAIN` multi dispatches the
subcommand (`evaluate`, `release <tag>`, `compile`) and hands off to the
`Runner`. In Docker everything goes through `docker/entrypoint.sh code-golf …`.

### The pipeline (the "chain")

Evaluation is a chain of small stages. Every stage is a **`Unit`** — a class
that implements one method:

```raku
role Unit { method transform(Supply $in --> Supply) { … } }
```

It takes a stream in and returns a transformed stream out. `Runner.run`
(`lib/Tubular/CodeGolf/Runner.rakumod`) just wires the stages together with
`Chain` and starts them:

```
Mono(root path)        # Producer: emits the starting value
  → DirList            # list competition task folders
  → Filter             # (release only) keep just the tagged task
  → CrossProduct       # pair every test with every solution
  → EntityTransformer  # turn paths into Solution objects
  → SolutionExecutor   # run each solution, emit a TestResult
  → ResultToCSV / ResultToMD   # the sink: format the results
```

`Chain` (`Runner/Flow/Chain.rakumod`) feeds each stage's output Supply into the
next. The first stage is a **`Producer`** (`Mono`) that seeds the stream; the
last is a **sink** that formats output. Adding a stage = write a `Unit` and slot
it into that list.

### Asynchronous evaluation

The whole thing is lazy and concurrent: nothing runs until `Chain.start` taps
the final Supply, then values flow through as they're produced. `Mono` and
`DirList` emit paths, and downstream stages process them as they arrive rather
than waiting for the full list.

The interesting async work is in `SolutionExecutor`: for each solution it spawns
the pipeline `cat <input> | <solution> | diff - <expected>` with `Proc::Async`,
wrapped in `Utils::PipeTimeout`, which races the processes against a timer
(`SIGHUP` at 10s, `SIGKILL` 2s later) and emits a `TestResult` with status
`success` / `wrong` / `timeout` / `error`.

### Adding a new language

There is **nothing language-specific in the evaluator** — it runs each solution
file directly via its shebang. So "adding a language" usually means just making
its interpreter available:

1. Install the toolchain in **`docker/Dockerfile.base`** (where Perl, Python,
   Raku, Scala/Java, Node.js, … are set up), then `make base` to rebuild.
2. Make sure the shebang form parses: language detection lives in the `Shebang`
   grammar in `lib/Tubular/CodeGolf/Entity/Solution.rakumod` (the reported
   language is the interpreter's basename). Standard
   `#!/usr/bin/env -S <interp> <flags>` shebangs work out of the box.
3. Add a solution in that language under some `competition/*/solutions/` and run
   `make evaluate` to confirm it executes and ranks.

### Adding a stage or output format

1. Create a class under `lib/Tubular/CodeGolf/Runner/` that `does Unit` and
   implements `transform`. (A formatter like `ResultToMD` is a good template; a
   filter like `Filter` is the minimal one.)
2. Register it in the **`provides`** section of `META6.json` — otherwise
   `prove6 -I.` and CI can't resolve it.
3. Slot it into the pipeline list in `Runner.run`.
4. Add a test under `t/` and run the suite (`prove6 -Ilib t`, or `make test` for
   a full container run). **Always run the tests after a Raku change.**

---

AUTHOR
======

cono <q@cono.org.ua>

COPYRIGHT AND LICENSE
=====================

Copyright 2022 cono

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

