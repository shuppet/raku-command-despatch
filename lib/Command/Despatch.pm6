use Command::Despatch::Command;

class X::Command::Despatch::InvalidCommand is Exception {
    has $.message;
};

# This is thrown when you try to run a command that has subcommands but no
# default. It means we don't report a command called _ but instead can be caught
# when unwinding the recursion to report the parent command name.
class X::Command::Despatch::InvalidCommand::NoDefault is Exception {}

class Command::Despatch::Command {
    has $.args;
    has $.payload;
}

class Command::Despatch {
    has %.command-table;

    #! Parses the string with the stored command-table. See parse($str, %table)
    method parse($str) {
        #| Takes a string and returns 1) an array of words that were recognised as commands and subcommands; 2) the remaining string
        my multi sub parse(\self, $str, %sub-table) {
            sub split-str($str) {
                return $str unless $str and $str ~~ / \s /;
                return ~<<($str ~~ / ^ (\S+) [\s+ (.*)]? $ /);
            }

            my @commands;
            my $args = $str;
            my ($command, $rest) = split-str($str);

            # It's OK if $str was empty and now there are no more commands -
            # that's what _ is for
            if $command and %sub-table{$command} -> $despatch {
                @commands.push($command);

                my ($subcommands, $remaining) = try {
                    CATCH {
                        when X::Command::Despatch::InvalidCommand::NoDefault {
                            X::Command::Despatch::InvalidCommand.new(
                                :message("$command requires a subcommand")
                            ).throw;
                        }
                    }

                    self.&parse($rest, $despatch);
                }

                @commands.append(|$subcommands);
                $args = $remaining;
            }
            elsif %sub-table<_> {
                @commands.push('_');
            }
            else {
                X::Command::Despatch::InvalidCommand::NoDefault.new.throw;
            }

            return (@commands, $args);
        }

        #| Stops recursion when we hit a leaf in the table. Returns the input as the "rest", i.e. the args to the command we were looking at.
        my multi sub parse(\self, $str, Callable $code) {
            return ([], $str);
        }

        try {
            CATCH {
                when X::Command::Despatch::InvalidCommand::NoDefault {
                    X::Command::Despatch::InvalidCommand.new(
                        :message(qq["$str" does not start with a recognised command])
                    ).throw;
                }
            }
            return self.&parse($str, %.command-table);
        }

    }

    #| Uses the output of parse to actually run a function in the commands table
    method despatch(@commands, $args, :$payload) {
        X::Command::Despatch::InvalidCommand.new(:message("No command to run!")).throw
            unless @commands;

        my multi sub despatch(\self, @commands is copy, %sub-table, $args, :$payload) {
            my $command = @commands.shift // '_';
            my $to-do = %sub-table{$command};

            # We do need to do this because despatch is public. You're not required
            # to parse a string; you can give us the array from whatever source.
            # That means we can't rely on parse throwing the error for us.
            unless $to-do {
                if $command eq '_' {
                    X::Command::Despatch::InvalidCommand::NoDefault.new.throw;
                }
                else {
                    X::Command::Despatch::InvalidCommand.new(
                        :message("Invalid command: $command")
                    ).throw;
                }
            }

            try {
                CATCH {
                    when X::Command::Despatch::InvalidCommand::NoDefault {
                        X::Command::Despatch::InvalidCommand.new(
                            :message("$command requires a subcommand")
                        ).throw;
                    }
                }

                return self.&despatch(@commands, $to-do, $args, :$payload);
            }
        }

        my multi sub despatch(\self, @commands, Callable $code, $args, :$payload) {
            $code(Command::Despatch::Command.new(
                :$args, :$payload
            ));
        }

        self.&despatch(@commands, %.command-table, $args, :$payload);
    }

    method run($str, :$payload) {
        self.despatch(|self.parse($str), :$payload);
    }
}
