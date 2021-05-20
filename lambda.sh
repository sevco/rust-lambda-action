#!/bin/bash
# build and pack a rust lambda library
# https://aws.amazon.com/blogs/opensource/rust-runtime-for-aws-lambda/

set -e

if [ "x$2" != "x" ]; then
    echo $2 > .git_credentials
    git config --global credential.helper "store --file $PWD/.git_credentials"
    git config --global "url.https://github.com/.insteadOf" "ssh://git@github.com/"
    git config --global --add "url.https://github.com/.insteadOf" "git@github.com:"
fi

echo "Setting up local Cargo env"
mkdir -p .cargo
ln -sf $CARGO_HOME/bin .cargo/
ln -sf $CARGO_HOME/config .cargo/
export CARGO_HOME=$PWD/.cargo

if [ "x$1" != x ]; then
    cd $1
fi

HOOKS_DIR="$PWD/.lambda-rust"
INSTALL_HOOK="install"
BUILD_HOOK="build"
PACKAGE_HOOK="package"

set -eo pipefail
mkdir -p target/lambda
export PROFILE=${PROFILE:-release}
export PACKAGE=${PACKAGE:-true}
export DEBUGINFO=${DEBUGINFO}

# cargo uses different names for target
# of its build profiles
if [[ "${PROFILE}" == "release" ]]; then
    TARGET_PROFILE="${PROFILE}"
else
    TARGET_PROFILE="debug"
fi
export CARGO_TARGET_DIR=$PWD/target
(
    if test -f "$HOOKS_DIR/$INSTALL_HOOK"; then
        echo "Running install hook"
        /bin/bash "$HOOKS_DIR/$INSTALL_HOOK"
        echo "Install hook ran successfully"
    fi

    CARGO_BIN_ARG="" && [[ -n "$BIN" ]] && CARGO_BIN_ARG="--bin ${BIN}"

    # cargo only supports --release flag for release
    # profiles. dev is implicit
    if [ "${PROFILE}" == "release" ]; then
        cargo build ${CARGO_BIN_ARG} ${CARGO_FLAGS:-} --${PROFILE} --all
    else
        cargo build ${CARGO_BIN_ARG} ${CARGO_FLAGS:-} --all
    fi

    echo "$HOOKS_DIR/$BUILD_HOOK"
    if test -f "$HOOKS_DIR/$BUILD_HOOK"; then
        echo "Running build hook"
        /bin/bash "$HOOKS_DIR/$BUILD_HOOK"
        echo "Build hook ran successfully"
    fi
) 

function package() {
    file="$1"
    OUTPUT_FOLDER="${CARGO_TARGET_DIR}/lambda/${file}"
    if [[ "${PROFILE}" == "release" ]] && [[ -z "${DEBUGINFO}" ]]; then
        objcopy --only-keep-debug "$file" "$file.debug"
        objcopy --strip-debug --strip-unneeded "$file"
        objcopy --add-gnu-debuglink="$file.debug" "$file"
    fi
    rm "$file.zip" > 2&>/dev/null || true
    rm -r "${OUTPUT_FOLDER}" > 2&>/dev/null || true
    mkdir -p "${OUTPUT_FOLDER}"
    cp "${file}" "${OUTPUT_FOLDER}/bootstrap"
    cp "${file}.debug" "${OUTPUT_FOLDER}/bootstrap.debug" > 2&>/dev/null || true

    if [[ "$PACKAGE" != "false" ]]; then
        zip -j "${CARGO_TARGET_DIR}/lambda/${file}.zip" "${OUTPUT_FOLDER}/bootstrap"
        if test -f "$HOOKS_DIR/$PACKAGE_HOOK"; then
            echo "Running package hook"
            /bin/bash "$HOOKS_DIR/$PACKAGE_HOOK" $file
            echo "Package hook ran successfully"
        fi
    fi
}

cd "${CARGO_TARGET_DIR}/x86_64-unknown-linux-musl/${TARGET_PROFILE}"
(
    if [ -z "$BIN" ]; then
        IFS=$'\n'
        for executable in $(cargo metadata --no-deps --format-version=1 | jq -r '.packages[] | .targets[] | select(.kind[] | contains("bin")) | .name'); do
          package "$executable"
        done
    else
        package "$BIN"
    fi

) 
