#!/bin/bash
src_path="$1"
dst_path="$2"
tag_path="${dst_path}/last_tag"
image_name=`basename "$src_path"`

echo "IMAGE NAME: $image_name"
cd $src_path
git tag -l | awk -F- '/^'${image_name}'-/ {print $2}' | sort -V | tail -n 1 > $tag_path;

echo "$tag_path: "
cat $tag_path
cd ..
cp $tag_path ${dst_path}/oldtag

echo "${dst_path}/oldtag:"
cat ${dst_path}/oldtag

#if no tag exists in the repository
[ -s "$tag_path" ] && echo "tags present" || ( echo "1.0" > $tag_path && exit 0)
val1_tag=`cat $tag_path |cut -d . -f1 `
val2_tag=`cat $tag_path |cut -d . -f2 `

let val2_tag++
echo "${val1_tag}.${val2_tag}" > $tag_path

echo "LAST TAG"
cat $tag_path

echo "OLD TAG"
cat ${dst_path}/oldtag

