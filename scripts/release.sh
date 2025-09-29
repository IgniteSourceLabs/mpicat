#!/bin/bash

# Originally from https://gist.github.com/devster/b91b97ebbca4db4d02b84337b2a3d933

# Script to simplify the release flow.
# 1) Fetch the current release version
# 2) Increase the version (major, minor, patch)
# 3) Add a new git tag
# 4) Push the tag

function stripPrefix {
  local version=$1
  local prefix=${2:-release-}
  echo "${version/${prefix}/}"
}

function addPrefix {
  local version=$1
  local prefix=${2:-release-}
  echo "${prefix}-${version}"
}

msg="Tagging release"
branch=main
prefix="v"

function usage {
  echo "usage: $(basename "$0") -[Mmpn] [-b <branch>] [-c \"message\"] [-C] [-P <prefix>]"
  echo ""
  echo "  -n Dry run"
  echo "  -M for a major release"
  echo "  -m for a minor release"
  echo "  -p for a patch release"
  echo "  -b to specify the branch to be tagged (${branch})"
  echo "  -c to specify the commit message (${msg})"
  echo "  -C to emit the current tag"
  echo "  -P to specify the prefix for the tag (${prefix})"
  echo ""
  echo " Example: release -p -c \"Some fix\""
  echo " means create a patch release with the message \"Some fix\""
  exit 1
}

# Parse command line options.
while getopts ":CMmnpb:c:P:" Option
do
  case ${Option} in
    M ) major=true;;
    m ) minor=true;;
    p ) patch=true;;
    n ) noexec=true;;
    b ) branch=$OPTARG;;
    c ) commitMsg=$OPTARG;;
    C ) emitCurrentTag=true;;
    P ) prefix=$OPTARG;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      usage 1>&2
      ;;
    : )
      echo "Invalid option: ${Option} requires an argument" 1>&2
      usage 1>&2
      ;;
  esac
done

shift $((Option - 1))

# Display usage
# need at least one component bumped
if [ -z "${major}" ] && [ -z "${minor}" ] && [ -z "${patch}" ] && [ -z "${emitCurrentTag}" ];
then
  usage 1>&2
fi

# Force to the root of the project
pushd "$(dirname "${0}")/../"

# 1) Fetch the current release version

git fetch --prune --tags

version=$(git describe --abbrev=0 --tags)
version=$(stripPrefix "${version}" ${prefix}) # Remove the prefix in the tag release-0.37.10 for example

[ "${emitCurrentTag}" = true ] && echo "${version}" && exit 0

# 2) Increase version number

# Build array from version string.

a=( "${version//./ }" )

# Increment version numbers as requested.

if [ -n "${patch}" ]
then
  ((a[2]++))
fi

if [ -n "${minor}" ]
then
  ((a[1]++))
  a[2]=0
fi

if [ -n "${major}" ]
then
  ((a[0]++))
  a[1]=0
  a[2]=0
fi

next_version=$(addPrefix "${a[0]}.${a[1]}.${a[2]}")

tagMsg="${commitMsg:-$msg $next_version}"

# If its a dry run, just display the new release version number
if [ -n "${noexec}" ]
then
  echo "Tag message: $tagMsg"
  echo "Next version tag: $next_version"
  cmd="echo git"
else
  cmd="git"
fi

# If a command fails, exit the script
set -e

# Push master
${cmd} checkout "${branch}"
${cmd} pull --rebase origin "${branch}" || exit 1
${cmd} push origin "${branch}"

# 3) Add git tag
echo "Add git tag $next_version with message: ${tagMsg}"
${cmd} tag -a "${next_version}" -m "${tagMsg}"

# 4) Push the new tag

echo "Push the tag"
${cmd} push --tags origin "${branch}"

echo "Release done: $next_version"

popd
