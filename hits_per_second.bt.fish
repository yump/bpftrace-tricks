#!/usr/bin/env fish

set bpfprog_rest '
{
  @[probe,comm,pid,tid] = count();
}

interval:s:$1
{
  time();
  print(@,$2,$1);
  clear(@);
}

END
{
  clear(@);
}
'

function usage
    echo -n "\
Usage: 
    $(status basename) [options] [probe...]

Options:
    -t, --top <N>              Show only the top N most frequently hit probes
    -i, --interval <seconds>   Interval between reports [default: 1]
    -f, --filter <expression>  Only count when <expression> is true

Example:
    $(status basename) -t10 -i5 -f 'comm == \"below\"' 't:syscalls:sys_enter*'
"
    exit 1
end

function check_for_bug_291
    for probe in $argv
        if string match -q -r\
            '^(h|hardware|s|software|p|profile|i|interval|it|iter):' $probe
            set -f badprobes $badprobes $probe
        end
    end
    if test -n "$badprobes"
        echo "ERROR: this script cannot work with the following probes because of bpftrace bug #291"
        printf "  %s\n" $badprobes
        echo "See https://github.com/iovisor/bpftrace/issues/291 for details"
        exit 2
    end
end

function main
    argparse -N 1 \
        't/top=!_validate_int --min 1' \
        'i/interval=!_validate_int --min 1' \
        'f/filter=' \
        -- $argv
    or usage
    set -q _flag_interval || set -f _flag_interval 1 # default: 1 second
    check_for_bug_291 $argv
    echo (string join , $argv) "/$_flag_filter/" $bpfprog_rest \
        | sudo bpftrace - $_flag_interval $_flag_top
end

main $argv
