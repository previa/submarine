#!/user/bin/perl
# use strict;
use POSIX;
use File::ReadBackwards;

my $filename = "robot.nl.srt";
my ($type, $time) = @ARGV;
my $usage = "-- Usage --
./sub_adjust.pl [add/sub] [timestring]
-- Example --
./sub_adjust.pl add \"00:00:00,000\"
";

# Read in blocks
$/ = "\n\n";

if(!defined $type || !defined $time) {
    print $usage;
    exit;
}

print $type, "\n"; 
print $time, "\n\n\n";


open(FH, '<', $filename) or die $!;
open(FH_COPY, '>', "${filename}.copy");

while(defined(my $line = <FH>)) {
    my @lines = split('\n', $line);
    print "\nLines: \n", $line, "\n";
    my @values = split(' --> ', $lines[1]);
    my $n_time_1 = "";
    my $n_time_2 = "";

    if($type eq "add") {
        $n_time_1 = add(parse_time($time), parse_time($values[0]));
        $n_time_2 = add(parse_time($time), parse_time($values[1]));
    } elsif($type eq "sub") {
        $n_time_1 = subtract(parse_time($time), parse_time($values[0]));
        $n_time_2 = subtract(parse_time($time), parse_time($values[1]));

    }

    print FH_COPY $lines[0], "\n";
    print FH_COPY $n_time_1, ' ---> ', $n_time_2, "\n";
    # Add remaining lines
    my $len = scalar @lines;
    for(my $j = 2; $j < $len; $j++) {
        print FH_COPY $lines[$j], "\n";
    }
    print FH_COPY "\n";
}

close(FH);
close(FH_COPY);

sub subtract {
    my ($n_hour, $n_min, $n_sec, $n_ms, $hour, $min, $sec, $ms) = (@_);
    my $next = 0;
    ($ms, $next) = sub_time($ms, $n_ms, $next, 1000);
    ($sec, $next) = sub_time($sec, $n_sec, $next, 60);
    ($min, $next) = sub_time($min, $n_min, $next, 60);
    ($hour, $next) = sub_time($hour, $n_hour, $next, 60);
    
    my $n_sec_ms = join(",", $sec, $ms);
    my $n_time_1 = join(":", $hour, $min, $n_sec_ms);
    
    if($next == 1) {
        print "Time goes negative!\nExiting...\n";
        exit;
    }

    return $n_time_1;
}

sub sub_time {
    my ($time, $n_time, $next, $base) = (@_);
    $time -= $n_time;
    $time -= $next;

    if($time < 0) {
        $time = $base + $time;
        $next = 1;
    } else {
        $next = 0;
    }

    $time = format_time($time, $base);
    return ($time, $next);
}

sub add {
    my ($n_hour, $n_min, $n_sec, $n_ms, $hour, $min, $sec, $ms) = (@_);
    my $next = 0;
    ($ms, $next) = add_time($ms, $n_ms, $next, 1000);
    ($sec, $next) = add_time($sec, $n_sec, $next, 60);
    ($min, $next) = add_time($min, $n_min, $next, 60);
    ($hour, $next) = add_time($hour, $n_hour, $next, 60);
    my $n_sec_ms = join(",", $sec, $ms);
    my $n_time_1 = join(":", $hour, $min, $n_sec_ms);
    return $n_time_1;
}

sub add_time {
    my ($time, $n_time, $next, $base) = (@_);
    $time += $n_time;
    $time += $next;
    
    if($time >= $base) {
        $next = $time/$base;
    } else {
        $next = 0;
    }

    $time = $time%$base;

    $time = format_time($time, $base);

    return ($time, floor($next));
}

sub format_time {
    my ($time, $base) = (@_);
    if($time < 10) {
        $time = join("", 0, $time);
    }

    # For MS
    if($base == 1000 && $time < 100) {
        $time = join("", 0, $time);
    }

    return $time;
}

sub parse_time {
    my $time = shift;
    my ($hours, $min, $sec_ms) = split(':', $time);
    my ($sec, $ms) = split(',', $sec_ms);
    return ($hours, $min, $sec, $ms);
}

# 1
# 00:00:03,545 --> 00:00:06,173
# M'n vader heeft me uit het raam geduwd.

# 2
# 00:00:06,298 --> 00:00:08,550
# Het spijt me.
# -Je bent ziek.