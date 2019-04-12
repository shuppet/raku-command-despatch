#!perl6

use Command::Despatch;
use Command::Despatch::Command;

my $d = Command::Despatch.new(
    command-table => {
        test => {
            _ => -> $self { say "Default for test: {$self.args}" },
            command => -> $self { say "args for test/command: {$self.args}" },
            foo => {
                bar => -> $self { say "args for test/foo/bar: {$self.args}" },
            },
            with-payload => -> $self { say "test/with-payload: args {$self.args}, payload {$self.payload}" },
            return-string => -> $self { $self.args },
            show-me => &show-me,
        }
    }
);

sub show-me ($self) {
    say $self
}

dd $d.parse('test default with args');
dd $d.parse("test command args");
dd $d.parse("test foo bar some args");
say "Doesn't recognise this" unless $d.parse("this is not even a thing")[0];

$d.run('test default with args');
$d.run("test command big long list of args");
$d.run("test foo bar big long list of args");
say $d.run("test return-string a string with spaces in");

$d.run("test with-payload with args", payload => "a payload!");

my $cmd = Command::Despatch::Command.new(
    command-list => [],
    args => 'anything',
    despatch-table => $d.command-table,
);

$cmd.run;

$d.run("not recognised at all");
