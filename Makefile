include /usr/share/dpkg/pkg-info.mk
include /usr/share/dpkg/architecture.mk

PACKAGE=pve-cluster

GITVERSION:=$(shell git rev-parse HEAD)

DEB=${PACKAGE}_${DEB_VERSION_UPSTREAM_REVISION}_${DEB_BUILD_ARCH}.deb
LIBDEB  = libpve-cluster-perl_${DEB_VERSION_UPSTREAM_REVISION}_all.deb
LIBDEB += libpve-cluster-api-perl_${DEB_VERSION_UPSTREAM_REVISION}_all.deb
DBGDEB=${PACKAGE}-dbgsym_${DEB_VERSION_UPSTREAM_REVISION}_${DEB_BUILD_ARCH}.deb

PERL_APIVER := `perl -MConfig -e 'print $$Config{debian_abi}//$$Config{version};'`

all: ${DEB} ${DBG_DEB}

cpgtest: cpgtest.c
	gcc -Wall cpgtest.c $(shell pkg-config --cflags --libs libcpg libqb) -o cpgtest

.PHONY: dinstall
dinstall: ${DEB} ${LIBDEB}
	dpkg -i $^

.PHONY: deb
deb ${DBG_DEB} ${LIBDEB}: ${DEB}
${DEB}:
	rm -f *.deb
	rm -rf build
	cp -a data build
	cp -a debian build/debian
	echo "git clone git://git.proxmox.com/git/pve-cluster.git\\ngit checkout ${GITVERSION}" > build/debian/SOURCE
	cd build; dpkg-buildpackage -rfakeroot -b -us -uc
	lintian ${DEB}


.PHONY: upload
upload: ${DEB} ${DBG_DEB} ${LIBDEB}
	tar cf - ${DEB} ${DBGDEB} ${LIBDEB}| ssh -X repoman@repo.proxmox.com -- upload --product pve --dist buster --arch ${DEB_BUILD_ARCH}

.PHONY: clean
clean:
	rm -rf *~ build *.deb *.changes *.dsc ${CSDIR} *.buildinfo
