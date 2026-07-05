--  _______ ___   _     _______ ____   ____   ____ _   _  ___  
-- |_   _  / _ \ | |   | ___  / ___| / ___| / ___| | | |/ _ \ 
--   | |  / /_\ \| |   | | | | |    | |    | |   | |_| | | | |
--   | |  |  _  || |   | | | | |    | |    | |   |  _  | | | |
--   | |  | | | || |___| |_| | |___ | |___ | |___| | | | |_| |
--   |_|  |_| |_|_____|_______|____| \____| \____|_| |_|\___/ 



local TaiOcCho_Env = {
    ["isfile"] = isfile or function() return false end,
    ["readfile"] = readfile or function() return "" end,
    ["writefile"] = writefile or function() end,
    ["loadstring"] = loadstring,
    ["game"] = game
}

local TaiOcCho_Key = "376a040c-ec48-4a69-b9db-d51c64b291d5"
local TaiOcCho_File = "verified_key.txt"
local TaiOcCho_Url = "https://api.jnkie.com/api/v1/luascripts/public/41d5c04c4b1bed72d57ee8a2912f627193e6f4305704a6b1dca68a11a1dd5644/download"

local function TaiOcCho_Function()
    local TaiOcCho_Check = false
    
    if TaiOcCho_Env["isfile"](TaiOcCho_File) then
        local currentKey = TaiOcCho_Env["readfile"](TaiOcCho_File):gsub("^%s*(.-)%s*$", "%1")
        if currentKey == TaiOcCho_Key then
            TaiOcCho_Check = true
        else
            TaiOcCho_Env["writefile"](TaiOcCho_File, TaiOcCho_Key)
            TaiOcCho_Check = true
        end
    else
        TaiOcCho_Env["writefile"](TaiOcCho_File, TaiOcCho_Key)
        TaiOcCho_Check = true
    end
    
    if TaiOcCho_Check then
        pcall(function()
            TaiOcCho_Env["loadstring"](TaiOcCho_Env["game"]:HttpGet(TaiOcCho_Url))()
        end)
    end
end

TaiOcCho_Function()
