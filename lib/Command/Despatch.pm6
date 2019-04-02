class X::Command::Despatch::InvalidCommand is Exception {
    has $.message;
};

class Command::Despatch {
    has %.command-table;

    #! Parses the string with the stored command-table. See parse($str, %table)
    multi method parse($str) {
        self.parse($str, %.command-table)
    }

    #| Takes a string returns 1) an array of all commands; 2) a string of the remaining words
    #| Commands are simply whitespace delimited, and so the array is all words at the start of the string, in order, that were found in the command tree in that order.
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

    #| Uses the output of parse to actually run a function in the commands table
    multi method despatch(@commands, $args) {
        X::Command::Despatch::InvalidCommand.new(:message("No command recognised")).throw
            unless @commands;
        self.despatch(@commands, %.command-table, $args);
    }

    multi method despatch(@commands is copy, %table, $args) {
        my $command = @commands.shift;
        my $to-do = %table{$command};
        unless $to-do {
            X::Command::Despatch::InvalidCommand.new(:message("Invalid command: $command")).throw;
        }

        return self.despatch(@commands, $to-do, $args);
    }

    multi method despatch(@commands, Callable $code, $args) {
        $code($args);
    }

    method run($str) {
        self.despatch(|self.parse($str))
    }
}