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
                file     => ($s.path.defined ?? $s.path.basename !! Str),
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

        # Celebrate the absolute winner(s) before the tables.
        @lines.append: self!winner-banner($folder, @valid);

        # Overall leaderboard
        @lines.push: "## 🏆 Overall leaderboard";
        @lines.push: "";
        if @valid {
            @lines.append: self!ranked-table(@valid, $folder, :language);
        }
        else {
            @lines.push: "_No valid solutions._";
        }
        @lines.push: "";

        # Per-language winners — one ranked table per represented language
        @lines.push: "## 🥇 Per-language winners";
        @lines.push: "";
        if @valid {
            my %by-lang;
            for @valid -> $s {
                %by-lang{$s<language>} //= [];
                %by-lang{$s<language>}.push: $s;
            }
            # @valid is size-sorted, so each language's list is already too.
            for %by-lang.keys.sort -> $lang {
                @lines.push: "### $lang";
                @lines.push: "";
                @lines.append: self!ranked-table(%by-lang{$lang}, $folder);
                @lines.push: "";
            }
        }
        else {
            @lines.push: "_No valid solutions._";
            @lines.push: "";
        }

        # Disqualified / failed
        if @failed {
            @lines.push: "## ❌ Disqualified";
            @lines.push: "";
            @lines.push: "| Solution | Language | Status |";
            @lines.push: "|---|---|---|";
            for @failed -> $s {
                @lines.push: "| {self!solution-cell($folder, $s)} | {$s<language>} | {self!worst-status($s<statuses>)} |";
            }
            @lines.push: "";
        }

        return @lines;
    }

    # A big celebration banner for the absolute winner(s) — the smallest valid
    # solution(s) overall. Empty when nobody has a passing solution.
    method !winner-banner(Str $folder, @valid) {
        return () unless @valid;
        my $best   = @valid[0]<size>;
        my @champs = @valid.grep({ .<size> == $best });
        my $names  = @champs.map(*.<author>).unique.join(' & ');
        my $word   = @champs.elems > 1 ?? 'CHAMPIONS' !! 'CHAMPION';

        my @lines;
        @lines.push: "# 🎉🎉🎉 &nbsp; 🏆 $word: $names 🏆 &nbsp; 🎉🎉🎉";
        @lines.push: "";
        for @champs -> $c {
            @lines.push: "## 🥇 {self!solution-cell($folder, $c)} — `{$c<language>}`, just **{$c<size>} bytes**! 🔥🎊";
        }
        @lines.push: "";
        return @lines;
    }

    # A size-ranked table for a list of solution hashes (already sorted by size
    # ascending). Rank 1 is marked; equal sizes share a rank. With :language the
    # table includes a Language column (used by the overall board).
    method !ranked-table(@sols, Str $folder, Bool :$language) {
        my @lines;
        @lines.push: $language
            ?? '| Rank | Author | Language | Size | Solution |'
            !! '| Rank | Author | Size | Solution |';
        @lines.push: $language
            ?? '|---:|---|---|---:|---|'
            !! '|---:|---|---:|---|';
        my $rank = 0;
        my $prev-size;
        for @sols.kv -> $i, $s {
            $rank = $i + 1 if !$prev-size.defined || $s<size> != $prev-size;
            $prev-size = $s<size>;
            my $marker = $rank == 1 ?? ' 🏆' !! '';
            my $sol = self!solution-cell($folder, $s);
            @lines.push: $language
                ?? "| {$rank}{$marker} | {$s<author>} | {$s<language>} | {$s<size>} | {$sol} |"
                !! "| {$rank}{$marker} | {$s<author>} | {$s<size>} | {$sol} |";
        }
        return @lines;
    }

    # The Solution cell: a link to the real file when we know its name, else the
    # plain author-version label.
    method !solution-cell(Str $folder, $s) {
        return "{$s<author>}-{$s<version>}" unless $s<file>.defined;
        # Link text is just author-attempt (no extension); the target is the real file.
        my $name = $s<file>.subst(/ '.' \w+ $ /, '');
        return "[{$name}]({self!folder-url($folder)}/solutions/{$s<file>})";
    }

    # Base URL of a competition folder: absolute when REPO_TREE_URL is set (in
    # CI), otherwise a repo-relative path (handy for local runs).
    method !folder-url(Str $folder) {
        my $base = %*ENV<REPO_TREE_URL> // '';
        return $base ?? "$base/competition/$folder" !! "competition/$folder";
    }

    method !task-link(Str $folder) {
        return "📖 [Task description & solutions]({self!folder-url($folder)})";
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
