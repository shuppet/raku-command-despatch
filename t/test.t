#!perl6

use Command::Despatch;

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
        },
        nodefault => {
            command => { say "nodefault command" }
        }
    }
);

sub show-me ($self) {
    say $self
}

dd $d.parse('test default with args');
dd $d.parse("test command args");
dd $d.parse("test foo bar some args");
try {
    CATCH {
        when X::Command::Despatch::InvalidCommand {
            say .message
        }
    }
    $d.parse("this is not even a thing");
}

$d.run('test default with args');
$d.run("test command big long list of args");
$d.run("test foo bar big long list of args");
say $d.run("test return-string a string with spaces in");

$d.run("test with-payload with args", payload => "a payload!");

try {
    CATCH {
        when X::Command::Despatch::InvalidCommand {
            say "InvalidCommand: {.message}";
        }
    }
}

try {
    $d.run("not recognised at all");
    CATCH {
        when X::Command::Despatch::InvalidCommand {
            say "InvalidCommand: {.message}";
        }
    }
}

try {
    $d.run("nodefault");
    CATCH {
        when X::Command::Despatch::InvalidCommand {
            say "InvalidCommand: {.message}";
        }
    }
}
