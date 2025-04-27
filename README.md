## A module for foundry vtt for the draw steel system: https://github.com/MetaMorphic-Digital/draw-steel

This currently adds class and kit abilities to a set of compendiums, which you can then drag and drop onto your abilities

You may have to alter the ability values base on your echantments/wards etc.

Install into foundry by going to Add on modules > Install module (at the bottom of the screen) and pasting https://github.com/rmarone/draw-steel-abilities/releases/download/1.2.0/module.json and then clicking install, then activate the module in your game

Future potential feature:

Common abilities

Integrate (tighter) with forge steel export to create actors to be imported

Automate versioning and deployment

Add enchantments and wards

Dev guide:

requires ruby and npm

ruby forgetofoundry.rb  #Will take the forge core export, extract and transform into src/packs

npm run pack  #Will transform src/packs into database files in packs/

zip up the packs and the module.json file into a release
