local Delaunay = require "src.delaunay"
local Point    = Delaunay.Point
local Edge     = Delaunay.Edge
--require "imgui"

local steps={}
local drawing ={}
local step_idx = 1
local rooms ={}

local temp_tab = {}
local triang_done = false

local temp_obj ={}
local world
local created_obj = false
local txt =" "
local data_copied = false

local max_width  = 20
local max_height = 25
local mean_thresh = 1.34
local max_rooms = 150

local main_rooms = {}

local count = 0
local old = 0
local wait = 0

local mst_done = false
  
local function refresh()
  --array resets
  step_idx = 1
  rooms ={}
  temp_obj ={}
  created_obj = false
  txt =" "
  data_copied = false
  
  -- user data reset
  --max_width  = 20
  --max_height = 25
  --mean_thresh = 1.25
  
  main_rooms = {}
  
  count = 0
  old = 0
  wait = 2
end
  
  
local function roundm(n, m)
  return math.floor(((n + m - 1)/m))*m
end
  
  
local function getRandomPointInCircle(radi)
  local t = 2*math.pi*math.random()
  local u = math.random()+math.random()
  local r = nil
  if u >1 then r = 2-u else r = u end
  return roundm(radi*r*math.cos(t)+100,5), roundm(radi*r*math.sin(t)+100,5)
end

local function getRandomPointInEllipse(ellipse_width, ellipse_height)
  local t = 2*math.pi*math.random()
  local u = math.random()+math.random()
  local r = nil
  if u > 1 then r = 2-u else r = u end
  return ellipse_width*r*math.cos(t)/2+350,
         ellipse_height*r*math.sin(t)/2+400
end
  
  
local function notFinished()
    c_hi = 0
   -- print("nope")
  end
  
local function notFinished2()
    c_hi = 0
   -- print("nope2")
  end
  
local function notFinished3()
    c_hi = 0
   -- print("nope3")
  end
local function finished(a,b,coll,n,t)
    txt=" "
    count = 0
end
    
  
  
  
 drawing[1] = function()
   for i in ipairs(rooms) do
    love.graphics.setColor(255,255,255,200)
    love.graphics.rectangle("fill",rooms[i].x,rooms[i].y,rooms[i].width,rooms[i].height)
    
    love.graphics.setColor(255,0,0,255)
    love.graphics.rectangle("line",rooms[i].x,rooms[i].y,rooms[i].width,rooms[i].height)
   end
 end
 
 drawing[2] = function()
   for i in ipairs(temp_obj) do
     love.graphics.setColor(255,255,255,200)
     x,y =temp_obj[i].body:getPosition()
     x,y = temp_obj[i].body:getWorldPoint(x,y)
     x,y = roundm(x,10) ,roundm(y,10)
     
     love.graphics.polygon("fill",temp_obj[i].body:getWorldPoints(temp_obj[i].shape:getPoints()))
     
     love.graphics.setColor(255,0,0,255)
     love.graphics.polygon("line",temp_obj[i].body:getWorldPoints(temp_obj[i].shape:getPoints()))
   end
    
    txt = world:getContactCount()
    if txt == old then
      count= count+1
    else
      count = 0
      old = txt
    end
    
    if count > 50 then
      --txt = "test\n"
      step_idx = step_idx +1
    end
    love.graphics.print(txt.." "..count,0,0)
end

  
 
 drawing[3] = function()
   for i in ipairs(rooms) do
     if rooms[i].isMain == true then
       love.graphics.setColor(255,0,0,200)
     else
       
      love.graphics.setColor(255,255,255,200)
    end
  
    love.graphics.rectangle("fill",rooms[i].x,rooms[i].y,rooms[i].width,rooms[i].height)
    
    love.graphics.setColor(255,0,0,255)
    love.graphics.rectangle("line",rooms[i].x,rooms[i].y,rooms[i].width,rooms[i].height)
   end
