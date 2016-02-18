------------------------------------------- Pathfinding test
local path = ...
local folder = path:match("(.-)[^%.]+$")
local upFolder = string.sub(folder, 1, -2):match("(.-)[^%.]+$") 
local extratable = require( upFolder.."extratable" )
local pathfinding = require( upFolder.."pathfinding" )

local pathfindingTest = {}
------------------------------------------ Variables

------------------------------------------ Tests
function pathfindingTest.testDijkstra()	
	local bestPath = {"a", "c", "e", "f"}

	local set = pathfinding.dijkstra.newSet()
	set:newNode("a")
	set:newNode("b")
	set:newNode("c")
	set:newNode("d")
	set:newNode("e")
	set:newNode("f")
	set:newNode("g")

	set:newEdge("a", "c", 10)
	set:newEdge("a", "d", 19)
	set:newEdge("b", "c", 4)
	set:newEdge("c", "d", 4)
	set:newEdge("b", "f", 41)
	set:newEdge("c", "e", 20)
	set:newEdge("e", "f", 17)
	set:newEdge("d", "g", 30)
	set:newEdge("g", "f", 4)

	local path = set:getPath("a", "f")

	assert(extratable.compare(path, bestPath))
end

return pathfindingTest
