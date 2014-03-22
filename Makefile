SKETCH=../github
OUTPUTDIR=output
EXECUTABLE=$(OUTPUTDIR)/github
TOKEN_FILE=token
TOKEN=$(shell cat $(TOKEN_FILE))
REPO=$(shell git config --get remote.origin.url | sed -e 's|.*github.com[:/]\?\(.*\)|\1|g' -e 's|\(.*\)\.git$$|\1|' | head -1)

LIB_PATH=code
JOPT_VERSION=4.6
JOPT_JAR=jopt-simple-$(JOPT_VERSION).jar
JOPT_URL=http://central.maven.org/maven2/net/sf/jopt-simple/jopt-simple/$(JOPT_VERSION)/$(JOPT_JAR)

# http://stackoverflow.com/a/14061796
# If the first argument is "run"...
ifeq (run,$(firstword $(MAKECMDGOALS)))
# use the rest as arguments for "run"
RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
# ...and turn them into do-nothing targets
$(eval $(RUN_ARGS):;@:)
endif

# Fallback
ifeq "$(REPO)" ""
REPO=pschmitt/github-contributions-visualisation
endif

# If no arg supplied guess em
ifndef RUN_ARGS
RUN_ARGS = $(REPO)
endif

ifneq "$(TOKEN)" ""
RUN_ARGS += -t $(TOKEN)
endif

all: libs
	processing-java --sketch=$(SKETCH) --output=$(OUTPUTDIR) --export --force

libs: jopt

jopt:
	mkdir -p $(LIB_PATH)
	test -f $(LIB_PATH)/$(JOPT_JAR) || wget $(JOPT_URL) -P $(LIB_PATH)


.PHONY: run
run:
	$(EXECUTABLE) $(RUN_ARGS)

.PHONY: clean
clean:
	rm -rf $(OUTPUTDIR) $(LIB_PATH)
