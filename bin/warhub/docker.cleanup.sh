#!/usr/bin/env bash
# Remove local Docker images whose repository names start with wt-,
# plus any additional image references passed as arguments.
#
# Usage:
#   ./docker.cleanup.sh
#   ./docker.cleanup.sh -d
#   ./docker.cleanup.sh --dry-run
#   ./docker.cleanup.sh some-other-image:tag
#
# Lists images with: docker image ls -a
# An image is selected when its repository (the name before the tag)
# starts with wt-. Other local images are left alone.

set -euo pipefail

# References to remove. Arguments are recorded first; wt-* images follow.
images=()

add_image() {
  local ref=$1 existing
  if [[ -z $ref ]]; then
    return 0
  fi
  if ((${#images[@]} > 0)); then
    for existing in "${images[@]}"; do
      if [[ $existing == "$ref" ]]; then
        return 0
      fi
    done
  fi
  images+=("$ref")
}

main() {
  local arg repo tag id list_output dry_run
  local -a image_args=()
  dry_run=0

  if ! command -v docker >/dev/null 2>&1; then
    printf 'docker not found in PATH\n' >&2
    exit 1
  fi

  while [[ $# -gt 0 ]]; do
    case $1 in
      -d|--dry-run)
        dry_run=1
        shift
        ;;
      --)
        shift
        while [[ $# -gt 0 ]]; do
          image_args+=("$1")
          shift
        done
        ;;
      -*)
        printf 'Unknown option: %s\n' "$1" >&2
        printf 'Usage: %s [-d|--dry-run] [image ...]\n' "$0" >&2
        exit 1
        ;;
      *)
        image_args+=("$1")
        shift
        ;;
    esac
  done

  if ((${#image_args[@]} > 0)); then
    for arg in "${image_args[@]}"; do
      add_image "$arg"
    done
  fi

  # Repository and tag are separate fields. A repository may contain a colon
  # (localhost:5000/name), so a repo:tag string cannot be split reliably.
  list_output=$(docker image ls -a --format $'{{.Repository}}\t{{.Tag}}\t{{.ID}}')

  while IFS=$'\t' read -r repo tag id || [[ -n ${repo:-} ]]; do
    [[ -z ${repo:-} ]] && continue
    [[ $repo == "REPOSITORY" ]] && continue
    if [[ $repo == wt-* ]]; then
      if [[ -n $tag && $tag != "<none>" ]]; then
        add_image "${repo}:${tag}"
      elif [[ -n $id && $id != "<none>" ]]; then
        add_image "$id"
      fi
    fi
  done <<< "$list_output"

  if ((${#images[@]} == 0)); then
    printf 'No images to remove.\n'
    return 0
  fi

  if ((dry_run)); then
    printf 'Would remove %d image(s):\n' "${#images[@]}"
  else
    printf 'Removing %d image(s):\n' "${#images[@]}"
  fi
  for ref in "${images[@]}"; do
    printf '  %s\n' "$ref"
  done

  if ((dry_run)); then
    return 0
  fi

  docker image rm "${images[@]}"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
