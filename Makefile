prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share
docdir = $(datarootdir)/doc/ccache
mandir = $(datarootdir)/man
man1dir = $(mandir)/man1
sysconfdir = $(prefix)/etc

default_sysconfdir = /usr/local/etc
doc_files = LICENSE.html MANUAL.html NEWS.html GPL-3.0.txt LICENSE.adoc README.md

PYTHON = python3

all:
	@echo "Available make targets:"
	@echo
	@echo "  install [prefix=...] [DESTDIR=...]"
	@echo
	@echo "Default prefix: $(prefix)"

install:
	mkdir -p "$(DESTDIR)$(bindir)"
	$(PYTHON) -c 'import sys; sysconfdir = b"$(sysconfdir)"; default_sysconfdir = b"$(default_sysconfdir)"; sys.stdout.buffer.write(sys.stdin.buffer.read().replace(default_sysconfdir + b"\x00" * (4096 - len(default_sysconfdir)), sysconfdir + b"\x00" * (4096 - len(sysconfdir))))' <ccache >"$(DESTDIR)$(bindir)/ccache"
	chmod +x "$(DESTDIR)$(bindir)/ccache"

	mkdir -p "$(DESTDIR)$(docdir)"
	cp $(doc_files) "$(DESTDIR)$(docdir)"

	mkdir -p "$(DESTDIR)$(man1dir)"
	cp ccache.1 "$(DESTDIR)$(man1dir)"
