local args = {...}
_G.OSoDE = {
  version = "beta 5",
}

local function log(...)
  print("[OSoDE] ",...)
  sleep(0)
end

local function logError(...)
  printError("[OSoDE] ",...)
  sleep(0)
end

local function makeNewPath(path,name)
	if not name then
		error("a nil value",2)
	end
	if fs.exists(path) then
		fs.delete(path)
	end
	fs.makeDir(path)
	local f = fs.open(path.."/OSoDE","w")
	f.write('name = "'..name..'"')
	f.close()
	log(name," created")
	OSoDE.name = name
end

if #args > 0 then
  OSoDE.path = args[1]
else
  print("Usage: OSoDE <directory>")
  return
end

log("OSoDE by Ale32bit")
log("VFS by MultMine")
log("Starting OSoDE "..OSoDE.version.."...")

if not fs.exists("/vfs") then
  local vfs = fs.open("/vfs","w")
  local source = http.get("https://raw.github.com/MultHub/Aurora/master/aurorasrc/vfs")
  vfs.write(source.readAll())
  vfs.close()
  source.close()
  log("Installed VFS")
end

if fs.exists(OSoDE.path.."/OSoDE") then
	dofile(OSoDE.path.."/OSoDE")
	OSoDE.name = name
	log("Starting up "..OSoDE.name)
else
	if args[2] then
		makeNewPath(OSoDE.path,args[2])
	else
		logError("New path: OSoDE <path> <name>")
		return
	end
end

if not fs.exists(OSoDE.path.."/data") then
  if fs.isDir(OSoDE.path.."/data") then
    fs.delete(OSoDE.path.."/data")
  end
  fs.makeDir(OSoDE.path.."/data")
end

if not fs.exists(OSoDE.path.."/data/rom") then
  fs.copy("/rom",OSoDE.path.."/data/rom")
end

sleep(1)

local oldShutdown = os.shutdown
local oldReboot = os.reboot
local oldShell = shell

function os.shutdown()
  coroutine.yield("shutdown")
end

function os.reboot()
  coroutine.yield("reboot")
end

function OSoDE.terminate()
  coroutine.yield("terminate")
end

shell = nil

dofile("/vfs")

local f = fs.open(OSoDE.path.."/data/rom/programs/shell","r")
local script = f.readAll()
f.close()

local oldRoot = fs.getRoot()
fs.setRoot(fs.redirectProxy(fs.getProxy(OSoDE.path.."/data"), fs.getProxiedPath(OSoDE.path.."/data")))

local native = fs.native
_G.fs.native = function()
  return fs
end

local ok, err = pcall(function()
  local co
  local function start()
    local env = setmetatable({}, {__index = getfenv()})
    env._G = env
    co = coroutine.create(setfenv(loadstring(script), env))
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1,1)
    coroutine.resume(co)
  end
  start()
  while true do
    if coroutine.status(co) == "dead" then
      return
    end
    local rtn = {coroutine.resume(co, os.pullEvent())}
    if rtn[2] == "reboot" then
      start()
    elseif rtn[2] == "shutdown" then
      return
    elseif rtn[2] == "terminate" then
      return
    end
  end
  setfenv(loadstring(script),getfenv())()
end)
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,1)
fs.setRoot(oldRoot)
_G.fs.native = native
if not ok then
  log(OSoDE.name.." crashed")
  logError(err)
  log("Tip: Reboot computer and restart OSoDE")
end
os.shutdown = oldShutdown
os.reboot = oldReboot
shell = oldShell

log(OSoDE.name.." terminated")
