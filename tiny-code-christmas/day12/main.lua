angle=0
t=0

function roty(p,angle)
	xt = p.x*math.cos(angle) - p.z*math.sin(angle)
	yt = p.y
	zt = p.x*math.sin(angle) + p.z*math.cos(angle)
	return {x=xt,y=yt,z=zt}
end

function TIC()
	cls()
	t=t + .01
	angle=angle + .01
	
	points = {}
	for y=-25,25,5 do
		r = (25+y)
		for a=0,2*math.pi,math.pi/16 do
			p = {x=r,y=y+math.sin(.1*t*y/10)*2,z=0}
			p = roty(p,a+t)
			table.insert(points,{x=p.x,y=p.y,z=p.z+300})
		end
	end

	table.sort(points,
	function (a,b) return a.z > b.z end)
	
	for i=1,#points do
		p = points[i]
		c = (p.z-300)/(50/8)+13
		c = c + i%.7
		pix(120+600*p.x/p.z, 68+600*p.y/p.z,
		c)
	end
end
-- <TILES>
-- 001:eccccccccc888888caaaaaaaca888888cacccccccacc0ccccacc0ccccacc0ccc
-- 002:ccccceee8888cceeaaaa0cee888a0ceeccca0ccc0cca0c0c0cca0c0c0cca0c0c
-- 003:eccccccccc888888caaaaaaaca888888cacccccccacccccccacc0ccccacc0ccc
-- 004:ccccceee8888cceeaaaa0cee888a0ceeccca0cccccca0c0c0cca0c0c0cca0c0c
-- 017:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 018:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- 019:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 020:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

