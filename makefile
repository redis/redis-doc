MD_FILES:=$(shell find commands -name '*.md')
JSON_FILES:=$(shell find . -name '*.json')
TEXT_FILES:=$(patsubst %.md,tmp/%.txt,$(MD_FILES))
SPELL_FILES:=$(patsubst %.txt,%.spell,$(TEXT_FILES))

default: parse

parse: $(JSON_FILES)
	rake parse

check: clients tools

clients:
	ruby utils/clients.rb clients.json

tools:
	ruby utils/clients.rb tools.json

check_duplicate_wordlist: wordlist
	@cat wordlist |sort |uniq -c |sort -n \
		|awk '{ if ($$1 > 1) print "grep -nw "$$2" wordlist"}' \
		|sh >tmp/duplicates_in_wordlist.txt || true
	@test -s tmp/duplicates_in_wordlist.txt \
		&& echo "ERROR: The following word(s) appear more than once in the './wordlist' file:" \
		&& echo "line:word" \
		&& echo "---------" \
		&& cat tmp/duplicates_in_wordlist.txt \
		|| true
	@test ! -s tmp/duplicates_in_wordlist.txt

check_command_wordlist: wordlist tmp/commands.txt check_duplicate_wordlist
	@cat wordlist tmp/commands.txt |sort |uniq -c |sort -n \
		|awk '{ if ($$1 > 1) print "grep -nw "$$2" wordlist"}' \
		|sh >tmp/commands_in_wordlist.txt || true
	@test -s tmp/commands_in_wordlist.txt \
		&& echo "ERROR: The following command(s) should be removed from in the './wordlist' file:" \
		&& echo "line:command" \
		&& echo "------------" \
		&& cat tmp/commands_in_wordlist.txt \
		|| true
	@test ! -s tmp/commands_in_wordlist.txt

spell: tmp/commands tmp/topics $(SPELL_FILES) check_command_wordlist
	find tmp -name '*.spell' | xargs cat > tmp/spelling-errors
	cat tmp/spelling-errors
	test ! -s tmp/spelling-errors

$(TEXT_FILES): tmp/%.txt: %.md
	./bin/text $< > $@

$(SPELL_FILES): %.spell: %.txt tmp/dict
	aspell -a --extra-dicts=./tmp/dict 2>/dev/null < $< | \
		awk -v FILE=$(patsubst tmp/%.spell,%.md,$@) '/^&/ { print FILE, $$2 }' | \
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
