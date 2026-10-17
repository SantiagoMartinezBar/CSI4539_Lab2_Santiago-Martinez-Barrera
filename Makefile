USER_ID := $(shell id -u)
GROUP_ID := $(shell id -g)
TOOLCHAIN_PACKAGES := binutils build-essential gcc-multilib gdb gnat \
	gprbuild libc6-dev-i386 make nasm python3

.PHONY: setup verify-safe report clean

setup: verify-safe report

verify-safe:
	docker run --rm --network=host --add-host proxy:127.0.0.1 \
		-e HTTP_PROXY -e HTTPS_PROXY -e NO_PROXY \
		-e HOST_UID=$(USER_ID) -e HOST_GID=$(GROUP_ID) \
		-v $(CURDIR):/workspace -w /workspace debian:bookworm-slim \
		sh -c 'apt-get update >/dev/null && \
			DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
			$(TOOLCHAIN_PACKAGES) >/dev/null && \
			sh scripts/verify_safe.sh; status=$$?; \
			chown -R "$$HOST_UID:$$HOST_GID" defense/bin defense/obj 2>/dev/null || true; \
			exit $$status'

report:
	mkdir -p /tmp/csi4539-lab2-font-cache
	XDG_CACHE_HOME=/tmp/csi4539-lab2-font-cache \
		pandoc report/report.md --from markdown --pdf-engine=xelatex \
		--output report/report.pdf

clean:
	rm -rf defense/bin defense/obj
