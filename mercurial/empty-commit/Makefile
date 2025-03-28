test:
	rm -rf tmp-repo
	mkdir tmp-repo
	cd tmp-repo && hg init
	cd tmp-repo && env HGRCPATH=../hgrc hg empty-commit
	cd tmp-repo && hg log
