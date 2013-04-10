#!/bin/bash

set -e

URLBASE="http://www.escemo.com"
URL="$URLBASE/cli/sphere-cli.gem"

usage() {
    echo "$(basename $0) - Installs the sphere CLI tooling"
    echo ""
    echo "Arguments:"
    echo "--help: to show this help text."
    echo "--check: Perform checks for necessary software versions."
    echo "--steps: to show hints for first steps after installation. Nothing else."
}

check_os() {
    UNAME=$(uname)
    if [ "$UNAME" != "Linux" -a "$UNAME" != "Darwin" ] ; then
        echo "Sorry, this OS is not supported yet."
        exit 1
    fi
}

check_dependencies() {
    echo
    echo "Checking if all necessary 3rd party software is available..."
    echo

    set +e

    # we need curl for the download
    which curl >/dev/null || echo "curl not installed. Please install curl via your package manager."

    # TODO check for ruby
    echo -n 'Checking Ruby 1.9.x       ...'
    RUBY_VERSION=$(ruby --version | grep -oe "1\.9\.[0-9]")
    if [ -n "$RUBY_VERSION" ]; then
      echo " OK, version $RUBY_VERSION installed"
    else
      echo " NOT installed, you will not be able to use the CLI tool. Please install Ruby 1.9. We recommend to use RVM on Mac: http://rvm.io"
      exit 1
    fi
    # TODO: if 1.8 check for rvm and use it
    # RVM_VERSION=$(~/.rvm/bin/rvm --version)

    echo -n 'Checking Java 1.6.x_y     ...'
    JAVA_VERSION=$(java -version 2>&1 | grep version | grep -oe "1\.6\.0_[0-9]*")
    if [ -n "$JAVA_VERSION" ]; then
      echo " OK, version $JAVA_VERSION installed"
    else
      echo " NOT installed, you will not be able to run the sample code."
    fi

    echo -n 'Checking Play 2.1         ...'
    PLAY_VERSION=$(play play-version 2>&1 | grep -oe "2\.1")

    if [ -n "$PLAY_VERSION" ]; then # TODO: do we check for 2.x here?
      echo " OK, version $PLAY_VERSION installed"
    else
      echo " NOT installed, you will not be able to run the sample code. You can download Play at http://www.playframework.org/"
    fi

    set -e
}

install() {
    echo
    echo "Downloading sphere-cli..."

    local dir=$(mktemp -d -t sphere-install.XXX)
    curl --progress-bar $URL >> "${dir}/sphere-cli.gem"

    echo
    echo "Installing sphere-cli... You will be asked for your password."
    # TODO: Do we need sudo when using rvm on Mac?
    sudo gem install "${dir}/sphere-cli.gem"
}

show_hint() {
    cat <<HINT

Sphere CLI installed! Here are some commands you may want to use to get started fast:

  $ sphere-cli login                            # to login with your sphere account
  $ sphere-cli projects                         # to list your projects
  $ sphere-cli project select <project_key>     # to select a project for all following commands
  $ sphere-cli type create @filename.json       # to create a product type using a JSON file
  $ sphere-cli taxes create                     # to create some tax information
  $ sphere-cli catalogs import filename.csv     # to import a catalog/category tree
  $ sphere-cli products import filename.csv     # to import products and upload images
  $ sphere-cli code get                         # to download the code
  $ sphere-cli code configure                   # to configure the code with your project
  $ play run                                    # to run the code locally

Have fun ;)

HINT
}

while (( $# > 0 ))
do
  token="$1"
  shift
  case "$token" in

    --check)
      readonly CHECK_ONLY="true"
      ;;

    --steps)
      readonly SHOW_STEPS="true"
      ;;

    --help)
      usage
      exit 0
      ;;
  *)
    usage
    exit 1
    ;;

  esac
done

trap "echo sphere-cli installation failed." EXIT

if [ "$SHOW_STEPS" != "true" ]; then
    check_os
    check_dependencies
fi
if [ "$CHECK_ONLY" != "true" -a "$SHOW_STEPS" != "true" ]; then
    install
    SHOW_STEPS="true" # after installation we want to see the steps always.
fi
if [ "$SHOW_STEPS" = "true" ]; then
    show_hint
fi

trap - EXIT
