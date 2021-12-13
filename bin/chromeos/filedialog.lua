local filedialog = {}
local io=require 'io'
local function run_python(arg)
    local realpath=love.filesystem.getRealDirectory("filedialog.py").."/filedialog.py"
    print(realpath)
    local handle=io.popen("python " .. realpath .." "..arg)
    local return_code=handle:read("*n")
    local ret
    if return_code==0 then
        ret=false
    else
        ret=handle:read("*l"):gsub("^%s*(.-)%s*$", "%1")
    end
    handle:close()
    return ret
end


function filedialog.open()
    return run_python('open')
end
function filedialog.save()
    return run_python('save')
end

return filedialog
