#!/bin/bash

elm make src/Test.elm --output=elm.js && tailwind -i input.css -o output.css
