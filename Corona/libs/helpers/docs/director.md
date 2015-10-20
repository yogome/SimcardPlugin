# director.*
### Overview
---
Scene manager
### Functions
---

- director.*getPrevious()*
- director.*getScene(**sceneName**)*
- director.*newScene(**sceneName**)*
- director.*loadScene(**sceneName**, **options**, **params**)*
- director.*showScene(**sceneName**, **zIndex**, **options**, **parentScene**)*
- director.*gotoScene(**...**)*
- director.*showOverlay(**sceneName**, **options**)*
- director.*hideOverlay(**...**)*
- director.*hideScene(**sceneName**, **effectName**, **effectTime**, **parentScene**)*
- director.*setVariable(**variableName**, **value**)*
- director.*getVariable(**variableName**)*
- director.*removeHidden(**shouldRecycle**)*
- director.*purgeScene(**sceneName**, **shouldRecycle**)*
- director.*reloadScene(**sceneName**, **params**, **parentScene**)*
- director.*reloadLocalization(**sceneName**)*
- director.*newLocalizedImage(**sceneName**, **...**)*
- director.*newLocalizedEmbossedText(**sceneName**, **stringID**, **...**)*
- director.*newLocalizedText(**sceneName**, **stringID**, **...**)*
- director.*to(**sceneName**, **target**, **params**)*
- director.*from(**sceneName**, **target**, **params**)*
- director.*performWithDelay(**sceneName**, **delay**, **listener**, **iterations**)*
- director.*pauseScene(**sceneName**, **pause**)*
- director.*setActivityIndicator(**state**)*
- director.*setDebug(**doDebug**)*
---
Copyright (c) 2014-2015, Basilio Germán
All rights reserved.
