local Trove = require(game.ReplicatedStorage.Packages.Trove)
local Util = require(game.ReplicatedStorage.Packages.Util)

type Trove = typeof(Trove.new())

function getLeaderstatFolder(player: Player)
    local folder = player:FindFirstChild("leaderstats")
    if folder == nil then
        folder = Util.createInstance("Folder", {
            Name = "leaderstats",
            Parent = player
        })
    end
    return folder
end

export type LeaderstatEntry<K> = {
    set: (LeaderstatEntry<K>, value: K) -> nil,
    get: (LeaderstatEntry<K>) -> K,
    change: (LeaderstatEntry<K>, transform: (K) -> K) -> nil,
    _instance: ValueBase,
    _trove: Trove
}

local LeaderstatEntry = {}
LeaderstatEntry.__index = LeaderstatEntry

function LeaderstatEntry._new<K>(player: Player, leaderstat: Leaderstat<K>): LeaderstatEntry<K>
    local self = setmetatable({
        _trove = Trove.new()
    }, LeaderstatEntry)

    self._instance = self._trove:Add(Instance.new(if typeof(leaderstat._defaultValue) == "number" then "NumberValue" else "StringValue") :: any)
    self._instance.Value = leaderstat._defaultValue
    self._instance.Name = leaderstat.Name
    self._instance.Parent = getLeaderstatFolder(player)

    leaderstat._trove:Add(self._trove :: any)
    leaderstat._entries[player] = self :: any
    return self :: any
end

function LeaderstatEntry:set(value: AcceptableValueType)
    self._instance.Value = value
end

function LeaderstatEntry:get(): AcceptableValueType
    return self._instance.Value
end

function LeaderstatEntry:change<K>(transform: (K) -> K)
    self._instance.Value = transform(self._instance.Value)
end

LeaderstatEntry.__call = LeaderstatEntry.get

type AcceptableValueType = number | string

export type Leaderstat<K> = {
    Name: string,
    _defaultValue: AcceptableValueType,
    Destroy: () -> nil,
    of: (Leaderstat<K>, player: Player) -> LeaderstatEntry<K>,
    _entries: {[Player]: LeaderstatEntry<K>},
    _trove: Trove
}

local Leaderstat = {}
Leaderstat.__index = Leaderstat

local leaderstats: {[string]: Leaderstat<AcceptableValueType>} = {}

function Leaderstat.new(name: string, default: AcceptableValueType): Leaderstat<AcceptableValueType>
    if leaderstats[name] then
        return leaderstats[name]
    end

    local self = setmetatable({
        Name = name,
        _defaultValue = default,
        _trove = Trove.new(),
        _entries = {}
    }, Leaderstat)

    leaderstats[name] = self :: any
    return self :: any
end

function Leaderstat.get(name: string): Leaderstat<AcceptableValueType>?
    return leaderstats[name]
end

function Leaderstat.of<K>(self: Leaderstat<K>, player: Player): LeaderstatEntry<K>
    return self._entries[player]
end

function Leaderstat:Destroy()
    self._trove:Clean()
    leaderstats[self.Name] = nil
end

Util.forPlayers(function(player)
    for _, leaderstat in pairs(leaderstats) do
        LeaderstatEntry._new(player, leaderstat)
    end
end)

return setmetatable(Leaderstat, {
    __call = Leaderstat.get
})