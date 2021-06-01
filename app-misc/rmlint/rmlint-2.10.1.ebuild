# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PLOCALES="de es fr"
PYTHON_COMPAT=( python3_{7..9} )

inherit eutils distutils-r1 gnome2-utils l10n python-r1 scons-utils

if [[ ${PV} = *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/sahib/rmlint.git"
	KEYWORDS=""
else
	SRC_URI="https://github.com/sahib/rmlint/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

DESCRIPTION="rmlint finds space waste and other broken things on your filesystem and offers to remove it"
HOMEPAGE="https://github.com/sahib/rmlint"

LICENSE="GPL-3"
SLOT="0"
IUSE="doc nls test gui"
RESTRICT="!test? ( test )"
REQUIRED_USE="gui? ( ${PYTHON_REQUIRED_USE} )"

RDEPEND="
	sys-libs/glibc
	>=dev-libs/glib-2.32
	dev-libs/json-glib
	sys-apps/util-linux
	virtual/libelf
	gui? (
		${PYTHON_DEPS}
		x11-libs/gtk+:3
		dev-python/pygobject:3[${PYTHON_USEDEP}]
		gnome-base/librsvg
		x11-libs/gtksourceview:3.0
	)
"
DEPEND="${RDEPEND}
	dev-util/scons[${PYTHON_USEDEP}]
	sys-kernel/linux-headers
	virtual/pkgconfig
	nls? ( sys-devel/gettext )
	doc? ( dev-python/sphinx[${PYTHON_USEDEP}] )
	test? ( dev-python/nose[${PYTHON_USEDEP}]
		dev-python/parameterized[${PYTHON_USEDEP}] )"

DOCS=( CHANGELOG.md README.rst gui/TODO )

src_prepare(){
	# Prevent installing /usr/share/glib-2.0/schemas/gschemas.compiled, gnome2-utils updates it
	epatch "${FILESDIR}/${PN}-gui-dont-compile-schemas.patch"

	default

	l10n_find_plocales_changes po "" .po
	rm_locale() {
		rm -fv po/"${1}".po || die "removing of ${1}.po failed"
	}
	l10n_for_each_disabled_locale_do rm_locale

	python_setup
}

src_configure(){
	escons config LIBDIR=/usr/$(get_libdir) --prefix="${ED}"/usr --actual-prefix=/usr $(use_with nls gettext) $(use_with gui gui)

}

src_compile(){
	escons DEBUG=0 CC="$(tc-getCC)" LIBDIR=/usr/$(get_libdir) --prefix="${ED}"/usr --actual-prefix=/usr
}

src_install(){
	default

	escons install DEBUG=0 LIBDIR=/usr/$(get_libdir) --prefix="${ED}"/usr --actual-prefix=/usr

	rm -f ${ED}/usr/share/glib-2.0/schemas/gschemas.compiled
	if ! use gui; then
		rm -rf "${D}"/usr/share/{glib-2.0,icons,applications}
		rm -rf "${D}"/usr/lib
	fi
}

pkg_preinst() {
	if use gui; then
		gnome2_schemas_savelist
	fi
}

pkg_postinst() {
	if use gui ; then
	    gnome2_icon_cache_update
	    gnome2_schemas_update
	fi
}

pkg_postrm() {
	if use gui ; then
	    gnome2_icon_cache_update
	    gnome2_schemas_update
	fi
}
