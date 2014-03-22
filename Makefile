SKETCH=../github
OUTPUTDIR=output
EXECUTABLE=$(OUTPUTDIR)/github
TOKEN_FILE=token
TOKEN=$(shell cat $(TOKEN_FILE))
REPO=$(shell git config --get remote.origin.url | sed 's|.*github.com/\(.*\)|\1|g')

# http://stackoverflow.com/a/14061796
# If the first argument is "run"...
ifeq (run,$(firstword $(MAKECMDGOALS)))
# use the rest as arguments for "run"
RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
# ...and turn them into do-nothing targets
$(eval $(RUN_ARGS):;@:)
ifndef RUN_ARGS
RUN_ARGS = $(REPO)
endif
endif

all:
	processing-java --sketch=$(SKETCH) --output=$(OUTPUTDIR) --export --force

.PHONY: run
run:
	$(EXECUTABLE) $(RUN_ARGS) $(TOKEN)

.PHONY: clean
clean:
	rm -rf $(OUTPUTDIR)/*
