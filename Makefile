APP_ID = de.magynhard.GoblinConverter
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
SHAREDIR = $(PREFIX)/share
APPDIR = $(SHAREDIR)/goblin-converter
LOCALEDIR = $(SHAREDIR)/locale

.PHONY: build run install uninstall locales clean test

build:
	crystal build src/goblin-converter.cr -o bin/goblin-converter

test:
	crystal spec

run: build
	./bin/goblin-converter

install: build locales
	install -Dm755 bin/goblin-converter $(DESTDIR)$(BINDIR)/goblin-converter
	install -Dm644 data/$(APP_ID).desktop $(DESTDIR)$(SHAREDIR)/applications/$(APP_ID).desktop
	install -Dm644 data/$(APP_ID).metainfo.xml $(DESTDIR)$(SHAREDIR)/metainfo/$(APP_ID).metainfo.xml
	install -Dm644 data/icons/app-icon.svg $(DESTDIR)$(SHAREDIR)/icons/$(APP_ID).svg
	install -Dm644 data/icons/app-icon-512.png $(DESTDIR)$(SHAREDIR)/icons/$(APP_ID)-512.png
	mkdir -p $(DESTDIR)$(APPDIR)
	cp -r src $(DESTDIR)$(APPDIR)/
	cp -r po $(DESTDIR)$(APPDIR)/
	cp -r data $(DESTDIR)$(APPDIR)/
	cp shard.yml $(DESTDIR)$(APPDIR)/

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/goblin-converter
	rm -f $(DESTDIR)$(SHAREDIR)/applications/$(APP_ID).desktop
	rm -f $(DESTDIR)$(SHAREDIR)/metainfo/$(APP_ID).metainfo.xml
	rm -f $(DESTDIR)$(SHAREDIR)/icons/$(APP_ID).svg
	rm -f $(DESTDIR)$(SHAREDIR)/icons/$(APP_ID)-512.png
	rm -rf $(DESTDIR)$(APPDIR)

locales:
	@for lang in $$(cat po/LINGUAS 2>/dev/null); do \
		mkdir -p po/$$lang/LC_MESSAGES; \
		if [ -f po/$$lang/LC_MESSAGES/$(APP_ID).po ]; then \
			msgfmt po/$$lang/LC_MESSAGES/$(APP_ID).po -o po/$$lang/LC_MESSAGES/$(APP_ID).mo; \
		fi; \
	done

generate_locales:
	@potfiles=$$(cat po/POTFILES 2>/dev/null); \
	if [ -n "$$potfiles" ]; then \
		xgettext -o po/$(APP_ID).pot --from-code=UTF-8 --language=C --keyword=translate $$potfiles; \
	fi
	@for lang in $$(cat po/LINGUAS 2>/dev/null); do \
		mkdir -p po/$$lang/LC_MESSAGES; \
		po_file="po/$$lang/LC_MESSAGES/$(APP_ID).po"; \
		if [ -f "$$po_file" ]; then \
			msgmerge --update --backup=none "$$po_file" po/$(APP_ID).pot; \
		else \
			msginit --input=po/$(APP_ID).pot --locale=$$lang --output="$$po_file" --no-translator; \
		fi; \
	done

clean:
	rm -f bin/goblin-converter
	rm -f *.dwarf
