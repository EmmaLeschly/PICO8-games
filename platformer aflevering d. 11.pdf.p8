pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
--unavngivet platformer
--by melanie og emma

function _init()
 state = "menu"
 
 player_init()
 world_init()
 enemy_init()
 color_init()
 npc_init()
 fireworks_init()
 items_init()
end

function _update()
 if state=="menu" then
  update_menu()
 elseif state=="game" then
  update_game()
 elseif state=="end" then
  update_end()
 end
end

function _draw()
 cls()
 if state=="menu" then
 	draw_menu()
 elseif state=="game" then
 	draw_game()
 elseif state=="end" then
  draw_end()
 end
end

--game
function update_game() 
 player:update()
 player:animate()
 npc:update()
 world_update()
 enemy_update()
 fireworks_update()
 items_update()
end

function draw_game()
 cls(1)
 fireworks_draw()
 world_draw()
 player:draw()
 npc:draw()
 enemy_draw()
 items_draw()
 --print(player.x,player.x,player.y-60,7)
 --print(player.y,player.x,player.y-50,7)
 --print(player.hit,player.x,player.y-40,7)
end
-->8
--player

function player_init()
 player={
	 sp=0, --player sprite
	 x=59,
	 y=59,
	 w=16,
	 h=8,
	 flp=false,
	 dx=0,
	 dy=0,
	 max_dx=2,
	 max_dy=3,
	 acc=0.5,
	 boost=4,
	 anim=0, --animation speed
	 running = false,
	 jumping = false,
	 falling = false,
	 sliding = false,
	 landed = false,
	 gravity = 0.3,
	 hit = false,
	 timer = 0,
	 attack = false,
	 life = 3, -- n of lives
	 lives={s=26,x=85,animtime=0,animwait=0.15},
	 animate = function(self)
		if self.jumping then
			self.sp=12
		 elseif self.falling then
		  self.sp=14
		 elseif self.sliding then
		  self.sp=16
		 elseif self.running then
			if time()-self.anim>.1 then
		   		self.anim=time()
		   		self.sp+=2
				if self.sp>10 then
		    		self.sp=4
		   		end
		  	end
		 	else --player idle
		  	if time()-self.anim>.3 then
		   		self.anim=time()
		   		self.sp+=2
		        if self.sp>2 then
			    	self.sp=0
	            end
	        end
	    end
	 end,
	 update = function(self)
	 
	  --slime pit
	  local friction = .85
		 if collide_map(self,4,2) then
		  friction=.35
		 else
		  friction=.85
		 end
		 
		 --spike pit
		 if collide_map(self,4,4) 
		 and not self.hit then
		  self.hit=true
		 end
		 
		 --hit
		 if self.hit then
		  self.timer += .5
		  if self.timer == 20 then
		   self.life-=1
		   self.sp=18
		   self.timer = 0
		   sfx(3)
		   self.hit=false
		  end
		 end		 	
		
		 --physics
		 self.dy+=self.gravity
		 self.dx*=friction
		 
		 --controls
		 if btn(⬅️) then
		  self.dx-=self.acc
		  self.running=true
		  self.flp=true
		 end
		 if btn(➡️) then
		  self.dx+=self.acc
		  self.running=true
		  self.flp=false
		 end
		 if btnp(🅾️) then
		  self.attack=true
		 end
		 
		 --slide
		 if self.running
		 and not btn(⬅️)
		 and not btn(➡️)
		 and not self.falling
		 and not self.jumping then
		  self.running=false
		  if not self.sliding then
		   sfx(1)
		  end
		  self.sliding=true
		 end
		 
		 --jump
		 if btnp(❎)
		 and self.landed then
		  self.dy-=self.boost
		  --sfx(2)
		  self.landed=false
		 end
		 
		 --collission with enemy
		 if collide_map(self,1,5) then
		  self.hit=true
   end
   if collide_map(self,2,5) then
		  self.hit=true
   end
   if collide_map(self,3,5) then
		  self.hit=true
   end
   if collide_map(self,4,5) then
		  self.hit=true
   end
		 
		 --check collision up and down
		 if self.dy>0 then
		  self.falling=true
		  self.landed=false
		  self.jumping=false
		
		  self.dy=limit_speed(self.dy,self.max_dy)
		
		 if collide_map(self,4,0) then
		  self.landed=true
		  if not self.impact then  
		   self.impact=true
		   sfx(0)
		  end
		  self.falling=false
		  self.dy=0
		  self.y-=((self.y+self.h+1)%8)-1
		 end
		 elseif self.dy<0 then
		  self.jumping=true
		  self.impact=false
		  if collide_map(self,3,1) then
		   self.dy=0
		  end
		 end
		 
		 --check collision left and right
		 if self.dx<0 then
		
		  self.dx=limit_speed(self.dx,self.max_dx)
		
		 if collide_map(self,1,1) then
		  self.dx=0
		 end
		 elseif self.dx>0 then
		
		  self.dx=limit_speed(self.dx,self.max_dx)
		
		  if collide_map(self,2,1) then
		   self.dx=0
		  end
		 end
		 
		 --stop sliding
		 if self.sliding then
		  if abs(self.dx)<.2
		  or self.running then
		   self.dx=0
		   self.sliding=false
		  end
		 end
		
		 self.x+=self.dx
		 self.y+=self.dy
		 
		 --limit player to map
		 if self.x<map_start then
		  self.x=map_start
		 end
		 if self.x>map_end-self.w then
		  self.x=map_end-self.w
		 end
		 		 
		 --lives
		 if time() - self.lives.animtime > self.lives.animwait then
		  self.lives.s+=1
		  self.lives.animtime=time()
	  end	
	  if self.lives.s > 31 then
			 self.lives.s=26
	  end
		 
		 --player die
		 if self.y>250 or self.life==0 then
		  if self.x < 180 then
		   self.x=60
		   self.y=59
		   self.life=3
		  elseif self.x > 180 and self.x < 590 then
		   self.x=316
		   self.y=96
		   self.life=3
		  elseif self.x > 590 then
		   self.x =590
		   self.y=96
		   self.life=3
		  end
		 end
		 end,
		 draw = function(self)
		  spr(self.sp,self.x,self.y+3,2,1,self.flp)
	 
	   --draw inventory
	   rectfill(cam_x,cam_y,cam_x+27,cam_y+11,5)
	   rect(cam_x,cam_y,cam_x+27,cam_y+11,12)
	   spr(160,cam_x+15,cam_y+2)
	   print(abs(#items-6).."X",cam_x+5,cam_y+3,12)
	   
	   --draw lives
	   rectfill(cam_x+85,cam_y,cam_x+130,cam_y+11,5)
    rect(cam_x+85,cam_y,cam_x+127,cam_y+11,12)
    for i=1,self.life do
     self.lives.x=self.x+(27+i*10)
     if self.lives.x<84+(i*10) then
      self.lives.x=84+(i*10)
     end
     if self.lives.x>976-(i*-10) then
      self.lives.x=976-(i*-10)
     end
     self.lives.y = player.y-70
		   spr(self.lives.s,self.lives.x,cam_y+3)
	   end
   end
  }
 return player
end		

function limit_speed(num,maximum)
	return mid(-maximum,num,maximum)
end  

function collide_map(obj,aim,flag)
 --obj = table needs x,y,w,h
 --aim = left,right,up,down

 local x=obj.x  local y=obj.y
 local w=obj.w  local h=obj.h

 local x1=0	 local y1=0
 local x2=0  local y2=0

 --left
 if aim==1 then
  x1=x-1  y1=y
  x2=x  y2=y+h-4

 --right
 elseif aim==2 then
  x1=x+w  y1=y
  x2=x+w  y2=y+h-4

 --up
 elseif aim==3 then
  x1=x+2    y1=y+3
  x2=x+w-3  y2=y
 
 --down
 elseif aim==4 then
  x1=x+2    y1=y+h
  x2=x+w-3  y2=y+h
 end

 --pixels to tiles
 x1/=8    y1/=8
 x2/=8    y2/=8

 if fget(mget(x1,y1), flag)
 or fget(mget(x1,y2), flag)
 or fget(mget(x2,y1), flag)
 or fget(mget(x2,y2), flag) then
  return true
 else
  return false
 end
end
 
-->8
--world

function world_init()
 --camera
 cam_x = 0
 cam_y = 0
	
	--map
	map_start = 0
	map_end = 1024
	
 --clouds
 clouds={}
 cloud_interval=8
 
 for i=1, 100 do
  cloud={
        sprite=128,
        x=cam_x+i*(rnd(10)+60),
        y=flr(rnd(70)-20)
        }
  add(clouds,cloud)
 end
 
 --butterfly
 butterfly={{s=230,x=950,y=35,animtime=0,animwait=.05,d=8,o=50},
       {s=230,x=980,y=20,animtime=0,animwait=.05,d=8,o=17},
       {s=230,x=965,y=35,animtime=0,animwait=.02,d=10,o=33}
      }
 
end

function color_init()
 poke(0x5f2e,1)

 pal(14,128,1)
 pal(12,133,1)
 pal(2,132,1)
 pal(8,3,1)
 pal(3,131,1)
 pal(15,12,1)
end

function world_update()
 --simple camera
 cam_x=player.x-64+(player.w/2)
 cam_y=player.y-85+(player.h/2)
 if cam_y>120 then
  cam_y=cam_y
 end
 if cam_x<map_start then
    cam_x=map_start
 end
 if cam_x>map_end-128 then
    cam_x=map_end-128
 end
 camera(cam_x,cam_y)
 
 --clouds
 for cloud in all(clouds) do
 	cloud.x-=.5
 end
 
 --butterfly
	for b in all(butterfly) do
	 --butterfly movement
	 b.d+=1
	 v=(b.d%360)/360
	 b.y=-abs(sin(v*5))*7+b.o
	 
	 --butterfly animation
	 if time() - b.animtime > b.animwait then
		 b.s+=1
		 b.animtime=time()
	 end	
	 if b.s > 237 then
			b.s=230
	 end
	end
end

function world_draw()
 --draw moon
 circfill(cam_x+20,15,13,7)
 circfill(cam_x+23,15,11,1)

 --draw clouds
 for cloud in all(clouds) do
 	spr(cloud.sprite,cloud.x,cloud.y,4,2)
 end
 
 --draw butterfly
 for b in all(butterfly) do
	 spr(b.s,b.x,b.y)
 end

 --fence
 for i=0,850,128 do
  map(112,16,i,0,16,8)
 end
 for i=0,850,128 do
  map(112,24,i,64,16,8)
  map(112,24,i,128,16,8)
  map(112,24,i,192,16,8)
  map(112,24,i,256,16,8)
 end

	--camera
	map(0,0)
end
-->8
--enemies

function enemy_init()

 --enemy = {x=120,sp=32}

 enemies = {}
 
 --level 1
 if player.x < 290 then
  add_new_enemy (32,5,30,14,16,0,0)
  add_new_enemy (32,15,90,14,16,0,0)
  add_new_enemy (32,114,20,14,16,0,0)
  add_new_enemy (32,150,111,14,16,0,0)
  add_new_enemy (32,122,112,14,16,0,0)
 end
 
end

function enemy_update()
 
 for e in all(enemies) do
  e:update()
  e:anim()
 end
 
end

function enemy_draw()
 for e in all(enemies) do
  e:draw()
 end
end

function add_new_enemy(_sp,_x,_y,_w,_h,_dx,_dy)

 add(enemies,
    {sp=_sp,
     x=_x,
     y=_y,
     w=_w,
     h=_h,
     dx=_dx,
     dy=_dy,
     anim_time=0,
     move=false,
     jumping=false,
     landed=false,
     anim=function(self)
      if time()-self.anim_time>.15 then
							self.anim_time=time()
							self.sp+=2
							if self.sp>40 then
								self.sp=32
							end
						end
					end, 
     update = function(self)
      --getting hit by player

      --enemy/player collision
      for e in all(enemies) do
       if e.y+e.h>=player.y
					  and e.y<=player.y+player.h
					  and e.x+e.w>=player.x
							and e.x<=player.x+player.w then
							 player.hit=true
							end
						end
		                      
		    --right
		    if player.x - self.x > 0 
			   and not collide_map(self,2,1)
			   and not collide_map(self,2,3) then
			    self.dx = 0.6
			    self.x += self.dx
			   else
			    self.dx=0
			   end
			   
			   --left
			   if player.x - self.x < 0 
			   and not collide_map(self,1,1)
			   and not collide_map(self,1,3) then
			    self.dx = 0.6
			    self.x -= self.dx
			   else 
			    self.dx=0
			   end
		    
		    --move y direction             		                      
		    self.y += self.dy
		    self.dy += 0.3
      
      --collision up and down
      if self.dy>0 then
					  self.landed=false
					  self.jumping=false
				
						 if collide_map(self,4,0) then
						  self.landed=true 
						  self.dy=0
						  --self.y-=((self.y+self.h+1)%8)-1
						 end
						elseif self.dy<0 then
						 self.jumping=true
						 if collide_map(self,3,1) then
						   self.dy=0
						 end
						end
      
      --jump
      if collide_map(self,2,1)
					 and self.landed then
					  self.dy-=4
					  self.landed=false
					 end 
					 if collide_map(self,1,1) 
					 and self.landed then
					  self.dy-=4
					  self.landed=false
					 end 
          
     end,
     draw = function(self)
       spr(self.sp,self.x,self.y+2,2,2)
     end,
    })
   return enemies
end

function enemy_attack_init()
 
 enemy_attack={}
  
end

function enemy_attack_update()

 if enemy.y-player.y<10 
 or player.y-enemy.y>10 then
  --shoot left
  while enemy.x-player.x>0 do
   add_new_attack(25,enemy.x+4,enemy.y+4,-1)
  end
  --shoot right
  while enemy.x-player.x<0 do
   add_new_attack(25,enemy.x+4,enemy.y+4,1)
  end
 end
 
 for a in all(enemy_attack) do
  a:update()
 end
end

function enemy_attack_draw()
 for a in all(enemy_attack) do
  a:draw()
 end
end

function add_new_attack
(_s,_x,_y,_vx)
   
 add(enemy_attack,
  {s=_s,
   x=_x,
   y=_y,
   vx=_vx,
   update = function(self)
    self.x+=self.vx
   
    if self.y+6>=player.y
		  and self.y<=player.y+player.h
		  and self.x+6>=player.x
				and self.x<=player.x+player.w then
				 player.hit=true
				 del(attack,self)
			 end
			end,
   draw = function(self)
    spr(self.s,self.x,self.y)
   end 
  })
 return attack
end
-->8
--npcs and items

function npc_init()
 npc={
  sp=42,
  x=264,
  y=93,
  anim_time=0,
  anim_wait=.2,
  update = function(self)
   if time() - self.anim_time > self.anim_wait then
    self.sp+=2
    self.anim_time=time()
    
    if self.sp > 44 then
     self.sp=42
    end
   end  
  end,
  draw = function(self)
   
   --red panda wall
   spr(self.sp,self.x,self.y,2,2)
   if player.x > 217 and player.x < 300 then
    if count(enemies) > 0 then
     spr(83,288,96,3,2)
     if player.x > 270 then
      player.x =270
     end
	    rectfill(cam_x+10,cam_y+105,cam_x+118,cam_y+122,10)
	    rect(cam_x+10,cam_y+105,cam_x+118,cam_y+122,9)
	    print("PLEASE KILL ALL ROBOTS TO",cam_x+13,cam_y+107,0)
	    print("PASS THROUGH!",cam_x+13,cam_y+115,0) 
    else 
     checkpoint_x=242
     checkpoint_y=96
     rectfill(cam_x+10,cam_y+105,cam_x+118,cam_y+122,10)
     rect(cam_x+10,cam_y+105,cam_x+118,cam_y+122,9)
     print("THANK YOU FOR YOUR HELP",cam_x+13,cam_y+107,0)
     print("YOU CAN NOW PASS THROUGH♥",cam_x+13,cam_y+115,0) 
    end
   end
   
   --robot wall
   spr(46,582,90,2,2)
   if player.x > 520
   and player.x < 620 then
    if not robot_open then
     spr(80,600,96,3,2)
     rectfill(cam_x+10,cam_y+105,cam_x+118,cam_y+122,8)
     rect(cam_x+10,cam_y+105,cam_x+118,cam_y+122,3)
     print("PLEASE FIND ALL MY SPARE",cam_x+13,cam_y+107,14)
     print("PARTS TO PASS THROUGH!",cam_x+13,cam_y+115,14) 
     if player.x > 582 then
      player.x = 582
     end
    elseif robot_open then
     player.checkpoint=580
     rectfill(cam_x+10,cam_y+105,cam_x+118,cam_y+122,10)
     rect(cam_x+10,cam_y+105,cam_x+118,cam_y+122,9)
     print("THANK YOU FOR YOUR HELP!",cam_x+13,cam_y+107,0)
     print("YOU MAY NOW PASS THROUGH.",cam_x+13,cam_y+115,0) 
   end
  end
 end
 }
 return npc
end

--items
function items_init()

 items={{s=160,x=506,y=78},
       {s=161,x=448,y=182},
       {s=162,x=438,y=6},
       {s=160,x=312,y=61},
       {s=161,x=457,y=115},
       {s=162,x=496,y=31}
  }
 
end

function items_update()
 for item in all(items) do
  
  --collisiion 
  if item.y>=player.y
  and item.y<=player.y+player.h
  and item.x+4>=player.x
		and item.x<=player.x+player.w then
		 del(items,item)
	 end
 
  if #items==0 then
   robot_open=true
  else
   robot_open=false
  end
 end
end

function items_draw()
 for item in all(items) do
  spr(item.s,item.x,item.y)
 end
end


-->8
--effects

-- fireworks -- 

function fireworks_init()
 particles = {}
end

function fireworks_update()
 while count(particles)<50 do
  add_new_particle
  (985,35,rnd(4)-2,rnd(4)-2,20,rnd(2),8)
  add_new_particle
  (960,20,rnd(4)-2,rnd(4)-2,20,rnd(2),10)
  add_new_particle
  (925,40,rnd(4)-2,rnd(4)-2,20,rnd(2),15)
 
 end
 
 for p in all(particles) do
  p:update()
 end
end
 
function fireworks_draw()
 for p in all(particles) do
  p:draw()
 end
end

function add_new_particle
(_x,_y,_vx,_vy,_life,_r,_c)

 add(particles,
    {x=_x,
     y=_y,
     vx=_vx,
     vy=_vy,
     life=_life,
     r=_r,
     c=_c,
     update = function(self)

      self.x+=self.vx
      self.y+=self.vy

      self.life-=1

      if self.life<0 then
       del(particles,self)
      end
      
       end,
     draw = function(self)
      circfill(self.x,self.y,self.r,self.c)
     end
    })
end

-->8
--menu/game over

--menu

fence_x=0
fence_spd=.7

cami=0
shadows={[0]=1,1,3,1,1,0,2,false,false,8}

function update_menu()
 if btnp(❎) then
  state="game"
 end
 
 --clouds
 for cloud in all(clouds) do
 	cloud.x-=0.5
 end

 fence_x-=fence_spd
	if fence_x<-127 then fence_x=0 end
end

function draw_menu()
 cls(1)
 
 --clouds
 for cloud in all(clouds) do
 	spr(cloud.sprite,cloud.x,cloud.y,4,2)
 end
 
 --fence
 map(112,16,fence_x,0,16,16)
 map(112,16,fence_x+128,0,16,16)
 
 --title cards
 map(16,32,0,0,16,16)
 
 print("press ❎ to start",31,94,2)
 print("press ❎ to start",32,94,4)
end

--game end

function update_end()
 
end

function draw_end()
 cls(15)

 map(32,32,0,0,16,16)
end
__gfx__
00000000000040200000000000000402000000000000040200000000000004040000000000000402000000000000040200000000000040200000000000004020
00000000000049900000000000004990000000000000499000000000000049900000000000004990000000000000499000000000000049900000000000004990
9000099aa99491950000099aa99491950000099aa99491950000099aa99491959990099aa99491950000099aa99491959000099aa99491959000099aa9949195
990999449a999977009999449a999977999999449a999977000999449a999977777999449a999977000999449a999977990999449a999977990999449a999977
79977442999997009977744299999700777774429999970099977442999997000007744299999700999774429999970079977442999997047997744299999700
07704420007747009770442000774700000044200077470077700420007747000000042000774700777004200077470007704420007444400770442000774700
00004090000040900000409000004090000040900000409000000940000944000000094400094400000009400009440000044000000440000000409000004090
00000409000004090000040900000409000400090004000900009040000094000000900040900040000090400000940000040000000000000000040900000409
000000000000000000000000000004020000000000000402000000000000000000000000bbbbbbb00aa0aa900a9a90000a9000000a9000000a9a90000aa9aa90
00000000000004020799000000004990900000000000499000000000000000000000000000000000a7aaaaa9aa7aa900a7a90000a7a90000aa7aa900a7aaaaa9
00000000000049900077999aa99498957999999aa994919500000000000000000000000000000000a7aaaaa9aa7aa900a7a90000a7a90000aa7aa900a7aaaaa9
0000099aa9949195000079449a999977077779449a999977000000000000000000000000000000000a7aaa900a7a9000a7a90000a7a900000a7a90000a7aaa90
009999449a999977000004429999970900000442999997000000000000000000000000000000000000aaa9000aaa90000a9000000a9000000aaa900000aaa900
09777442999997000000442000774794000044200074444400000000000000000000000000000000000a900000a900000a9000000a90000000a90000000a9000
09704420007747900004090000000440000440000004400000000000000000000000000000000000000000000000000000000000000000000000000000000000
09970444400044990000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000007d000000000000000000000000000000000000000000000000000000000000007d00000000000000000000000000000000000000000000000000000000
70000676d000060000000000000000000000000000000000000000000000000070000676d0000600000020000000000000002000000000000ddddddddddd5550
6764677dd42d65000000007d0000000000000000000000000000007d000000006764677dd42d6500000942000000000000094200000000000d333333333d5550
0d74a77d9946d00070000676d0000600000000000000000070000676d00006000d74a77d9946d000007742000000000000774200000000000d388888888d5550
05499a999994c0006764677dd42d65000000007d000000006764677dd42d650005499a999994c000099794000000000009979400000099000d388888888d5dcc
04c8bc99c8bc20000d74a77d9946d00070000676d00006000d74a77d9946d00004c8bc99c8bc2000e212244000992000e2122440000922000d3a88888a8d5dcc
05433cccc334500005499a999994c0006764677dd42d650005499a999994c00005433cccc3345000762299400092990076229940000299900d388aaa888d5dcc
0c2499999942500004c8bc99c8bc20000d74a77d9946d00004c8bc99c8bc20000c24999999425000006699940009922000669994000092220d388888888d5550
00cc444222cd000005433cccc334500005499a999994c00005433cccc334500000cc444222cd0000000999994000299900099999400029990ddddddddddd5550
0001dcccc51000000c2499999942500004c8bc99c8bc20000c249999994250000001dcccc510000000799999940009220079999994000922000ccccccccc0000
0005c6d551c0000000cc444222cd000005433cccc334500000cc444222cd00000005c6d551c00000006999226944029900699922694402990000555555c00000
0001dcccc51000000001dcccc51000000c249999994250000001dcccc51000000001dcccc51000000006924699999990000692469999999000d55dddc55d0000
0005c6d551c000000005c6d551c0000000cc444222cd00000005c6d551c000000005c6d551c000000006929999999400000692999999940000005dddc5c00000
0001dcccc51000000001dcccc51000000001dcccc51000000001dcccc51000000001dcccc5100000000492499994400000049249999440000000555555c00000
0000c6d5510000000000c6d551c000000000c6d551c000000000c6d551c000000000c6d551000000000240249944200000024024994420000000050050000000
00000cccc000000000000cccc000000000000cccc000000000000cccc000000000000cccc00000000022022242220000002202224222000000000d00d0000000
05ceeeeeeeeeeeeeeeeeeee002ceeeeeeeeeeeeeeeeeeee003ceeeeeeeeeeeeeeeeeeee005ceeeeeeeeeeeeeeeeeeee000000000000000000000000000000000
5cccccccccccccccccccccce2cccccccccccccccccccccce3cccccccccccccccccccccce5cc3c888cccc88cccc8cccce00000000000000000000000000000000
555555555555555552c2cccc22222222222222222225255c33333333333333333535555c55858a8b888bab885832cccc00000000005555000000000000000000
d555555555555555552c222c42222222222222222252555c83333333333333335355555cd5588ba8b8b8ba3b838c823c00000000005555000000000000000000
ddddddddddddddddddd222224444444444444444444dddd588888888888888888dddddd5d38bbabbbbbbbbbbbbb838220000000000c42c000000000000000000
6ddddddddddddddddd222222944444444444444444d4ddd5b88888888888888888ddddd56dd8bbbabbbbbbbbb8bb822200000000000420000000000000000000
76ddddddddddddddd2d22222a9444444444444444d4dddd56b888888888888888d8dddd5763d8bab8b388bb8bb38223200000000000420000000000000000000
67666666666666664444442c9a999999999999996966665cb6bbddddbbbbbbbbbb6b665c67666688b86668b88b84442c00000000000420000000000000000000
6d5ccccc55555555552222ce942ccccc2c22c222225555ceb83ccccc33333333335355ce6d5cc83855555583888222ce00c00c0000c42c000000000000000000
65d5cc5c555555555252242e9242cc2c2222c22225255d5eb383cccc3333333333353d5e65d5cc83555555583822242e0c0cc0c00c0420c00000000000000000
65555c555555555555252c2e92c22c22222222222252555eb3c33ccc335333333333535e65555c855555555533852c2ec0c00c0cc055550c0000000000000000
655555555555555555525c5e92c22222222222222225c5ceb3c33cc3333333333333353e655555555555555558525c5e0c0000c0005555000000000000000000
65555c555555555555555c5e92c222222222222222222cceb3c33cc3333333333333333e65555c355555555553555c5e0c0000c000c42c000000000000000000
d5555555555555555555255e4222222222222222222252ce83333c33333333533333533ed5555555555555555555255ec0c00c0cc004200c0000000000000000
d5555555555555555555552e42222222222222222222225e83333333333333333333335ed5555555555555555355552e0c0cc0c00c0420c00000000000000000
d5d555555555555555555d5e42422c22222222222222242e83833c33333333333333383ed5d555555555555555555d5e00c00c0000c42c000000000000000000
d5c55555555555555555555e422222222222222222222c2e833333333333333333333c3ed5c55555555555555555555e00c00c0000c42c000000000000000000
d5c55555555555555555555e422222222222222222222c2e833333333333333333333c3ed5c55555555555555555555e0c0cc0c00c0420c00000000000000000
d5555555555555555555555e42222222222222222222222e83333333333333333333333ed5555555555555555555555ec0c00c0cc055550c0000000000000000
d5555555555555555555555e42222222222222222222222e83333333333333333333333ed5555555555555555555555e0c0000c0005555000000000000000000
d5555555555555555555555e42222222222222222222222e83333333333333333333333ed5555555555555555555555e0c0000c000c42c000000000000000000
d5d555555555555555555d5e42422222222222222222242e83833333333333333333383ed5d555555555555555555d5ec0c00c0cc004200c0000000000000000
55555555555555555555555e22222222222222222222222e33333333333333333333333e55555555555555555555555e0c0cc0c00c0420c00000000000000000
ceeeeeeeeeeeeeeeeeeeeee5ceeeeeeeeeeeeeeeeeeeeee2ceeeeeeeeeeeeeeeeeeeeee3ceeeeeeeeeeeeeeeeeeeeee500c00c0000c42c000000000000000000
02ce7eeeeee7eeeeee7eeee000000000000000000000000003ce7eeeeee7eeeeee7eeee000000000000000000065cee000000000000000000000000000000000
2cc76ccccc76ccccc76cccce0000000000000000000000003cc76ccccc76ccccc76cccce000000000000000000665ce000000000000000000000000000000000
22266d22226d522226d5255c0000000000000000000000003336d533336d533336d6555c660000000000006600065c0000000000000000000000000000000000
4276d55226d555226d55525c000000000000000000000000837d555337d555337d5c555c56670000000076650007650000000000000000000000000000000000
446d55c44d555c44d555cdd5000000000000000000000000886555c886555c88655ccdd5c55667000076655c0000600000000000000000000000000000000000
94d5ccc44d5ccc44d5cccdd5000000000000000000000000b8d5ccc88d5ccc88d5cccdd5ecc5000000005cce0000700000000000000000000000000000000000
a9444444444444444d4dddd50000000000000000000000006b888888888888888d8dddd5ee000000000000ee0000000000000000000000000000000000000000
9a999999999999996966665c000000000000000000000000b6bbddddbbbbbbbbbb6b665c00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000067777760000006777760000000000000000000000000000000000000000000000000000000000000000000002222000cc0000cc000000cc0000cc0
00000000667777777760067777777700000000eded0000ed0000ed00ed000000000000ed00ed0000ed0000ed00ed000002c44c20c55c3c3553c33c3553c3cd5c
006776666777777777766777777777700000000000000000000000000000000000000000000000000000000000000000024554205555b5b55b5bb5b55b5b55d5
07777777767777777767777777777776000000ed0000ed00ed00ed00ed00000000000000ed0000ed00ed00ed00ed0000024554205d5585855858858558585555
07777777777777777777777777777777000000000000000000000000000000000000000000000000000000000000000002c44c20c5dc3c3553c33c3553c3c55c
67777777777777777777777777777777000000eded00ed00ed0000ed0000000000000000ed000000ed000000ed000000002222000cc0000cc000000cc0000cc0
67777777777777777777777777777776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67777777777777777777777777777776000000ed0000ed00ed00ed00ed0000000000000000000000000000000000000000c55c00000000000000000000000000
6677777777777777777777777777777600000000000000000000000000000000000000000000000000000000000000000c5d55c00000000cc000000cc0000000
66677777777777777777777777777766000000ed000000ed0000ed00ed000000000000ed00ed0000ed0000eded0000000cd555c000033335533cc33553333000
06667777777777776677777777776666000000000000000000000000000000000000000000000000000000000000000000c55c00003cbb85588558855888c300
006667777777776666666677776666000000d9f8d9f9d9f9d9f9d9f9d9f80000000000edeeed00ed00ed00ed00ed0000003b8300003b58855885588558858300
00066677777666666666666666666000000000000000000000000000000000000000000000000000000000000000000000c55c00003b8c355358853553c88300
000066666666666000066666666000000000ca00cacbcacbcacacacaca000000000000ededed0000ed0000ed00ed0000003b83000038830cc038830cc0388300
0000066666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000c5555c00c5555c00c5555c00c5555c0
700000000c00000000000bb0000000000000daf8dbf9ca00d9f9cafbdaf80000000000000000000000000000000000000c5555c00c5555c00c5555c00c5555c0
d70000000dcccc500000bb80000000000000000000000000000000000000000000000000000000000000000000000000003b83000038830cc038830cc0388300
0d7000005c6d551c00006800000000000000ca00c9cacac9cacaca00ca00000000acbccc0000000000000000acbccc0000c55c0000388c3553c88c3553c88300
00d600071dcccc516667d600000000000000000000000000000000000000000000000000000000000000000000000000003b830000c558855885588558855c00
000d60765c6d551c617d1600000000000000dbf8dbfbdbfbcbcbcb00dbf8000000adbdcddd00000000000000adbdcddd003b830000c558855885588558855c00
0000d6601dcccc516666660000000000000000000000000000000000000000000000000000000000000000000000000000c55c0000388c3553c88c3553c88300
000066000c6d5510dddddd0000000000840000000000000000000000000000640000fdacbccc6c0111009dbcccfd9d00003b83000038830cc038830cc0388300
0006600000cccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000c5555c00c5555c00c5555c00c5555c0
0000000000000000000000000000000085000000000000000000000000000065003c0c1c2c0c1c2c0c1c2c0c1c4c4c5c0c5555c00c5555c00c5555c00c5555c0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b83000038830cc038830cc0388300
0000000000000000000000000000000086142434445464748404142434445466003d0d1d2d0d1d2d0d1d2d0d1d2d4d5d00c55c00003b8c3553c88c3553c88300
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b8300003b58855885588558858300
0000000000000000000000000000000005152535455565758505152535455505003e0e1e2e0e1e2e0e1e2e0e1e2e4e5e00c55c00003c8885588558855888c300
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cd555c000033335533cc33553333000
0000000000000000000000000000000006162636465666768606162636465606003f0f1f2f0f1f2f0f1f2f0f1f2f4f5f0c5d55c00000000cc000000cc0000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c55c00000000000000000000000000
33333333333333333333333300000333333333300000000000000d000aa000000b0000000b003bb000000000000008b000000000000000000000000000083440
b6bb76bbbbbb76bbbb76bbbb00033b67bbbb76b33000000000006df0a7a00aa080b80b003003b033000000000008b88b88800000000000000000000088888440
bbb76bbbbb76bbb3b76bbbb3003bbbb67bb76bbbb300000000d00f7099983a7aba8b03b03a3b013b0000000008b88888b8b8b8000000000000888888bbb83440
33bbbb3b376bbb3b3bbb3b3e07bbb3bbb33bbb3bbb70000006df6d000833b999ba0a88b01a3a13b00000008bb88333338333800000000000bb8bbb88bb883440
ee333bb3e3bbb3bbbbb3b3ee067bbb3bbbbbb3bbb760000000f7ddf033baa3338b10308b1b1b3b000000000033b833383b800000000000003888888888332440
eeee333ee33b3b33bb3b33ee036b33b3bbbb3b33b630000003381f703ba7ab380b1b8b381b1b3b30000000000b83323388b8b800000000000383338338832494
eee555eeee3333ee3bb33eee03b3bbbbb33bbbbb3b30000038b8188883999b3003b333b333b333b000000008b833324333333000000000000033003300332494
e555555eee55555ee333e5ee0bbbb3333ee3333bbbb0000003b88b80083333800333333303333300000000033300324033300000000000000000000330032494
e56d6d55e5d6dd5eeeee55ee0b3b35eeeeeeee53b3b000000aa00000000000000000000000000900000000000008bbb000000000000000000aa1b81000032294
55d76655e5d66d5ee555ee660b3bee555ee555eeb3b00000a7a00aa0000000000aa000000000f9a0000000008888bb3bb800000000000000a7a38aa100032244
5d766de5ee5dd5eeeeeee5dd03b35eeeeeeeeee53b30000099983a7a0aa83300a7a83aa000900a7000088888bbb888338b8838000000000099988a7a00322294
5d6ddd5eeee55ee55555e55503b55e55555555e55b3000000833b999a7a3baa09993ba7a0f9a8900038bbb88bb8883338bbb8b8833300000138bb99900322294
e5d6d5e5eeeeee5776d55eee0b3ee55d6776d55ee3b0000013baa333999bba7a83bbb99900a7f9a0003888888833343888b8bbb8bb8300008bbaa38300324294
ee5e5e5ee55ee5d6665deee50bbeeed566665deeebb000003ba7ab383bbaa9993bbaab3808338a70000333833883234383888338833000003ba7ab3100324294
5ee55ee5776de5ddddde5e6603b6e5edddddde5e6b30000083999b3083a7ab3083a7ab3083b383880000003300333440300330003300000013999b3000324224
d5eeeeed666d5ee555e5eedd003eee5e5555e5eee300000008333380089993800899938008b3fb80000000033000244300330033300000000133331000322224
55e6d5ed66dd5eeeeeeeeee5000eeeeeeeeeeeeee500000009900aa0000000000000000000000000000000000000000000000000000000000000000000000000
5eed55e5dddd5eeeeeeee5ee000e5eeeeeeeeee5ee0000000990aaaa099000000900000000d0000000d0000000d0000009000000099000000008b00000000000
eeeeeee555555ee66d5eed5e0006dee5d66d5eed60000000099aaaaa0d90aaa00d900000099aaa00099aaa00099aaa000d9000000d90aaa0008b880000000000
eee5eeeeeeeeee66dd5ee55e00055ee5dddd5ee5500000000d9aaaa000aaaaa000aaa000099aaaa0099aaaa0099aaaa000aaa00000aaaaa00088b80000000000
ee5d6dd5edd5e5ddd55eeeee000eeee55dd55eeee000000000daaa00000aaaa0000aaa00099aaaa0999aaaa0099aaaa0000aaa00000aaaa0088aa88000000000
e5d66d65ed5ee555555e56de00ed65e555555e56de000000000d00000000da000000da00000aaa00990aaa00000aaa000000da000000da0003a7ab3000000000
e56dd6d5eeeeeeeeeeeeddd5005dddeeeeeeeeddd50000000000d0000000000000000000000aa000000aaa00000aa00000000000000000000399933000000000
5edddd5ee5555eeeeeeee55500655eeeeeeeeee55600000000000000000000000000000000000000000a00000000000000000000000000000133331000000000
55edd55e5d66dd555e5dee550055eed5e55e5dee5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55e555ee5ddddd555ed55eee000ee55de55ed55ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5eeeeeeee5555555eeeeeeee000eeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee5e5eddeeeeeeeeeeee56d5005d65eeeeeeee56d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5eeeee55eeed5e55ee5eddd5005ddde5eeee5eddd500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5edd5eeeed5ee5665eeee55500655eeee55eeee55600000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee555edde55ee5dd5ed5eeee005eee5de55ed5eee500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5ee55e55eeeeeee5ee55e55e00e55e55eeee55e55e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddmdmdmdmdmdmdmdmddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
mmmmmmmmmmmmmmmmmdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmmmmmmmmmmmmmmmmdddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmdmdmdmdmdmdmdmddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddmmmmmmmmmmmmmmmmdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
mdmdmdmdmdmdmdmddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmdmdmdmdmdmdmdmddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmmmmmmmmmmmmmmmmdddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddmdmdmdmdmdmdmdmddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
mmmmmmmmmmmmmmmmdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmmmmmmmmmmmmmmmmdddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmdmdmdmdmdmdmdmddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddmmmmmmmmmmmmmmmmddddddddddddddmdddddddddddddddddmdddmdddddddddmddddddddddddddmdddddddddddddddmdd
ddddddddddddddddddddddddddddddddddddddddddmddddddmddddddddddmdddddddddddddddddddddddddddddddmddddddddddddmdddddddddddddddddddddd
ddddddddddddddddmddmddddddddddddddddddddddddddddddddddddddddmdddddddddddddddddddmdmdddddddddmdddddddddddddddddddddddddddddddmddd
ddddddddddddddddddddddddddddmdddddddddddddmddddddddddddddddddddddddddddddddddddddddddmddddddmddddddddddddddddddddddddddddddddmdd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmddddddddddddddddddddddddddddmddddddmdddddddddddddddddddddddddddmddd
mdmddddddddddddddmddddddddddmddddddddddddddddmddddddddddddddddddddddddddddddddmddddddddmddddmddddddddddddddddddddddddddddddddddd
ddddddddddmdddddddddddddddddddddddddddddddddddmdddddddddddddddddddddddddddddddmdddmddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmdddddddddddddddddddddddddddddddddddddddmdddddddddddddd
ddmdddmdddddddddddmddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddmdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmdddddddddddmdddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddmdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddmddddddddmdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddmdddmdddmdddmdddmdddmdddmdddmdddmmdddmdddmdddmdddmdddmdddmdddmdddmdddddddddddddddddddddddmddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmdmddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmmmmmmmdmdddmmmmdddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddmdmdmdmdmdmdmdmddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
mmmmmmmmmmmmmmmmdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmmmmmmmmmmmmmmmmdddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmdmdmdmdmdmdmdmddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddmmmmmmmmmmmmmmmmdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
mdmdmdmdmdmdmdmddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmdmdmdmdmdmdmdmddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddmmddddmdddddmddmmddddddmddmddmdddddmddmdddddmddmmdddddddmdddddmdddddmdmdmddddmdmmdddddmdddddddddddddddddddddddd
mdmddmddddddmdmddmdmddmdddddddddddddddddddddddddddmdddddddddmdmdmddddmdddmdddddmddddddmdddddmmmddmdmddddddddmddmdmdddddddmdddddd
ddmddddddddddddddddddddddddddddmdmmddddddddmdddmddddddmdddddmmmddmmddddddddmddmdmddmdmddmddmmddmdddddmdddmddddddddddddddmdmddddd
dddmmdddddddddddmddddddddddmddddmdddddddmdmddddddmddddmddmddddddddddmddmddmddddddmddmdddddddmddmdddddddmddddmddddddddddddddddddd
ddddddmdddmmdddmdddddddmmdddmddddddddddmdmdddmmddmmdmddddddddddmdddmdddddddddddddddmdmdmmmdmdddddddmddddddddmddmdddddddddddmdddd
ddddddddddddddmddddmddddddddmdddddmddddmdddddmmdddddmdddmdmddmddddddddddddddmddddddddmddddddddddmdddddddddmmdmdddddddddmddmddddd
dddddddddmdddddddddddddddddmdmddddmdddddmddmddmdmdddddddddmdddddddddddddmddmdddddddddddddddddddddddddmdddddddddddddddmdmdmdddddm
dddmmdddmddmdmddddddddddddmdddddddddddmdmddddddddmmddmdmdddmddmdmmmdddddmddmddddddmddddddddddddddmdmmdmdddddddmdddmmddmdddmdddmd
dddmdmddddddddmdmddmmdmmdddddddmddmddmdmddmdddmdmddmdmddmddmdddddmddddddddddddddddddddddddddddddddddddddddddddddmmdmmmmdddddmmdd
dddddddddddddddddddddmddddddmdddddddddddddddddddddddddddddddddddmddddddddmddddmmddddddmdddddmmddddmmdddddmddmddddddddddddddddddd
dddddddddmdddddddddddmdmdmdmdddddmdddmmmdddddmddddddddmddddddmdddddddddmdddddmdddddmdddddddddddmdddmddmmmdddmdddmdmmdmmddddddddd
dmdddmdmdmdddmdddmdmdmdddddddddddddddddddddddddmmmmmddddddddmmdddmdddddddmdddddddddmddddddmdmdddddmddddmddddddmmddddddmddddddddd
ddmddddmdmdmdmddmdddddmdddmdmdddddddddmddddddddddmdddddmmddddddddmdddddddmdddmddmddddmddmdddmdddddmddddddmmmdddddmmddddddddddddm
dmdddddmddddddmddddddddmddddddddddddmddmdddddddddddddmdmddddddddddmddddmddddmddmddddmmdddmddddddddddmdddddmdmddddmmmmddddddddddd
ddmddddddddddddmdmmddmddddddddddmdddmmmddddddddddmddddddmddmddddmmmddddddddddmdmdddddmmddddddmdmddddddmddmdddddddmddddmdddddmdmd
mddmmdddddmddmddddddddddddddddddddddmdddddddddmmddmdddddmdddmmdmddddddmddmddddddddddddddddddddddddmdddmdddddmdddddmdddmmdddddddd
dddddmddddddddmdmmddmddddddddddddddddddmddmdmdddddmddmmdddddddmdddmmdmddddddddddmddmddddddddddddmdmdddddddddmmddddddddmddddddddd
dddddmddddmddddmdddddddddddmddmdmdmdmddddmdmddddmddddmddddddmdddddddddddddddddmdddddmdmdddddddddddmdmdddddddddmddddddddmdddddmdd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__gff__
0000000000000000000000000000000000000000000000000000000000000000202020202020202020200000000040402020202020202020202000000000404003030303030303030307070700000800030303030303030303030303000000000303030303030303030303030000000013131300000013131313131300000000
0000000000000000000000000000000000000000000000000000000000000000802000200000000000000000000000002020000000000000000000000000000003030303030300000000000000000000030300030303000000000000000000000300000303030000000000000000000000000003030300000000000000000000
__map__
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007a434445000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000043444445000000000000000000000000000000000000464748000000000000000000007a636465000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000063646465000000000000000000000000000000000000565758000000000000000000007a505152000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000004e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009d666768000000004041427900007a606162000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000434445000000000000000000000000000000000000000000000000000000000000404141420000000000000000000046474748000000000000000000ac535455000000405051527900007a565758000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000636465000000000000000000000000000000000000004344450000000000000000606161620000000000000000000066676768000000000000000000ac636465000000606161627900007a6667680000000000000000000000000000000000000000000000000000000000000000000000cb
00000000004e0000004e0000000000000000000000004e000000004e000000000000009d5354550000000000000000000000000000000000000000000000000000000000000000000000bd505152420000005657587900007a53545500000000000000000000000000000000000000000000000000000000cbcc00000000dadb
43444540424e0000004e404246484e0000000000000000464747480000000000000000ac63646500000000000000000000000000464747474748000000000000000000000000000000009d606161620000006667687900007a636465000000000000000000000000000000000000000000000000000000dadbdcdd000000cecf
6364656062000000000060626668000000000000000000666767680000000000000000ac5051524200000000000000000000000066676767676800000000000000000000000000000000ac565758000000435354557900007a505152790000000000000040420000000000000000000000000000000000cecfcbcc000000cbdb
0000000000000000004e0000000000004e000000004e00000000000000000000000000ac6061616200000000000000000000000000000000000000000000000000000000000000000000ac666768000000636464657900007a606162790000000000000060620000000000000046480000c6c9c8c9d7d9d8dfdbdc00c9c8c3c4
0000000000004647480000000000000000404141420000000000000000000000000000ac5657580000000000000000000000000000000000000000000043444444444500000000000000bd535455450000005051527900007a56575800000000000000000000000000000000006668c3c2c1c2c0c1c2c0c1c2c0c1c2c0c2e4d4
0000000000006667680000000000000000606161620000000000000000000000000000bd666768000000000046474747480000000000000000000000006364646464650000000000000000636464650000006161627900007a66676800000000464747480000000043450000000000d3d0d1d2d0d1d2d0d1d2d0d1d2d0d1d2d1
00000000004e4e000000004e000000000000000000000000000000000000000000000000000000000000000066676767680000000000000040414200000000000000000000000000000000000000000000465657587900007a53545545000000666767680000000063650000000000e3e0e1e2e0e1e2e0e1e2e0e1e2e0e1e2e1
404142434445000000000000434445000000000000000000000000000000404142464748404142434445000000000000000000000000000060616200000000000000000000004041424344454647484041666767687900007a636464650000000000007b0000000000000000000000f3f0f1f2e2f1f2f0f1f2f0f1f2f0f1f2f1
5051525354550000000000005354550000004e000000004e00004e000000505152565758505152535455000000000000000000000000000000000000000000000000000000005051525354555657585051525354557900007a50515200000000000000000000000000000000000000e3d0d1e2e1e1e2e0d1e2e0d1e2e0d1d1d1
606162636465707172767778636465464748000000000000464800434445606162666768606162636465000000000000000000000000000000000000000000000000000043446061626364656667686061626364657900007a60616200000000494a4a4b0000000000000000000000f3f0f1f2f0f1f2f0f1f2f0f1f2d2e2f2f1
565758505152535455565758505152565758000000000000666800535455565758535455565758505152420000000000000000000000000000000000000000000000000053545454555657585051525354555051520000000056575848000000696a6a6b00000000000000000000000000000000000000000000000000000000
6667686061626364656667686061626667684e00004e00000000006364656667686364656667686061616200000000000000000000000000000000000000000000000000636464646566676860616263646560616200000000666767680000000000007b00000000000000000000000000000000000000000000000000000000
5853545556575850515253545556575758550043450000000000005051525354555051525051525657580000000000000000000000000000000000004647474748000000000056575850515253545550520000000000000000535455000000000000000000000000000000000000000000000000000000000000000000000000
68636465666768606162636465666767686500636500000000000060616263646560616260616266676800000000000043444444444500000000000066676767680000000000666768606162636465606200000000000043456364650000000040414142000000000000000000000000004d0000000000000000004d00000000
51525051525354545455565758505151515200000000000000000056575850515256575856575853545500000000000063646464646500000000000000000000000000000000535455565758505152000000000000004354555657584800000060616162000000000000000000000000006d004d00000000004d006d6c4d0000
61626061626364646465666768696a61616276777870717276777866676860616266676866676863646545000000000000000000000000000000000000000000000000000000636465666768606162000000000040426364656667676800000000007b7b000000000000000000000000005d5c5d004d004d005d5c5d5c5d004d
54555657585657575758505152565758535556575853545556575853545556575853545553545550515162000000000000000000000000000000000000000000000000000000505152505152565758000000004051525657585051527b000000000000000000000000000000000000006c6d6c6d6c6d6c6d6c6d6c6d6c6d6c6d
646566676866676767686061626667686365666768636465666768636465666768636465636465606162000043450000000000000000004041420000000000000000000000006061626061626667680000000060616266676860616200000043450000000000000000000000000000005c5d5c5d5c5d5c5d5c5d5c5d5c5d5c5d
505152535455565758505152565758505152505152535455565758505152535455505152505152565758000063650000000000000000005051520000000000000000000000005657585657585354550000000000000000000000000000000053550000000000000000000000000000006c6d6c6d6c6d6c6d6c6d6c6d6c6d6c6d
606162636465666768606162666768606162606162636465666768606162636465606162606162666768000000000000004647480000006061620000000000000000000000006667686667686364654041424344454647484041424344454663650000000000000000000000000000005c5d5c5d5c5d5c5d5c5d5c5d5c5d5c5d
555657585051525354555657585354555657585657585051525354555658505152565758565758535455000000000000006667680000000000000000000000000000000000005354555354555051525051525354555657585051525354555657580000000000000000000000000000006c6d6c6d6c6d6c6d6c6d6c6d6c6d6c6d
656667686061626364656667686364656667686667686061626364656668606162666768666768636465000000000000000000000000000000000000000000000000000000006364656364656061626061626364656667686061626364656667680000000000000000000000000000005c5d5c5d5c5d5c5d5c5d5c5d5c5d5c5d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005354555657585051525354555657585051525354555657585051520000000000000000000000000000006c6d6c6d6c6d6c6d6c6d6c6d6c6d6c6d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006364656667686061626364656667686061626364656667686061620000000000000000000000000000005c5d5c5d5c5d5c5d5c5d5c5d5c5d5c5d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006c6d6c6d6c6d6c6d6c6d6c6d6c6d6c6d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c5d5c5d5c5d5c5d5c5d5c5d5c5d5c5d
__sfx__
00010000110001100010000000000f0000e0000e0000d000000000c0000b000000000900008000070000600005000040000400005000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000311004110051100711008110091100a1100b1100c1100e1100f1101011012110121101411015110161101500014000140000a0000600001000000000000000000000000000000000000000000000000
000100000f050100501105011050100500f0500e0500c0500a0500905007050050500405002050010500005000050000000000000000000000000000000000000000000000000000000000000000000000000000
00020000135001555017550195501d5501d55021550245502655027550285502555029550295502955029550275502155022550357003570000000215001f5000000000000000000000000000000000000000000
