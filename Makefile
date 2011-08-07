LIBPREFIX = $(HOME)/gtest
GCCPREFIX = $(HOME)/avr-gcc-4.5.1
SHELL = /bin/bash

GCCOPTS = -v --enable-languages=c,c++ \
 --prefix=$(GCCPREFIX) \
 --infodir=$(GCCPREFIX)/usr/share/info \
 --mandir=$(GCCPREFIX)/usr/share/man \
 --bindir=$(GCCPREFIX)/usr/bin \
 --libexecdir=$(GCCPREFIX)/usr/lib \
 --libdir=$(GCCPREFIX)/usr/lib \
 --enable-shared \
 --with-system-zlib \
 --enable-long-long \
 --enable-nls \
 --without-included-gettext \
 --disable-checking \
 --disable-libssp \
 --enable-lto \
 --build=x86_64-linux-gnu \
 --host=x86_64-linux-gnu \
 --target=avr \
 $(addprefix --with-gmp=,$(LIBPREFIX)) \
 $(addprefix --with-mpfr=,$(LIBPREFIX)) \
 $(addprefix --with-mpc=,$(LIBPREFIX)) \
 $(addprefix --with-ppl=,$(LIBPREFIX)) \
 $(addprefix --with-libelf=,$(LIBPREFIX)) \
 --with-dwarf2

pathexport = $(if $(LIBPREFIX),export PATH=$(LIBPREFIX)/bin:$(LIBPREFIX)/usr/bin:$$PATH && export LD_LIBRARY_PATH=$(LIBPREFIX)/lib:$$LD_LIBRARY_PATH && ) export PATH=$(GCCPREFIX)/bin:$(GCCPREFIX)/usr/bin:$$PATH &&

#pathexport = export PATH=$(GCCPREFIX)/bin:$$PATH &&

makedirs = $(if $(LIBPREFIX),mkdir -p $(LIBPREFIX) && ) mkdir -p $(GCCPREFIX) &&

install: binutils-2.20.1.installed gcc-4.5.1.installed avr-libc-1.7.1.installed
.PHONY: install

INST =   @echo $$(tput setaf 3)Installing $(@:.installed=)$$(tput sgr0)
UNPACK = @echo $$(tput setaf 3)Unpacking  $(@:.unpacked=)$$(tput sgr0)
PATCH  = @echo $$(tput setaf 3)Patching   $(@:.patched=)$$(tput sgr0)

gmp-5.0.2.installed: gmp-5.0.2.tar.bz2.unpacked
	$(INST)
	( cd gmp-5.0.2 &&       ./configure $(addprefix --prefix=,$(LIBPREFIX)) && $(makedirs) $(MAKE) && $(MAKE) install ) && touch $@

mpfr-3.0.1.installed: mpfr-3.0.1.tar.bz2.unpacked
	$(INST)
	( cd mpfr-3.0.1 &&      ./configure $(addprefix --prefix=,$(LIBPREFIX)) && $(makedirs) $(MAKE) && $(MAKE) install ) && touch $@
	
mpc-0.9.installed: gmp-5.0.2.installed mpfr-3.0.1.installed mpc-0.9.tar.gz.unpacked
	$(INST)
	( cd mpc-0.9 &&         ./configure $(addprefix --prefix=,$(LIBPREFIX)) $(addprefix --with-gmp=,$(LIBPREFIX)) $(addprefix --with-mpfr=,$(LIBPREFIX)) && $(makedirs) $(MAKE) && $(MAKE) install ) && touch $@

ppl-0.11.2.installed: gmp-5.0.2.installed ppl-0.11.2.tar.bz2.unpacked
	$(INST)
	( cd ppl-0.11.2 &&      ./configure $(addprefix --prefix=,$(LIBPREFIX)) $(addprefix --with-gmp=,$(LIBPREFIX)) && $(makedirs) $(MAKE) && $(MAKE) install ) && touch $@

libelf-0.8.13.installed: libelf-0.8.13.tar.gz.unpacked
	$(INST)
	( cd libelf-0.8.13 &&   ./configure $(addprefix --prefix=,$(LIBPREFIX)) && $(makedirs) $(MAKE) && $(MAKE) install ) && touch $@

