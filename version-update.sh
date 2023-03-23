#!/bin/bash

fileListArr=("package.json" "composer.json")
versionPattern="([0-9]+).([0-9]+).([0-9]+)"
expressionPattern="\w+=\w+"

major=0
minor=0
build=0
hash=$(eval 'git rev-parse --short HEAD')


function help {
  echo "Usage: $(basename "$0") version=<newversion> or release=[major|feat|fix]"
}

function addVerToFile {
  echo "$hash|$1|$(date +'%d-%m-%Y %T')" >|'version'
}

function addToGit {
  if [[ -n $togit ]]; then
    git add . && git add --update && git commit --amend --reset-author --no-edit && git push --force
  fi
}

function addGitTag {
  if [[ -n $gittag && ! $(git tag -l v"$1") ]]; then
      git tag v"$1" && git push origin v"$1"
  fi
}

function newVersion {
  if [[ ! -f version || $(sed -E -e 's/^(\w+).*/\1/' version) != "$hash" ]]; then
    return
  fi
  false
}

function parseArguments {
  for ARGUMENT in "$@"; do
    if [[ "$ARGUMENT" =~ $expressionPattern ]]; then
      KEY=$(echo $ARGUMENT | cut -f1 -d=)
      KEY_LENGTH=${#KEY}
      VALUE="${ARGUMENT:$KEY_LENGTH+1}"
      export "$KEY"="$VALUE"
    fi
  done
}

function setVersion {
  sed -ri 's/("version":)\s+\".*"/\1 "'"$1"'"/g' "$2"
}

function main() {
  parseArguments "$@"
  if [[ -n $gittag || -n $togit ]]; then
    git config user.email "$gitemail" || _exit $? "Could not set git user.email"
    git config user.name "$gitname" || _exit $? "Could not set git user.name"
  fi
  if [[ -n $version ]]; then
    if [[ "$version" =~ $versionPattern ]]; then
      for file in "${fileListArr[@]}"; do
        setVersion "$version" "$file"
      done
      echo "$version"
      exit
    else
      echo "Wrong version format, pls. use $versionPattern"
      exit 1
    fi
  fi
  for file in "${fileListArr[@]}"; do
    if [[ -f "$file" ]]; then
      PACKAGE_VERSION=$(cat $file | grep version | head -1 | awk -F: '{ print $2 }' | sed 's/[\",]//g' | tr -d '[[:space:]]')
      if [[ -n "$PACKAGE_VERSION" ]]; then
        break
      fi
    fi
  done
  if [[ "$PACKAGE_VERSION" =~ $versionPattern ]]; then
    major="${BASH_REMATCH[1]}"
    minor="${BASH_REMATCH[2]}"
    build="${BASH_REMATCH[3]}"
  fi

  if [[ -z "$release" && -n $message ]]; then
    release=$(echo "$message" | sed -E -e 's/^(fix|feat|major|breaking change):.*$/\1/g')
    else
    release=$(git log --no-merges --format=%s -1 | sed -E -e 's/^(fix|feat|major|breaking change):.*$/\1/g')
  fi

  if [[ "$release" == "feat" ]]; then
    minor=$(echo "$((minor + 1))")
  elif [[ "$release" == "fix" ]]; then
    build=$(echo "$((build + 1))")
  elif [[ "$release" == "major" || "$release" == "breaking change" ]]; then
    major=$(echo "$((major + 1))")
  else
    help
    echo "Error"
    exit 1
  fi

  if newVersion; then
    for file in "${fileListArr[@]}"; do
      if [[ -f $file ]]; then
        setVersion "${major}.${minor}.${build}" "$file"
      fi
    done
    addVerToFile "${major}.${minor}.${build}"
    addToGit
    addGitTag "${major}.${minor}.${build}"
  fi
  echo "${major}.${minor}.${build}"
}

main "$@"
