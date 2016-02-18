---------------------------------------------- Pathfinding
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require(folder.."logger")
local extratable = require(folder.."extratable")
local extramath = require(folder.."extramath")

local pathfinding = {dijkstra = {}}
---------------------------------------------- Caches
local tableInsert = table.insert
---------------------------------------------- Local functions
local function doesEdgeConnectNodes(edge, node1, node2)
	return edge.node1 == node1 and edge.node2 == node2 or edge.node1 == node2 and edge.node2 == node1
end

local function getNodeDistance(set, node1, node2)
	for index = 1, #set.edges do
		if doesEdgeConnectNodes(set.edges[index], node1, node2) then
			return set.edges[index].distance
		end
	end
	return -1
end

local function getTotalUnvisitedNodes(set)
	local total = 0
	for index = 1, #set.nodes do
		if not set.nodes[index].visited then
			total = total + 1
		end
	end
	return total
end

local function getAdjacentNodes(set, nodeName)
	local adjacentNodes = {}
	for index = 1, #set.edges do
		if set.edges[index].node1 == nodeName and not set.nodes[set.nodesIndex[set.edges[index].node2]].visited then
			adjacentNodes[#adjacentNodes + 1] = set.edges[index].node2
		elseif set.edges[index].node2 == nodeName and not set.nodes[set.nodesIndex[set.edges[index].node1]].visited then
			adjacentNodes[#adjacentNodes + 1] = set.edges[index].node1
		end
	end
	return adjacentNodes
end

local function visitClosestNode(set)
	local closestIndex = 1
	local distance = 0
	for index = 1, #set.nodes do
		if not set.nodes[index].visited and set.nodes[index].distance >= 0 then
			distance = set.nodes[index].distance
			closestIndex = index
			break
		end
	end
	for index = 1, #set.nodes do
		if set.nodes[index].distance < distance and not set.nodes[index].visited and set.nodes[index].distance >= 0 then
			distance = set.nodes[index].distance
			closestIndex = index
		end
	end
	set.nodes[closestIndex].visited = true
	return closestIndex
end

local function dijkstra(set)
	while getTotalUnvisitedNodes(set) > 0 do
		local closestNode = set.nodes[visitClosestNode(set)]
		
		local adjacentNodes = getAdjacentNodes(set, closestNode.name)
		for index = 1, #adjacentNodes do
			local distance = closestNode.distance + getNodeDistance(set, closestNode.name, adjacentNodes[index])
			if set.nodes[set.nodesIndex[adjacentNodes[index]]].distance >= 0 then
				if distance < set.nodes[set.nodesIndex[adjacentNodes[index]]].distance then
					set.nodes[set.nodesIndex[adjacentNodes[index]]].distance = distance
					set.nodes[set.nodesIndex[adjacentNodes[index]]].previous = closestNode.name
				end
			else
				set.nodes[set.nodesIndex[adjacentNodes[index]]].distance = distance
				set.nodes[set.nodesIndex[adjacentNodes[index]]].previous = closestNode.name
			end
		end
	end
end

local function getPathTo(set, targetNode)
	local path = {}
	local currentNode = targetNode
	while not (currentNode == set.startNode) do
		local tempNode = currentNode
		tableInsert(path, 1, tempNode)
		currentNode = set.nodes[set.nodesIndex[currentNode]].previous
	end
	tableInsert(path, 1, set.startNode)
	
	return path
end

---------------------------------------------- Module functions
function pathfinding.dijkstra.newSet()
	local set = {
		nodesIndex = {},
		nodes = {},
		edges = {},
		startNode = nil,
	}
	
	function set:newNode(name, displayObject)
		local newNode = {
			name = name,
			distance = -1,
			visited = false,
		}
		
		if displayObject and "table" == type(displayObject) then
			newNode.x, newNode.y = displayObject.x, displayObject.y
		end
		
		self.nodes[#self.nodes + 1] = newNode
		self.nodesIndex[name] = #self.nodes
		
		return newNode
	end
	
	function set:newEdge(node1Name, node2Name, distance)
		if not distance then
			local node1 = self.nodes[node1Name]
			local node2 = self.nodes[node2Name]
			if node1.x and node1.y and node2.x and node2.y then
				local distanceX = node1.x - node2.x
				local distanceY = node1.y - node2.y
				distance = (distanceX * distanceX + distanceY * distanceY) ^ 0.5
			end
		end
		
		local newEdge = {
			node1 = node1Name,
			node2 = node2Name,
			distance = distance,
		}
		self.edges[#self.edges + 1] = newEdge
		
		return newEdge
	end
	
	local myCopy
	
	function set:getPath(fromNodeName, toNodeName)
		myCopy = extratable.deepcopy(self)
		
		myCopy.nodes[myCopy.nodesIndex[fromNodeName]].distance = 0
		myCopy.startNode = fromNodeName
		
		dijkstra(myCopy)
		
		return getPathTo(myCopy, toNodeName)
	end
	
	return set
end

return pathfinding
