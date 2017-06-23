require "dungeon"
  

function love.load()
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
  

