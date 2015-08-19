PATH := ./node_modules/.bin:${PATH}

.PHONY : init clean build watch dist publish

init:
	npm install

docs:
	docco src/*.coffee

clean:
	rm -rf lib/

build:
	coffee -o lib/ -c src/

watch:
	coffee -o lib/ -cw src/

dist: clean init build

publish: dist
	npm publish

