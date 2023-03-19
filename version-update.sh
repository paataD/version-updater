#!/bin/bash

fileListArr=("package.json" "composer.json")
versionPattern="([0-9]+).([0-9]+).([0-9]+)"
expressionPattern="\w+=\w+"

major=0
minor=0
build=0

function help {
  echo "Usage: $(basename "$0") version=<newversion> or release=[major|feat|fix]"
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
  if [[ -n $version ]]; then
    if [[ "$version" =~ $versionPattern ]]; then
      for file in "${fileListArr[@]}"; do
        setVersion "$version" "$file"
      done
       echo "New version: $version"
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

  if [[ "$release" == "feat" ]]; then
    minor=$(echo "$minor + 1" | bc)
  elif [[ "$release" == "fix" ]]; then
    build=$(echo "$build + 1" | bc)
  elif [[ "$release" == "major" || "$release" == "breaking change" ]]; then
    major=$(echo "$major+1" | bc)
  else
    help
    echo "Error"
    exit 1
  fi

  for file in "${fileListArr[@]}"; do
    setVersion "${major}.${minor}.${build}" "$file"
  done
  echo "New version: ${major}.${minor}.${build}"
}

main "$@"
