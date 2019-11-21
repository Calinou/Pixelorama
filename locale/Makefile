# Makefile providing various facilities to manage translations
# Adapted from https://github.com/godotengine/godot/blob/master/editor/translations/Makefile

MAKEFLAGS += --silent
TEMPLATE = pixelorama.pot
POFILES = $(wildcard *.po)
LANGS = $(POFILES:%.po=%)

all: generate-pot merge check

.PHONY: generate-pot
generate-pot:
	# See <https://docs.godotengine.org/en/latest/tutorials/i18n/localization_using_gettext.html>
	# for more information about using Babel with Godot to extract localization strings.
	pybabel extract \
		--mapping-file babelrc \
		--keyword text \
		--keyword LineEdit/placeholder_text \
		--keyword tr \
		--output pixelorama.pot \
		--project Pixelorama \
		--version 0.4 \
		--copyright-holder OverloadedOrama \
		..

.PHONY: merge
merge:
	for po in $(POFILES); do \
	  echo -e "\nMerging $$po..."; \
	  msgmerge -w 79 -C $$po $$po $(TEMPLATE) > "$$po".new; \
	  mv -f "$$po".new $$po; \
	done

.PHONY: check
check:
	for po in $(POFILES); do \
		msgfmt -c $$po -o /dev/null; \
	done
