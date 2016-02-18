-------------------------------------------- Extra table functions
local extratable = {}
-------------------------------------------- Caches
local tableRemove = table.remove 
local tableInsert = table.insert
local tableSort = table.sort
local tableGetn = table.getn
local mathRandom = math.random
-------------------------------------------- Functions
local function __genOrderedIndex( tab )
    local orderedIndex = {}
    for key in pairs(tab) do
        tableInsert( orderedIndex, key )
    end
    tableSort( orderedIndex )
    return orderedIndex
end

local function orderedNext(tab, state)
	local key
    if state == nil then
        tab.__orderedIndex = __genOrderedIndex( tab )
        key = tab.__orderedIndex[1]
        return key, tab[key]
    end
   
    key = nil
    for index = 1,tableGetn(tab.__orderedIndex) do
        if tab.__orderedIndex[index] == state then
            key = tab.__orderedIndex[index+1]
        end
    end

    if key then
        return key, tab[key]
    end

    tab.__orderedIndex = nil
    return
end

-------------------------------------------- Module functions
function extratable.orderedPairs(tab)
    return orderedNext, tab, nil
end

function extratable.deepcopy(originalTable)
	local typeOriginal = type(originalTable)
	local copyTable
	if typeOriginal == "table" and not (originalTable._proxy or originalTable._class) then
		copyTable = {}
		for key, value in next, originalTable, nil do
			copyTable[extratable.deepcopy(key)] = extratable.deepcopy(value)
		end
		setmetatable(copyTable, extratable.deepcopy(getmetatable(originalTable)))
	else
		copyTable = originalTable
	end
	return copyTable
end

function extratable.shuffle(tab)
	local numberElements, order, resultTable = #tab, {}, {}
	
	for index = 1,numberElements do
		order[index] = { rnd = mathRandom(), idx = index }
	end
	
	tableSort(order, function(a,b)
		return a.rnd < b.rnd 
	end)
	
	for index = 1,numberElements do
		resultTable[index] = tab[order[index].idx]
	end
	return resultTable
end

function extratable.compare(tab1, tab2, floatPrecision)
	floatPrecision = floatPrecision or 0.1
	local foundValues = 0
	local equalValues = 0
	
	for index1, value1 in pairs(tab1) do
		foundValues = foundValues + 1
		for index2, value2 in pairs(tab2) do
			if index2 == index1 then
				if "number" == type(value1) then
					local isFloat = value1 % 1 > 0
					
					if isFloat then
						local isFloatEqual = (value1 - floatPrecision) < value2 and value2 < (value1 + floatPrecision)
						equalValues = isFloatEqual and (equalValues + 1) or equalValues
					else
						equalValues = value1 == value2 and (equalValues + 1) or equalValues
					end
				else
					equalValues = value1 == value2 and (equalValues + 1) or equalValues
				end
			end
		end
	end
	return foundValues == equalValues
end

function extratable.sortDescByKey(tab, keyName)
	local function compare(a,b)
		return a[keyName] > b[keyName]
	end
	tableSort(tab, compare)
end

function extratable.sortAscByKey(tab, keyName)
	local function compare(a,b)
		return a[keyName] < b[keyName]
	end
	tableSort(tab, compare)
end

function extratable.isEmpty(tab)
	return next(tab) == nil
end

function extratable.add(t1, t2)
	t1 = t1 or {}
	for index = 1, #t2 do
		t1[#t1 + 1] = t2[index]
	end
	return t1
end

function extratable.merge(t1, t2)
	t1 = t1 or {}
	for key, value in pairs(t2) do
		if type(value) == "table" and type(t1[key] or false == "table") then
			t1[key] = extratable.merge(t1[key], t2[key])
		else
			t1[key] = value
		end
	end
	return t1
end

function extratable.containsValue(tab, value)
	for index = 1, #tab do
		if tab[index] == value then
			return true
		end
	end
	return false
end

function extratable.searchIndex(tab, item)
	if tab and "table" == type(tab) then
		for index = #tab, 1, -1 do
			if item == tab[index] then
				return index
			end
		end
	end
end

function extratable.removeItem(tab, item)
	if tab and "table" == type(tab) then
		for index = #tab, 1, -1 do
			if item == tab[index] then
				tableRemove(tab, index)
				return true
			end
		end
	end
	return false
end

function extratable.getRandom(t1, count)
	local function permute(tab, n, count)
		n = n or #tab
		for i = 1, count or n do
			local j = mathRandom(i, n)
			tab[i], tab[j] = tab[j], tab[i]
		end
		return tab
	end

	local meta = {
		__index = function (self, key)
			return key
		end
	}
	local function getInfiniteTable() return setmetatable({}, meta) end

	local randomIndices = {unpack(permute(getInfiniteTable(), #t1, count), 1, count)}
	
	local randomNewTable = {}
	for index = 1, #randomIndices do
		randomNewTable[index] = extratable.deepcopy(t1[randomIndices[index]])
	end
	return randomNewTable
end

function extratable.findTableWithKey(tab, key, value)
	if tab and #tab > 0 then
		for index = 1, #tab do
			if tab[index] and tab[index][key] then
				if tab[index][key] == value then
					return tab[index]
				end
			end
		end
	end
end

return extratable
