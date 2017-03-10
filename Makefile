srcdir = .


prefix = /usr/local
exec_prefix = ${prefix}
bindir = ${exec_prefix}/bin
mandir = ${datarootdir}/man
datarootdir = ${prefix}/share
sysconfdir = ${prefix}/etc
installcmd = /usr/bin/install -c

AR = ar
CC = gcc -std=gnu99
CFLAGS = -g -O2 -Wall -W
CPPFLAGS = 
EXEEXT = 
LDFLAGS = 
LIBS = -lm  -lz
RANLIB = ranlib

all_cflags = $(CFLAGS)
all_cppflags = -DHAVE_CONFIG_H -DSYSCONFDIR=$(sysconfdir) -I. -I$(srcdir) $(CPPFLAGS)
extra_libs = 

non_3pp_sources = \
    args.c \
    ccache.c \
    cleanup.c \
    compopt.c \
    conf.c \
    counters.c \
    execute.c \
    exitfn.c \
    hash.c \
    hashutil.c \
    language.c \
    lockfile.c \
    manifest.c \
    mdfour.c \
    stats.c \
    unify.c \
    util.c \
    version.c
3pp_sources = \
    getopt_long.c \
    hashtable.c \
    hashtable_itr.c \
    murmurhashneutral2.c \
    snprintf.c
base_sources = $(non_3pp_sources) $(3pp_sources)
base_objs = $(base_sources:.c=.o)

ccache_sources = main.c $(base_sources)
ccache_objs = $(ccache_sources:.c=.o)

zlib_sources = \
    zlib/adler32.c zlib/crc32.c zlib/deflate.c zlib/gzclose.c zlib/gzlib.c \
    zlib/gzread.c zlib/gzwrite.c zlib/inffast.c zlib/inflate.c \
    zlib/inftrees.c zlib/trees.c zlib/zutil.c
zlib_objs = $(zlib_sources:.c=.o)

test_suites = ./test/test_args.c ./test/test_argument_processing.c ./test/test_compopt.c ./test/test_conf.c ./test/test_counters.c ./test/test_hash.c ./test/test_hashutil.c ./test/test_lockfile.c ./test/test_stats.c ./test/test_util.c
test_sources = test/main.c test/framework.c test/util.c $(test_suites)
test_objs = $(test_sources:.c=.o)

all_sources = $(ccache_sources) $(test_sources)
all_objs = $(ccache_objs) $(test_objs) $(zlib_objs)

files_to_clean = $(all_objs) ccache$(EXEEXT) test/main$(EXEEXT) *~ testdir.*
files_to_distclean = Makefile config.h config.log config.status

.PHONY: all
all: ccache$(EXEEXT)

ccache$(EXEEXT): $(ccache_objs) $(extra_libs)
	$(CC) $(all_cflags) -o $@ $(ccache_objs) $(LDFLAGS) $(extra_libs) $(LIBS)

.PHONY: install
install: all $(srcdir)/ccache.1
	$(installcmd) -d $(DESTDIR)$(bindir)
	$(installcmd) -m 755 ccache$(EXEEXT) $(DESTDIR)$(bindir)
	$(installcmd) -d $(DESTDIR)$(mandir)/man1
	-$(installcmd) -m 644 $(srcdir)/ccache.1 $(DESTDIR)$(mandir)/man1/

.PHONY: clean
clean:
	rm -rf $(files_to_clean)

conf.c: confitems_lookup.c envtoconfitems_lookup.c

$(zlib_objs): CPPFLAGS += -include config.h

zlib/libz.a: $(zlib_objs)
	$(AR) cr $@ $(zlib_objs)
	$(RANLIB) $@

.PHONY: perf
perf: ccache$(EXEEXT)
	$(srcdir)/perf.py --ccache ccache$(EXEEXT) $(CC) $(all_cppflags) $(all_cflags) $(srcdir)/ccache.c

.PHONY: test
test: ccache$(EXEEXT) test/main$(EXEEXT)
	test/main$(EXEEXT)
	CC='$(CC)' $(srcdir)/test.sh

.PHONY: quicktest
quicktest: test/main$(EXEEXT)
	test/main$(EXEEXT)

test/main$(EXEEXT): $(base_objs) $(test_objs) $(extra_libs)
	$(CC) $(all_cflags) -o $@ $(base_objs) $(test_objs) $(LDFLAGS) $(extra_libs) $(LIBS)

test/main.o: test/suites.h

test/suites.h: $(test_suites) Makefile
	sed -n 's/TEST_SUITE(\(.*\))/SUITE(\1)/p' $(test_suites) >$@

.PHONY: check
check: test

.PHONY: distclean
distclean: clean
	rm -rf $(files_to_distclean)

.PHONY: installcheck
installcheck: ccache$(EXEEXT) test/main$(EXEEXT)
	test/main$(EXEEXT)
	CCACHE=$(bindir)/ccache CC='$(CC)' $(srcdir)/test.sh

.c.o:
	$(CC) $(all_cppflags) $(all_cflags) -c -o $@ $<


