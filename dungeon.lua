DungeonCreator = {}

local BASE = (...)..'.' 
local i= BASE:find("dungeon")
BASE=BASE:sub(1,i-1)

Delaunay = require(BASE .. 'src.delaunay')



local Point    = Delaunay.Point
local Edge     = Delaunay.Edge
-- needed for triangulation !
--local Delaunay = require "src.delaunay"



-----------------------------------------------------------------------
----  TABLE/variable definitions
-----------------------------------------------------------------------
local steps     = {}
local drawing   = {}

local rooms     = {}
local temp_tab  = {}
local temp_obj  = {}
local main_rooms = {}

local path_edges  = {}
local edges_pre   = {}
local edges_final = {}
local id ={}
local rooms_n = {}


local world
local triangles
local c_hi         -- TODO: change that value to something usefull or remove it !


local named_options ={ "max_width","max_height","mean_thresh","max_rooms","useSeed","seed","height_circle","width_circle","percent_paths_added_back"}


local options_default = 
{
    --static stuff only changed internaly!
    triang_done = false,
    created_obj = false,
    data_copied = false,
    mst_done    = false,
    norm_done = false,
    step_idx = 1,
    txt =" ",
    count = 0,
    old = 0,
    max = 10000,           
    true_c = 0,
    wait = 0,
    no_draw = false,
    
    --changeable settings
    max_width  = 20,              --max room width
    max_height = 25,              --max room height
    mean_thresh = 1.34,
    max_rooms = 150,
    
    --seed options
    useSeed   = false,
    seed      = 0,
    
    --generation
    width_circle  =  400 ,  --these both say if a dungeon will be longer or higher 
    height_circle =  200,
    
    percent_paths_added_back = 15,   --percentage of lines addedd back after the perfect way
  }

local options = options_default 

-----------------------------------------------------------------------------
-- Start helper functions
-----------------------------------------------------------------------------




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
  
  --the additional number is that it doesn't go out of the view ... only important for preview
  return ellipse_width*r*math.cos(t)/2+350,
         ellipse_height*r*math.sin(t)/2+400
end
  
  
 function math.sign(n) return n>0 and 1 or n<0 and -1 or 0 end

local function root(x)
  
  while id[x]~=x do
    id[x] = id[id[x]]
    x = id[x]
  end
  return x
  
end


local function union1(x,y)
  local p = root(x)
  local q = root(y)
  id[p] = id[q]
end





local function checkIntersect(l1p1, l1p2, l2p1, l2p2)
	local function checkDir(pt1, pt2, pt3) return math.sign(((pt2.x-pt1.x)*(pt3.y-pt1.y)) - ((pt3.x-pt1.x)*(pt2.y-pt1.y))) end
	return (checkDir(l1p1,l1p2,l2p1) ~= checkDir(l1p1,l1p2,l2p2)) and (checkDir(l2p1,l2p2,l1p1) ~= checkDir(l2p1,l2p2,l1p2))
end
  
  
local function CheckCollision(room,line)
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
    options.true_c = options.true_c + 1
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
   for i=1,options.max do
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
  
  ---------------------------------------------------------------------------
  -- World callback functions , needed temporary for moving rectangles
  ---------------------------------------------------------------------------
local function notFinished()
    c_hi = 0
  end
  
local function notFinished2()
    c_hi = 0
  end
  
local function notFinished3()
    c_hi = 0
  end
local function finished(a,b,coll,n,t)
    options.txt=" "
    options.count = 0
