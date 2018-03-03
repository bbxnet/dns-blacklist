include config.mk

.PHONY: all
all: update deploy

.PHONY: build
build: $(NAMEDBLACKLIST) $(ZONEFILE)

.PHONY: deploy
deploy: build
	@rm -f "$(DEPLOYDIR)/$(NAMEDBLACKLIST)"
	@rm -f "$(DEPLOYDIR)/$(ZONEFILE)"
	@./deploy.sh "$(DEPLOYDIR)" "$(NAMEDBLACKLIST)" "$(ZONEFILE)"
	@service "$(SERVICE)" reload

.PHONY: update
update: $(BLACKLIST)

.PHONY: test
test: $(BLACKLIST)
	@./test.sh "$(BLACKLIST)"

.PHONY: clean
clean:
	@rm -f "$(BLACKLIST)"
	@rm -f "$(NAMEDBLACKLIST)"
	@rm -f "$(ZONEFILE)"

$(BLACKLIST):
	@./update-source.sh "$(BLACKLIST)"

$(NAMEDBLACKLIST): $(BLACKLIST)
	./blacklist.sh "$(BLACKLIST)" "$(NAMEDBLACKLIST)"

$(ZONEFILE):
	@./zonefile.sh "$(ZONEFILE)" "$(PRIMARYDNS)" "$(SECONDARYDNS)" "$(HOSTMASTER)"

