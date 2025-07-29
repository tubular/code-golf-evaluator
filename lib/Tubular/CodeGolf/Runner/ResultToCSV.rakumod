use Tubular::CodeGolf::Runner::Unit;

class Tubular::CodeGolf::Runner::ResultToCSV does Tubular::CodeGolf::Runner::Unit {
    method transform(Supply $in --> Supply) {
        supply {
            "task,author,version,size,language,test,status".emit;
            whenever $in -> $result {
                (
                    $result.solution.task.name,
                    $result.solution.author,
                    $result.solution.version,
                    $result.solution.size,
                    $result.solution.language,
                    $result.solution.test-suite.test,
                    $result.status,
                ).join(',').emit;
            }
        }
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::ResultToCSV if $short_name
}
