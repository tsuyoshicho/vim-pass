.PHONY: all check replace html clean

all:

check:
	nvcheck doc/*
	vim -eu tools/maketags.vim

replace:
	nvcheck -i doc/*

html:
	rm -rf build/
	mkdir -p build/generate
	cp doc/* build/generate
	cd build/generate; vim -eu ../../tools/buildhtml.vim -c "qall!"; cd -
	cp build/generate/*.html build/
	rm -rf build/generate

clean:
	rm -rf build
