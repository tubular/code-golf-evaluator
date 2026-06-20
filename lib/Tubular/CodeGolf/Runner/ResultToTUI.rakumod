use Tubular::CodeGolf::Runner::Unit;

#| Renders a continuous stream of TestResults as a live terminal leaderboard,
#| the watcher's counterpart to ResultToCSV / ResultToMD. It keeps the latest
#| result per (solution, test), and on each settle emits a full-screen frame:
#| the N smallest solutions as OK/NOT OK + byte size, 🏆 on the smallest passing
#| one.
class Tubular::CodeGolf::Runner::ResultToTUI does Tubular::CodeGolf::Runner::Unit {
    has Int  $.count is built = 3;
    # Quiet window (seconds) after a burst of results before redrawing.
    has Real $.debounce is built = 0.15;

    method transform(Supply $in --> Supply) {
        supply {
            my %model;
            my $tick = Supplier.new;
            whenever $in -> $result {
                self!record(%model, $result);
                $tick.emit: True;
            }
            whenever $tick.Supply.stable($!debounce) {
                emit self!frame(self!rows(%model));
            }
        }
    }

    # Fold one TestResult into the model, keyed by solution file path so a later
    # round overwrites the previous round's verdict for the same file.
    method !record(%model, $result) {
        my $s = $result.solution;
        my $key = $s.path.Str;
        %model{$key} //= {
            path     => $s.path,
            file     => $s.path.basename,
            folder   => $s.task.folder,
            language => $s.language,
            size     => $s.size,
            tests    => {},
        };
        %model{$key}<tests>{$s.test-suite.test} = $result.status;
    }

    # Aggregate the model to one row per solution. Solutions whose file no longer
    # exists (deleted/renamed between rounds) are pruned here. A solution passes
    # only if all its tests pass; otherwise the first failing status is shown.
    method !rows(%model) {
        %model.values.grep({ .<path>.e }).map(-> %m {
            my @tests = %m<tests>.keys.sort;
            my $fail  = @tests.first({ %m<tests>{$_} ne 'success' });
            %(
                file     => %m<file>,
                folder   => %m<folder>,
                language => %m<language>,
                size     => %m<size>,
                status   => $fail ?? %m<tests>{$fail} !! 'success',
            )
        }).List;
    }

    # A full terminal frame: clear screen, the board, then a timestamped footer.
    method !frame(@rows --> Str) {
        "\e[2J\e[H"
            ~ self.render(@rows).join("\n")
            ~ "\n\nupdated {DateTime.now.hh-mm-ss}\n";
    }

    # Pure: aggregated rows -> board lines. The smallest *passing* solution gets 🏆.
    method render(@rows) {
        my $folder = (@rows ?? @rows[0]<folder> !! '') || 'golf board';
        my @lines;
        @lines.push: "🏁 $folder — top $!count smallest";
        @lines.push: "";

        unless @rows {
            @lines.push: "  (no solutions yet)";
            return @lines;
        }

        my @sorted = @rows.sort({ $^a<size> <=> $^b<size> });
        my $best = @sorted.first({ .<status> eq 'success' });
        my $best-size = $best ?? $best<size> !! -1;

        my %label =
            success => '✓ OK     ',
            wrong   => '✗ WRONG  ',
            timeout => '✗ TIMEOUT',
            error   => '✗ ERROR  ';

        for @sorted.head($!count).kv -> $i, $r {
            my $cup = ($r<status> eq 'success' && $r<size> == $best-size) ?? '🏆' !! '  ';
            @lines.push: sprintf('%d %s %s %5d  %-16s %s',
                $i + 1, $cup, %label{$r<status>} // "? $r<status>",
                $r<size>, $r<file>, $r<language>);
        }
        @lines;
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::ResultToTUI if $short_name
}
