SHELL := bash

artstories.json:
	curl new.artsmia.org/crashpad/griot > $@

art: artstories.json
	@mkdir -p art
	@jq -c '.objects | .[]' $< | sed 's/<\([^ ]*\) [^>]*>/<\1>/g' | while read json; do \
		title=$$(jq -r '.title' <<<$$json); \
		slug=$$(echo $$title | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr A-Z a-z | sed -e 's/--/-/; s/^-//; s/-$$//'); \
		echo -e "\
# $$title \n\
![$$title]($$(jq -r '.thumbnail' <<<$$json)) \n\
" > art/$$slug.md; \
	done

.PHONY: art
