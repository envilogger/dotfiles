-- Remmina connections for walker (prefix "rdp ", see ~/.config/walker/config.toml).
-- Reads the profiles at query time, so nothing about them lives in the dotfiles.
-- Return: connect, ctrl+e: edit the profile in Remmina.
Name = "remmina"
NamePretty = "Remmina"
Icon = "org.remmina.Remmina"
SearchName = true
Actions = {
    connect = "remmina -c '%VALUE%'",
    edit = "remmina -e '%VALUE%'",
}

-- Profiles live in datadir_path from remmina.pref, or $XDG_DATA_HOME/remmina.
local function profileDir()
    local home = os.getenv("HOME")
    local config = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
    local pref = io.open(config .. "/remmina/remmina.pref", "r")
    if pref then
        for line in pref:lines() do
            local dir = line:match("^datadir_path=(.+)$")
            if dir then
                pref:close()
                return dir
            end
        end
        pref:close()
    end
    return (os.getenv("XDG_DATA_HOME") or (home .. "/.local/share")) .. "/remmina"
end

-- The [remmina] section's keys
local function readProfile(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local profile = {}
    for line in file:lines() do
        local key, value = line:match("^([%w_-]+)=(.*)$")
        if key then profile[key] = value end
    end
    file:close()
    return profile
end

function GetEntries()
    local entries = {}
    local list = io.popen("find '" .. profileDir() .. "' -maxdepth 1 -name '*.remmina' 2>/dev/null")
    if not list then return entries end

    for path in list:lines() do
        local p = readProfile(path)
        if p and p.name and p.name ~= "" then
            local details = {}
            for _, v in ipairs({ p.group, p.protocol, p.server }) do
                if v and v ~= "" then table.insert(details, v) end
            end
            table.insert(entries, {
                Text = p.name,
                Subtext = table.concat(details, " · "),
                Value = path,
                Keywords = { p.group or "", p.server or "" },
            })
        end
    end
    list:close()

    table.sort(entries, function(a, b) return a.Subtext .. a.Text < b.Subtext .. b.Text end)
    return entries
end
