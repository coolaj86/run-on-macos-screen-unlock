# run-on-macos-screen-unlock

A tiny Swift program to run a command whenever the screen unlocks \
(I use it for mounting remounting network shares after sleep)

```sh
run-on-macos-screen-unlock ./examples/mount-network-shares.sh
```

# Install

1. Download
    ```sh
    curl --fail-with-body -L -O https://github.com/coolaj86/run-on-macos-screen-unlock/releases/download/v1.0.0/run-on-macos-screen-unlock-v1.0.0.tar.gz
    ```
2. Extract
    ```sh
    tar xvf ./run-on-macos-screen-unlock-v1.0.0.tar.gz
    ```
3. Allow running even though it's unsigned
    ```sh
    xattr -r -d com.apple.quarantine ./run-on-macos-screen-unlock
    ```
4. Move into your `PATH`
    ```sh
    mv ./run-on-macos-screen-unlock ~/bin/
    ```

# Build from Source

1. Install XCode Tools \
   (including `git` and `swift`)
    ```sh
    xcode-select --install
    ```
2. Clone and enter the repo
    ```sh
    git clone https://github.com/coolaj86/run-on-macos-screen-unlock.git
    pushd ./run-on-macos-screen-unlock/
    ```
3. Build with `swiftc`
    ```sh
    swiftc ./run-on-macos-screen-unlock.swift
    ```

# Release

1. Git tag and push
    ```sh
    git tag v1.0.x
    git push --tags
    ```
2. Create a release \
   <https://github.com/coolaj86/run-on-macos-screen-unlock/releases/new>
3. Tar and upload
    ```sh
    tar cvf ./run-on-macos-screen-unlock-v1.0.x.tar ./run-on-macos-screen-unlock
    gzip ./run-on-macos-screen-unlock-v1.0.x.tar
    open .
    ```
