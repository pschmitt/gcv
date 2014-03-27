# gcv

gcv - GitHub Contribution Visualisation

Student project - Visualisation de données 2014

Authors: Philipp Schmitt (pschmitt) and Vincent Lamouroux (skad)

## Installation

### Linux (or any other real OS)

```bash
git clone https://github.com/pschmitt/gcv
cd !$
./run.sh -b
```

### Alternative

You may try calling make directly:

```
make clean
make
make run
```

### Manually

In order to use the [Processing IDE](http://www.processing.org/) directly, you'll have to first download [jopt-simple](http://central.maven.org/maven2/net/sf/jopt-simple/jopt-simple/4.6/) and save it to a folder called `code` inside the project.
You should then be able to open the sketch with Processing and run it.

## Auth token

Since we are making use of the [GitHub API](https://developer.github.com/v3/) we strongly recommend using an auth token. Just save it in a file called `token` in the root folder of this project. Or just launch `gcv` like this:

```bash
./gcv -t $TOKEN
```

## Documentation

[Presentation (French)](https://docs.google.com/presentation/d/1Gf9_dqAwb_rAL8qRICn0STKEop78Y4-qsVYG8Hz2Ug8/edit?usp=sharing)

### Usage

```
Usage: gcv [-t TOKEN] [-d] [-v] REPO
REPO: username/repository
TOKEN: Optional GitHub token
-d: Debug mode
-v: Verbose
```

### Examples

```bash
# default repo
./gcv
# User supplied repo
./gcv owncloud/core
# Debug
./gcv -d -v
```

## Known issues

Sometimes the GitHub API is yielding an empty response. After 3 consecutive failures our program exits.
When this happens, just keep on trying.