binutils-2.20.1.installed: binutils-2.20.1.tar.bz2.unpacked binutils-2.20.1.patched
	$(INST)
	( mkdir -p binutilsobj && cd binutilsobj && $(pathexport) ../binutils-2.20.1/configure $(addprefix --prefix=,$(GCCPREFIX)) --target=avr --disable-nls && $(makedirs) $(MAKE) && $(MAKE) install ) && touch $@

gcc-4.5.1.installed: binutils-2.20.1.installed gmp-5.0.2.installed mpfr-3.0.1.installed mpc-0.9.installed ppl-0.11.2.installed libelf-0.8.13.installed gcc-4.5.1.tar.bz2.unpacked gcc-4.5.1.patched
	$(INST)
	( mkdir -p gccobj && cd gccobj && $(pathexport) ../gcc-4.5.1/configure $(GCCOPTS) && $(makedirs) $(MAKE) && $(MAKE) install ) && touch $@

avr-libc-1.7.1.installed: binutils-2.20.1.installed gcc-4.5.1.installed avr-libc-1.7.1.tar.bz2.unpacked avr-libc-1.7.1.patched
	$(INST)
	( mkdir -p avrlibcobj && cd avrlibcobj && $(pathexport) ../avr-libc-1.7.1/configure --build=`../avr-libc-1.7.1/config.guess` --host=avr $(addprefix --prefix=,$(GCCPREFIX)) && $(makedirs) $(MAKE) && $(MAKE) install ) && touch $@

%.bz2.unpacked: %.bz2
	$(UNPACK)
	tar jxvf $< && touch $@

%.gz.unpacked: %.gz
	$(UNPACK)
	tar zxvf $< && touch $@

%.patched: %.tar.bz2.unpacked
	$(PATCH)
	( cd $(@:.patched=); for q in ../gcc-patch/avr-gcc/$(@:.patched=)/*.patch; do patch -N -p0 <$$q; done; ) && touch $@

emptymakefiles = $(foreach p,avr35/attiny1634 avr4/atmega48pa avr5/at90pwm161 avr5/atmega325pa avr5/atmega3250pa avr5/atmega3290pa avrxmega2/atxmega32x1 avrxmega6/atxmega128b1 avrxmega6/atxmega256a3bu,avr-libc-1.7.1/avr/lib/$(p)/Makefile.in)

avr-libc-1.7.1/avr/lib/%/Makefile.in: avr-libc-1.7.1.tar.bz2.unpacked
	mkdir -p $(dir $@) && touch $@

avr-libc-1.7.1.patched: $(emptymakefiles)

clean:
	rm -rf binutils-2.20.1 avr-libc-1.7.1 gcc-4.5.1 gmp-5.0.2 mpfr-3.0.1 ppl-0.11.2 libelf-0.8.13 mpc-0.9 *.unpacked *.patched *.installed gccobj binutilsobj avrlibcobj
.PHONY: clean

avr-libc-1.7.1.tar.bz2:
	wget http://mirror.lihnidos.org/GNU/savannah/avr-libc/avr-libc-1.7.1.tar.bz2

mpc-0.9.tar.gz:
	wget http://www.multiprecision.org/mpc/download/mpc-0.9.tar.gz

ppl-0.11.2.tar.bz2:
	wget http://www.cs.unipr.it/ppl/Download/ftp/releases/0.11.2/ppl-0.11.2.tar.bz2

mpfr-3.0.1.tar.bz2:
	wget http://www.mpfr.org/mpfr-current/mpfr-3.0.1.tar.bz2

gmp-5.0.2.tar.bz2:
	wget ftp://ftp.gmplib.org/pub/gmp-5.0.2/gmp-5.0.2.tar.bz2

gcc-4.5.1.tar.bz2:
	wget ftp://gd.tuwien.ac.at/gnu/gcc/releases/gcc-4.5.1/gcc-4.5.1.tar.bz2

libelf-0.8.13.tar.gz:
	wget http://www.mr511.de/software/libelf-0.8.13.tar.gz

binutils-2.20.1.tar.bz2:
	wget http://ftp.gnu.org/gnu/binutils/binutils-2.20.1.tar.bz2

.DELETE_ON_ERROR:

