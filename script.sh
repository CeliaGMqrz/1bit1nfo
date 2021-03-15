#!/bin/bash
git add *
git commit -am "modificaciones"
git push
hugo -D
cd public
cp -r * /home/celiagm/github/app_static/1bit1nfo/public /home/celiagm/github/app_static/sitio
cd /home/celiagm/github/app_static/sitio
git add *
git commit -m "commit automatico"
git pull
git push
