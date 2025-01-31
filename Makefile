# This file does not contain explicit building/cleaning of
# modules directory: individual programs will build only
# required modules. Programs should be build before other
# components.

.PHONY: all install clean
all:
	make -C programs
	make -C docs
	make -C docs/man
	make -C vmap_data

install:
	make -C programs install
	make -C docs/man install
	make -C vmap_data install

clean:
	make -C programs clean
	make -C docs clean
	make -C docs/man clean
	make -C vmap_data clean
