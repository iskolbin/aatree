local AATree = require'AATree'
print(AATree{x = 2}:index('x'))
print(AATree.Nil)
print(AATree{x = 2, y = 4})
print(AATree{x = 2, y = 4, z = 5}:insert( 'k', 33 ):insert( 'w', 56 ))
print(AATree{x = 2, y = 4, z = 5}:insert( 'k', 33 ):insert( 'w', 56 ):remove('x'))
print(AATree{x = 4, y = 6, z = 2, a = 2}:remove( 'a' ):remove('y'):len())
print(table.unpack( AATree{x = 4, y = 6, a = 2}:keys()))
print(table.unpack( AATree{x = 4, y = 6, a = 2}:values()))
print(AATree{x = 4, y = 6, z = 2, a = 2}:filter( function(k,v) return k == 'x' end ))
print(AATree{x = 4, y = 6, z = 2, a = 2}:filter( function(k,v) return v > 2 end ))
print(AATree{x = 4, y = 6}:map( function(k,v) return v*v end ))

for k, v in pairs( AATree{x = 4, a = 2, z = 5, w = 4} ) do
	print( k, v )
end
