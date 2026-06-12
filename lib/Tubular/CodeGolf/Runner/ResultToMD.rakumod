use Tubular::CodeGolf::Runner::Unit;

class Tubular::CodeGolf::Runner::ResultToMD does Tubular::CodeGolf::Runner::Unit {

    method transform(Supply $in --> Supply) {
        supply {
            my @all;
            whenever $in -> $result {
                @all.push: $result;
                LAST { .emit for self!render(@all); }
            }
        }
    }

    # Collected TestResults (one per solution × test) -> markdown lines.
    method !render(@results) {
        my @lines;

        my %tasks;
        for @results -> $r {
            %tasks{$r.solution.task.folder} //= [];
            %tasks{$r.solution.task.folder}.push: $r;
        }

        for %tasks.keys.sort -> $folder {
            @lines.append: self!render-task($folder, %tasks{$folder});
        }

        @lines.append: self!render-footer();
        return @lines;
    }

    method !render-task(Str $folder, @results) {
        my @lines;

        # Aggregate per solution: a solution passes only if ALL its tests succeed.
        my %sol;
        for @results -> $r {
            my $s = $r.solution;
            my $key = "{$s.author}-{$s.version}";
            %sol{$key} //= {
                author   => $s.author,
                version  => $s.version,
                language => $s.language,
                size     => $s.size,
                statuses => [],
            };
            %sol{$key}<statuses>.push: $r.status;
        }

        my @valid = %sol.values
            .grep({ .<statuses>.grep(* ne 'success').elems == 0 })
            .sort({ $^a<size> <=> $^b<size> });
        my @failed = %sol.values
            .grep({ .<statuses>.grep(* ne 'success').elems != 0 })
            .sort({ $^a<author> cmp $^b<author> });

        @lines.push: "# $folder";
        @lines.push: "";
        @lines.push: self!task-link($folder);
        @lines.push: "";

        # Overall leaderboard
        @lines.push: "## 🏆 Overall leaderboard";
        @lines.push: "";
        if @valid {
            @lines.push: "| Rank | Author | Language | Size | Solution |";
            @lines.push: "|---:|---|---|---:|---|";
            my $rank = 0;
            my $prev-size;
            for @valid.kv -> $i, $s {
                $rank = $i + 1 if !$prev-size.defined || $s<size> != $prev-size;
                $prev-size = $s<size>;
                my $marker = $rank == 1 ?? ' 🏆' !! '';
                @lines.push: "| {$rank}{$marker} | {$s<author>} | {$s<language>} | {$s<size>} | {$s<author>}-{$s<version>} |";
            }
        }
        else {
            @lines.push: "_No valid solutions._";
        }
        @lines.push: "";

        # Per-language winners
        @lines.push: "## 🥇 Per-language winners";
        @lines.push: "";
        if @valid {
            @lines.push: "| Language | Author | Size |";
            @lines.push: "|---|---|---:|";
            my %best;
            for @valid -> $s {
                my $lang = $s<language>;
                %best{$lang} = $s if !(%best{$lang}:exists) || $s<size> < %best{$lang}<size>;
            }
            for %best.keys.sort -> $lang {
                my $s = %best{$lang};
                @lines.push: "| {$lang} | {$s<author>} | {$s<size>} |";
            }
        }
        else {
            @lines.push: "_No valid solutions._";
        }
        @lines.push: "";

        # Disqualified / failed
        if @failed {
            @lines.push: "## ❌ Disqualified";
            @lines.push: "";
            @lines.push: "| Solution | Language | Status |";
            @lines.push: "|---|---|---|";
            for @failed -> $s {
                @lines.push: "| {$s<author>}-{$s<version>} | {$s<language>} | {self!worst-status($s<statuses>)} |";
            }
            @lines.push: "";
        }

        return @lines;
    }

    method !task-link(Str $folder) {
        my $base = %*ENV<REPO_TREE_URL> // '';
        my $url = $base ?? "$base/competition/$folder" !! "competition/$folder";
        return "📖 [Task description & solutions]($url)";
    }

    method !worst-status(@statuses) {
        my %prio = error => 3, timeout => 2, wrong => 1;
        return @statuses
            .grep(* ne 'success')
            .sort({ (%prio{$^b} // 0) <=> (%prio{$^a} // 0) })
            .first // 'wrong';
    }

    method !render-footer() {
        my @lines;
        my $sha = %*ENV<GIT_SHA> // '';
        my $at = %*ENV<FINALIZED_AT> // '';
        if $sha || $at {
            @lines.push: "---";
            my @parts;
            @parts.push: "Finalized: $at" if $at;
            @parts.push: "Commit: `{$sha.substr(0, 7)}`" if $sha;
            @lines.push: "_{@parts.join(' · ')}_";
        }
        return @lines;
    }
}

sub EXPORT($short_name?) {
    Map.new: do $short_name => Tubular::CodeGolf::Runner::ResultToMD if $short_name
}
