#!/bin/sh -e

mkdir -p ../dist

cd elm-src
elm make src/Test.elm --output=../dist/elm.js
cd -

tailwind -i elm-src/input.css -o dist/output.css

cp elm-src/index.html dist/
