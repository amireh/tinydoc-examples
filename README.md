# tinydoc-examples

To compile these, you need to have tinydoc cloned from master.

I'll assume tinydoc is cloned at `../tinydoc`

Go into it and NPM install it, then make sure it and all its packages are 
compiled by running `./bin/prepublish-all`

Now you're ready to run tinydoc against the config files here. You do that by adjusting NODE_PATH to point to the local packages directory then choose the
config file you wish:

    NODE_PATH=../tinydoc/packages \
      ../tinydoc/cli/tinydoc \
      --config ./orientjs.tinydoc.conf.js

For ./d3, you need to `npm install` inside of it so you get its dependencies. 
It has only 1 README file, we scrape things under `d3/node_modules` to get the
beef.

For ./pibi, you need to have the gems installed (ruby/bundler) using the 
regular way.

**BONUS** I made you a helper script that does what is described above. To use 
it:

    ./compile.sh ./orientjs.tinydoc.conf.js