srcdir = .
builddir = .


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
all_cppflags = -DHAVE_CONFIG_H -DSYSCONFDIR=$(sysconfdir) -I. -I$(srcdir)/src -I$(builddir)/unittest $(CPPFLAGS)
extra_libs = 

v_at_0 = yes
v_at_ = $(v_at_0)
quiet := $(v_at_$(V))
Q=$(if $(quiet),@)

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
    src/util.c
generated_sources = \
    src/version.c
3pp_sources = \
     \
    src/hashtable.c \
    src/hashtable_itr.c \
    src/murmurhashneutral2.c \
    src/snprintf.c
base_sources = $(non_3pp_sources) $(generated_sources) $(3pp_sources)
base_objs = $(base_sources:.c=.o)

ccache_sources = src/main.c $(base_sources)
ccache_objs = $(ccache_sources:.c=.o)

zlib_sources = \
    src/zlib/adler32.c \
    src/zlib/crc32.c \
    src/zlib/deflate.c \
    src/zlib/gzclose.c \
    src/zlib/gzlib.c \
    src/zlib/gzread.c \
    src/zlib/gzwrite.c \
    src/zlib/inffast.c \
    src/zlib/inflate.c \
    src/zlib/inftrees.c \
    src/zlib/trees.c \
    src/zlib/zutil.c

zlib_objs = $(zlib_sources:.c=.o)

test_suites = unittest/test_args.c unittest/test_argument_processing.c unittest/test_compopt.c unittest/test_conf.c unittest/test_counters.c unittest/test_hash.c unittest/test_hashutil.c unittest/test_lockfile.c unittest/test_stats.c unittest/test_util.c
test_sources = unittest/main.c unittest/framework.c unittest/util.c
test_sources += $(test_suites)
test_objs = $(test_sources:.c=.o)

all_sources = $(ccache_sources) $(test_sources)
all_objs = $(ccache_objs) $(test_objs) $(zlib_objs)

files_to_clean = \
    $(all_objs) \
    ccache$(EXEEXT) \
    src/*~ \
    src/zlib/libz.a \
    testdir.* \
    unittest/run$(EXEEXT) \
    *~

files_to_distclean = Makefile config.h config.log config.status

.PHONY: all
all: ccache$(EXEEXT)

ccache$(EXEEXT): $(ccache_objs) $(extra_libs)
	$(if $(quiet),@echo "  LD       $@")
	$(Q)$(CC) $(all_cflags) -o $@ $(ccache_objs) $(LDFLAGS) $(extra_libs) $(LIBS)

ccache.1: doc/ccache.1
	$(if $(quiet),@echo "  CP       $@")
	$(Q)cp $< $@

.PHONY: install
install: ccache$(EXEEXT) ccache.1
	$(if $(quiet),@echo "  INSTALL  ccache$(EXEEXT)")
	$(Q)$(installcmd) -d $(DESTDIR)$(bindir)
	$(Q)$(installcmd) -m 755 ccache$(EXEEXT) $(DESTDIR)$(bindir)
	$(if $(quiet),@echo "  INSTALL  ccache.1")
	$(Q)$(installcmd) -d $(DESTDIR)$(mandir)/man1
	$(Q)-$(installcmd) -m 644 ccache.1 $(DESTDIR)$(mandir)/man1/

.PHONY: clean
clean:
	rm -rf $(files_to_clean)

conf.c: confitems_lookup.c envtoconfitems_lookup.c

$(zlib_objs): CPPFLAGS += -include config.h
$(zlib_objs): CFLAGS += -Wno-implicit-fallthrough

src/zlib/libz.a: $(zlib_objs)
	$(if $(quiet),@echo "  AR       $@")
	$(Q)$(AR) cr $@ $(zlib_objs)
	$(if $(quiet),@echo "  RANLIB   $@")
	$(Q)$(RANLIB) $@

.PHONY: perf
perf: ccache$(EXEEXT)
	$(srcdir)/perf/perf.py --ccache ccache$(EXEEXT) $(CC) $(all_cppflags) $(all_cflags) $(srcdir)/src/ccache.c

.PHONY: test
test: ccache$(EXEEXT) unittest/run$(EXEEXT)
	$(if $(quiet),@echo "  TEST     unittest/run$(EXEEXT)")
	$(Q)unittest/run$(EXEEXT)
	$(if $(quiet),@echo "  TEST     $(srcdir)/test/run")
	$(Q)CC='$(CC)' $(BASH) $(srcdir)/test/run

.PHONY: unittest
unittest: unittest/run$(EXEEXT)
	$(if $(quiet),@echo "  TEST     $@")
	$(Q)unittest/run$(EXEEXT)

unittest/run$(EXEEXT): $(base_objs) $(test_objs) $(extra_libs)
	$(if $(quiet),@echo "  LD       $@")
	$(Q)$(CC) $(all_cflags) -o $@ $(base_objs) $(test_objs) $(LDFLAGS) $(extra_libs) $(LIBS)

unittest/main.o: unittest/suites.h

unittest/suites.h: $(test_suites) Makefile
	$(if $(quiet),@echo "  GEN      $@")
	$(Q)ls $^ | grep -v Makefile | xargs sed -n 's/TEST_SUITE(\(.*\))/SUITE(\1)/p' >$@

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
	$(if $(quiet),@echo "  CC       $@")
	$(Q)$(CC) $(all_cppflags) $(all_cflags) -c -o $@ $<


