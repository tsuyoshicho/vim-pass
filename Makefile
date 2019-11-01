.PHONY: all check replace html clean

VIM = vim

all:

check:
	nvcheck doc/*
	$(VIM) -eu tools/maketags.vim

replace:
	nvcheck -i doc/*

html:
	rm -rf build/
	mkdir -p build/generate
	cp doc/* build/generate
	cd build/generate; $(VIM) -eu ../../tools/buildhtml.vim -c "qall!"; cd -
	cp build/generate/*.html build/
	rm -rf build/generate
	cd build;sh ../tools/genindex.sh > index.html; cd -

clean:
	rm -rf build
