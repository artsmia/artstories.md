SHELL := bash

artstories.json:
	curl new.artsmia.org/crashpad/griot > $@

art: artstories.json
	@mkdir -p art
	@echo > readme.md
	@jq -c '.objects | .[]' $< | sed 's/<\([^ >]*\) [^>]*>/<\1>/g' | while read json; do \
		title=$$(jq -r '.title' <<<$$json); \
		slug=$$(echo $$title | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr A-Z a-z | sed -e 's/--/-/; s/^-//; s/-$$//'); \
		echo "* [$$title](art/$$slug.md)" >> readme.md; \
		id=$$(jq -r '.id' <<<$$json); \
		doc="# [$$title](http://artsmia.github.io/griot/#/o/$$id)\n"; \
		doc+="![$$title]($$(jq -r '.thumbnail' <<<$$json))\n"; \
		doc+="\n$$(jq -r '.description' <<<$$json)"; \
		doc+="\n\n---"; \
		jq -c -r '.views[] | .annotations[] | .title, .description' <<<$$json | while read title; do \
			read description; \
			note="\n\n## $$title\n$$description"; \
			doc+=$$note; \
			echo -e $$doc > art/$$slug.md; \
		done; \
		doc=$$(cat art/$$slug.md); \
		doc+="\n\n---\n"; \
		jq -c -r '.relatedStories[]' <<<$$json | while read storyId; do \
			storyTitle=$$(jq -r --arg id $$storyId '.stories[$$id] | .title' artstories.json); \
			doc+="\n* [$$storyTitle](http://artsmia.github.io/griot/#/stories/$$storyId)"; \
			echo -e "$$doc" > art/$$slug.md; \
		done; \
		doc=$$(cat art/$$slug.md); \
		echo -e "$$doc" | sed 's/>n$$/>/g; s/>n</></g' > art/$$slug.md; \
	done

.PHONY: art
