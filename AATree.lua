local AATree = {}

local AATreeMt

local KEY, VALUE, LEFT, RIGHT, LEVEL = 1, 2, 3, 4, 5

local Nil = {false,false,false,false,0}

local function setmt( bst )
	return setmetatable( bst, AATreeMt )
end

local function skew( bst )
	if bst ~= Nil then
		local lbst = bst[LEFT]
		if lbst ~= Nil then
			local level = bst[LEVEL]
			local llevel = lbst[LEVEL]
			if level == llevel then
				return setmt{lbst[KEY], lbst[VALUE], lbst[LEFT], setmt{bst[KEY], bst[VALUE], lbst[RIGHT], bst[RIGHT], level}, level}
			end
		end
	end
	return bst
end

local function split( bst )
	if bst ~= Nil then
		local rbst = bst[RIGHT]
		if rbst ~= Nil then
			local rrbst = rbst[RIGHT]
			if rrbst ~= Nil then
				local level = bst[LEVEL]
				local rrlevel = rrbst[LEVEL]
				if level == rrlevel then
					return setmt{rbst[KEY], rbst[VALUE], setmt{bst[KEY], bst[VALUE], bst[LEFT], rbst[LEFT], level}, rrbst, level+1}
				end
			end
		end
	end
	return bst
end

local function insertrebalance( bst )
	return split( skew ( bst ))
end

local function min( a, b )
	return a > b and b or a
end

local function decrease( bst )
	local shouldbe = min( bst[LEFT][LEVEL], bst[RIGHT][LEVEL] + 1 )
	if shouldbe < bst[LEVEL] then
		return setmt{bst[KEY], bst[VALUE], bst[LEFT], bst[RIGHT], shouldbe}
	elseif shouldbe < bst[RIGHT][LEVEL] then
		return setmt{bst[KEY], bst[VALUE], bst[LEFT], setmt{bst[RIGHT][KEY], bst[RIGHT][VALUE], bst[RIGHT][LEFT], bst[RIGHT][RIGHT], shouldbe}, bst[LEVEL]}
	else
		return bst
	end
end

local function removerebalance( bst )
	local bst1 = skew( decrease( bst ))
	local bst2 = setmt{bst1[KEY], bst1[VALUE], bst1[LEFT], skew( bst1[RIGHT] ), bst1[LEVEL]}
	local bst3 = bst2
	local bst2r = bst2[RIGHT]
	if bst2r ~= Nil then
		local bst3rr = skew( bst2r[RIGHT] )
		local bst3r = setmt{bst2r[KEY], bst2r[VALUE], bst2r[LEFT], bst3rr, bst2r[LEVEL]}
		bst3 = setmt{bst2[KEY], bst2[VALUE], bst2[LEFT], bst3r, bst2[LEVEL]}
	end
	local bst4 = split( bst3 )
	return setmt{bst4[KEY], bst4[VALUE], bst4[LEFT], split( bst4[RIGHT] ), bst4[LEVEL]}
end

local function predecessor( bst )
	local bst_ = bst[LEFT]
	while bst_[RIGHT] ~= Nil do
		bst_ = bst_[RIGHT]
	end
	return bst_
end

local function successor( bst )
	local bst_ = bst[RIGHT]
	while bst_[LEFT] ~= Nil do
		bst_ = bst_[LEFT]
	end
	return bst_
end


function AATree:index( key )
	if self == Nil then
		return false
	elseif key == self[KEY] then
		return self[VALUE]
	elseif key < self[KEY] then
		return self[LEFT]:index( key )
	else
		return self[RIGHT]:index( key )
	end
end

function AATree:insert( key, value )
	if self == Nil then
		return setmt{key, value, Nil, Nil, 1}
	else
		local selfkey = self[KEY]
		if key == selfkey then
			return setmt{key, value, self[LEFT], self[RIGHT], self[LEVEL]}
		elseif key < selfkey then
			return insertrebalance( setmt{selfkey, self[VALUE], self[LEFT]:insert( key, value ), self[RIGHT], self[LEVEL]})
		else
			return insertrebalance( setmt{selfkey, self[VALUE], self[LEFT], self[RIGHT]:insert( key, value ), self[LEVEL]})
		end
	end