end
 
  
steps[1] = function() 
    if #rooms > max_rooms then
      step_idx = step_idx+1
      return
    end
    rooms[#rooms+1]       ={}
    rooms[#rooms].height  =love.math.randomNormal(10,max_height)
    rooms[#rooms].width   =love.math.randomNormal(10,max_width)
    if  rooms[#rooms].width < 0 then
      rooms[#rooms].width = 0
    end
    
    if  rooms[#rooms].height < 0 then
      rooms[#rooms].height = 0
    end

    
    rooms[#rooms].width = rooms[#rooms].width  +5
     rooms[#rooms].height  = rooms[#rooms].height  +5
    rooms[#rooms].x,rooms[#rooms].y = getRandomPointInEllipse(400,200)
    rooms[#rooms].id = #rooms
end

steps[2] = function(dt)
  if created_obj == false then
    -- create all the objects
    world:setCallbacks(notFinished,notFinished2,notFinished3,finished)
    for j in ipairs(rooms) do
      temp_obj[#temp_obj+1] = {}
      temp_obj[#temp_obj].body = love.physics.newBody(world,rooms[j].x,rooms[j].y,"dynamic")
      temp_obj[#temp_obj].body:setFixedRotation(true)
      temp_obj[#temp_obj].body:setSleepingAllowed(true)
      temp_obj[#temp_obj].body:setAwake(true)
      temp_obj[#temp_obj].shape   = love.physics.newRectangleShape(rooms[j].width,rooms[j].height)
      success , temp_obj[#temp_obj].fixture =pcall( love.physics.newFixture,temp_obj[#temp_obj].body,temp_obj[#temp_obj].shape,1)
      if success == true then
        --go on nothing to see here
      else
      -- point out what is wrong and fix it then do it again  
        print("hiiii")
      end
      
    end
    created_obj = true
  else
    --only update till there is no collision anymore
    world:update(dt)
  end
end

steps[3] = function(dt)
  --copy data  and select the main rooms
  if data_copied == false then
    for i in ipairs(temp_obj)do
      x,y = temp_obj[i].body:getWorldPoints(temp_obj[i].shape:getPoints())
      print(roundm(x,2).." "..roundm(y,2))
      rooms[i].x = roundm(x,2)
      rooms[i].y = roundm(y,2)
      
      if rooms[i].width > max_width*mean_thresh and rooms[i].height> max_height*mean_thresh then
        rooms[i].isMain = true
        
        rooms[i].CenterX = (rooms[i].x+rooms[i].width+rooms[i].x)/2 
        rooms[i].CenterY = (rooms[i].y+rooms[i].height+rooms[i].y)/2 
        
        main_rooms[#main_rooms+1] = rooms[i]
        end
    end
    world:destroy()
    data_copied = true
  else
    wait = wait + dt
    if wait >2 then
      step_idx = step_idx+1
    end
  end

end


steps[4] = function ()
  if triang_done == false then
    for i in ipairs( main_rooms) do
      temp_tab[#temp_tab+1]= Point(main_rooms[i].CenterX,main_rooms[i].CenterY)
    end
      triangles = Delaunay.triangulate(unpack(temp_tab))
      for i, triangle in ipairs(triangles) do
        print(triangle)
        end
     triang_done = true
  end  
end


local path_edges  = {}
local edges_pre   = {}
local edges_final = {}


local id ={}
local max =10000

local norm_done = false
local true_c = 0
local rooms_n = {}

function math.sign(n) return n>0 and 1 or n<0 and -1 or 0 end

function root(x)
  
  while id[x]~=x do
    id[x] = id[id[x]]
    x = id[x]
  end
  return x
  
end


function union1(x,y)
  local p = root(x)
  local q = root(y)
  id[p] = id[q]
end



steps[6] = function ()
  -- normalise the edges to vertical and horizontal lines
  -- add them to edges_final
 
 --first find out which room these midpoints belong to add number
  for i, edge in ipairs(path_edges) do
    for j,room in ipairs(main_rooms) do
      if room.CenterX == edge.p1.x and room.CenterY == edge.p1.y then
        path_edges[i].p1_id = room.id
      else
        if room.CenterX == edge.p2.x and room.CenterY == edge.p2.y then
          path_edges[i].p2_id = room.id
        end
      end
    end
  end
  
  
  
  for i, edge in ipairs(path_edges) do
    local mid_x,mid_y
    mid_x = (edge.p1.x + edge.p2.x)/2
    mid_y = (edge.p1.y + edge.p2.y)/2
    
    --check if midpoints are somewhere in the boundary
    if mid_x >= rooms[edge.p1_id].x and mid_x <= rooms[edge.p1_id].x +rooms[edge.p1_id].width  and  mid_x >= rooms[edge.p2_id].x and mid_x <= rooms[edge.p2_id].x +rooms[edge.p2_id].width then
      -- make a vertical line at the mid point l
      edges_final[#edges_final+1]={}
      edges_final[#edges_final].p1 = {}
      edges_final[#edges_final].p1.y = rooms[edge.p1_id].CenterY
      edges_final[#edges_final].p1.x = mid_x
      
      edges_final[#edges_final].p2 = {}
      edges_final[#edges_final].p2.y = rooms[edge.p2_id].CenterY
      edges_final[#edges_final].p2.x = mid_x
      
      edges_final[#edges_final].isL = false
      edges_final[#edges_final].room1 = edge.p1_id
      edges_final[#edges_final].room2 = edge.p2_id
      
    else
      if mid_y >= rooms[edge.p1_id].x and mid_y <= rooms[edge.p1_id].x +rooms[edge.p1_id].height  and  mid_y >= rooms[edge.p2_id].x and mid_y <= rooms[edge.p2_id].x +rooms[edge.p2_id].height then
         --make a horizontal line at the mid point --
         edges_final[#edges_final+1]={}
         edges_final[#edges_final].p1 = {}
         edges_final[#edges_final].p1.x = rooms[edge.p1_id].CenterX
         edges_final[#edges_final].p1.y = mid_y
        
         edges_final[#edges_final].p2 = {}
         edges_final[#edges_final].p2.x = rooms[edge.p2_id].CenterX
         edges_final[#edges_final].p2.y = mid_y
        
         edges_final[#edges_final].isL = false
         edges_final[#edges_final].room1 = edge.p1_id
         edges_final[#edges_final].room2 = edge.p2_id
         
      else
         -- make two lines from each center to the center of the other
         edges_final[#edges_final+1]={}
         --p1  center 1
         edges_final[#edges_final].p1 = edge.p1
         
         --p2  center 2
        edges_final[#edges_final].p2 = edge.p2
        
        
         --p3
         edges_final[#edges_final].p3 = {}
         edges_final[#edges_final].p3.x = edge.p1.x
         edges_final[#edges_final].p3.y = edge.p2.y
         
         
         
         edges_final[#edges_final].isL = true
         
         edges_final[#edges_final].room1 = edge.p1_id
         edges_final[#edges_final].room2 = edge.p2_id
         
      end
    end
    
    
  end
  
  norm_done = true
  step_idx = step_idx+1
end

function checkIntersect(l1p1, l1p2, l2p1, l2p2)
	local function checkDir(pt1, pt2, pt3) return math.sign(((pt2.x-pt1.x)*(pt3.y-pt1.y)) - ((pt3.x-pt1.x)*(pt2.y-pt1.y))) end
	return (checkDir(l1p1,l1p2,l2p1) ~= checkDir(l1p1,l1p2,l2p2)) and (checkDir(l2p1,l2p2,l1p1) ~= checkDir(l2p1,l2p2,l1p2))
end


function CheckCollision(room,line)
  local sum = false
  local b = 0
  local a = 0
  local c = 0
  local d = 0
  love.graphics.clear()
  if line.isL == false then
     a = checkIntersect({x=room.x,y=room.y}, {x=room.x+room.width,y=room.y},               {x = line.p1.x,y=line.p1.y},{x=line.p2.x,y=line.p2.y})
     b = checkIntersect({x=room.x,y=room.y}, {x=room.x,y=room.y+room.height},              {x=line.p1.x,y=line.p1.y},{x=line.p2.x,y=line.p2.y})
     c = checkIntersect({x=room.x+room.width,y=room.y}, {x=room.x+room.width,y=room.y+ room.height},             {x=line.p1.x,y=line.p1.y},{x=line.p2.x,y=line.p2.y})
     d = checkIntersect({x=room.x+room.width,y=room.y+room.height}, {x=room.x,y=room.y +room.height},{x=line.p1.x,y=line.p1.y},{x=line.p2.x,y=line.p2.y})
     
  else
     a = checkIntersect({x=room.x,y=room.y}, {x=room.x+room.width,y=room.y},               {x = line.p1.x,y=line.p1.y},{x=line.p3.x,y=line.p3.y})
     b = checkIntersect({x=room.x,y=room.y}, {x=room.x,y=room.y+room.height},              {x=line.p1.x,y=line.p1.y},{x=line.p3.x,y=line.p3.y})
     c = checkIntersect({x=room.x+room.width,y=room.y}, {x=room.x+room.width,y=room.y+ room.height},             {x=line.p1.x,y=line.p1.y},{x=line.p3.x,y=line.p3.y})
     d = checkIntersect({x=room.x+room.width,y=room.y+room.height}, {x=room.x,y=room.y +room.height},{x=line.p1.x,y=line.p1.y},{x=line.p3.x,y=line.p3.y})
    if not a and not b and not c and not d then
      sum = false
    else
      sum = true
    end
    
     
    
    a = checkIntersect({x=room.x,y=room.y}, {x=room.x+room.width,y=room.y},               {x = line.p3.x,y=line.p3.y},{x=line.p2.x,y=line.p2.y})
     b = checkIntersect({x=room.x,y=room.y}, {x=room.x,y=room.y+room.height},              {x=line.p3.x,y=line.p3.y},{x=line.p2.x,y=line.p2.y})
     c = checkIntersect({x=room.x+room.width,y=room.y}, {x=room.x+room.width,y=room.y+ room.height},             {x=line.p3.x,y=line.p3.y},{x=line.p2.x,y=line.p2.y})
     d = checkIntersect({x=room.x+room.width,y=room.y+room.height}, {x=room.x,y=room.y +room.height},{x=line.p3.x,y=line.p3.y},{x=line.p2.x,y=line.p2.y})
    --a = sum + a
  end
  
  love.graphics.line(room.x,room.y, room.x+room.width,room.y)
  love.graphics.line(room.x,room.y, room.x,room.y+room.height)
  love.graphics.line(room.x+room.width,room.y, room.x+room.width,room.y+ room.height)
  love.graphics.line(room.x+room.width,room.y+room.height, room.x,room.y +room.height)
  
  if not a and not b and not c and not d and not sum then
    --print (a.." "..b.." "..c.." "..d.." "..sum)
    
    return false
  else
    true_c = true_c + 1
    rooms_n[#rooms_n+1] =room
     -- love.graphics.clear()
        love.graphics.setColor(0,100,200,255)
        love.graphics.rectangle("fill",room.x,room.y,room.width,room.height)
        love.graphics.setColor(0,255,0,255)
        if line.isL == true then
          love.graphics.line(line.p1.x,line.p1.y,line.p3.x,line.p3.y)
          love.graphics.line(line.p2.x,line.p2.y,line.p3.x,line.p3.y)
        else
          love.graphics.line(line.p1.x,line.p1.y,line.p2.x,line.p2.y)
        end
        
      --love.graphics.present()
      
    --love.timer.sleep(1)
    return true
  end
  
end





function mst ()
  local temp_edge = {}
   local x,y
   local cost
   local minimumCost = 0
   local count = 0
   
   --init ids
   for i=1,max do
      id[i]= i
   end
   
   for i=1,#path_edges do
     x = math.floor(path_edges[i].p1.x+path_edges[i].p1.y)
     y = math.floor(path_edges[i].p2.x+path_edges[i].p2.y)
     cost = path_edges[i]:length()
     
     if root(x) ~= root(y) then
        minimumCost = minimumCost+cost
        temp_edge[#temp_edge+1] = path_edges[i]
        path_edges[i].added = true
        
        count = count +1
        
        for i,edge in ipairs(temp_edge) do
            love.graphics.line(edge.p1.x,edge.p1.y,edge.p2.x,edge.p2.y)
        end
        love.graphics.present()
        union1(x,y)
        
        --love.timer.sleep(1)
     end
     
   end
  
  return temp_edge, minimumCost,count
   
end



steps[5] = function ()
  
  if mst_done == true  then
    return
  end
  
  
   for i, triangle in ipairs(triangles) do
     local temp_ = {}
     local not_inp = true
     local edge_idx = 1
     local num = 0
     local weight = 0
     
     
      temp_[1], temp_[2] ,temp_[3] = triangle.e1,triangle.e2,triangle.e3
         --  love.graphics.polygon("line",triangle.p1.x,triangle.p1.y,triangle.p2.x,triangle.p2.y,triangle.p3.x,triangle.p3.y)
           for i=1,3 do
             if #path_edges == 0 then
                table.insert(path_edges,1,temp_[i])
             else
               while not_inp and edge_idx <= #path_edges do
                 --print(path_edges[edge_idx]:length())
                 if temp_[i]:length()<path_edges[edge_idx]:length() then
 
                   table.insert(path_edges,edge_idx,temp_[i])
                   print("Insert length ".. temp_[i]:length().." at pos "..edge_idx)
                   not_inp = false
                   break
                 end 
                 edge_idx = edge_idx + 1
               end
               if not_inp == true then
                 --input on last place
                 table.insert(path_edges,#path_edges+1,temp_[i])
                 print("Insert length ".. temp_[i]:length().."  after fail at pos "..#path_edges)
               end
               
               edge_idx = 1
               not_inp = true
             end
           end
   end  
   
   print("möp")
   
   --start minimum spanning tree algorithmus
    temp,weight,num = mst()
    
    print(weight.."  "..num)
    
    --add additional lines back
    local add_back =math.floor((#path_edges)/100*15) -- <-number to add back
    --print(weight.."  "..num.." "..add_back)
    num = 0
    local idx = #path_edges
    
    
    while num < add_back do
      if path_edges[idx].added == true then
        idx = idx -1
      else
        num = num+1
        temp[#temp+1] = path_edges[idx]
        idx = idx -1
      end
    end
    

    
    
    path_edges = temp
    mst_done = true
    
    step_idx = step_idx +1
end

steps[7] = function ()
  true_c = 0
  rooms_n = 0
  rooms_n = {}
    for i, edge in ipairs (edges_final)do
      for j, room in ipairs (rooms)do
          if room.isMain == true or room.isHall == true then
           
          else
            rooms[i].isHall = CheckCollision(room,edge)
          end
      end
    end
  
end



drawing[4] = function ()
  for i in ipairs(rooms) do
     if rooms[i].isMain == true then
       love.graphics.setColor(255,255,255,255)
       love.graphics.print(rooms[i].id,rooms[i].CenterX,rooms[i].CenterY)
       
       love.graphics.setColor(255,0,0,200)
     else
       
      love.graphics.setColor(255,255,255,200)
    end
  
    love.graphics.rectangle("fill",rooms[i].x,rooms[i].y,rooms[i].width,rooms[i].height)
    
    love.graphics.setColor(255,0,0,255)
    love.graphics.rectangle("line",rooms[i].x,rooms[i].y,rooms[i].width,rooms[i].height)
   end
   
   if triang_done == true then
     love.graphics.setColor(0,255,0,255)
     love.graphics.setLineWidth(3)
         for i, triangle in ipairs(triangles) do
           --triangle.p1.x
           love.graphics.polygon("line",triangle.p1.x,triangle.p1.y,triangle.p2.x,triangle.p2.y,triangle.p3.x,triangle.p3.y)
           
       -- print(triangle)

       
      end  
      love.timer.sleep(1)
       step_idx = step_idx+1
   end
   
end






drawing[5] = function ()
  love.graphics.clear()
  for i in ipairs(rooms) do
     if rooms[i].isMain == true then
       love.graphics.setColor(255,255,255,255)
       love.graphics.print(rooms[i].id,rooms[i].CenterX,rooms[i].CenterY)
       
       love.graphics.setColor(255,0,0,200)
     else
       
      love.graphics.setColor(255,255,255,200)
    end
  
    love.graphics.rectangle("fill",rooms[i].x,rooms[i].y,rooms[i].width,rooms[i].height)
    
    love.graphics.setColor(255,0,0,255)
    love.graphics.rectangle("line",rooms[i].x,rooms[i].y,rooms[i].width,rooms[i].height)
   end
   
   if triang_done == true then
     love.graphics.setColor(0,255,0,255)
     love.graphics.setLineWidth(3)
     if mst_done == true then
       for i,edge in ipairs(path_edges) do
        love.graphics.line(edge.p1.x,edge.p1.y,edge.p2.x,edge.p2.y)
       end
     else
       
         for i, triangle in ipairs(triangles) do
           --triangle.p1.x
           love.graphics.polygon("line",triangle.p1.x,triangle.p1.y,triangle.p2.x,triangle.p2.y,triangle.p3.x,triangle.p3.y)
           
       -- print(triangle)
      end  
    end
    
   end
   
end

drawing[6] = function()
  
  love.graphics.setColor(0,255,0,255)
  love.graphics.setLineWidth(5)
  if norm_done == true then
    for i,edge in ipairs(edges_final) do
      if edge.isL == true then
        love.graphics.line(edge.p1.x,edge.p1.y,edge.p3.x,edge.p3.y,edge.p2.x,edge.p2.y)
      else
        love.graphics.line(edge.p1.x,edge.p1.y,edge.p2.x,edge.p2.y)
      end
    end
  else
    for i,edge in ipairs(path_edges) do
        love.graphics.line(edge.p1.x,edge.p1.y,edge.p2.x,edge.p2.y)
     end
  end
  
  love.graphics.setLineWidth(1)
  for i in ipairs(rooms) do
     if rooms[i].isMain == true then
       love.graphics.setColor(255,255,255,255)
       
       
       love.graphics.setColor(255,0,0,200)
       
       love.graphics.rectangle("fill",rooms[i].x,rooms[i].y,rooms[i].width,rooms[i].height)
    
       love.graphics.setColor(255,0,0,255)
       love.graphics.rectangle("line",rooms[i].x,rooms[i].y,rooms[i].width,rooms[i].height)
       
       love.graphics.setColor(255,255,255,255)
       love.graphics.print(rooms[i].id,rooms[i].CenterX,rooms[i].CenterY)
     else
       
      love.graphics.setColor(255,255,255,200)
    end
   end
end

drawing[7]= function()
  love.graphics.setColor(0,255,0,255)
  love.graphics.setLineWidth(3)
  
   if norm_done == true then
    for i,edge in ipairs(edges_final) do
      if edge.isL == true then
        love.graphics.line(edge.p1.x,edge.p1.y,edge.p3.x,edge.p3.y,edge.p2.x,edge.p2.y)
      else
        love.graphics.line(edge.p1.x,edge.p1.y,edge.p2.x,edge.p2.y)
      end
    end
  else
    for i,edge in ipairs(path_edges) do
        love.graphics.line(edge.p1.x,edge.p1.y,edge.p2.x,edge.p2.y)
     end
  end
  

  
  love.graphics.setLineWidth(1)
  for i in ipairs(rooms) do
     if rooms[i].isMain == true then
       love.graphics.setColor(255,255,255,255)
       
       
       love.graphics.setColor(255,0,0,200)
       
       love.graphics.rectangle("fill",rooms[i].x,rooms[i].y,rooms[i].width,rooms[i].height)
    
       love.graphics.setColor(255,0,0,255)
       love.graphics.rectangle("line",rooms[i].x,rooms[i].y,rooms[i].width,rooms[i].height)
       
       love.graphics.setColor(255,255,255,255)
       love.graphics.print(rooms[i].id,rooms[i].CenterX,rooms[i].CenterY)
     else
       
       if rooms[i].isHall == true then
         love.graphics.setColor(255,255,255,255)
       
       
         love.graphics.setColor(0,0,200,200)
         
         love.graphics.rectangle("fill",rooms[i].x,rooms[i].y,rooms[i].width,rooms[i].height)
      
         love.graphics.setColor(0,0,200,255)
         love.graphics.rectangle("line",rooms[i].x,rooms[i].y,rooms[i].width,rooms[i].height)
         
       else

       end
      love.graphics.setColor(255,255,255,200)
    end
   end
  
  for i in ipairs(rooms_n) do
       
       
         love.graphics.setColor(0,200,200,200)
         
         love.graphics.rectangle("fill",rooms_n[i].x,rooms_n[i].y,rooms_n[i].width,rooms_n[i].height)
      
         love.graphics.setColor(0,200,200,255)
         love.graphics.rectangle("line",rooms_n[i].x,rooms_n[i].y,rooms_n[i].width,rooms_n[i].height)
  end
  
 
  
  
end



function love.load()
  -- require("mobdebug").start()
  
  --love.math.setRandomSeed(1)
 -- math.randomseed(1)
  math.randomseed(os.time())
  --steps[1]=random_rects()
  love.physics.setMeter(1)
  world = love.physics.newWorld(0,0,true)
  --initialise the world before starting
end


function refresh_main()
  main_rooms = {}
  for i in ipairs(rooms) do
    if rooms[i].width > max_width*mean_thresh and rooms[i].height> max_height*mean_thresh then
          rooms[i].isMain = true
          
          --rooms[i].CenterX = (rooms[i].x+rooms[i].width+rooms[i].x)/2 
          --rooms[i].CenterY = (rooms[i].y+rooms[i].height+rooms[i].y)/2 
          
          main_rooms[#main_rooms+1] = rooms[i]
    end
  end
end




function love.update(dt)
  --print(step_idx)
  steps[step_idx](dt)
 -- imgui.NewFrame(dt)
end



function love.draw()
  drawing[step_idx]()
  
  --s,mean_thresh = imgui.SliderFloat("mean thresh",mean_thresh,0,2)
  --imgui.Text(#main_rooms)
  --imgui.Text(true_c)
  
  --if imgui.Button("reset two steps") then
    --triang_done = false
    --refresh_main()
    --temp_tab ={}
    
  --end
  
  --imgui.Render()


 end
  

function love.keypressed()
    refresh()
    love.load()
end

function love.mousemoved(x, y)
    --imgui.MouseMoved(x, y)
    --if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    --end
end

function love.mousepressed(x, y, button)
    --imgui.MousePressed(button)
    --if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    --end
end


function love.mousereleased(x, y, button)
    --imgui.MouseReleased(button)
    --if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    --end
end

function love.wheelmoved(x, y)
    --imgui.WheelMoved(y)
    --if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    --end
end