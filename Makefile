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
		doc+="\n$$(jq -r '.description' <<<$$json | sed 's/>n$$/>/g; s/>n</></g' | pandoc --no-wrap -f html -t markdown)"; \
		doc+="\n\n---"; \
		jq -c -r '.views[] | .annotations[] | .title, .description' <<<$$json | while read title; do \
			read description; \
			pandocDesc=$$(echo $$description | sed 's/>n$$/>/g; s/>n</></g' | pandoc --no-wrap -f html -t markdown); \
			note="\n\n## $$title\n\n$$pandocDesc"; \
			doc+="$$note"; \
			echo -e "$$doc" > art/$$slug.md; \
		done; \
		doc=$$(cat art/$$slug.md); \
		doc+="\n\n---\n"; \
		jq -c -r '.relatedStories[]' <<<$$json | while read storyId; do \
			storyTitle=$$(jq -r --arg id $$storyId '.stories[$$id] | .title' artstories.json); \
			storySlug=$$(echo $$storyTitle | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr A-Z a-z | sed -e 's/--/-/; s/^-//; s/-$$//'); \
			doc+="\n* [$$storyTitle](../stories/$$storySlug.md)"; \
			echo -e "$$doc" > art/$$slug.md; \
		done; \
		doc=$$(cat art/$$slug.md); \
		echo -e "$$doc" | sed 's/>n$$/>/g; s/>n</></g' > art/$$slug.md; \
	done

stories: artstories.json
	@mkdir -p stories
	@jq -c '.stories[]' $< | sed 's/<\([^ >]*\) [^>]*>/<\1>/g' | while read json; do \
		title=$$(jq -r '.title' <<<$$json); \
		slug=$$(echo $$title | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr A-Z a-z | sed -e 's/--/-/; s/^-//; s/-$$//'); \
		id=$$(jq -r '.id' <<<$$json); \
		file=stories/$$slug.md; \
		doc="# [$$title](http://artsmia.github.io/griot/#/stories/$$id)"; \
		echo -e "$$doc" > $$file; \
		jq -c -r '.pages[] | .text, .image, .type, .video' <<<$$json | while read text; do \
			read image; read type; read video; \
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
