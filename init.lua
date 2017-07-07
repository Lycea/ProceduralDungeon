local BASE = (...)..'.' 

i= BASE:find("init")
if i then
  BASE=BASE:sub(1,i-1)
end



assert(not BASE:match('%.init%.$'), "Invalid require path `"..(...).."' (drop the `.init').")


return {
  
	DungeonCreator = require(BASE .. 'dungeon'),
}