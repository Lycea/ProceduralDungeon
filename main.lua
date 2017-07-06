require "dungeon"
  
local newOptions = {
    --changeable settings
    max_width  = 20,              --max room width
    max_height = 25,              --max room height
    mean_thresh = 1.5,           --mean_thresh - bigger than that will be main rooms
    max_rooms = 150,              --max rooms , more means more rooms, more everything :P
    
    --seed options
    useSeed   = false,            --do you want to create a special seed ?
    seed      = 0 ,                --which seed should that be :p
    
    width_circle  =  400 ,  --these both say if a dungeon will be longer or higher 
    height_circle =  200,
    
    percent_paths_added_back = 15,   --percentage of lines addedd back after the perfect way
  }
  
  
function love.load()
  DungeonCreator.setOptions(newOptions)
  DungeonCreator.newDungeon()
end



function love.update(dt)
    DungeonCreator.Update(dt)
end



function love.draw()
DungeonCreator.Draw()
 end
  

