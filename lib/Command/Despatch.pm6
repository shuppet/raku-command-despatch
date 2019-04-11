use Command::Despatch::Command;

class Command::Despatch {
    has %.command-table;

    #! Parses the string with the stored command-table. See parse($str, %table)
    multi method parse($str) {
        my ($commands, $args) = self.parse($str, %.command-table);
        return Command::Despatch::Command.new(
            command-list => @$commands, 
            args => $args,
            despatch-table => %.command-table,
        );
    }

    #| Takes a string and returns 1) an array of words that were recognised as commands and subcommands; 2) the remaining string
    multi method parse($str, %table) {
        sub split-str($str) {
            return ~<<($str ~~ / ^ (\S+) [\s+ (.*)]? $ /);
        }

        my (@commands, $args = $str);
        my ($command, $rest) = split-str($str);

        if %table{$command} -> $despatch {
            @commands.push($command);
            my ($subcommands, $remaining) = self.parse($rest, $despatch);
            @commands.append(|$subcommands);
            $args = $remaining;
        }

        return (@commands, $args);

    }

    #| Stops recursion when we hit a leaf in the table. Returns the input as the "rest", i.e. the args to the command we were looking at.
    multi method parse($str, Callable $code) {
        return ([], $str);
    }

    method run($str, :$payload) {
        my $cmd = self.parse($str);
        $cmd.payload = $payload;
        $cmd.run;
    }
}
