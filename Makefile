include config.mk

.PHONY: build
build: $(NAMEDBLACKLIST) $(ZONEFILE)

.PHONY: deploy
deploy: build
	@rm -f "$(DEPLOYDIR)/$(NAMEDBLACKLIST)"
	@rm -f "$(DEPLOYDIR)/$(ZONEFILE)"
	@./deploy.sh "$(DEPLOYDIR)" "$(NAMEDBLACKLIST)" "$(ZONEFILE)"
	@service "$(SERVICE)" reload

.PHONY: test
test:
	@./test.sh "$(BLACKLIST)"

.PHONY: clean
clean:
	@rm -f "$(NAMEDBLACKLIST)"
	@rm -f "$(ZONEFILE)"

$(NAMEDBLACKLIST):
	@./blacklist.sh "$(BLACKLIST)" "$(NAMEDBLACKLIST)"

$(ZONEFILE):
	@./zonefile.sh "$(ZONEFILE)" "$(PRIMARYDNS)" "$(SECONDARYDNS)" "$(HOSTMASTER)"

