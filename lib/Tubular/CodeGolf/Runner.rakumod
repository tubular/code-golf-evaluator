use Tubular::CodeGolf::Conf;
use Tubular::CodeGolf::Entity::Solution 'Solution';
use Tubular::CodeGolf::Entity::SolutionPath 'SolutionPath';
use Tubular::CodeGolf::Entity::TaskPath 'TaskPath';
use Tubular::CodeGolf::Runner::DirList 'DirList';
use Tubular::CodeGolf::Runner::EntityTransformer 'EntityTransformer';
use Tubular::CodeGolf::Runner::Filter 'Filter';
use Tubular::CodeGolf::Runner::Mono 'Mono';
use Tubular::CodeGolf::Runner::ResultToCSV 'ResultToCSV';
use Tubular::CodeGolf::Runner::ResultToMD 'ResultToMD';
use Tubular::CodeGolf::Runner::SolutionExecutor 'SolutionExecutor';
use Tubular::CodeGolf::Runner::Flow::Chain 'Chain';
use Tubular::CodeGolf::Runner::Flow::CrossProduct 'CrossProduct';

class Tubular::CodeGolf::Runner {
    has Tubular::CodeGolf::Conf $!config is built;

    method run(Str :$task, Str :$format = 'csv') {
        my $tests-chain = Chain.new(
            EntityTransformer.new(:entity(TaskPath)),
            DirList.new,
        );
        my $solutions-chain = Chain.new(
            EntityTransformer.new(:entity(SolutionPath)),
            DirList.new,
        );
        # Define data pipeline
        my @pipeline = (
            Mono.new(:value($!config.get('CODEGOLF_PATH'))),
            DirList.new,
        );
        # Scope to a single competition folder when a task is given.
        @pipeline.push: Filter.new(:pred(-> $p { $p.basename eq $task })) if $task;
        @pipeline.append:
            CrossProduct.new(
                $tests-chain, $solutions-chain
            ),
            EntityTransformer.new(:entity(Solution)),
            SolutionExecutor.new;
        @pipeline.push: $format eq 'md' ?? ResultToMD.new !! ResultToCSV.new;

        my $result = Chain.new(|@pipeline);

        my $sup = $result.start;

        react {
            whenever $sup -> $test {
                $test.say;
            }
        }
    }
}
