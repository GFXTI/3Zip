local folderName = "3Zip"

local folders = {}
local loadedFiles = {}

local function fixFile(path: string)
    local realStart = string.find(path, folderName)

    return string.sub(path, realStart)
end

local struct = {}

struct.__index = struct

function struct.load(self, file: string): (any...)
    assert(file, "no filename passed")
    local realFile = self.files[file]

    if not realFile then
        return error(file .. " does not exist in this directory")
    end

    if not loadedFiles[realFile] then
        local func, err = loadfile(realFile, file)

        if not func then
            return error(err)
        end

        local returned = {func()}

        loadedFiles[realFile] = returned
    end

    return unpack(loadedFiles[realFile])
end

function struct.make(self, file: string, data: string?)
    assert(file, "no filename passed")

    if self.files[file] then
        return error(file .. " already exists in this directory")
    end

    local finalPath = self.path .. "/" .. file

    writefile(finalPath, data or "")
    self.files[file] = finalPath
end

function struct.write(self, file: string, content: string)
    assert(file, "no filename passed")
    assert(content, "no content passed")

    local realFile = self.files[file]
    if not realFile then
        return error(file .. " does not exist in this directory")
    end

    writefile(realFile, content)

    if loadedFiles[realFile] then
        loadedFiles[realFile] = nil
        return struct.load(self, file)
    end
end

function struct.append(self, file: string, content: string)
    assert(file, "no filename passed")
    assert(content, "no content passed")

    local realFile = self.files[file]
    if not realFile then
        return error(file .. " does not exist in this directory")
    end

    appendfile(realFile, content)

    if loadedFiles[realFile] then
        loadedFiles[realFile] = nil
        return struct.load(self, file)
    end
end

function struct.read(self, file: string)
    assert(file, "no filename passed")
    local realFile = self.files[file]
    if not realFile then
        return error(file .. " does not exist in this directory")
    end

    return readfile(realFile)
end

function struct.delete(self, file: string)
    assert(file, "no filename passed")
    local realFile = self.files[file]
    if not realFile then
        return error(file .. " does not exist in this directory")
    end

    delfile(realFile)
end

function struct.get(self, subFolder: string)
    assert(subFolder, "no folder passed")
    if not self.folders[subFolder] then
        return error(subFolder .. " does not exist in this directory")
    end

    return self.folders[subFolder]
end

function struct.is(self, item: string)
    assert(item, "no item passed")

    if self.files[item] or self.folders[item] then
        return true
    end

    return false
end

function struct.new(folder)
    local newStruct = setmetatable({files = {}, folders = {}, path = fixFile(folder)}, struct)

    for i,v in listfiles(folder) do
        v = fixFile(v)
        local realName = string.split(v, "\\")
        realName = realName[#realName]

        if isfolder(v) then
            newStruct.folders[realName] = struct.new(v)

            continue
        end

        --realName = string.sub(realName, select(1, string.find(realName, ".lua")))
        newStruct.files[realName] = v
    end

    return newStruct
end

for i,v in listfiles(folderName) do
    if not isfolder(v) then continue end
    local realName = string.split(v, "\\")
    realName = realName[#realName]
    folders[realName] = struct.new(v)
end

-- get("ui"):load("frame") -> (...)
-- get("ui"):make("balls.lua", "stuff")
-- get("ui"):is("balls.lua")
-- get("ui"):write("balls.lua", "stuff") -> (...)?
-- get("ui"):append("balls.lua", "stuff\n")
-- get("ui"):read("balls.lua") -> (string)
-- get("ui"):delete("balls.lua")
-- get("ui"):get("subfolder")


getgenv().get = function(folder)
    return folders[folder]
end

return get
