PKGVERSION = $(shell git describe --always --dirty)

TESTS=$(wildcard tests/*.ml)

build:
	jbuilder build @install $(TESTS:.ml=.exe) --dev

tests: build
	for t in $(TESTS:.ml=.exe); do \
	  echo "Executing test $$t"; \
	  ./_build/default/$$t; \
	done

install uninstall:
	jbuilder $@

doc:
	sed -e 's/%%VERSION%%/$(PKGVERSION)/' src/moss.mli \
	  > _build/default/src/moss.mli
	jbuilder build @doc
	echo '.def { background: #f0f0f0; }' >> _build/default/_doc/odoc.css


.PHONY: build tests install uninstall doc
