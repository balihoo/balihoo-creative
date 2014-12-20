PATH := ./node_modules/.bin:${PATH}

.PHONY : init clean-docs clean build test dist publish

init:
	npm install

docs:
	docco src/*.coffee

clean-docs:
	rm -rf docs/

clean: clean-docs
	rm -rf lib/ test/*.js

build:
	coffee -o lib/ -c src/ && coffee -c test/creative.coffee
	cat src/header.txt lib/creative.js > lib/creative_tmp.js
	mv lib/creative_tmp.js lib/creative.js

test:
	nodeunit test/balihoo-creative.js

dist: clean init docs build test

publish: dist
	npm publish

