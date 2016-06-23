MD_FILES:=$(shell find commands -name '*.md')
JSON_FILES:=$(shell find . -name '*.json')
TEXT_FILES:=$(patsubst %.md,tmp/%.txt,$(MD_FILES))
SPELL_FILES:=$(patsubst %.txt,%.spell,$(TEXT_FILES))

default: parse spell

parse: $(JSON_FILES)
	rake parse

check: clients tools

clients:
	ruby utils/clients.rb clients.json

tools:
	ruby utils/clients.rb tools.json


spell: tmp/commands tmp/topics $(SPELL_FILES)
	find tmp -name '*.spell' | xargs cat > tmp/spelling-errors
	cat tmp/spelling-errors
	test ! -s tmp/spelling-errors

$(TEXT_FILES): tmp/%.txt: %.md
	./bin/text $< > $@

$(SPELL_FILES): %.spell: %.txt tmp/dict
	aspell -a --extra-dicts=./tmp/dict 2>/dev/null < $< | \
		awk -v FILE=$(patsubst tmp/%.spell,%.md,$@) '/^\&/ { print FILE, $$2 }' | \
		sort -f | uniq > $@

tmp/commands:
	mkdir -p tmp/commands

tmp/topics:
	mkdir -p tmp/topics

tmp/commands.txt: commands.json
	ruby -rjson -e 'puts JSON.parse(File.read("$<")).keys.map { |str| str.split(/[ -]/) }.flatten(1)' > $@

tmp/dict: wordlist tmp/commands.txt
	cat $^ | aspell --lang=en create master ./$@

clean:
	rm -rf tmp/*

.PHONY: parse spell clean check clients tools
