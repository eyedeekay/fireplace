
#export proxy_addr := http://192.168.1.98:3142
export distro ?= debian

export CARGO_PATH = "$(HOME)/.cargo/bin/cargo"
export PATH += :$(HOME)/.cargo/bin/
export LIBCLANG_PATH = /usr/lib/clang/

dummy:
	echo "$(PATH)"

clean:
	rm -rf doc-pak description-pak ewlc
	"$(CARGO_PATH)" clean
	cd fireplace && "$(CARGO_PATH)" clean && cd ../

build:
	cd fireplace && "$(CARGO_PATH)" build --release && cd ../

ewlc:
	git clone https://github.com/Enerccio/ewlc; \
	cd ewlc && git submodule update --init --recursive; \
	mkdir target && cd target; \
	cmake -DCMAKE_BUILD_TYPE=Upstream ..; \
	make

wlc: ewlc

wlc-install:
	cd ewlc/target && make install

wlc-checkinstall: wlc
	cd ewlc/target && \
	checkinstall -y \
		--install=no \
		--pkgname=wlc \
		--pkgversion=2.0.1 \
		--pkglicense=mit \
		--pkggroup=x11 \
		--maintainer=problemsolver@openmailbox.org \
		--pkgsource=ewlc \
		--deldoc=yes \
		--deldesc=yes \
		--delspec=yes \
		--backup=no \
		--pakdir=.. \
		--requires="libegl1-mesa (>= 8.0-2) | libegl1-x11, libwayland-egl1-mesa (>= 10.1.0-2) | libwayland-egl1, libgles2-mesa (>= 8.0-2) | libgles2, libc6 (>= 2.17), libcairo2 (>= 1.10.0), libcolord2 (>= 0.1.29), libdbus-1-3 (>= 1.1.1), libdrm2 (>= 2.4.31), libgbm1 (>= 8.1~0), libglib2.0-0 (>= 2.31.8), libinput5 (>= 0.6.0), libjpeg62-turbo (>= 1:1.3.1), liblcms2-2 (>= 2.2+git20110628), libmtdev1 (>= 1.0.8), libpam0g (>= 0.99.7.1), libpango-1.0-0 (>= 1.14.0), libpangocairo-1.0-0 (>= 1.14.0), libpixman-1-0 (>= 0.30.0), libpng12-0 (>= 1.2.13-4), libsystemd0, libudev1 (>= 183), libwayland-client0 (>= 1.5.91), libwayland-cursor0 (>= 1.5.91), libwayland-server0 (>= 1.5.91), libx11-6, libx11-xcb1, libxcb-composite0, libxcb-render0, libxcb-shape0, libxcb-shm0, libxcb-xfixes0, libxcb-xkb1, libxcb1 (>= 1.8), libxcursor1 (>> 1.1.2), libxkbcommon0 (>= 0.2.0)"

docker-wlc-deb:
	docker rmi -f fireplace-wlc-build
	docker run --name fireplace-wlc-build -t fireplace-build make wlc-checkinstall
	rm -rf ./bin && mkdir -p ./bin
	docker cp fireplace-build:/home/build/fireplace/wlc_2.0.1-1_amd64.deb ./
	docker rmi -f fireplace-wlc-build

docker-rust-static:
	docker build --force-rm \
		-f "Dockerfiles/Dockerfile.$(distro)" \
		--build-arg "CACHING_PROXY=$(proxy_addr)" \
		-t rust-static .

docker:
	docker build --force-rm \
		-f "Dockerfiles/Dockerfile.$(distro)" \
		--build-arg "CACHING_PROXY=$(proxy_addr)" \
		-t fireplace-build .

docker-build: docker
	docker rm -f fireplace-build; \
	docker run --name fireplace-build -t fireplace-build
	rm -rf ./target && mkdir -p ./target
	docker cp fireplace-build:/home/build/fireplace/target ./target
	docker rm -f fireplace-build

docker-clobber:
	docker rm -f fireplace-build; \
	docker rmi -f fireplace-build

install:
	install target/release/fireplace /usr/local/bin/fireplace
	install fireplace.yaml /etc/fireplace/fireplace.yaml
	install fireplace.desktop /usr/share/wayland-sessions/fireplace.desktop

