use Tubular::CodeGolf::Conf;
use Tubular::CodeGolf::Entity::Solution 'Solution';
use Tubular::CodeGolf::Entity::SolutionPath 'SolutionPath';
use Tubular::CodeGolf::Entity::TaskPath 'TaskPath';
use Tubular::CodeGolf::Runner::Collect 'Collect';
use Tubular::CodeGolf::Runner::DirList 'DirList';
use Tubular::CodeGolf::Runner::DirWatch 'DirWatch';
use Tubular::CodeGolf::Runner::EntityTransformer 'EntityTransformer';
use Tubular::CodeGolf::Runner::Filter 'Filter';
use Tubular::CodeGolf::Runner::Mono 'Mono';
use Tubular::CodeGolf::Runner::ResultToTUI 'ResultToTUI';
use Tubular::CodeGolf::Runner::SolutionExecutor 'SolutionExecutor';
use Tubular::CodeGolf::Runner::Flow::Chain 'Chain';
use Tubular::CodeGolf::Runner::Flow::CrossProduct 'CrossProduct';

#| Interactive evaluation mode (sibling of Tubular::CodeGolf::Evaluator). Builds
#| the same DirList/CrossProduct/Solution/SolutionExecutor pipeline, but the
#| source picks a single task (named, or the latest) and re-pulses on every save
#| via DirWatch, and the sink is a live terminal leaderboard (ResultToTUI)
#| instead of CSV/Markdown.
class Tubular::CodeGolf::Watcher {
    # Config is injected by the CLI, exactly like Tubular::CodeGolf::Evaluator.
    has Tubular::CodeGolf::Conf $!config is built;

    # A task folder name (002-tictactoe). Empty/undefined → the latest task in
    # the competition root.
    has Str $.task is built;
    has Int $.count is built = 3;

    method run {
        # Per-task tests and solutions sub-chains, identical to the Evaluator's.
        my $tests-chain = Chain.new(
            EntityTransformer.new(:entity(TaskPath)),
            DirList.new,
        );
        my $solutions-chain = Chain.new(
            EntityTransformer.new(:entity(SolutionPath)),
            DirList.new,
        );

        my $root = $!config.get('CODEGOLF_PATH');

        # List the competition root, wrap each folder as a SolutionPath (which
        # knows where its solutions/ live), Filter to the wanted task (a real
        # task folder, scoped to $!task when given), Collect the set to pick the
        # latest, then watch it and feed the usual evaluation pipeline into a
        # live terminal leaderboard.
        my $pipeline = Chain.new(
            Mono.new(:value($root)),
            DirList.new,
            EntityTransformer.new(:entity(SolutionPath)),
            Filter.new(:pred(-> $p {!$!task || $p.path.basename eq $!task})),
            Collect.new(:fold(-> @tasks {
                @tasks.sort(*.path.basename).tail
                    // die "No task matching '{$!task || '*'}' under {$root}"
            })),
            DirWatch.new,
            CrossProduct.new($tests-chain, $solutions-chain),
            EntityTransformer.new(:entity(Solution), :skip-errors),
            SolutionExecutor.new(:capture-output),
            ResultToTUI.new(:$!count),
        );

        my $frames = $pipeline.start;
        react {
            whenever $frames -> $frame {
                $frame.print;
                $*OUT.flush;
            }
        }
    }
}
