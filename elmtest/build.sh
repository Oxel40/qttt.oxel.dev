#!/bin/bash

elm make src/Test.elm --output=elm.js && tailwind -i input.css -o output.css

mkdir -p ../output/static/
cp index.html ../output/static/
cp output.css ../output/static/
cp elm.js ../output/static/
cp Caddyfile ../output/
