#!/bin/bash

g++ -g -I. fastq-mcf.cpp fastq-lib.cpp -o fastq-mcf.ex

ok=/opt/bin/fastq-mcf
new=./fastq-mcf.ex
err=0

err()
{
	err=1	
} 

runtmp ()
{
	grep -v Command $2 > a.tmp 
    grep -v Command $3 > b.tmp
	$1 a.tmp b.tmp 1>&2
}

if [ "$1" = "-b" ]; then
	list="new ok"
else
	list="new"
fi

trap err ERR

set -o xtrace
for v in $list; do
	eval prog=\$$v
	${prog} -l 15 test.fa test1.fq > test1.$v.out 2> test1.$v.err || echo err during 1 $v
    echo should be error during 2...
	${prog} -l 15 test.fa test2.fq > test2.$v.out 2> test2.$v.err || echo err during 2 $v
	${prog} -l 15 test.fa test1.fq -o test3.$v.out > test3.$v.err || echo err during 3 $v
	${prog} -l 15 -L 72 -f test.fa test4.fq1 test4.fq2 -o test4.$v.out -o test4.$v.out2 > /dev/null || echo err during 4 $v
# check skip saving & hompol removal
	${prog} -l 15 -H test.fa test1.fq -S -o test5.$v.out > test5.$v.err || echo err during 5 $v
# check gzipping
	${prog} -l 15 test.fa test1.fq -o test6.$v.out.gz > test6.$v.err || echo err during 6 $v
# test duplicate removal
    ${prog} -0 -D 20 n/a test-mcf-dup.fq > test7.$v.out 2> test7.$v.err || echo err during 7 $v
	mv test5.$v.out.skip test5.$v.out
done
set +o xtrace	

for n in test1 test2 test3 test4 test5 test7; do
	echo diff $n.new.out $n.ok.out
	diff $n.new.out $n.ok.out 1>&2
	[[ -e $n.ok.err ]] && runtmp diff $n.new.err $n.ok.err 1>&2
done

n=test6
echo special: $n
zdiff $n.new.out.gz $n.ok.out.gz

shopt -s extglob

if [ $err == 1 ]; then
	echo NOT OK, some differences
	exit 1
else
    rm test?.@(new).@(out|err)
    rm test?.@(new).@(out|err).gz
    rm -f a.tmp b.tmp
	echo OK, all tests passed
	exit 0
fi
