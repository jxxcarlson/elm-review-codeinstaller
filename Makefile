.PHONY: install uninstall deps

install:
	git checkout counter/
	cp -r counter-original/src/. counter/src/
	cp vendor-secret/Env.elm counter/src
	npx elm-review --config preview counter/src --debug --fix-all

deps:
	lamdera install MartinSStewart/elm-nonempty-string
	lamdera install TSFoster/elm-sha1@2.1.1
	lamdera install TSFoster/elm-uuid@4.2.0
	lamdera install billstclair/elm-sha256@1.0.9
	lamdera install chelovek0v/bbase64@1.0.1
	lamdera install dillonkearns/elm-markdown@7.0.1
	lamdera install elm/browser@1.0.2
	lamdera install elm/bytes@1.0.8
	lamdera install elm/core@1.0.5
	lamdera install elm/html@1.0.0
	lamdera install elm/http@2.0.0
	lamdera install elm/json@1.1.3
	lamdera install elm/parser@1.1.0
	lamdera install elm/random@1.0.0
	lamdera install elm/time@1.0.0
	lamdera install elm/url@1.0.0
	lamdera install elmcraft/core-extra@2.0.0
	lamdera install ianmackenzie/elm-units@2.10.0
	lamdera install lamdera/codecs@1.0.0
	lamdera install lamdera/core@1.0.0
	lamdera install mdgriffith/elm-ui@1.1.8
	lamdera install mgold/elm-nonempty-list@4.2.0
	lamdera install pzp1997/assoc-list@1.0.0
	lamdera install rtfeldman/elm-hex@1.0.0

uninstall:
	cp vendor-open/Env.elm src/
	cp -r counter-original/src/. counter/src/