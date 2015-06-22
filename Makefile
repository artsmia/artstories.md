SHELL := bash

default: art stories

artstories.json:
	curl new.artsmia.org/crashpad/griot/ > $@

art: artstories.json
	@rm -rf art
	@mkdir -p art
	@echo > readme.md
	@jq -c '.objects | .[]' $< | sed 's/<\([^ >]*\) [^>]*>/<\1>/g' | while read -r json; do \
		title=$$(jq -r '.title' <<<$$json); \
		slug=$$(echo $$title | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr A-Z a-z | sed -e 's/--/-/; s/^-//; s/-$$//'); \
		file=art/$$slug.md; \
		echo "* [$$title](art/$$slug.md)" >> readme.md; \
		id=$$(jq -r '.id' <<<$$json); \
		doc="# [$$title](http://artstories.artsmia.org/#/o/$$id)\n"; \
		doc+="![$$title]($$(jq -r '.thumbnail' <<<$$json))\n"; \
		doc+="\n$$(jq -r '.description' <<<$$json | sed 's/>n$$/>/g; s/>n</></g' | pandoc --no-wrap -f html -t markdown)"; \
		doc+="\n\n---"; \
		echo -e "$$doc" > "$$file"; \
		jq -c -r '.views[] | .annotations[]' <<<$$json | grep -v '^$$' | while read -r note; do \
			title=$$(jq -r '.title' <<<$$note | sed 's/ *$$//g'); \
			description=$$(jq -r '.description' <<<$$note | sed 's/>n$$/>/g; s/>n</></g' | pandoc --no-wrap -f html -t markdown); \
			note="\n\n## $$title\n\n$$description"; \
			doc+="$$note"; \
			echo -e "$$doc" > "$$file"; \
		done; \
		doc=$$(cat "$$file"); \
		doc+="\n\n---\n"; \
		jq -c -r '.relatedStories[]' <<<$$json | while read -r storyId; do \
			storyTitle=$$(jq -r --arg id $$storyId '.stories[$$id] | .title' artstories.json); \
			storySlug=$$(echo $$storyTitle | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr A-Z a-z | sed -e 's/--/-/; s/^-//; s/-$$//'); \
			doc+="\n* [$$storyTitle](../stories/$$storySlug.md)"; \
			echo -e "$$doc" > "$$file"; \
		done; \
		doc=$$(cat "$$file"); \
		echo -e "$$doc" | sed 's/>n$$/>/g; s/>n</></g' > "$$file"; \
	done

stories: artstories.json
	@rm -rf stories
	@mkdir -p stories
	@jq -c '.stories[]' $< | sed 's/<\([^ >]*\) [^>]*>/<\1>/g' | while read -r json; do \
		title=$$(jq -r '.title' <<<$$json); \
		slug=$$(echo $$title | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr A-Z a-z | sed -e 's/--/-/; s/^-//; s/-$$//'); \
		id=$$(jq -r '.id' <<<$$json); \
		file=stories/$$slug.md; \
		doc="# [$$title](http://artstories.artsmia.org/#/stories/$$id)"; \
		echo -e "$$doc" > $$file; \
		jq -c -r '.pages[]' <<<$$json | grep -v '^$$' | while read -r page; do \
			text=$$(jq -r '.text' <<<$$page); \
			image=$$(jq -r '.image' <<<$$page); \
			imageB=$$(jq -r '.imageB' <<<$$page); \
			type=$$(jq -r '.type' <<<$$page); \
			video=$$(jq -r '.video' <<<$$page); \
			case $$type in \
				image) media="\n\n![](http://cdn.dx.artsmia.org/thumbs/tn_$$image.jpg)";; \
				video) media="\n\n<video src='$$video'></video>";; \
				comparison) media="\n\n![](http://cdn.dx.artsmia.org/thumbs/tn_$$image.jpg)\n![](http://cdn.dx.artsmia.org/thumbs/tn_$$imageB.jpg)";; \
				text) ;; \
				*) echo "type $$type not supported!!!";; \
			esac; \
			pandocText=$$(echo $$text | sed 's/>n$$/>/g; s/>n</></g' | pandoc --no-wrap -f html -t markdown); \
			doc+="$$media\n\n$$pandocText\n\n---"; \
			echo -e "$$doc" > $$file; \
		done; \
		doc=$$(cat $$file); \
		echo -e "$$doc" | sed 's/>n$$/>/g; s/>n</></g' > $$file; \
	done

.PHONY: art stories
