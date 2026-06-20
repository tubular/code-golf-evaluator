use Tubular::CodeGolf::Entity::Solution;

class Tubular::CodeGolf::Entity::TestResult {
    has Tubular::CodeGolf::Entity::Solution $.solution;
    has Str $.status;
    # Diff output, populated only when the executor runs with :capture-output
    # (the watcher's live board shows it; CSV/MD ignore it).
    has Str $.diff;
}
