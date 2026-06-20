# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Testing
- `prove6 -Ilib t` - Run all tests using Prove6 (fast local loop)
- `prove6 -I. t` - Run tests via the distribution `META6.json` (mirrors CI)
- `make test` - Build the Docker image and run the suite inside it (CI parity; needed for solutions whose interpreters only exist in the container)
- `zef install --/test --test-depends --deps-only .` - Install dependencies
- `zef install --/test App::Prove6` - Install the Prove6 test runner

> **ALWAYS run the tests after changing anything Raku-related** — any edit under
> `lib/`, `bin/`, or `t/`, or to `META6.json`. Run `prove6 -Ilib t` for the quick
> loop while iterating, and the full suite must pass before the change is
> considered done. A change is not complete until tests pass.
>
> When you add a new module under `lib/`, you MUST also add it to the `provides`
> section of `META6.json` — otherwise `prove6 -I.` and `zef`/CI cannot resolve it.
> Every module with logic should have a matching test in `t/`.

### Running the Application
- `./bin/code-golf evaluate` - Main command to evaluate code golf solutions
- `./bin/code-golf compile` - Compilation check (currently just prints "ok")

## Project Architecture

This is a **Raku-based code golf evaluator** that processes programming contest solutions in various languages. The system uses a pipeline architecture with reactive streams (Supply/Supply transformers).

### Evaluation modes
Two top-level entry points, both consuming the `Runner/` pipeline units:
- **`Tubular::CodeGolf::Evaluator`** — batch mode; evaluates the whole tree (or one
  task) and renders CSV/Markdown. Driven by `code-golf evaluate` / `release`.
- **`Tubular::CodeGolf::Watcher`** — interactive mode; watches a task's `solutions/`
  and redraws a live leaderboard on every save. Driven by `code-golf watch`.

### Core Pipeline Flow
The batch pipeline (`Tubular::CodeGolf::Evaluator`) processes data through these transformers:
1. **DirList** - Lists directories/files
2. **EntityTransformer** - Converts paths to Task/TestSuite/Solution entities  
3. **SolutionExecutor** - Runs solution against test cases
4. **ResultToCSV** - Formats output

### Key Components

**Configuration (`Tubular::CodeGolf::Conf`)**
- Singleton pattern for app configuration
- Defaults: `/app/code-golf/competition` path, `solutions/` and `tests/` subdirs
- Environment variables override defaults (CODEGOLF_PATH, SOLUTIONS_PATH, TESTS_PATH)

**Solution Processing (`Tubular::CodeGolf::Entity::Solution`)**
- Parses solution filenames with format: `<author>-<version>.<extension>`
- Extracts language from shebang line (`#!` interpreter)
- Calculates code size excluding shebang overhead

**Solution Execution (`Tubular::CodeGolf::Runner::SolutionExecutor`)**
- Creates pipeline: `cat input | solution | diff expected`
- Uses `PipeTimeout` for timeouts (10s SIGHUP, 2s SIGKILL)
- Returns status: success/wrong/timeout/error

**Directory Structure Expected**
```
competition/
├── task-name/
│   ├── solutions/
│   │   ├── author-01.pl
│   │   └── author-02.raku
│   └── tests/
│       ├── test1.in
│       ├── test1.ex
│       ├── test2.in
│       └── test2.ex
```

### Testing Structure
- Tests use the standard Raku `Test` module; shared fixtures live in `t/data/`
- Coverage: `Conf` (`t/03`), entities (`t/04`), runner units & flow (`t/05`),
  `SolutionExecutor`/`PipeTimeout` (`t/06`), `CrossSupply` (`t/10`), `ResultToMD` (`t/11`), CLI (`t/02`)
- `SolutionExecutor`/`PipeTimeout` tests spawn real processes and need the
  interpreters present (always true inside the Docker image / `make test`)
- CI runs on Ubuntu/macOS/Windows via GitHub Actions

### Dependencies
- Pure Raku project with no external dependencies
- Requires Raku 6.d or later
- Uses App::Prove6 for testing
