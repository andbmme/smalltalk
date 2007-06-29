dnl I'd like this to be edited in -*- Autoconf -*- mode...
dnl

dnl GST_PACKAGE(NAME, DIR, [TESTS], [VARS-TO-TEST], [CONFIG-FILES], [LIBS])
dnl ------------------------------------------------------------------------
dnl Arrange for installation of package NAME in directory DIR (prefixed
dnl by whatever was set up with GST_PACKAGE_PREFIX.
dnl TESTS are run and VARS-TO-TEST are inspected after running them -- if
dnl any of them is 'no' or 'not found' the package will not be built.
dnl CONFIG-FILES (prefixed by DIR) are created from corresponding .in files;
dnl it is important to specify package.xml here if it is automatically
dnl generated.  LIBS are libraries (possibly with .la extensions) that are
dnl built and will be preloaded by the wrapper script in `tests/gst'.

AC_DEFUN([GST_PACKAGE_PREFIX], [
m4_define([_GST_PKG_PREFIX], [$1/])])

m4_define([_GST_RULES_PREPARE],
[m4_expand_once([
  PACKAGE_RULES=pkgrules.tmp
  rm -f pkgrules.tmp])
  AC_SUBST_FILE([PACKAGE_RULES])])

m4_define([_GST_PKG_ENABLE], [
  cat >> pkgrules.tmp << \EOF
all-local: $1.star
EOF
  m4_if([$3], [], [], 
    [PACKAGE_DLOPEN_FLAGS="$PACKAGE_DLOPEN_FLAGS m4_foreach_w(GST_Lib,
	[$3], [-dlopen \"\${abs_top_builddir}/_GST_PKG_DIR/GST_Lib\"])"])
  m4_foreach_w(GST_File, [$2],
	       [m4_if(GST_File, Makefile,
		      [BUILT_PACKAGES="$BUILT_PACKAGES _GST_PKG_DIR"])])])

m4_define([_GST_PKG_IF_FILE], [dnl
m4_define([_GST_COND], [$4])dnl
m4_foreach_w(GST_File, [$1],
	    [m4_if(GST_File, $2, [m4_define([_GST_COND], [$3])])])dnl
_GST_COND])

m4_define([_GST_PKG_PREFIX], [])

AC_DEFUN([GST_PACKAGE], [
  $3
  AC_MSG_CHECKING([whether to install $1])
  _GST_RULES_PREPARE
  m4_define([_GST_PKG_DIR], [_GST_PKG_PREFIX[]$2])dnl
  m4_define([_GST_PKG_XML], [_GST_PKG_DIR/package.xml])dnl
  m4_define([_GST_PKG_DISTDIR], [$(distdir)/_GST_PKG_DIR])dnl
  m4_define([_GST_PKG_STAMP], [_GST_PKG_DIR/stamp-classes])dnl
  m4_define([_GST_PKG_XML_IN],
	    [_GST_PKG_IF_FILE([$5], [package.xml],
			      [$(srcdir)/_GST_PKG_DIR/package.xml.in],
			      [_GST_PKG_XML])])dnl

  cat >> pkgrules.tmp << \EOF
$1.star: _GST_PKG_XML $(srcdir)/_GST_PKG_STAMP
	_GST_PKG_IF_FILE([$5], [Makefile], [cd _GST_PKG_DIR && $(MAKE)
	])$(GST_[]PACKAGE) --srcdir=$(srcdir) --target-directory=. $<

clean-local::
	-rm -f $1.star

uninstall-local::
	$(GST_[]PACKAGE) --srcdir=$(srcdir) --target-directory=$(pkgdatadir) --destdir=$(DESTDIR) --uninstall $(DESTDIR)$(pkgdatadir)/$1.star

install-data-hook:: $1.star
	$(GST_[]PACKAGE) --srcdir=$(srcdir) --target-directory=$(pkgdatadir) --destdir=$(DESTDIR) $1.star

dist-hook:: _GST_PKG_XML
	$(GST_[]PACKAGE) --srcdir=$(srcdir) --target-directory=_GST_PKG_DISTDIR --dist $<

dist-hook:: $(srcdir)/_GST_PKG_STAMP
	cp -p $< _GST_PKG_DISTDIR/stamp-classes

-include $(srcdir)/_GST_PKG_STAMP
$(srcdir)/_GST_PKG_STAMP:: _GST_PKG_XML_IN
	(echo '$1_FILES = \'; \
	  $(GST_[]PACKAGE) --srcdir=$(srcdir) --vpath --list-files $1 $< | \
	    tr -d \\r | tr \\n " "; \
	echo; \
	echo '$$($1_FILES):'; \
	echo '$$(srcdir)/_GST_PKG_STAMP:: $$($1_FILES)'; \
	echo '	touch $$(srcdir)/_GST_PKG_STAMP') > $(srcdir)/_GST_PKG_STAMP
EOF

    m4_if([$4], [],
      [_GST_PKG_ENABLE([$1], [$5], [$6])
      AC_MSG_RESULT([yes])],

      [(for i in $4; do
	eval ac_var='${'$i'-bad}'
	case "$ac_var" in
	  no | 'not found' )
	    exit 1 ;;
	  bad )
	    AC_MSG_WARN([variable $i not set, proceeding as if \"no\"])
	    exit 1 ;;
	esac
      done)
      if test $? = 0; then
        _GST_PKG_ENABLE([$1], [$5], [$6])
	AC_MSG_RESULT([yes])
      else
	AC_MSG_RESULT([no])
      fi
      ])

  m4_if([$5], [], [], 
    [_GST_PKG_IF_FILE([$5], [Makefile], [ALL_PACKAGES="$ALL_PACKAGES _GST_PKG_DIR"])
    AC_CONFIG_FILES(m4_foreach_w(GST_File, [$5], [_GST_PKG_DIR/GST_File ])) ])

  AC_SUBST([ALL_PACKAGES])
  AC_SUBST([BUILT_PACKAGES])
  AC_SUBST([PACKAGE_DLOPEN_FLAGS])
])dnl
