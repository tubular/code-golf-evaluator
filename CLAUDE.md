# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Testing
- `prove6 -Ilib t` - Run all tests using Prove6
- `zef install --/test --test-depends --deps-only .` - Install dependencies
- `zef install --/test App::Prove6` - Install the Prove6 test runner

### Running the Application
- `./bin/code-golf evaluate` - Main command to evaluate code golf solutions
- `./bin/code-golf compile` - Compilation check (currently just prints "ok")

## Project Architecture

This is a **Raku-based code golf evaluator** that processes programming contest solutions in various languages. The system uses a pipeline architecture with reactive streams (Supply/Supply transformers).

### Core Pipeline Flow
The main evaluation pipeline (`Tubular::CodeGolf::Runner:13-35`) processes data through these transformers:
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
- Tests use standard Raku Test module
- Current test suite is minimal (`t/01-basic.rakutest:4`)
- CI runs on Ubuntu/macOS/Windows via GitHub Actions

### Dependencies
- Pure Raku project with no external dependencies
- Requires Raku 6.d or later
- Uses App::Prove6 for testing
