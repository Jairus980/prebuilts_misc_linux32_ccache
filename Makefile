srcdir = .


prefix = /usr/local
exec_prefix = ${prefix}
bindir = ${exec_prefix}/bin
mandir = ${datarootdir}/man
datarootdir = ${prefix}/share
sysconfdir = ${prefix}/etc
installcmd = /usr/bin/install -c

AR = ar
BASH = /bin/bash
CC = gcc
CFLAGS = -g -O2 -Wall -W
CPPFLAGS = 
EXEEXT = 
LDFLAGS = 
LIBS = -lm  -lz
RANLIB = ranlib

all_cflags = $(CFLAGS)
all_cppflags = -DHAVE_CONFIG_H -DSYSCONFDIR=$(sysconfdir) -I. -I$(srcdir)/src $(CPPFLAGS)
extra_libs = 

non_3pp_sources = \
    src/args.c \
    src/ccache.c \
    src/cleanup.c \
    src/compopt.c \
    src/conf.c \
    src/counters.c \
    src/execute.c \
    src/exitfn.c \
    src/hash.c \
    src/hashutil.c \
    src/language.c \
    src/lockfile.c \
    src/manifest.c \
    src/mdfour.c \
    src/stats.c \
    src/unify.c \
    src/util.c \
    src/version.c
3pp_sources = \
    src/getopt_long.c \
    src/hashtable.c \
    src/hashtable_itr.c \
    src/murmurhashneutral2.c \
    src/snprintf.c
base_sources = $(non_3pp_sources) $(3pp_sources)
base_objs = $(base_sources:.c=.o)

ccache_sources = src/main.c $(base_sources)
ccache_objs = $(ccache_sources:.c=.o)

zlib_sources = \
    zlib/adler32.c zlib/crc32.c zlib/deflate.c zlib/gzclose.c zlib/gzlib.c \
    zlib/gzread.c zlib/gzwrite.c zlib/inffast.c zlib/inflate.c \
    zlib/inftrees.c zlib/trees.c zlib/zutil.c
zlib_objs = $(zlib_sources:.c=.o)

test_suites = ./unittest/test_args.c ./unittest/test_argument_processing.c ./unittest/test_compopt.c ./unittest/test_conf.c ./unittest/test_counters.c ./unittest/test_hash.c ./unittest/test_hashutil.c ./unittest/test_lockfile.c ./unittest/test_stats.c ./unittest/test_util.c
test_sources = unittest/main.c unittest/framework.c unittest/util.c
test_sources += $(test_suites)
test_objs = $(test_sources:.c=.o)

all_sources = $(ccache_sources) $(test_sources)
all_objs = $(ccache_objs) $(test_objs) $(zlib_objs)

files_to_clean = $(all_objs) ccache$(EXEEXT) unittest/run$(EXEEXT) *~ testdir.*
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
	$(srcdir)/perf/perf.py --ccache ccache$(EXEEXT) $(CC) $(all_cppflags) $(all_cflags) $(srcdir)/src/ccache.c

.PHONY: test
test: ccache$(EXEEXT) unittest/run$(EXEEXT)
	unittest/run$(EXEEXT)
	CC='$(CC)' $(BASH) $(srcdir)/test/run

.PHONY: unittest
unittest: unittest/run$(EXEEXT)
	unittest/run$(EXEEXT)

unittest/run$(EXEEXT): $(base_objs) $(test_objs) $(extra_libs)
	$(CC) $(all_cflags) -o $@ $(base_objs) $(test_objs) $(LDFLAGS) $(extra_libs) $(LIBS)

unittest/main.o: unittest/suites.h

unittest/suites.h: $(test_suites) Makefile
	sed -n 's/TEST_SUITE(\(.*\))/SUITE(\1)/p' $(test_suites) >$@

.PHONY: check
check: test

.PHONY: distclean
distclean: clean
	rm -rf $(files_to_distclean)

.PHONY: installcheck
installcheck: ccache$(EXEEXT) unittest/run$(EXEEXT)
	unittest/run$(EXEEXT)
	CCACHE=$(bindir)/ccache CC='$(CC)' $(BASH) $(srcdir)/test/run

.c.o:
	$(CC) $(all_cppflags) $(all_cflags) -c -o $@ $<


