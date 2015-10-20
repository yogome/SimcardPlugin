# spine.*
### Overview
---
Spine helper. Wrapped around the original runtime files to facilitate spine object usage.
### Functions
---
- spine.*new(**fileName**, **options**)*: Creates a new spine object
  - **filename** *(string)*: A string specifying where the json file is at.
  - **options** *(table)*: A table with various options for the spine object. Possible options are:
    - **scale** *(number)*: The visual scale from 0 to 1, 0 being 0% and 1 being 100%.
    - **folder** *(string)*: An optional string that specifies where the skins are at. It is recommended that you do not use this option.
    - **debugSkeleton** *(boolean)*: An option to render skeleton bones.
    - **animationSpeed** *(number)*: A number used to specify the animation speed. Default is 1.
    - **defaultMix** *(number)*: A number between 0 and 1 used to mix or fade animations between each other. Default is 0.1.
    - **animationEvents** *(table)*: A table specifying the events on different animations. each animation should have its own key, with the following possible events inside as functions:
      - **onStart** *(function)*: You can read more about events on the spine documentation pages.
      - **onEnd** *(function)*:You can read more about events on the spine documentation pages.
      - **onComplete** *(function)*:You can read more about events on the spine documentation pages.
      - **onEvent** *(function)*:You can read more about events on the spine documentation pages.
- spine.*remove(**spineObject**)*: Function to remove spines. You can also use *display.remove* or remove the parent group without problems.

### Spine object
---
A spine object inherits all *display group* properties
---
Copyright (c) 2014-2015, Basilio Germán
All rights reserved.
