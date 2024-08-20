# run-on-macos-screen-unlock

A tiny Swift program to run a command whenever the screen unlocks \
(I use it for remounting network shares when waking from sleep)

```sh
# run-on-macos-screen-unlock <command-to-run-on-unlock> [command-args]
run-on-macos-screen-unlock ./examples/mount-network-shares.sh
```

```sh
# add to launchctl (start on login)
serviceman add --user \
    --path "$PATH" \
    ./run-on-macos-screen-unlock ./examples/mount-network-shares.sh
```

# Table of Contents

-   [Install](#install)
-   [Run on Login](#run-on-login)
    -   [With serviceman](#with-serviceman)
    -   [With a plist template](#with-a-plist-template)
-   [Build from Source](#build-from-source)
-   [Publish Release](#publish-release)
-   [Similar Products](#similar-products)

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

# Run on Login

You'll see notifications similar to these when adding launchctl services yourself:

<img width="376" alt="Background Items Added" src="https://github.com/user-attachments/assets/362d180b-51e6-4e5a-a9be-8cdc356e5b34">

<img width="827" alt="Login Items from unidentified developer" src="https://github.com/user-attachments/assets/fb8fce4c-035a-40ae-8f37-70c28e67ad87">

## With `serviceman`

1. Install `serviceman`
    ```sh
    curl --fail-with-body -sS https://webi.sh/serviceman | sh
    source ~/.config/envman/PATH.env
    ```
2. Register with Launchd \
   (change `COMMAND_GOES_HERE` to your command)

    ```sh
    serviceman add --user \
        --path "$PATH" \
        ~/bin/run-on-macos-screen-unlock COMMAND_GOES_HERE
    ```

## With a plist template

1. Download the template plist file
    ```sh
    curl --fail-with-body -L -O https://raw.githubusercontent.com/coolaj86/run-on-macos-screen-unlock/main/examples/run-on-macos-screen-unlock.COMMAND_LABEL_GOES_HERE.plist
    ```
2. Change the template variables to what you need:

    - `USERNAME_GOES_HERE` (the result of `$(id -u -n)` or `echo $USER`)
    - `COMMAND_LABEL_GOES_HERE` (lowercase, dashes, no spaces)
    - `COMMAND_GOES_HERE` (the example uses `./examples/mount-network-shares.sh`)

3. Rename and move the file to `~/Library/LaunchDaemons/`
    ```sh
    mv ./run-on-macos-screen-unlock.COMMAND_LABEL_GOES_HERE.plist ./run-on-macos-screen-unlock.example-label.plist
    mv ./run-on-macos-screen-unlock.*.plist ~/Library/LaunchDaemons/
    ```
4. Register using `launchctl`
    ```sh
    launchctl load -w ~/Library/LaunchAgents/run-on-macos-screen-unlock.*.plist
    ```

## View logs

```sh
tail -f ~/.local/share/run-on-macos-screen-unlock.*/var/log/run-on-macos-screen-unlock.*.log
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
    swift build --configuration release
    ```

# Publish Release

1. Git tag and push
    ```sh
    git tag v1.0.x
    git push --tags
    ```
2. Create a release \
   <https://github.com/coolaj86/run-on-macos-screen-unlock/releases/new>
3. Tar and upload
    ```sh
    tar cvf ./run-on-macos-screen-unlock-v1.0.x.tar -C .build/release/ ./run-on-macos-screen-unlock
    gzip ./run-on-macos-screen-unlock-v1.0.x.tar
    open .
    ```

# Similar Products

-   [EventScripts](https://apps.apple.com/us/app/eventscripts/id525319418?l=en&mt=12)
-   [HammarSpoon: caffeinate.watcher](https://www.hammerspoon.org/docs/hs.caffeinate.watcher.html)
-   [sleepwatcher](https://github.com/fishman/sleepwatcher)
