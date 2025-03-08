## A module for foundry vtt for the draw steel system: https://github.com/MetaMorphic-Digital/draw-steel

This currently adds class abilities to a set of compendiums, which you can then drag and drop onto your abilities

You may have to alter the ability values base on your kit/wards etc.

Kit abilities are currently missing

Future potential feature:

Add kit abilities

Integrate (tighter) with forge steel export to create actors to be imported

Automate versioning and deployment

Dev guide:

requires ruby and npm

ruby forgetofoundry.rb  #Will take the forge exports, extract and transform into src/packs

npm run pack  #Will transform src/packs into database files in packs/

zip up the packs and the module.json file into a release
