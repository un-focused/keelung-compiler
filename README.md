# The Keelung Compiler 

Documentation on how to hack it is on the way.
Feel free to open issues or make PRs!

## For Users

### Installation
See the [Installation Guide](https://btq.gitbook.io/keelung/getting-started/setting-up-the-environment) on Gitbook.

### Release Notes
Visit the [Releases](https://github.com/btq-ag/keelung-compiler/releases) page to see all the releases and their changelogs, note that old releases before v0.12.1 are in the [release page of btq-ag/keelung](https://github.com/btq-ag/keelung/releases) repo instead.


## For Developers

### How to dockerize `keelungc`

To dockerize the executable `keelungc`, run the following command in the root of the repository:

```bash 
DOCKER_BUILDKIT=1  docker build --ssh default -t keelung -f Dockerfile .
```

(add `--platform linux/amd64` if you are using architectures like arm64)

The built image is currently available on the Docker Hub as [banacorn/keelung](https://hub.docker.com/repository/docker/banacorn/keelung).

To execute the image, run:

```
docker run banacorn/keelung
```

(add `--platform linux/amd64` if you are using architectures like arm64)

### How to profile the compiler and generate flamegraphs

1. Install [ghc-prof-flamegraph](https://hackage.haskell.org/package/ghc-prof-flamegraph) on your machine: 

```bash
stack install ghc-prof-flamegraph
```

2. Prepare an executable like `profile` in `profiling/Main.hs` with the program you want to profile.
3. Build and install the executable with profiling enabled:

```bash
stack install keelung-compiler:exe:profile --profile
``` 

4. Generate a profiling report:

```bash
stack exec --profile -- profile +RTS -p
```

5. Generate a flamegraph:

```bash
ghc-prof-flamegraph profile.prof
``` 

### Notes for Releasing Binaries
Binaries released to the [Keelung repo](https://github.com/btq-ag/keelung/releases) includes automatically generated licenses using [cabal-plan](https://github.com/haskell-hvr/cabal-plan), for Github Actions to work, `keelung` dependency in `cabal.project` must be updated to match its commit hash used in `stack.yaml` for the CI to build. This is only required when a major release is needed.
