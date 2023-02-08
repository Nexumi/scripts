#!/bin/sh
for z in *.zip; do
	mkdir "${z%%.*}"
	mv "${z}" "${z%%.*}"
	cd "${z%%.*}"
	unzip -qq "${z}"
	rm "${z}"
	cd ..
done