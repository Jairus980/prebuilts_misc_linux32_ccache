dnl Process this file with autoconf to produce a configure script.

AC_INIT()
AC_PREREQ(2.52)

AC_MSG_NOTICE([configuring ccache])

AC_CONFIG_HEADER(config.h)

AC_CANONICAL_HOST

case $host in
    *mingw32* | *mingw64* | *cygwin* | *wince* | *mingwce*)
        windows_os=yes
        AC_DEFINE(_WIN32_WINNT,0x0600, Windows Vista or newer is required)
        ;;
    *os400* | *aix*)
        AR="ar -X64"
        ;;
esac

AC_SUBST(disable_man)
AC_SUBST(extra_libs)
AC_SUBST(extra_sources)
AC_SUBST(include_dev_mk)
AC_SUBST(more_warnings)
AC_SUBST(no_implicit_fallthrough_warning)
AC_SUBST(test_suites)

m4_include(m4/feature_macros.m4)
m4_include(m4/clang.m4)

dnl Checks for programs.
AC_PROG_CC
_AC_LANG_COMPILER_CLANG
AC_PROG_CC_C99
if test "$ac_cv_prog_cc_c99" = no; then
    AC_MSG_ERROR(cannot find a C99-compatible compiler)
fi

AC_PROG_CPP
AC_PROG_INSTALL
AC_PROG_RANLIB
AC_CHECK_TOOL(AR, ar)
if test -z "$AR"; then
    AC_MSG_ERROR(cannot find ar)
fi

# Prefer bash, needed for test.sh
AC_PATH_TOOL(BASH, bash, "/bin/bash")

# If GCC (or clang), turn on warnings.
if test "$ac_compiler_gnu" = yes; then
    CFLAGS="$CFLAGS -Wall -W"
else
    CFLAGS="$CFLAGS -O"
fi

AC_ARG_ENABLE(more_warnings,
  [AS_HELP_STRING([--enable-more-warnings],
    [enable more compiler warnings])])
if test x${enable_more_warnings} = xyes; then
    more_warnings="-Wextra -Wpedantic"
    if test "$ac_compiler_clang" = yes; then
        more_warnings="$more_warnings -Weverything"
        more_warnings="$more_warnings -Wno-conversion"
        more_warnings="$more_warnings -Wno-disabled-macro-expansion"
        more_warnings="$more_warnings -Wno-format-nonliteral"
        more_warnings="$more_warnings -Wno-padded"
        more_warnings="$more_warnings -Wno-shorten-64-to-32"
        more_warnings="$more_warnings -Wno-sign-conversion"
    fi
fi

AC_HEADER_DIRENT
AC_HEADER_TIME
AC_HEADER_SYS_WAIT

AC_CHECK_TYPES(long long)

AC_CHECK_HEADERS(ctype.h pwd.h stdlib.h string.h strings.h sys/time.h sys/mman.h)
AC_CHECK_HEADERS(termios.h)

AC_CHECK_FUNCS(gethostname)
AC_CHECK_FUNCS(getopt_long)
AC_CHECK_FUNCS(getpwuid)
AC_CHECK_FUNCS(gettimeofday)
AC_CHECK_FUNCS(localtime_r)
AC_CHECK_FUNCS(mkstemp)
AC_CHECK_FUNCS(realpath)
AC_CHECK_FUNCS(setenv)
AC_CHECK_FUNCS(strndup)
AC_CHECK_FUNCS(strtok_r)
AC_CHECK_FUNCS(unsetenv)
AC_CHECK_FUNCS(utimes)

