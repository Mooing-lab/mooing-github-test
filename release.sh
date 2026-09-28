#!/bin/bash
set -euo pipefail

# mooing-github-test Release Script
# Usage: ./release.sh [patch|minor|major]

BUMP_TYPE="${1:-patch}"
VERSION_FILE="build.gradle"
PROJECT_NAME="mooing-github-test"

# 현재 버전 읽기
CURRENT_VERSION=$(grep "^version = " "$VERSION_FILE" | sed "s/version = '\\(.*\\)'/\\1/")
if [ -z "$CURRENT_VERSION" ]; then
    echo "Error: Cannot read version from $VERSION_FILE"
    exit 1
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# 버전 bump
case "$BUMP_TYPE" in
    major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
    minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
    patch) PATCH=$((PATCH + 1)) ;;
    *) echo "Usage: $0 [patch|minor|major]"; exit 1 ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
TAG="v${NEW_VERSION}"

echo "[$PROJECT_NAME] $CURRENT_VERSION → $NEW_VERSION"

# 워킹 디렉토리 확인
if [ -n "$(git status --porcelain)" ]; then
    echo "Error: Working directory is not clean. Commit or stash changes first."
    exit 1
fi

# 버전 업데이트 (sed -i 옵션은 BSD/GNU 간 호환되지 않으므로 임시 파일 방식 사용)
TMP_FILE="${VERSION_FILE}.tmp"
sed "s/version = '${CURRENT_VERSION}'/version = '${NEW_VERSION}'/" "$VERSION_FILE" > "$TMP_FILE"
mv "$TMP_FILE" "$VERSION_FILE"

# 커밋 & 태그
git add "$VERSION_FILE"
git commit -m "release: ${PROJECT_NAME} ${TAG}"
git tag -a "$TAG" -m "Release ${TAG}"

echo ""
echo "Done! Created commit and tag: $TAG"
echo ""
echo "Next steps:"
echo "  git push origin main --tags    # push to remote"
echo "  gh release create $TAG --generate-notes    # create GitHub Release"
