#!perl6

use Command::Despatch;

my $d = Command::Despatch.new(
    command-table => {
        test => {
            command => -> $args { say "args for test/command: $args" },
            foo => {
                bar => -> $args { say "args for test/foo/bar: $args" },
            },
            return-string => -> $args { $args },
        }
    }
);

dd $d.parse("test command args");
dd $d.parse("test foo bar some args");
say "Doesn't recognise this" unless $d.parse("this is not even a thing")[0];

$d.run("test command big long list of args");
$d.run("test foo bar big long list of args");
say $d.run("test return-string a string with spaces in");

$d.run("not recognised at all");
$d.despatch(<test broken>, "this is not a command");