end

function AATree:remove( key )
	if self ~= Nil then
		local selfkey = self[KEY]
		if selfkey == key then
			if self[LEFT] == Nil and self[RIGHT] == Nil then
				return Nil
			elseif self[LEFT] == Nil then
				local succ = successor( self )
				return setmt{succ[KEY], succ[VALUE], Nil, self[RIGHT]:remove( succ[KEY] ), self[LEVEL]}
			else
				local pred = predecessor( self )
				return setmt{pred[KEY], pred[VALUE], self[LEFT]:remove( pred[KEY] ), self[RIGHT], self[LEVEL]}
			end
		elseif key < selfkey then
			return removerebalance( setmt{selfkey, self[VALUE], self[LEFT]:remove( key ), self[RIGHT], self[LEVEL]} )
		else
			return removerebalance( setmt{selfkey, self[VALUE], self[LEFT], self[RIGHT]:remove( key ), self[LEVEL]} )
		end
	else
		return self
	end
end

function AATree:len()
	if self ~= Nil then
		return 1 + self[LEFT]:len() + self[RIGHT]:len()
	else
		return 0
	end
end

function AATree:insertpairs( iterator, state, var1 )
	local result = self
	for k, v in iterator, state, var1 do
		result = result:insert( k, v )
	end
	return result
end

local function iteratepairs( state )
	if state ~= Nil then
		iteratepairs( state[LEFT] )
		coroutine.yield( state[KEY], state[VALUE] )
		iteratepairs( state[RIGHT] )
	end
end

function AATree:pairs()
	return coroutine.wrap( iteratepairs )(self)
end

function AATree:preorder( f, ... ) 
	if self ~= Nil then
		f( self[KEY], self[VALUE], ... )
		self[LEFT]:preorder( f, ... )
		self[RIGHT]:preorder( f, ... ) 
	end
	return ...
end

function AATree:inorder( f, ... ) 
	if self ~= Nil then
		self[LEFT]:inorder( f, ... )
		f( self[KEY], self[VALUE], ... )
		self[RIGHT]:inorder( f, ... ) 
	end 
	return ...
end

function AATree:postorder( f, ... ) 
	if self ~= Nil then
		self[LEFT]:postorder( f, ... )
		self[RIGHT]:postorder( f, ... ) 
		f( self[KEY], self[VALUE], ... )
	end
	return ...
end

function AATree:map( f ) 
	if self ~= Nil then
		return setmt{self[KEY], f( self[KEY], self[VALUE] ), self[LEFT]:map( f ), self[RIGHT]:map( f ), self[LEVEL]}
	else
		return Nil
	end
end

function AATree:filter( p )
	if self ~= Nil then
		if p( self[KEY], self[VALUE] ) then
			return setmt{self[KEY], self[VALUE], self[LEFT]:filter( p ), self[RIGHT]:filter( p ), self[LEVEL]}
		else
			return self:remove( self[KEY] ):filter( p )
		end
	else
		return Nil
	end
end

function AATree:reduce( f, acc ) 
	if self ~= Nil then
		return self[RIGHT]:reduce( f, self[LEFT]:reduce( f, f( self[KEY], self[VALUE], acc )))
	else 
		return acc 
	end
end

local function insertkey( key, _, acc )
	acc[#acc+1] = key
	return acc
end

local function insertvalue( _, value, acc )
	acc[#acc+1] = value
	return acc
end

function AATree:keys()
	return self:inorder( insertkey, {} )
end

function AATree:values()
	return self:inorder( insertvalue, {} )
end

local function collectstring( key, value, acc )
	table.insert( acc, ('  %s => %s'):format( tostring( key ), tostring( value )))
	return acc
end

function AATree:tostring()
	if self == Nil then
		return '{}'
	else
		local acc = self:inorder( collectstring, {'{'} )
		table.insert( acc, '}')
		return table.concat( acc, '\n' )
	end
end

AATreeMt = {
	__index = AATree,
	__len = AATree.len,
	__pairs = AATree.pairs,
	__tostring = AATree.tostring,
}

AATree.Nil = setmt( Nil )

return setmetatable( AATree, { 
	__call = function( _, t )
		return Nil:insertpairs( next, t )
	end
} )