AC_CACHE_CHECK([for compar_fn_t in stdlib.h],ccache_cv_COMPAR_FN_T, [
    AC_TRY_COMPILE(
        [#include <stdlib.h>],
        [void test_fn(void) { qsort(NULL, 0, 0, (__compar_fn_t)NULL); }],
        ccache_cv_COMPAR_FN_T=yes,
        ccache_cv_COMPAR_FN_T=no)])
if test x"$ccache_cv_COMPAR_FN_T" = x"yes"; then
   AC_DEFINE(HAVE_COMPAR_FN_T, 1,
             Define to 1 if you have the `__compar_fn_t' typedef.)
fi

dnl Replacements of snprintf and friends.
m4_include(m4/snprintf.m4)
HW_FUNC_VSNPRINTF
HW_FUNC_SNPRINTF
HW_FUNC_VASPRINTF
HW_FUNC_ASPRINTF

dnl Check if -lm is needed.
AC_SEARCH_LIBS(cos, m)


dnl Check for zlib
AC_ARG_WITH(bundled-zlib,
  [AS_HELP_STRING([--with-bundled-zlib],
    [use bundled zlib instead of the system's default zlib])])
if test x${with_bundled_zlib} = x; then
    AC_CACHE_CHECK(
        [for zlib >= 1.2.3],
        [ccache_cv_zlib_1_2_3],
        AC_TRY_COMPILE(
            [#include <zlib.h>],
            [
            #if (ZLIB_VERNUM >= 0x1230)
            #else
            #error "ZLIB_VERNUM < 0x1230"
            #endif
            ],
            [ccache_cv_zlib_1_2_3=yes],
            [ccache_cv_zlib_1_2_3=no]))
    AC_CHECK_LIB(z, gzdopen, true)
    if test $ccache_cv_zlib_1_2_3 = yes && test $ac_cv_lib_z_gzdopen = yes; then
        use_bundled_zlib=no
    else
        AC_MSG_WARN(using bundled zlib)
        use_bundled_zlib=yes
    fi
else
    if test x${with_bundled_zlib} = xno; then
        AC_MSG_NOTICE(using system zlib as requested)
        use_bundled_zlib=no
    else
        AC_MSG_NOTICE(using bundled zlib as requested)
        use_bundled_zlib=yes
    fi
fi

if test x${use_bundled_zlib} = xyes; then
    CPPFLAGS="$CPPFLAGS -I\$(srcdir)/src/zlib"
    extra_libs="src/zlib/libz.a"
    mkdir -p src/zlib
else
    LIBS="$LIBS -lz"
fi

AC_ARG_ENABLE(man,
  [AS_HELP_STRING([--disable-man],
    [disable installing man pages])])
if test x${enable_man} = xno; then
    disable_man='#'
fi

AC_ARG_ENABLE(tracing,
  [AS_HELP_STRING([--enable-tracing],
    [enable possibility to use internal ccache tracing])])
if test x${enable_tracing} = xyes; then
    CPPFLAGS="$CPPFLAGS -DMTR_ENABLED"
    extra_sources="src/minitrace.c"
fi

dnl Linking on Windows needs ws2_32
if test x${windows_os} = xyes; then
    LIBS="$LIBS -lws2_32"
fi

AC_C_BIGENDIAN

AC_C_INLINE

dnl Check for "extern inline".
AC_CACHE_CHECK(
    for extern inline,
    ac_cv_c_extern_inline,
    [
    ac_cv_c_extern_inline=no
    AC_TRY_COMPILE(
        [
        extern $ac_cv_c_inline double foo(double x);
        extern $ac_cv_c_inline double foo(double x) { return x+1.0; };
        double foo (double x) { return x + 1.0; };
        ],
        [foo(1.0)],
        [ac_cv_c_extern_inline="yes"])])
if test "$ac_cv_c_extern_inline" != no ; then
    AC_DEFINE(HAVE_EXTERN_INLINE, 1,
              Define to 1 if your compiler supports extern inline)
fi

mkdir -p .deps src unittest

dnl Enable developer mode if dev.mk.in exists.
if test ! -f $srcdir/dev_mode_disabled; then
    AC_MSG_NOTICE(developer mode enabled)
    AC_CONFIG_FILES([dev.mk])
    include_dev_mk='include dev.mk'
    version=`(git --git-dir=$srcdir/.git describe --dirty 2>/dev/null || echo vunknown) | sed -e 's/v//' -e 's/-/+/' -e 's/-/_/g'`
    mkdir -p src
    echo "extern const char CCACHE_VERSION@<:@@:>@; const char CCACHE_VERSION@<:@@:>@ = \"$version\";" >src/version.c
    AC_CHECK_TOOL(GPERF, gperf)
    if test -z "$GPERF"; then
        AC_MSG_ERROR(please install gperf)
    fi
else
    AC_MSG_NOTICE(developer mode disabled)
fi

if test ! -f $srcdir/src/version.c -a ! -f src/version.c ; then
    AC_MSG_WARN(unable to determine ccache version)
    echo "extern const char CCACHE_VERSION@<:@@:>@; const char CCACHE_VERSION@<:@@:>@ = \"unknown\";" >src/version.c
fi

dnl Check for -Wno-implicit-fallthrough
AC_MSG_CHECKING([whether C compiler supports -Wno-implicit-fallthrough])
saved_cflags=$CFLAGS
CFLAGS=-Wno-implicit-fallthrough
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([])],
    [AC_MSG_RESULT([yes])]
    [no_implicit_fallthrough_warning="-Wno-implicit-fallthrough"],
    [AC_MSG_RESULT([no])]
)
CFLAGS=$saved_cflags

dnl Find test suite files.
test_suites=`cd $srcdir && ls unittest/test_*.c | egrep -v 'BASE|BACKUP|LOCAL|REMOTE' | xargs echo`

AC_CONFIG_FILES([Makefile])
AC_OUTPUT

cat <<EOF >config.h.tmp
#ifndef CCACHE_CONFIG_H
#define CCACHE_CONFIG_H
#ifdef __clang__
#pragma clang diagnostic push
#if __has_warning("-Wreserved-id-macro")
#pragma clang diagnostic ignored "-Wreserved-id-macro"
#endif
#endif

EOF
cat config.h >>config.h.tmp
cat <<EOF >>config.h.tmp

#ifdef __clang__
#pragma clang diagnostic pop
#endif
#endif // ifndef CCACHE_CONFIG_H
EOF
mv config.h.tmp config.h

AC_MSG_NOTICE(now build ccache by running make)
