class Tubular::CodeGolf::Utils::PipeTimeout {
    has Proc::Async @!commands is built;
    has Int $!hup is built;
    has Int $!kill is built;

    submethod TWEAK() {
        for @!commands Z @!commands[1..*] -> ($prev, $next) {
            $next.bind-stdin: $prev.stdout;
        }
    }

    method start(-->Supply) {
        .start for @!commands.head(*-1);

        supply {
            whenever @!commands[*-1].start {
                .emit;
                done;
            }

            whenever Promise.in($!hup) {
                .kill for @!commands;
                whenever Promise.in($!kill) {
                    .kill(SIGKILL) for @!commands;
                }
            }
        }
    }
}
