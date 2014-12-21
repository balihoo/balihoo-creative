PATH := ./node_modules/.bin:${PATH}

.PHONY : init clean build dist publish

init:
	npm install

docs:
	docco src/*.coffee

clean:
	rm -rf lib/

build:
	coffee -o lib/ -c src/

dist: clean init build

publish: dist
	npm publish

