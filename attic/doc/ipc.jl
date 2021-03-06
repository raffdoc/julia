## doesn't execute, just creates command object:

cmd = Cmd("cat","/dev/random")
cmd = Cmd(["cat","/dev/random"])
cmd = Cmd("cat","/dev/random", env={"PATH"=>"/bin:/sbin"})

## access to command's file descriptors:

cmd.fd(n)                         # file descriptor n
cmd.fd(n...)                      # combined output of fds given as args
cmd.stdin                         # stdin, i.e. cmd.fd(0)
cmd.input                         # same as stdin
cmd.stdout                        # stdout, i.e. cmd.fd(1)
cmd.stderr                        # stderr, i.e. cmd.fd(2)
cmd.output                        # stdout & stderr, i.e. cmd.fd(1,2)

## connect processes, making composite pipe object:

p = pipe(foo.stdout, bar.stdin)   # explicitly connect via pipe
p = pipe(foo, bar)                # defaults to using stdout and stdin
p = pipe(foo.stderr, bar.stdin)   # pipe stderr to bar
p = pipe(foo.stdout, baz.stdin)   # pipe stdout to baz
p = pipe(foo.output, bar)         # pipe both 

## running commands:

run(cmd)                          # execute and wait for command object
run("sleep","10")                 # shortcut for run(Cmd("sleep","10"))
run(pipe)                         # run an entire pipeline

start(cmd)                        # start executing, but don't wait
pid(cmd)                          # get the command pid
pid(pipe)                         # get the process group pid
                                  # (typically -pid of group leader)
wait(123)                         # wait for process 123
wait(cmd)                         # wait for running process cmd
wait(pipe)                        # wait for running pipeline pipe
wait(foo, bar, baz)               # wait for several cmds or pipes
kill(signal, cmd)                 # send signal to cmd
kill(signal, pipe)                # send signal to pipe process group
kill(signal, foo...)              # send signal to multiple entities

## processing output (implicitly calls run if necessary):

each_line(foo.fd(n))              # iterator over output of fd n
each_line(foo.stdout)             # iterator over stdout
each_line(foo.output)             # iterator over stdout & stderr
each_line(foo)                    # defaults to stdout
each_line(foo...)                 # read sequentially from several sources

each_char(foo)                    # get each character
each_char(foo, enc="UTF-32")      # read chars with UTF-32 encoding
each_byte(foo)                    # get each byte
each_block(1024, foo)             # get blocks of bytes
each_record(Record, foo)          # read and cast each blitable record

all_lines(foo)                    # slurp all lines
all_chars(foo)                    # slurp all chars
all_bytes(foo)                    # slurp all bytes
all_records(Record, foo)          # slurp all records

## tossing julia into the mix:

pipe(foo, LineFilter(line->strcat("prefix: ",line)))
pipe(foo, CharFilter(char->upcase(char)))
pipe(foo, ByteFilter(byte->0x7f & byte))
pipe(foo, BlockFilter(1024, bytes->sum(bytes)))
pipe(foo, RecordFilter(Record, rec->rec.field))

## some potential nice syntax:

foo | bar                         # pipe(foo, bar)
foo.stderr & foo.stdout           # composite desciptor object
foo & bar                         # run in parallel with composite descriptors
!foo                              # negate return code

## mmap usage:

A = mmap(file, Record)            # return an mmapped array or records

## potential `` syntax:

# Summary: split on words but leave interpolations whole
#
#   - e.g. `cat -n $file` => Cmd("cat","-n",file)
#   - it feels like using the shell but its safer
#     and more efficient since there's no shell or
#     shell quoting and unquoting issues
#   - interpolating vectors or tuples should make
#     multiple words like so:
#        `cat $files` => Cmd("cat", files...)
#

for line = each_line(`bzcat $files` | `sort -k1n` | `cut -f2-`)
  # do something with the rest of the line
end

## some parallel pipe examples:

run(`echo hello` & `echo world`)
run(`echo hello` & `echo world` | `sort`)
run(`echo hello` & `echo world` | `sort` | `tac`)

run(`perl -e 'warn "world\n"; print "hello\n"'`)
run(`perl -e 'warn "world\n"; print "hello\n"'` | `sort`)
run(stderr(`perl -e 'warn "world\n"; print "hello\n"'`) | `sort`)
run(output(`perl -e 'warn "world\n"; print "hello\n"'`) | `sort`)

prefixer(sleep, prefix) =
  `perl -nle '$|=1; print "'$prefix'\t", $_; sleep '$sleep''`

run(`perl -le '$|=1; for(0..9){ print; sleep 1 }'` |
    prefixer(2,"A") & prefixer(2,"B"))

run(`perl -le '$|=1; for(0..9){ print; sleep 1 }'` |
    prefixer(3,"X") & prefixer(3,"Y") & prefixer(3,"Z") |
    prefixer(2,"A") & prefixer(2,"B"))

gen = `perl -le '$|=1; for(0..9){ print; sleep 1 }'`
dup = `perl -pe '$|=1; warn $_; sleep 1'`
run(gen | dup | dup)
