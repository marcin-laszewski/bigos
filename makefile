#--- Config -----------------------------------------------
MAKE_OPTS	?= -j`nproc`

BINUTILS_VER	= 164dc55d3d9488a487d39c2e7f3f8cadf6dc12f5
BINUTILS_GIT	= https://github.com/tkchia/binutils-ia16
GCC_VER		= 17bd8a491ca31f8fd867b1f1a380cbbc5ef53b07
GMP_VER		= 6.1.2
MPFR_VER	= 3.1.5
MPC_VER		= 1.0.3

#----------------------------------------------------------
DL		= dl
BUILD		= build
HOST		= host
SRC		= src

BINUTILS	= binutils-ia16
BINUTILS_DL	= $(DL)/$(BINUTILS).tar.gz
BINUTILS_BUILD	= $(BUILD)/host/binutils

GCC		= gcc-ia16
GCC_DL		= $(DL)/$(GCC)-$(GCC_VER).tar.gz
GCC_BUILD	= $(BUILD)/host/$(GCC)
GCC_SRC		= $(SRC)/$(GCC)

GMP	= gmp
GMP_DL	= $(DL)/$(GMP)-$(GMP_VER).tar.bz2

MPFR	= mpfr
MPFR_DL	= $(DL)/$(MPFR)-$(MPFR_VER).tar.bz2

MPC	= mpc
MPC_DL	= $(DL)/$(MPC)-$(MPC_VER).tar.gz

all: \
 $(HOST)/.binutils \
 $(HOST)/.gcc \

$(HOST)/.gcc: $(GCC_BUILD)/.build
	$(MAKE) -C $(dir $<) install
	touch $@

$(GCC_BUILD)/.build: $(GCC_BUILD)/Makefile
	$(MAKE) -C $(dir $<) $(MAKE_OPTS)
	touch $@

$(GCC_BUILD)/Makefile: \
 $(GCC_SRC)/configure \
 $(GCC_SRC)/gmp/configure \
 $(GCC_SRC)/mpc/configure \
 $(GCC_SRC)/mpfr/configure
	mkdir $(dir $@)
	cd $(dir $@) \
	&& $(abspath $(GCC_SRC)/configure) \
		--target=ia16-elf \
		--prefix=$(abspath $(HOST)) \
		--without-headers \
		--enable-languages=c \
		--disable-libssp \
		--without-isl

$(GCC_SRC)/configure:		$(GCC_DL)
$(GCC_SRC)/gmp/configure:	$(GMP_DL)
$(GCC_SRC)/mpc/configure:	$(MPC_DL)
$(GCC_SRC)/mpfr/configure:	$(MPFR_DL)

$(GCC_DL):	URL=https://github.com/tkchia/gcc-ia16/tarball/$(GCC_VER)
$(GMP_DL):	URL=https://gmplib.org/download/gmp/$(GMP)-$(GMP_VER).tar.bz2
$(MPFR_DL):	URL=https://www.mpfr.org/$(MPFR)-$(MPFR_VER)/$(MPFR)-$(MPFR_VER).tar.bz2
$(MPFR_DL):	OPTS=--no-check-certificate

$(MPC_DL):	URL=https://ftp.gnu.org/gnu/$(MPC)/$(MPC)-$(MPC_VER).tar.gz

$(HOST)/.binutils: $(BINUTILS_BUILD)/.build
	$(MAKE) -C $(dir $<) install
	touch $@

$(BINUTILS_BUILD)/.build: $(BINUTILS_BUILD)/Makefile
	$(MAKE) -C $(dir $<) $(MAKE_OPTS)
	touch $@

$(BINUTILS_BUILD)/Makefile: $(BINUTILS_BUILD)/configure
	cd $(dir $@) \
	&& ./configure \
		--target=ia16-elf \
		--prefix=$(abspath $(HOST)) \
		--enable-ld=default \
		--enable-gold=yes \
		--enable-targets=ia16-elf \
		--enable-x86-hpa-segelf=yes \
		--disable-gdb \
		--disable-libdecnumber \
		--disable-readline \
		--disable-sim \
		--disable-nls

$(BINUTILS_BUILD)/configure: $(BINUTILS_DL)

$(BINUTILS_DL): URL=$(BINUTILS_GIT)/archive/$(BINUTILS_VER).tar.gz

%/configure:
	mkdir -p $(dir $@)
	tar xf $< -C $(dir $@) --strip=1
	touch $@

%: %.wget
	mv $< $@

dl/%.wget:
	mkdir -p $(dir $@)
	wget -c $(URL) -O $@ $(OPTS)

clean::
	$(RM) -r $(BUILD)

distclean: clean
	find . -name '*~' | xargs $(RM) -r $(HOST) $(SRC)
