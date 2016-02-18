# magnets.*
### Overview
---
Drag and drop library, with magnet like snap feature. Consists of slots and cloners.
### Functions
---
- spine.*newSlot(**options**)*: Creates a new slot
  - **options** *(table)*: A table containing slot customization options
	- **radius** *(number)*: If specified, the slot will have a circle shape, the radius specifies the size of the area.
    - **width** *(number)*: Width of the slot
    - **height** *(number)*: Height of the slot
    - **isVisible** *(boolean)*: If set to true, the area will be outlined with a white stroke.

    - **capacity** *(number)*: The max items a slot can contain.
    - **offsetFunction** *(function)*: A function that can be used to arrange items in a slot
    - **prefill** *(table)*: A table that can contain information to prefill the slot
      - **cloneFunction** *(table)*:
      - **slots** *(table)*: A table containing at least 1 slot where objects generated from cloner can be inserted to. the slot itself will be automatically included here.
      - **canvasGroup** *(table)*: A canvas group, where all objects will float when dragging them.
      - **amount** *(table)*: The amount of items for the slot to be prefilled with.
      - **returnToPrevious** *(boolean)*: Defaults to *true*, items dragged outside slot will return to slot instead of dissapearing.

- spine.*newCloner(**cloneFunction**, **options**)*: Creates a new cloner.
  - **cloneFunction** *(function)*: The function that generates new slot items, item must be returned here.
  - **options** *(table)*: A table containing cloner customization options
    - **radius** *(number)*: If specified, the cloner will have a circle shape, the radius specifies the size of the area.
    - **width** *(number)*: Width of the cloner
    - **height** *(number)*: Height of the cloner
    - **isVisible** *(boolean)*: If set to true, the area will be outlined with a white stroke.
    - **canvasGroup** *(displayObject)*: A canvas group, where all objects will float when dragging them.
    - **slots** *(table)*: A table containing at least 1 slot where objects generated from cloner can be inserted to.

### Slot
---
A slot is a display group that represents an area, where items can be dragged and they will automatically be inserted as if the slot had a magnet.

### Cloner
---
A cloner is a display group that represents an area, that when touched, generates items using the cloneFunction specified, that can be dragged and inserted automatically into a slot.

### Example
---
The following is an example for **offsetFunction** and **cloneFunction**:
``` lua
local function offsetFunction(index)
	local offsetX = -50 + ((index - 1) % 2) * 100
	local offsetY = -50 + math.floor((index - 1) / 2) * 100
	
	return unpack({offsetX, offsetY})
end

local function cloneFunction()
	local circle = display.newCircle(0, 0, 50)
	circle:setFillColor(unpack(colors.random()))
	
	return circle
end
```
A *cloner* with a slot example:
``` lua
local slotRightOptions = {
		isVisible = true,
		width = 300,
		height = 300,
		capacity = 4,
		offsetFunction = offsetFunction,
	}
	
	local slotRight = magnets.newSlot(slotRightOptions)
	slotRight.x, slotRight.y = display.contentCenterX + 300, display.contentCenterY - 200
	magnetGroup:insert(slotRight)
	
	local clonerOptions = {
		width = 200,
		height = 200,
		isVisible = true,
		slots = {slotRight},
		canRemove = false,
	}
	
	local cloner = magnets.newCloner(cloneFunction, clonerOptions)
	cloner.x, cloner.y = display.contentCenterX, display.contentCenterY - 200
	magnetGroup:insert(cloner)
```
A *cloner*less *slot* system, with prefilled elements, which can be dragged from slot to slot and are not destroyed:
``` lua
local clonelessSlot1Options = {
		isVisible = true,
		width = 300,
		height = 300,
		capacity = 4,
		offsetFunction = offsetFunction,
	}
	
	local clonelessSlot1 = magnets.newSlot(clonelessSlot1Options)
	clonelessSlot1.x, clonelessSlot1.y = display.contentCenterX - 200, display.contentCenterY + 200
	magnetGroup:insert(clonelessSlot1)
	
	local clonelessSlot2Options = {
		isVisible = true,
		width = 300,
		height = 300,
		capacity = 4,
		offsetFunction = offsetFunction,
		prefill = {
			cloneFunction = cloneFunction,
			amount = 4,
			slots = {clonelessSlot1},
			canvasGroup = magnetGroup,
		}
	}
	
	local clonelessSlot2 = magnets.newSlot(clonelessSlot2Options)
	clonelessSlot2.x, clonelessSlot2.y = display.contentCenterX + 200, display.contentCenterY + 200
	magnetGroup:insert(clonelessSlot2)
```

---
Copyright (c) 2014-2015, Basilio Germán
All rights reserved.