checkinstall:
	mkdir -p bin; \
	checkinstall -y \
		--install=no \
		--pkgname=fireplace \
		--pkgversion=$(shell grep fireplace_lib Cargo.toml | sed 's|fireplace_lib||' | tr -d ":\",={}pathtofireplacelib_/" | sed 's|    . ||' | tr -d " \n") \
		--pkglicense=mit \
		--pkggroup=x11 \
		--maintainer=problemsolver@openmailbox.org \
		--pkgsource=fireplace \
		--deldoc=yes \
		--deldesc=yes \
		--delspec=yes \
		--backup=no \
		--pakdir=./bin \
		--requires="adduser, libegl1-mesa (>= 8.0-2) | libegl1-x11, libwayland-egl1-mesa (>= 10.1.0-2) | libwayland-egl1, libgles2-mesa (>= 8.0-2) | libgles2, libc6 (>= 2.17), libcairo2 (>= 1.10.0), libcolord2 (>= 0.1.29), libdbus-1-3 (>= 1.1.1), libdrm2 (>= 2.4.31), libgbm1 (>= 8.1~0), libglib2.0-0 (>= 2.31.8), libinput5 (>= 0.6.0), libjpeg62-turbo (>= 1:1.3.1), liblcms2-2 (>= 2.2+git20110628), libmtdev1 (>= 1.0.8), libpam0g (>= 0.99.7.1), libpango-1.0-0 (>= 1.14.0), libpangocairo-1.0-0 (>= 1.14.0), libpixman-1-0 (>= 0.30.0), libpng12-0 (>= 1.2.13-4), libsystemd0, libudev1 (>= 183), libwayland-client0 (>= 1.5.91), libwayland-cursor0 (>= 1.5.91), libwayland-server0 (>= 1.5.91), libx11-6, libx11-xcb1, libxcb-composite0, libxcb-render0, libxcb-shape0, libxcb-shm0, libxcb-xfixes0, libxcb-xkb1, libxcb1 (>= 1.8), libxcursor1 (>> 1.1.2), libxkbcommon0 (>= 0.2.0)"

checkinstall-static:
	mkdir -p bin; \
	checkinstall -y \
		--install=no \
		--pkgname=fireplace-static \
		--pkgversion=$(shell grep fireplace_lib Cargo.toml | sed 's|fireplace_lib||' | tr -d ":\",={}pathtofireplacelib_/" | sed 's|    . ||' | tr -d " \n") \
		--pkglicense=mit \
		--pkggroup=x11 \
		--maintainer=problemsolver@openmailbox.org \
		--pkgsource=fireplace \
		--deldoc=yes \
		--deldesc=yes \
		--delspec=yes \
		--backup=no \
		--pakdir=.bin \
		--requires="adduser, libegl1-mesa (>= 8.0-2) | libegl1-x11, libwayland-egl1-mesa (>= 10.1.0-2) | libwayland-egl1, libgles2-mesa (>= 8.0-2) | libgles2, libc6 (>= 2.17), libcairo2 (>= 1.10.0), libcolord2 (>= 0.1.29), libdbus-1-3 (>= 1.1.1), libdrm2 (>= 2.4.31), libgbm1 (>= 8.1~0), libglib2.0-0 (>= 2.31.8), libinput5 (>= 0.6.0), libjpeg62-turbo (>= 1:1.3.1), liblcms2-2 (>= 2.2+git20110628), libmtdev1 (>= 1.0.8), libpam0g (>= 0.99.7.1), libpango-1.0-0 (>= 1.14.0), libpangocairo-1.0-0 (>= 1.14.0), libpixman-1-0 (>= 0.30.0), libpng12-0 (>= 1.2.13-4), libsystemd0, libudev1 (>= 183), libwayland-client0 (>= 1.5.91), libwayland-cursor0 (>= 1.5.91), libwayland-server0 (>= 1.5.91), libx11-6, libx11-xcb1, libxcb-composite0, libxcb-render0, libxcb-shape0, libxcb-shm0, libxcb-xfixes0, libxcb-xkb1, libxcb1 (>= 1.8), libxcursor1 (>> 1.1.2), libxkbcommon0 (>= 0.2.0)"

version:
	@echo $(shell grep fireplace_lib Cargo.toml | sed 's|fireplace_lib||' | tr -d ":\",={}pathtofireplacelib_/" | sed 's|    . ||' | tr -d " \n")

docker-deb:
	make docker
	make docker-wlc-deb
	make docker-build
	make checkinstall
