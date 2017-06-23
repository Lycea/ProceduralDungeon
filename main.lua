require "dungeon"
  
local newOptions = {
    --changeable settings
    max_width  = 20,              --max room width
    max_height = 25,              --max room height
    mean_thresh = 1.34,           --mean_thresh - bigger than that will be main rooms
    max_rooms = 150,              --max rooms , more means more romms, more everything :P
    
    --seed options
    useSeed   = false,            --do you want to create a special seed ?
    seed      = 0                 --which seed should that be :p
    }
function love.load()
  DungeonCreator.setOptions(newOptions)
  DungeonCreator.newDungeon()
end







function love.update(dt)
  --print(step_idx)
    DungeonCreator.Update(dt)
 -- imgui.NewFrame(dt)
end



function love.draw()
DungeonCreator.Draw()
 end
  

