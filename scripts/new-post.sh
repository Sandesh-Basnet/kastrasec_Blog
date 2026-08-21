#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: ./scripts/new-post.sh /path/to/notion-export.md"
  exit 1
fi

SRC_MD="$1"
SRC_DIR=$(dirname "$SRC_MD")

read -p "Post title: " TITLE
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-+|-+$//g')

POST_DIR="content/posts/$SLUG"
mkdir -p "$POST_DIR"

DATE=$(date +"%Y-%m-%dT%H:%M:%S%:z")

{
  echo "+++"
  echo "title = '$TITLE'"
  echo "date = '$DATE'"
  echo "draft = true"
  echo "tags = []"
  echo "+++"
  echo ""
  tail -n +2 "$SRC_MD"
} > "$POST_DIR/index.md"

# Find the sibling image folder Notion exported (matches the page title, no ID suffix)
IMG_DIR=$(find "$SRC_DIR" -maxdepth 1 -type d ! -path "$SRC_DIR" | head -n 1)

if [ -n "$IMG_DIR" ]; then
  IMG_FOLDER_NAME=$(basename "$IMG_DIR")
  ENCODED_FOLDER_NAME=$(echo "$IMG_FOLDER_NAME" | sed 's/ /%20/g')

  cp -r "$IMG_DIR"/* "$POST_DIR/"
  # Strip only the folder-name prefix from image links, leave %20 encoding intact for filenames
  sed -i "s|${ENCODED_FOLDER_NAME}/||g" "$POST_DIR/index.md"

  echo "Images copied into $POST_DIR"
else
  echo "No image folder found alongside the markdown file — skipping image copy."
fi

echo "Post created at $POST_DIR/index.md"
echo "Edit it, set draft = false when ready to publish."
