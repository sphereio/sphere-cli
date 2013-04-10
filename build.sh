#!/bin/bash

run_tests() {
    rspec1.9.1 --format html -o testresults/rspec.html -r rspec_junit_formatter --format RspecJunitFormatter -o testresults/rspec.xml --format nested --color --tag ~skip spec
    cucumber1.9.1 --color --tags ~@wip --format pretty --format html --out result.html
}

get_pkg() {
    wget -O sphere-cli.pkg -nv "${JENKINS_URL}job/sphere-cli-on-mac/ws/cli/sphere-cli.pkg"
}

revert_git_changes() {
    git checkout -- debian/changelog lib/sphere-cli/version.rb
}

set_version() {
    local BASE_VERSION=$(grep -o -e "[0-9]\+\.[0-9]\+\.[0-9]\+" lib/sphere-cli/version.rb)
    VERSION="${BASE_VERSION}.$(date +%Y%m%d%H%M%S)"
    sed -i "s/@VERSION@/${VERSION}/g" debian/changelog
    sed -i "s/'.*'/'${VERSION}'/g" lib/sphere-cli/version.rb
}

build_gem() {
    rm -rf *.gem
    gem build sphere-cli.gemspec
    ln -s sphere-cli-${VERSION}.gem sphere-cli.gem
}
    
package_deb() {
    rm -rf ../*.deb
    dpkg-buildpackage -uc -us
    rm -rf *.deb
    mv ../*.deb .
}


release() {
  rake perform_release
}

if [ "$1" != "-b" ]; then
    echo "Build script for internal usage. Read the source, luke..."
    exit 1
fi

set -e

run_tests
get_pkg
revert_git_changes
set_version
build_gem
package_deb
revert_git_changes

if [ "${PERFORM_RELEASE}" = "true" ]; then
    release
fi