end
    
  
  
  
  
  
  ------------------------------------------------------
  --start of main functions for drawing and calculating
  ------------------------------------------------------
  
  
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
     x,y = temp_obj[i].body:getPosition()
     x,y = temp_obj[i].body:getWorldPoint(x,y)
     x,y = roundm(x,10) ,roundm(y,10)
     
     love.graphics.polygon("fill",temp_obj[i].body:getWorldPoints(temp_obj[i].shape:getPoints()))
     
     love.graphics.setColor(255,0,0,255)
     love.graphics.polygon("line",temp_obj[i].body:getWorldPoints(temp_obj[i].shape:getPoints()))
   end
    
    options.txt = world:getContactCount()
    if options.txt == options.old then
      options.count= options.count+1
    else
      options.count = 0
      options.old = options.txt
    end
    
    if options.count > 50 then
      --txt = "test\n"
      options.step_idx = options.step_idx +1
    end
    love.graphics.print(options.txt.." "..options.count,0,0)
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
    if #rooms > options.max_rooms then
      options.step_idx = options.step_idx+1
      return
    end
    rooms[#rooms+1]       ={}
    rooms[#rooms].height  =love.math.randomNormal(10,options.max_height)
    rooms[#rooms].width   =love.math.randomNormal(10,options.max_width)
    if  rooms[#rooms].width < 0 then
      rooms[#rooms].width = 0
    end
    
    if  rooms[#rooms].height < 0 then
      rooms[#rooms].height = 0
    end

    
    rooms[#rooms].width = rooms[#rooms].width  +5
    rooms[#rooms].height  = rooms[#rooms].height  +5
    rooms[#rooms].x,rooms[#rooms].y = getRandomPointInEllipse(options.width_circle,options.height_circle)
    rooms[#rooms].id = #rooms
end

steps[2] = function(dt)
  local success
  
  if options.created_obj == false then
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
        print("Something went wrong with the fixture")
        print("for debuging please make an issue with the seeds\n then it is reproducable\n")
        print("love seed: "..love.math.getRandomSeed())
        print("lua  seed: ")
        print("also copy the settings send them,if changed!")
      end
      
    end
    options.created_obj = true
  else
    --only update till there is no collision anymore
    world:update(dt)
  end
end

steps[3] = function(dt)
  local x,y
  --copy data  and select the main rooms in one step
  if options.data_copied == false then
    for i in ipairs(temp_obj)do
      x,y = temp_obj[i].body:getWorldPoints(temp_obj[i].shape:getPoints())
      --print(roundm(x,2).." "..roundm(y,2))
      rooms[i].x = roundm(x,2)
      rooms[i].y = roundm(y,2)
      
      --check if rooms are main rooms
      if rooms[i].width > options.max_width*options.mean_thresh and rooms[i].height> options.max_height*options.mean_thresh then
        rooms[i].isMain = true
        
        --get the center points
        rooms[i].CenterX = (rooms[i].x+rooms[i].width+rooms[i].x)/2 
        rooms[i].CenterY = (rooms[i].y+rooms[i].height+rooms[i].y)/2 
        
        main_rooms[#main_rooms+1] = rooms[i]
        end
    end
    world:destroy()
    options.data_copied = true
  else
    options.wait =options.wait + dt
    if options.wait >2 then
      options.step_idx = options.step_idx+1
    end
  end

end


steps[4] = function ()
  if options.triang_done == false then
    --add all the points of the main rooms to the list
    for i in ipairs( main_rooms) do
      temp_tab[#temp_tab+1]= Point(main_rooms[i].CenterX,main_rooms[i].CenterY)
    end
    --do the triangulation stuff ...
    triangles = Delaunay.triangulate(unpack(temp_tab))
    
    --print the triangles (?)
  --  for i, triangle in ipairs(triangles) do
    --  print(triangle)
    --end
     options.triang_done = true
  end  
end

steps[5] = function ()
  
  if options.mst_done == true  then
    return 
  end
  
  --first sort all of the edges biggest to smallest 
  --TODO: Add other way around ? :P
   for i, triangle in ipairs(triangles) do
     local temp_ = {}
     local not_inp = true
     local edge_idx = 1
     local num = 0
     local weight = 0
     
      temp_[1], temp_[2] ,temp_[3] = triangle.e1,triangle.e2,triangle.e3
       for i=1,3 do
         if #path_edges == 0 then
            table.insert(path_edges,1,temp_[i])
         else
           while not_inp and edge_idx <= #path_edges do
             if temp_[i]:length()<path_edges[edge_idx]:length() then

               table.insert(path_edges,edge_idx,temp_[i])
               --print("Insert length ".. temp_[i]:length().." at pos "..edge_idx)
               not_inp = false
               break
             end 
             edge_idx = edge_idx + 1
           end
           if not_inp == true then
             --input on last place
             --TODO: maybe addd the posibility to change where to add -> only small ways /long ways / missing islands ?
             table.insert(path_edges,#path_edges+1,temp_[i])
           end
           
           edge_idx = 1
           not_inp = true
         end
       end
   end  
   

   
   --start minimum spanning tree algorithmus
    local temp,weight,num = mst()
    
    --print(weight.."  "..num)
    
    --add additional lines back
    local add_back =math.floor((#path_edges)/100*options.percent_paths_added_back) -- <-number to add back
    --print(weight.."  "..num.." "..add_back)
    num = 0
    local idx = #path_edges
    
    
    while (num < add_back) and (idx > 0) do
      if path_edges[idx].added == true then
        idx = idx -1
      else
        num = num+1
        temp[#temp+1] = path_edges[idx]
        idx = idx -1
      end
    end
    

    
    
    path_edges = temp
    options.mst_done = true
    
    options.step_idx = options.step_idx +1
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
  
  options.norm_done = true
  options.step_idx = options.step_idx+1
end

steps[7] = function ()
  options.true_c = 0
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
   
   if options.triang_done == true then
     love.graphics.setColor(0,255,0,255)
     love.graphics.setLineWidth(3)
         for i, triangle in ipairs(triangles) do
           --triangle.p1.x
           love.graphics.polygon("line",triangle.p1.x,triangle.p1.y,triangle.p2.x,triangle.p2.y,triangle.p3.x,triangle.p3.y)
           
       -- print(triangle)

       
      end  
      love.timer.sleep(1)
       options.step_idx = options.step_idx+1
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
   
   if options.triang_done == true then
     love.graphics.setColor(0,255,0,255)
     love.graphics.setLineWidth(3)
     if options.mst_done == true then
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
  if options.norm_done == true then
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
  
   if options.norm_done == true then
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








---------------------------------------------
-- Functions accessable from outside
---------------------------------------------
function DungeonCreator.setOptions(newOptions)
  local options_changed = 0
  for i,name in ipairs(named_options) do
    if newOptions[name] then
      options[name] = newOptions[name]
      options_changed = options_changed +1
    end
  end
  print(options_changed.." settings were actualised!")
end

function DungeonCreator.newDungeon()
  if options.useSeed == false then
    math.randomseed(os.time())

  else
    math.randomseed(options.seed)
    love.math.setRandomSeed(options.seed)
  end
  --init physics stuff
  love.physics.setMeter(1)
  world = love.physics.newWorld(0,0,true)
end


--needed for updating the dungeon
function DungeonCreator.Update(dt)
    steps[options.step_idx](dt)
  
end

 --needed for drawing the dungeon
 function DungeonCreator.Draw()
    drawing[options.step_idx]()
  
end