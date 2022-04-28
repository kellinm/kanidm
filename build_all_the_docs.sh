#!/bin/bash

export CARGO_TARGET_DIR="${TMPDIR}cargo_target"
DOCS_DIR="/tmp/kanidm_docs"

echo "DOCS DIR: ${DOCS_DIR}"
echo "PWD: $(pwd)"

function build_version() {
    BOOK_VERSION=$1
    echo "Book version: ${BOOK_VERSION}"
    echo "<li><a href=\"/kanidm/${BOOK_VERSION}\">${BOOK_VERSION}</a></li>" >> "${DOCS_DIR}/index.html"
	git switch -c "${BOOK_VERSION}" || git switch "${BOOK_VERSION}"
	git pull origin "${BOOK_VERSION}"
	echo "Running mdbook"
    mdbook build kanidm_book
	mv ./kanidm_book/book/ "${DOCS_DIR}/${BOOK_VERSION}/"
    echo "Running cargo doc"
    cargo doc --no-deps
	mkdir -p "${DOCS_DIR}/${BOOK_VERSION}/rustdoc/"
	mv ./target/doc/* "${DOCS_DIR}/${BOOK_VERSION}/rustdoc/"
}

rm -rf "${DOCS_DIR}"
mkdir -p "${DOCS_DIR}"

cat > "${DOCS_DIR}/index.html" <<-'EOM'
<html>
<head>
<title>kanidm docs root</title>
</head>
<body>
<h1>Kanidm docs</h1>
<ul>
EOM


LATEST="$(git tag -l 'v*' --sort "-version:refname" | grep -v '1.1.0alpha' | head -n1)"
{
    echo "<li><strong><a href=\"/kanidm/master/\">Latest Dev Version</a></strong></li>"
    echo "<li><strong><a href=\"/kanidm/stable/\">Latest Stable Version (${LATEST})</a></strong></li>"
} >> "${DOCS_DIR}/index.html"

# build the current head
build_version master

# build all the other versions
for version in $(git tag -l 'v*' --sort "-version:refname" | grep -v '1.1.0alpha'); do
    echo "$version"
    build_version "${version}"
done

cat >> "${DOCS_DIR}/index.html" <<-'EOM'
</ul>
</body>
</html>
EOM
ls -la "${DOCS_DIR}"

mv "${DOCS_DIR}" ./docs/

# keep jekyll outta things
touch ./docs/.nojekyll

# link latest to stable
ln -s "${LATEST}" ./docs/stable

