.PHONY: install uninstall

install:
	git co counter/
	cp -r counter-original/src/. counter/src/
	cp vendor-secret/Env.elm counter/src
	npx elm-review --config preview counter/src --debug --fix-all

uninstall:
	cp vendor-open/Env.elm src/
	cp -r counter-original/src/. counter/src/