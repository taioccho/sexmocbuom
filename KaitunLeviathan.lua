--  _______ ___   _     _______ ____   ____   ____ _   _  ___  
-- |_   _  / _ \ | |   | ___  / ___| / ___| / ___| | | |/ _ \ 
--   | |  / /_\ \| |   | | | | |    | |    | |   | |_| | | | |
--   | |  |  _  || |   | | | | |    | |    | |   |  _  | | | |
--   | |  | | | || |___| |_| | |___ | |___ | |___| | | | |_| |
--   |_|  |_| |_|_____|_______|____| \____| \____|_| |_|\___/ 


if getgenv().Fynix then return
else
getgenv().SCRIPT_KEY = "c4738f65-59b3-42e4-bd17-93fe5b4005f3"
    loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/b9dfd0f629fa7112e8139981199e7dabb4946a39862027dbfefac48b0de1ba1b/download"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Dev-AnhTuansitink/Module/refs/heads/main/EzFastAttack.lua"))()
end
