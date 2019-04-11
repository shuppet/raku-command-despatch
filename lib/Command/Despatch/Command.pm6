class X::Command::Despatch::InvalidCommand is Exception {
    has $.message;
};

class Command::Despatch::Command {
    has @.command-list;
    has $.args;
    has $.payload is rw;
    has %.despatch-table;

    method run {
        self.despatch(@.command-list, $.args);
    }

    #| Uses the output of parse to actually run a function in the commands table
    multi method despatch(@commands, $args) {
        X::Command::Despatch::InvalidCommand.new(:message("No command to run!")).throw
            unless @commands;
        self.despatch(@commands, %.despatch-table, $args);
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
        $code(self);
    }
}
