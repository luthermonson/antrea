#!/usr/bin/env bash

set -eo pipefail

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function reset_docs_master {
  printf "Resetting master docs directory\n"
  rm -rf *
}

function copy_root_markdowns_to_docs_master {
  # Copy README.md and other root markdown docs used in site documentation
  printf "Copying root markdown docs and fixing up relative links\n"

  ROOT_DOCS=( README CONTRIBUTING CODE_OF_CONDUCT CHANGELOG ROADMAP )

  for doc in "${ROOT_DOCS[@]}"; do
      cp -f ../../../${doc}.md .
      sed -i.bak 's/\([("]\)\(\/\)\{0,1\}docs\//\1/g' ${doc}.md
      rm -f ${doc}.md.bak
  done
}

function copy_markdowns_to_docs_master {
  printf "Copying markdown docs\n"

  cp -rf ../../../docs/* .

  printf "Using symbolic links for assets\n"

  rm -rf assets
  ln -s ../../../docs/assets assets
  rm -rf cookbooks/multus/assets
  ln -s ../../../../../docs/cookbooks/multus/assets cookbooks/multus/assets

  printf "Fixing up HTML img tags\n"

  # The Antrea markdown files sometimes use HTML tags for images in order to
  # set a fixed size for them. We still need jekyll / redcarpet to fix the links
  # for us, so we convert the HTML tag to standard markdown (and lose the size
  # information). This is quite brittle but it works for now.
  for doc in $(find "$PWD" -type f -name "*.md"); do
      sed -i.bak 's/<img src="\(.*\)" \(.*\) alt="\(.*\)">/![\3](\1)/' ${doc}
      rm -f ${doc}.bak
  done

  # For some reason (list formatting I think), jekyll / redcarpet does not like
  # the "toc" comments
  printf "Fixing up HTML comments\n"
  for doc in $(find "$PWD" -type f -name "*.md"); do
      sed -i.bak '/<!-- toc -->/d' ${doc}
      rm -f ${doc}.bak
      sed -i.bak '/<!-- \/toc -->/d' ${doc}
      rm -f ${doc}.bak
  done
}

pushd $THIS_DIR/docs/master

reset_docs_master
copy_markdowns_to_docs_master
# This is done after copy_markdowns_to_docs_master, to overwrite changes made by
# that function
copy_root_markdowns_to_docs_master
cp -f ../../api-reference.md .

popd

printf "complete\n"