--####################################################################################
--####################################################################################
--SearchProvider
--####################################################################################
--Dependencies: none

local SearchProvider = {};
SearchProvider.__index		= SearchProvider;
LinksInChat_SearchProvider	= SearchProvider; --Global declaration


--Local variables that cache stuff so we dont have to recreate large objects
local cache_GameLocale		= GetLocale();	--Localization to the current game-client language
local cache_Provider		= nil;			--Table with provider data
local cache_Provider_Locale	= "";			--String. Language code for provider data


--Declaration of Provider dataset
local CONST_Provider_Sorted = {[1]="baidu", [2]="bing", [3]="duckduckgo", [4]="google", [5]="startpage.com", [6]="yahoo", [7]="wowdb", [8]="wowhead", [9]="buffed.de", [10]="judgehype"}; --Array with provider key's in a 'sorted' order
--[9]="eu.battle.net", [10]="us.battle.net", [11]="asia.battle.net"

local CONST_Provider = {
	["google"] = { --Google --(this key must be unique and is what we save as 'provider' in settings)
		["enUS"] = { --English (United Kingdom) and English (United States) **Default locales**
			["Title"]		= "Google (simple)",							--Title in dropdown menu
			["Simple"]		= "https://www.google.com/search?q=@ITEMID@",	--Simple search HTTPS link
			["ForceHTTPS"]	= false,										--Boolean. Will override user settings and always use https:// if set to true.
			["Advanced"]	= ""											--Empty string or comma separated list with hyperlinks supported
		},--enUS
		["deDE"] = { --German (Germany)
			["Title"]		= "Google (einfach)",
			["Simple"]		= "https://www.google.de/search?q=@ITEMID@"
		},
		["esES"] = { --Spanish (Spain)
			["Title"]		= "Google (simple)",
			["Simple"]		= "https://www.google.es/search?q=@ITEMID@"
		},
		["esMX"] = { --Spanish (Mexico)
			["Title"]		= "Google (simple)",
			["Simple"]		= "https://www.google.com.mx/search?q=@ITEMID@"
		},
		["frFR"] = { --French (France)
			["Title"]		= "Google (simple)",
			["Simple"]		= "https://www.google.fr/search?q=@ITEMID@"
		},
		["itIT"] = { --Italian (Italy)
			["Title"]		= "Google (semplice)",
			["Simple"]		= "https://www.google.it/search?q=@ITEMID@"
		},
		["koKR"] = { --Korean (Korea)
			["Title"]		= "Google (단순한)",
			["Simple"]		= "https://www.google.co.kr/search?q=@ITEMID@"
		},
		["ptBR"] = { --Portuguese (Brazil)
			["Title"]		= "Google (simple)",
			["Simple"]		= "https://www.google.br/search?q=@ITEMID@"
		},
		["ruRU"] = { --Russian (Russia)
			["Title"]		= "Google (простой)",
			["Simple"]		= "https://www.google.ru/search?q=@ITEMID@"
		},
		["zhCN"] = { --Chinese (Simplified, PRC)
			["Title"]		= "Google (简单)",
			["Simple"]		= "https://www.google.com/search?q=@ITEMID@"
		},
		["zhTW"] = { --Chinese (Traditional, Taiwan)
			["Title"]		= "Google (簡單)",
			["Simple"]		= "https://www.google.com.tw/search?q=@ITEMID@"
		}
	},--google

	["bing"] = { --Bing (simple, all languages)
		["enUS"] = { --English (United Kingdom) and English (United States) **Default locales**
			["Title"]		= "Bing (simple)",							--Title in dropdown menu
			["Simple"]		= "https://www.bing.com/search?q=@ITEMID@",	--Simple search HTTPS link
			["ForceHTTPS"]	= false,									--Boolean. Will override user settings and always use https:// if set to true.
			["Advanced"]	= ""										--Empty string or comma separated list with hyperlinks supported
		},--enUS
		["deDE"] = { --German (Germany)
			["Title"]		= "Bing (einfach)",
			["Simple"]		= "https://www.bing.com/search?cc=de&q=@ITEMID@"
		},
		["esES"] = { --Spanish (Spain)
			["Title"]		= "Bing (simple)",
			["Simple"]		= "https://www.bing.com/search?cc=es&q=@ITEMID@"
		},
		["esMX"] = { --Spanish (Mexico)
			["Title"]		= "Bing (simple)",
			["Simple"]		= "https://www.bing.com/search?cc=mx&q=@ITEMID@"
		},
		["frFR"] = { --French (France)
			["Title"]		= "Bing (simple)",
			["Simple"]		= "https://www.bing.com/search?cc=fr&q=@ITEMID@"
		},
		["itIT"] = { --Italian (Italy)
			["Title"]		= "Bing (semplice)",
			["Simple"]		= "https://www.bing.com/search?cc=it&q=@ITEMID@"
		},
		["koKR"] = { --Korean (Korea)
			["Title"]		= "Bing (단순한)",
			["Simple"]		= "https://www.bing.com/search?cc=kr&q=@ITEMID@"
		},
		["ptBR"] = { --Portuguese (Brazil)
			["Title"]		= "Bing (simple)",
			["Simple"]		= "https://www.bing.com/search?cc=br&q=@ITEMID@"
		},
		["ruRU"] = { --Russian (Russia)
			["Title"]		= "Bing (простой)",
			["Simple"]		= "https://www.bing.com/search?cc=ru&q=@ITEMID@"
		},
		["zhCN"] = { --Chinese (Simplified, PRC)
			["Title"]		= "Bing (简单)",
			["Simple"]		= "https://cn.bing.com/search?cc=cn&q=@ITEMID@"
		},
		["zhTW"] = { --Chinese (Traditional, Taiwan)
			["Title"]		= "Bing (簡單)",
			["Simple"]		= "https://www.bing.com/search?cc=tw&q=@ITEMID@"
		}
	},--bing

	["yahoo"] = { --Yahoo (simple, all languages)
		["enUS"] = { --English (United Kingdom) and English (United States) **Default locales**
			["Title"]		= "Yahoo (simple)",								--Title in dropdown menu
			["Simple"]		= "https://search.yahoo.com/search?p=@ITEMID@",	--Simple search HTTPS link
			["ForceHTTPS"]	= false,										--Boolean. Will override user settings and always use https:// if set to true.
			["Advanced"]	= ""											--Empty string or comma separated list with hyperlinks supported
		},--enUS
		["deDE"] = { --German (Germany)
			["Title"]		= "Yahoo (einfach)",
			["Simple"]		= "https://de.search.yahoo.com/search?p=@ITEMID@"
		},
		["esES"] = { --Spanish (Spain)
			["Title"]		= "Yahoo (simple)",
			["Simple"]		= "https://es.search.yahoo.com/search?p=@ITEMID@"
		},
		["esMX"] = { --Spanish (Mexico)
			["Title"]		= "Yahoo (simple)",
			["Simple"]		= "https://mx.search.yahoo.com/search?p=@ITEMID@"
		},
		["frFR"] = { --French (France)
			["Title"]		= "Yahoo (simple)",
			["Simple"]		= "https://fr.search.yahoo.com/search?p=@ITEMID@"
		},
		["itIT"] = { --Italian (Italy)
			["Title"]		= "Yahoo (semplice)",
			["Simple"]		= "https://it.search.yahoo.com/search?p=@ITEMID@"
		},
		["koKR"] = { --Korean (Korea)
			["Title"]		= "Yahoo (단순한)",
			["Simple"]		= "https://kr.search.yahoo.com/search?p=@ITEMID@"
		},
		["ptBR"] = { --Portuguese (Brazil)
			["Title"]		= "Yahoo (simple)",
			["Simple"]		= "https://br.search.yahoo.com/search?p=@ITEMID@"
		},
		["ruRU"] = { --Russian (Russia)
			["Title"]		= "Yahoo (простой)",
			["Simple"]		= "https://ru.search.yahoo.com/search?p=@ITEMID@"
		},
		["zhCN"] = { --Chinese (Simplified, PRC)
			["Title"]		= "Yahoo (简单)",
			["Simple"]		= "https://search.yahoo.com/search?p=@ITEMID@"
		},
		["zhTW"] = { --Chinese (Traditional, Taiwan)
			["Title"]		= "Yahoo (簡單)",
			["Simple"]		= "https://tw.search.yahoo.com/search?p=@ITEMID@"
		}
	},--yahoo

	["wowhead"] = { --Wowhead (english, german, spanish/mexico, french, italian, korean, portugese, russian, chinese)
		["enUS"] = { --English (United Kingdom) and English (United States) **Default locales**
			["Title"]		= "Wowhead (simple & advanced)",				--Title in dropdown menu
			["Simple"]		= "https://www.wowhead.com/?search=@ITEMID@",	--Simple search HTTPS link
			["ForceHTTPS"]	= false,										--Boolean. Will override user settings and always use https:// if set to true.
			["Advanced"]	= "item,spell,achievement,currency,faction,quest,garrmission,garrfollower,garrfollower-ship,garrfollower-champion,garrfollowerability,battlepetabil,npc", --Empty string or comma separated list with hyperlinks supported
			["Bonus-Delimiter"]			= ":",								--Delimiter used with bonus data
			["Advanced-item"]			= "https://www.wowhead.com/item=@ITEMID@",
			["Advanced-item-bonus"]		= "https://www.wowhead.com/item=@ITEMID@&bonus=@BONUS@",
			["Advanced-spell"]			= "https://www.wowhead.com/spell=@ITEMID@",
			["Advanced-achievement"]	= "https://www.wowhead.com/achievement=@ITEMID@",
			["Advanced-currency"]		= "https://www.wowhead.com/currency=@ITEMID@",
			["Advanced-faction"]		= "https://www.wowhead.com/faction=@ITEMID@",
			["Advanced-quest"]			= "https://www.wowhead.com/quest=@ITEMID@",
			["Advanced-garrmission"]			= "https://www.wowhead.com/mission=@ITEMID@",
			["Advanced-garrfollower"]			= "https://www.wowhead.com/follower=@ITEMID@",
			["Advanced-garrfollower-ship"]		= "https://www.wowhead.com/ship=@ITEMID@",		--wowhead uses /ship= for WOD, Garrison Shipyard ships. Same itemlink type tho.
			["Advanced-garrfollower-champion"]	= "https://www.wowhead.com/champion=@ITEMID@", 	--wowhead uses /champion= for Legion, Order Hall champions but /follower= for WOD Garrison Followers. Same itemlink type tho.
			["Advanced-garrfollowerability"]	= "https://www.wowhead.com/garrisonability=@ITEMID@",
			["Advanced-battlepetabil"]	= "https://www.wowhead.com/petability=@ITEMID@",
			["Advanced-npc"]			= "https://www.wowhead.com/npc=@ITEMID@"
		},--enUS
		["deDE"] = { --German (Germany)
			["Title"]		= "Wowhead (einfach & fortgeschritten)",
			["Simple"]		= "https://de.wowhead.com/?search=@ITEMID@",
			["Advanced-item"]			= "https://de.wowhead.com/item=@ITEMID@",
			["Advanced-item-bonus"]		= "https://de.wowhead.com/item=@ITEMID@&bonus=@BONUS@",
			["Advanced-spell"]			= "https://de.wowhead.com/spell=@ITEMID@",
			["Advanced-achievement"]	= "https://de.wowhead.com/achievement=@ITEMID@",
			["Advanced-currency"]		= "https://de.wowhead.com/currency=@ITEMID@",
			["Advanced-faction"]		= "https://de.wowhead.com/faction=@ITEMID@",
			["Advanced-quest"]			= "https://de.wowhead.com/quest=@ITEMID@",
			["Advanced-garrmission"]			= "https://de.wowhead.com/mission=@ITEMID@",
			["Advanced-garrfollower"]			= "https://de.wowhead.com/follower=@ITEMID@",
			["Advanced-garrfollower-ship"]		= "https://de.wowhead.com/ship=@ITEMID@",
			["Advanced-garrfollower-champion"]	= "https://de.wowhead.com/champion=@ITEMID@",
			["Advanced-garrfollowerability"]	= "https://de.wowhead.com/garrisonability=@ITEMID@",
			["Advanced-battlepetabil"]	= "https://de.wowhead.com/petability=@ITEMID@",
			["Advanced-npc"]			= "https://de.wowhead.com/npc=@ITEMID@"
		},
		["esES"] = { --Spanish (Spain)
			["Title"]		= "Wowhead (simple & avanzado)",
			["Simple"]		= "https://es.wowhead.com/?search=@ITEMID@",
			["Advanced-item"]			= "https://es.wowhead.com/item=@ITEMID@",
			["Advanced-item-bonus"]		= "https://es.wowhead.com/item=@ITEMID@&bonus=@BONUS@",
			["Advanced-spell"]			= "https://es.wowhead.com/spell=@ITEMID@",
			["Advanced-achievement"]	= "https://es.wowhead.com/achievement=@ITEMID@",
			["Advanced-currency"]		= "https://es.wowhead.com/currency=@ITEMID@",
			["Advanced-faction"]		= "https://es.wowhead.com/faction=@ITEMID@",
			["Advanced-quest"]			= "https://es.wowhead.com/quest=@ITEMID@",
			["Advanced-garrmission"]			= "https://es.wowhead.com/mission=@ITEMID@",
			["Advanced-garrfollower"]			= "https://es.wowhead.com/follower=@ITEMID@",
			["Advanced-garrfollower-ship"]		= "https://es.wowhead.com/ship=@ITEMID@",
			["Advanced-garrfollower-champion"]	= "https://es.wowhead.com/champion=@ITEMID@",
			["Advanced-garrfollowerability"]	= "https://es.wowhead.com/garrisonability=@ITEMID@",
			["Advanced-battlepetabil"]	= "https://es.wowhead.com/petability=@ITEMID@",
			["Advanced-npc"]			= "https://es.wowhead.com/npc=@ITEMID@"
		},
		["esMX"] = { --Spanish (Mexico)
			["Title"]		= "Wowhead (simple & avanzado)",
			["Simple"]		= "https://es.wowhead.com/?search=@ITEMID@",
			["Advanced-item"]			= "https://es.wowhead.com/item=@ITEMID@",
			["Advanced-item-bonus"]		= "https://es.wowhead.com/item=@ITEMID@&bonus=@BONUS@",
			["Advanced-spell"]			= "https://es.wowhead.com/spell=@ITEMID@",
			["Advanced-achievement"]	= "https://es.wowhead.com/achievement=@ITEMID@",
			["Advanced-currency"]		= "https://es.wowhead.com/currency=@ITEMID@",
			["Advanced-faction"]		= "https://es.wowhead.com/faction=@ITEMID@",
			["Advanced-quest"]			= "https://es.wowhead.com/quest=@ITEMID@",
			["Advanced-garrmission"]			= "https://es.wowhead.com/mission=@ITEMID@",
			["Advanced-garrfollower"]			= "https://es.wowhead.com/follower=@ITEMID@",
			["Advanced-garrfollower-ship"]		= "https://es.wowhead.com/ship=@ITEMID@",
			["Advanced-garrfollower-champion"]	= "https://es.wowhead.com/champion=@ITEMID@",
			["Advanced-garrfollowerability"]	= "https://es.wowhead.com/garrisonability=@ITEMID@",
			["Advanced-battlepetabil"]	= "https://es.wowhead.com/petability=@ITEMID@",
			["Advanced-npc"]			= "https://es.wowhead.com/npc=@ITEMID@"
		},
		["frFR"] = { --French (France)
			["Title"]		= "Wowhead (simple & avancé)",
			["Simple"]		= "https://fr.wowhead.com/?search=@ITEMID@",
			["Advanced-item"]			= "https://fr.wowhead.com/item=@ITEMID@",
			["Advanced-item-bonus"]		= "https://fr.wowhead.com/item=@ITEMID@&bonus=@BONUS@",
			["Advanced-spell"]			= "https://fr.wowhead.com/spell=@ITEMID@",
			["Advanced-achievement"]	= "https://fr.wowhead.com/achievement=@ITEMID@",
			["Advanced-currency"]		= "https://fr.wowhead.com/currency=@ITEMID@",
			["Advanced-faction"]		= "https://fr.wowhead.com/faction=@ITEMID@",
			["Advanced-quest"]			= "https://fr.wowhead.com/quest=@ITEMID@",
			["Advanced-garrmission"]			= "https://fr.wowhead.com/mission=@ITEMID@",
			["Advanced-garrfollower"]			= "https://fr.wowhead.com/follower=@ITEMID@",
			["Advanced-garrfollower-ship"]		= "https://fr.wowhead.com/ship=@ITEMID@",
			["Advanced-garrfollower-champion"]	= "https://fr.wowhead.com/champion=@ITEMID@",
			["Advanced-garrfollowerability"]	= "https://fr.wowhead.com/garrisonability=@ITEMID@",
			["Advanced-battlepetabil"]	= "https://fr.wowhead.com/petability=@ITEMID@",
			["Advanced-npc"]			= "https://fr.wowhead.com/npc=@ITEMID@"
		},
		["itIT"] = { --Italian (Italy)
			["Title"]		= "Wowhead (semplice e avanzato)",
			["Simple"]		= "https://it.wowhead.com/?search=@ITEMID@",
			["Advanced-item"]			= "https://it.wowhead.com/item=@ITEMID@",
			["Advanced-item-bonus"]		= "https://it.wowhead.com/item=@ITEMID@&bonus=@BONUS@",
			["Advanced-spell"]			= "https://it.wowhead.com/spell=@ITEMID@",
			["Advanced-achievement"]	= "https://it.wowhead.com/achievement=@ITEMID@",
			["Advanced-currency"]		= "https://it.wowhead.com/currency=@ITEMID@",
			["Advanced-faction"]		= "https://it.wowhead.com/faction=@ITEMID@",
			["Advanced-quest"]			= "https://it.wowhead.com/quest=@ITEMID@",
			["Advanced-garrmission"]			= "https://it.wowhead.com/mission=@ITEMID@",
			["Advanced-garrfollower"]			= "https://it.wowhead.com/follower=@ITEMID@",
			["Advanced-garrfollower-ship"]		= "https://it.wowhead.com/ship=@ITEMID@",
			["Advanced-garrfollower-champion"]	= "https://it.wowhead.com/champion=@ITEMID@",
			["Advanced-garrfollowerability"]	= "https://it.wowhead.com/garrisonability=@ITEMID@",
			["Advanced-battlepetabil"]	= "https://it.wowhead.com/petability=@ITEMID@",
			["Advanced-npc"]			= "https://it.wowhead.com/npc=@ITEMID@"
		},
		["koKR"] = { --Korean (Korea)
			["Title"]		= "Wowhead (심플 & 고급)",
			["Simple"]		= "https://ko.wowhead.com/?search=@ITEMID@",
			["Advanced-item"]			= "https://ko.wowhead.com/item=@ITEMID@",
			["Advanced-item-bonus"]		= "https://ko.wowhead.com/item=@ITEMID@&bonus=@BONUS@",
			["Advanced-spell"]			= "https://ko.wowhead.com/spell=@ITEMID@",
			["Advanced-achievement"]	= "https://ko.wowhead.com/achievement=@ITEMID@",
			["Advanced-currency"]		= "https://ko.wowhead.com/currency=@ITEMID@",
			["Advanced-faction"]		= "https://ko.wowhead.com/faction=@ITEMID@",
			["Advanced-quest"]			= "https://ko.wowhead.com/quest=@ITEMID@",
			["Advanced-garrmission"]			= "https://ko.wowhead.com/mission=@ITEMID@",
			["Advanced-garrfollower"]			= "https://ko.wowhead.com/follower=@ITEMID@",
			["Advanced-garrfollower-ship"]		= "https://ko.wowhead.com/ship=@ITEMID@",
			["Advanced-garrfollower-champion"]	= "https://ko.wowhead.com/champion=@ITEMID@",
			["Advanced-garrfollowerability"]	= "https://ko.wowhead.com/garrisonability=@ITEMID@",
			["Advanced-battlepetabil"]	= "https://ko.wowhead.com/petability=@ITEMID@",
			["Advanced-npc"]			= "https://ko.wowhead.com/npc=@ITEMID@"
		},
		["ptBR"] = { --Portuguese (Brazil)
			["Title"]		= "Wowhead (simples & avançado)",
			["Simple"]		= "https://pt.wowhead.com/?search=@ITEMID@",
			["Advanced-item"]			= "https://pt.wowhead.com/item=@ITEMID@",
			["Advanced-item-bonus"]		= "https://pt.wowhead.com/item=@ITEMID@&bonus=@BONUS@",
			["Advanced-spell"]			= "https://pt.wowhead.com/spell=@ITEMID@",
			["Advanced-achievement"]	= "https://pt.wowhead.com/achievement=@ITEMID@",
			["Advanced-currency"]		= "https://pt.wowhead.com/currency=@ITEMID@",
			["Advanced-faction"]		= "https://pt.wowhead.com/faction=@ITEMID@",
			["Advanced-quest"]			= "https://pt.wowhead.com/quest=@ITEMID@",
			["Advanced-garrmission"]			= "https://pt.wowhead.com/mission=@ITEMID@",
			["Advanced-garrfollower"]			= "https://pt.wowhead.com/follower=@ITEMID@",
			["Advanced-garrfollower-ship"]		= "https://pt.wowhead.com/ship=@ITEMID@",
			["Advanced-garrfollower-champion"]	= "https://pt.wowhead.com/champion=@ITEMID@",
			["Advanced-garrfollowerability"]	= "https://pt.wowhead.com/garrisonability=@ITEMID@",
			["Advanced-battlepetabil"]	= "https://pt.wowhead.com/petability=@ITEMID@",
			["Advanced-npc"]			= "https://pt.wowhead.com/npc=@ITEMID@"
		},
		["ruRU"] = { --Russian (Russia)
			["Title"]		= "Wowhead (простой & продвинутый)",
			["Simple"]		= "https://ru.wowhead.com/?search=@ITEMID@",
			["Advanced-item"]			= "https://ru.wowhead.com/item=@ITEMID@",
			["Advanced-item-bonus"]		= "https://ru.wowhead.com/item=@ITEMID@&bonus=@BONUS@",
			["Advanced-spell"]			= "https://ru.wowhead.com/spell=@ITEMID@",
			["Advanced-achievement"]	= "https://ru.wowhead.com/achievement=@ITEMID@",
			["Advanced-currency"]		= "https://ru.wowhead.com/currency=@ITEMID@",
			["Advanced-faction"]		= "https://ru.wowhead.com/faction=@ITEMID@",
			["Advanced-quest"]			= "https://ru.wowhead.com/quest=@ITEMID@",
			["Advanced-garrmission"]			= "https://ru.wowhead.com/mission=@ITEMID@",
			["Advanced-garrfollower"]			= "https://ru.wowhead.com/follower=@ITEMID@",
			["Advanced-garrfollower-ship"]		= "https://ru.wowhead.com/ship=@ITEMID@",
			["Advanced-garrfollower-champion"]	= "https://ru.wowhead.com/champion=@ITEMID@",
			["Advanced-garrfollowerability"]	= "https://ru.wowhead.com/garrisonability=@ITEMID@",
			["Advanced-battlepetabil"]	= "https://ru.wowhead.com/petability=@ITEMID@",
			["Advanced-npc"]			= "https://ru.wowhead.com/npc=@ITEMID@"
		},
		["zhCN"] = { --Chinese (Simplified, PRC)
			["Title"]		= "Wowhead 英文数据库 (简单 & 高级)",
			["Simple"]		= "https://cn.wowhead.com/?search=@ITEMID@",
			["Advanced-item"]			= "https://cn.wowhead.com/item=@ITEMID@",
			["Advanced-item-bonus"]		= "https://cn.wowhead.com/item=@ITEMID@&bonus=@BONUS@",
			["Advanced-spell"]			= "https://cn.wowhead.com/spell=@ITEMID@",
			["Advanced-achievement"]	= "https://cn.wowhead.com/achievement=@ITEMID@",
			["Advanced-currency"]		= "https://cn.wowhead.com/currency=@ITEMID@",
			["Advanced-faction"]		= "https://cn.wowhead.com/faction=@ITEMID@",
			["Advanced-quest"]			= "https://cn.wowhead.com/quest=@ITEMID@",
			["Advanced-garrmission"]			= "https://cn.wowhead.com/mission=@ITEMID@",
			["Advanced-garrfollower"]			= "https://cn.wowhead.com/follower=@ITEMID@",
			["Advanced-garrfollower-ship"]		= "https://cn.wowhead.com/ship=@ITEMID@",
			["Advanced-garrfollower-champion"]	= "https://cn.wowhead.com/champion=@ITEMID@",
			["Advanced-garrfollowerability"]	= "https://cn.wowhead.com/garrisonability=@ITEMID@",
			["Advanced-battlepetabil"]	= "https://cn.wowhead.com/petability=@ITEMID@",
			["Advanced-npc"]			= "https://cn.wowhead.com/npc=@ITEMID@"
		},
		["zhTW"] = { --Chinese (Traditional, Taiwan)
			["Title"]		= "Wowhead (簡單 & 先進)";
			--Not supported
		}
	},--wowhead

	["wowdb"] = { --WowDB (english)
		["enUS"] = { --English (United Kingdom) and English (United States) **Default locales**
			["Title"]		= "WowDB.com (simple & advanced)",					--Title in dropdown menu
			["Simple"]		= "https://www.wowdb.com/search?search=@ITEMID@",	--Simple search HTTPS link
			["ForceHTTPS"]	= false,											--Boolean. Will override user settings and always use https:// if set to true.
			["Advanced"]	= "item,spell,achievement,currency,faction,quest,garrmission,garrfollower,garrfollower-ship,garrfollower-champion,garrfollowerability,battlepetabil,npc", --Empty string or comma separated list with hyperlinks supported
			["Bonus-Delimiter"]			= ",",									--Delimiter used with bonus data
			["Advanced-item"]			= "https://www.wowdb.com/items/@ITEMID@",
			["Advanced-item-bonus"]		= "https://www.wowdb.com/items/@ITEMID@?bonusIDs=@BONUS@",
			["Advanced-spell"]			= "https://www.wowdb.com/spells/@ITEMID@",
			["Advanced-achievement"]	= "https://www.wowdb.com/achievements/@ITEMID@",
			["Advanced-currency"]		= "https://www.wowdb.com/currencies/@ITEMID@",
			["Advanced-faction"]		= "https://www.wowdb.com/factions/@ITEMID@",
			["Advanced-quest"]			= "https://www.wowdb.com/quests/@ITEMID@",
			["Advanced-garrmission"]			= "https://www.wowdb.com/garrison/missions/@ITEMID@",
			["Advanced-garrfollower"]			= "https://www.wowdb.com/garrison/followers/@ITEMID@",
			["Advanced-garrfollower-ship"]		= "https://www.wowdb.com/garrison/ships/@ITEMID@",
			["Advanced-garrfollower-champion"]	= "https://www.wowdb.com/garrison/followers/@ITEMID@",
			["Advanced-garrfollowerability"]= "https://www.wowdb.com/garrison/abilities/@ITEMID@",
			["Advanced-battlepetabil"]	= "https://www.wowdb.com/pet-abilities/@ITEMID@",
			["Advanced-npc"]			= "http://www.wowdb.com/npcs/@ITEMID@"
		},--enUS
		["deDE"] = { --German (Germany)
			["Title"]		= "WowDB.com (einfach & fortgeschritten)"
			--Not supported
		},
		["esES"] = { --Spanish (Spain)
			["Title"]		= "WowDB.com (simple & avanzado)"
			--Not supported
		},
		["esMX"] = { --Spanish (Mexico)
			["Title"]		= "WowDB.com (simple & avanzado)"
			--Not supported
		},
		["frFR"] = { --French (France)
			["Title"]		= "WowDB.com (simple & avancé)"
			--Not supported
		},
		["itIT"] = { --Italian (Italy)
			["Title"]		= "WowDB.com (semplice e avanzato)"
			--Not supported
		},
		["koKR"] = { --Korean (Korea)
			["Title"]		= "WowDB.com (심플 & 고급)"
			--Not supported
		},
		["ptBR"] = { --Portuguese (Brazil)
			["Title"]		= "WowDB.com (simples & avançado)"
			--Not supported
		},
		["ruRU"] = { --Russian (Russia)
			["Title"]		= "WowDB.com (простой & продвинутый)"
			--Not supported
		},
		["zhCN"] = { --Chinese (Simplified, PRC)
			["Title"]		= "WowDB 英文数据库 (简单 & 高级)"
			--Will use default enUS values
		},
		["zhTW"] = { --Chinese (Traditional, Taiwan)
			["Title"]		= "WowDB.com (簡單 & 先進)"
			--Not supported
		}
	},--wowdb

	["buffed.de"] = { --Buffed.de (only HTTP, english, german, russian)
		["enUS"] = { --English (United Kingdom) and English (United States) **Default locales**
			["Title"]		= "Buffed.de (simple & advanced)",				--Title in dropdown menu
			["Simple"]		= "http://wowdata.getbuffed.com/?f=@ITEMID@",	--Simple search HTTPS link
			["ForceHTTPS"]	= false,										--Boolean. Will override user settings and always use https:// if set to true.
			["Advanced"]	= "item,spell,achievement,currency,faction,quest,npc",	--Empty string or comma separated list with hyperlinks supported
			["Advanced-item"]			= "http://wowdata.getbuffed.com/?i=@ITEMID@",
			["Advanced-spell"]			= "http://wowdata.getbuffed.com/?s=@ITEMID@",
			["Advanced-achievement"]	= "http://wowdata.getbuffed.com/?a=@ITEMID@",
			["Advanced-currency"]		= "http://wowdata.getbuffed.com/currency/x-@ITEMID@",
			["Advanced-faction"]		= "http://wowdata.getbuffed.com/faction/x-@ITEMID@",
			["Advanced-quest"]			= "http://wowdata.getbuffed.com/?q=@ITEMID@",
			["Advanced-npc"]			= "http://wowdata.getbuffed.com/?n=@ITEMID@"
		},--enUS
		["deDE"] = { --German (Germany)
			["Title"]		= "Buffed.de (einfach & fortgeschritten)",
			["Simple"]		= "http://wowdata.buffed.de/?f=@ITEMID@",
			["Advanced-item"]			= "http://wowdata.buffed.de/?i=@ITEMID@",
			["Advanced-spell"]			= "http://wowdata.buffed.de/?s=@ITEMID@",
			["Advanced-achievement"]	= "http://wowdata.buffed.de/?a=@ITEMID@",
			["Advanced-currency"]		= "http://wowdata.buffed.de/currency/x-@ITEMID@",
			["Advanced-faction"]		= "http://wowdata.buffed.de/faction/x-@ITEMID@",
			["Advanced-quest"]			= "http://wowdata.buffed.de/?q=@ITEMID@",
			["Advanced-npc"]			= "http://wowdata.buffed.de/?n=@ITEMID@"
		},
		["esES"] = { --Spanish (Spain)
			["Title"]		= "Buffed.de (simple & avanzado)"
			--Not supported
		},
		["esMX"] = { --Spanish (Mexico)
			["Title"]		= "Buffed.de (simple & avanzado)"
			--Not supported
		},
		["frFR"] = { --French (France)
			["Title"]		= "Buffed.de (simple & avancé)"
			--Not supported
		},
		["itIT"] = { --Italian (Italy)
			["Title"]		= "Buffed.de (semplice e avanzato)"
			--Not supported
		},
		["koKR"] = { --Korean (Korea)
			["Title"]		= "Buffed.de (심플 & 고급)"
			--Not supported
		},
		["ptBR"] = { --Portuguese (Brazil)
			["Title"]		= "Buffed.de (simples & avançado)"
			--Not supported
		},
		["ruRU"] = { --Russian (Russia)
			["Title"]		= "Buffed.de (простой & продвинутый)",
			["Simple"]		= "http://wowdata.buffed.ru/?f=@ITEMID@",
			["Advanced-item"]			= "http://wowdata.buffed.ru/?i=@ITEMID@",
			["Advanced-spell"]			= "http://wowdata.buffed.ru/?s=@ITEMID@",
			["Advanced-achievement"]	= "http://wowdata.buffed.ru/?a=@ITEMID@",
			["Advanced-currency"]		= "http://wowdata.buffed.ru/currency/x-@ITEMID@",
			["Advanced-faction"]		= "http://wowdata.buffed.ru/faction/x-@ITEMID@",
			["Advanced-quest"]			= "http://wowdata.buffed.ru/?q=@ITEMID@",
			["Advanced-npc"]			= "http://wowdata.buffed.ru/?n=@ITEMID@"
		},
		["zhCN"] = { --Chinese (Simplified, PRC)
			["Title"]		= "Buffed.de (简单 & 高级)"
			--Not supported
		},
		["zhTW"] = { --Chinese (Traditional, Taiwan)
			["Title"]		= "Buffed.de (簡單 & 先進)"
			--Not supported
		}
	},--buffed.de

	["judgehype"] = { --Judgehype (only HTTP, french)
		["enUS"] = { --English (United Kingdom) and English (United States) **Default locales**
			["Title"]		= "JudgeHype (simple & advanced)",								--Title in dropdown menu
			["Simple"]		= "http://worldofwarcraft.judgehype.com/db-resultat/@ITEMID@",	--Simple search HTTPS link
			["ForceHTTPS"]	= false,														--Boolean. Will override user settings and always use https:// if set to true.
			["Advanced"]	= "item,spell,achievement,quest,npc",							--Empty string or comma separated list with hyperlinks supported
			["Advanced-item"]			= "http://worldofwarcraft.judgehype.com/objet/@ITEMID@",
			["Advanced-spell"]			= "http://worldofwarcraft.judgehype.com/spell/@ITEMID@",
			["Advanced-achievement"]	= "http://worldofwarcraft.judgehype.com/hautfait/@ITEMID@",
			["Advanced-quest"]			= "http://worldofwarcraft.judgehype.com/quete/@ITEMID@",
			["Advanced-npc"]			= "http://worldofwarcraft.judgehype.com/pnj/@ITEMID@"
		},--enUS
		["deDE"] = { --German (Germany)
			["Title"]		= "JudgeHype (einfach & fortgeschritten)"
			--Not supported
		},
		["esES"] = { --Spanish (Spain)
			["Title"]		= "JudgeHype (simple & avanzado)"
			--Not supported
		},
		["esMX"] = { --Spanish (Mexico)
			["Title"]		= "JudgeHype (simple & avanzado)"
			--Not supported
		},
		["frFR"] = { --French (France)
			["Title"]		= "JudgeHype (simple & avancé)"
			--This website is in French only. All links listed under enUS
		},
		["itIT"] = { --Italian (Italy)
			["Title"]		= "JudgeHype (semplice e avanzato)"
			--Not supported
		},
		["koKR"] = { --Korean (Korea)
			["Title"]		= "JudgeHype (심플 & 고급)"
			--Not supported
		},
		["ptBR"] = { --Portuguese (Brazil)
			["Title"]		= "JudgeHype (simples & avançado)"
			--Not supported
		},
		["ruRU"] = { --Russian (Russia)
			["Title"]		= "JudgeHype (простой & продвинутый)"
			--Not supported
		},
		["zhCN"] = { --Chinese (Simplified, PRC)
			["Title"]		= "JudgeHype (简单 & 高级)"
			--Not supported
		},
		["zhTW"] = { --Chinese (Traditional, Taiwan)
			["Title"]		= "JudgeHype (簡單 & 先進)"
			--Not supported
		}
	},--judgehype

	["duckduckgo"] = { --DuckDuckGo --(only HTTPS, english)
		["enUS"] = { --English (United Kingdom) and English (United States) **Default locales**
			["Title"]		= "DuckDuckGo (simple)",				--Title in dropdown menu
			["Simple"]		= "https://duckduckgo.com/?q=@ITEMID@",	--Simple search HTTPS link
			["ForceHTTPS"]	= true,									--Boolean. Will override user settings and always use https:// if set to true.
			["Advanced"]	= ""									--Empty string or comma separated list with hyperlinks supported
		},--enUS
		["deDE"] = { --German (Germany)
			["Title"]		= "DuckDuckGo (einfach)"
			--Not supported
		},
		["esES"] = { --Spanish (Spain)
			["Title"]		= "DuckDuckGo (simple)"
			--Not supported
		},
		["esMX"] = { --Spanish (Mexico)
			["Title"]		= "DuckDuckGo (simple)"
			--Not supported
		},
		["frFR"] = { --French (France)
			["Title"]		= "DuckDuckGo (simple)"
			--Not supported
		},
		["itIT"] = { --Italian (Italy)
			["Title"]		= "DuckDuckGo (semplice)"
			--Not supported
		},
		["koKR"] = { --Korean (Korea)
			["Title"]		= "DuckDuckGo (단순한)"
			--Not supported
		},
		["ptBR"] = { --Portuguese (Brazil)
			["Title"]		= "DuckDuckGo (simple)"
			--Not supported
		},
		["ruRU"] = { --Russian (Russia)
			["Title"]		= "DuckDuckGo (простой)"
			--Not supported
		},
		["zhCN"] = { --Chinese (Simplified, PRC)
			["Title"]		= "DuckDuckGo (简单)"
			--Not supported
		},
		["zhTW"] = { --Chinese (Traditional, Taiwan)
			["Title"]		= "DuckDuckGo (簡單)"
			--Not supported
		}
	},--duckduckgo

	["startpage.com"] = { --Startpage.com --(only HTTPS, english, german, spanish, french, italian, portugese, russian)
		["enUS"] = { --English (United Kingdom) and English (United States) **Default locales**
			["Title"]		= "Startpage.com (simple)",						--Title in dropdown menu
			["Simple"]		= "https://startpage.com/do/search?q=@ITEMID@",	--Simple search HTTPS link
			["ForceHTTPS"]	= true,											--Boolean. Will override user settings and always use https:// if set to true.
			["Advanced"]	= ""											--Empty string or comma separated list with hyperlinks supported
		},--enUS
		["deDE"] = { --German (Germany)
			["Title"]		= "Startpage.com (einfach)",
			["Simple"]		= "https://startpage.com/do/search?lui=deutsch&language=deutsch&query=@ITEMID@"
		},
		["esES"] = { --Spanish (Spain)
			["Title"]		= "Startpage.com (simple)",
			["Simple"]		= "https://startpage.com/do/search?lui=espanol&language=espanol&query=@ITEMID@"
		},
		["esMX"] = { --Spanish (Mexico)
			["Title"]		= "Startpage.com (simple)",
			["Simple"]		= "https://startpage.com/do/search?lui=espanol&language=espanol&query=@ITEMID@"
		},
		["frFR"] = { --French (France)
			["Title"]		= "Startpage.com (simple)",
			["Simple"]		= "https://startpage.com/do/search?lui=francais&language=francais&query=@ITEMID@"
		},
		["itIT"] = { --Italian (Italy)
			["Title"]		= "Startpage.com (semplice)",
			["Simple"]		= "https://startpage.com/do/search?lui=italiano&language=italiano&query=@ITEMID@"
		},
		["koKR"] = { --Korean (Korea)
			["Title"]		= "Startpage.com (단순한)"
			--Not supported
		},
		["ptBR"] = { --Portuguese (Brazil)
			["Title"]		= "Startpage.com (simple)",
			["Simple"]		= "https://startpage.com/do/search?lui=portugues&language=portugues&query=@ITEMID@"
		},
		["ruRU"] = { --Russian (Russia)
			["Title"]		= "Startpage.com (простой)",
			["Simple"]		= "https://startpage.com/do/search?lui=&language=russian&query=@ITEMID@"
		},
		["zhCN"] = { --Chinese (Simplified, PRC)
			["Title"]		= "Startpage.com (简单)"
			--Not supported
		},
		["zhTW"] = { --Chinese (Traditional, Taiwan)
			["Title"]		= "Startpage.com (簡單)"
			--Not supported
		}
	},--startpage.com

	["baidu"] = { --Baidu --(simple, chinese)
		["enUS"] = { --English (United Kingdom) and English (United States) **Default locales**
			["Title"]		= "Baidu (simple)",								--Title in dropdown menu
			["Simple"]		= "https://www.baidu.com/s?wd=@ITEMID@",		--Simple search HTTPS link
			["ForceHTTPS"]	= false,										--Boolean. Will override user settings and always use https:// if set to true.
			["Advanced"]	= ""											--Empty string or comma separated list with hyperlinks supported
		},--enUS
		["deDE"] = { --German (Germany)
			["Title"]		= "Baidu (einfach)"
			--Not supported
		},
		["esES"] = { --Spanish (Spain)
			["Title"]		= "Baidu (simple)"
			--Not supported
		},
		["esMX"] = { --Spanish (Mexico)
			["Title"]		= "Baidu (simple)"
			--Not supported
		},
		["frFR"] = { --French (France)
			["Title"]		= "Baidu (simple)"
			--Not supported
		},
		["itIT"] = { --Italian (Italy)
			["Title"]		= "Baidu (semplice)"
			--Not supported
		},
		["koKR"] = { --Korean (Korea)
			["Title"]		= "Baidu (단순한)"
			--Not supported
		},
		["ptBR"] = { --Portuguese (Brazil)
			["Title"]		= "Baidu (simple)"
			--Not supported
		},
		["ruRU"] = { --Russian (Russia)
			["Title"]		= "Baidu (простой)"
			--Not supported
		},
		["zhCN"] = { --Chinese (Simplified, PRC)
			["Title"]		= "Baidu (简单)"
			--This website is in Chinese only. All links listed under enUS
		},
		["zhTW"] = { --Chinese (Traditional, Taiwan)
			["Title"]		= "Baidu (簡單)"
			--This website is in Chinese only. All links listed under enUS
		}
	}--baidu

	--[[
	--2017-May: Blizzard changed the website armory pages to a new design.
	--			The armory no longer lists ingame items. Also, simple search provides really no useful data except for when searching for a player name.
	--			'eu.battle.net/wow/en/' now redirects to 'worldofwarcraft.com/en-gb/' and so on. Conversion to the new domain is a simple string-replacement except for maybe Portugese that has 'pt-pt' for EU and 'pt-br' for US.
	--			Since these sites provide no useful info, i removed them from the search-provider list
	["eu.battle.net"] = { --eu.battle.net (english, german, spanish, french, italian, russian, portugese)
		["enUS"] = { --English (United Kingdom) and English (United States) **Default locales**
			["Title"]		= "eu.battle.net (simple)",							--Title in dropdown menu
			["Simple"]		= "https://eu.battle.net/wow/en/search?q=@ITEMID@",	--Simple search HTTPS link
			["ForceHTTPS"]	= false,											--Boolean. Will override user settings and always use https:// if set to true.
			["Advanced"]	= "item",											--Empty string or comma separated list with hyperlinks supported
			["Advanced-item"] = "https://eu.battle.net/wow/en/item/@ITEMID@"
		},--enUS
		["deDE"] = { --German (Germany)
			["Title"]		= "eu.battle.net (einfach)",
			["Simple"]		= "https://eu.battle.net/wow/de-de/search?q=@ITEMID@",
			["Advanced-item"] = "https://eu.battle.net/wow/de-de/item/@ITEMID@"
		},
		["esES"] = { --Spanish (Spain)
			["Title"]		= "eu.battle.net (simple)",
			["Simple"]		= "https://eu.battle.net/wow/es-es/search?q=@ITEMID@",
			["Advanced-item"] = "https://eu.battle.net/wow/es-es/item/@ITEMID@"
		},
		["esMX"] = { --Spanish (Mexico)
			["Title"]		= "eu.battle.net (simple)"
			--Not supported
		},
		["frFR"] = { --French (France)
			["Title"]		= "eu.battle.net (simple)",
			["Simple"]		= "https://eu.battle.net/wow/fr-fr/search?q=@ITEMID@",
			["Advanced-item"] = "https://eu.battle.net/wow/fr-fr/item/@ITEMID@"
		},
		["itIT"] = { --Italian (Italy)
			["Title"]		= "eu.battle.net (semplice)",
			["Simple"]		= "https://eu.battle.net/wow/it-it/search?q=@ITEMID@",
			["Advanced-item"] = "https://eu.battle.net/wow/it-it/item/@ITEMID@"
		},
		["koKR"] = { --Korean (Korea)
			["Title"]		= "eu.battle.net (단순한)"
			--Not supported
		},
		["ptBR"] = { --Portuguese (Brazil)
			["Title"]		= "eu.battle.net (simples)",
			["Simple"]		= "https://eu.battle.net/wow/pt-pt/search?q=@ITEMID@",
			["Advanced-item"] = "https://eu.battle.net/wow/pt-pt/item/@ITEMID@"
		},
		["ruRU"] = { --Russian (Russia)
			["Title"]		= "eu.battle.net (простой)",
			["Simple"]		= "https://eu.battle.net/wow/ru-ru/search?q=@ITEMID@",
			["Advanced-item"] = "https://eu.battle.net/wow/ru-ru/item/@ITEMID@"
		},
		["zhCN"] = { --Chinese (Simplified, PRC)
			["Title"]		= "eu.battle.net (简单)"
			--Not supported
		},
		["zhTW"] = { --Chinese (Traditional, Taiwan)
			["Title"]		= "eu.battle.net (簡單)"
			--Not supported
		}
	},--eu.battle.net
	["us.battle.net"] = { --us.battle.net (us, mexico, brazil)
		["enUS"] = { --English (United Kingdom) and English (United States) **Default locales**
			["Title"]		= "us.battle.net (simple)",								--Title in dropdown menu
			["Simple"]		= "https://us.battle.net/wow/en-us/search?q=@ITEMID@",	--Simple search HTTPS link
			["ForceHTTPS"]	= false,												--Boolean. Will override user settings and always use https:// if set to true.
			["Advanced"]	= "item",												--Empty string or comma separated list with hyperlinks supported
			["Advanced-item"] = "https://us.battle.net/wow/en-us/item/@ITEMID@"
		},--enUS
		["deDE"] = { --German (Germany)
			["Title"]		= "us.battle.net (einfach)"
			--Not supported
		},
		["esES"] = { --Spanish (Spain)
			["Title"]		= "us.battle.net (simple)"
			--Not supported
		},
		["esMX"] = { --Spanish (Mexico)
			["Title"]		= "us.battle.net (simple)",
			["Simple"]		= "https://us.battle.net/wow/es-mx/search?q=@ITEMID@",
			["Advanced-item"] = "https://us.battle.net/wow/es-mx/item/@ITEMID@"
		},
		["frFR"] = { --French (France)
			["Title"]		= "us.battle.net (simple)"
			--Not supported
		},
		["itIT"] = { --Italian (Italy)
			["Title"]		= "us.battle.net (semplice)"
			--Not supported
		},
		["koKR"] = { --Korean (Korea)
			["Title"]		= "us.battle.net (단순한)"
			--Not supported
		},
		["ptBR"] = { --Portuguese (Brazil)
			["Title"]		= "us.battle.net (simples)",
			["Simple"]		= "https://us.battle.net/wow/pt-br/search?q=@ITEMID@",
			["Advanced-item"] = "https://us.battle.net/wow/pt-br/item/@ITEMID@"
		},
		["ruRU"] = { --Russian (Russia)
			["Title"]		= "us.battle.net (простой)"
			--Not supported
		},
		["zhCN"] = { --Chinese (Simplified, PRC)
			["Title"]		= "us.battle.net (简单)"
			--Not supported
		},
		["zhTW"] = { --Chinese (Traditional, Taiwan)
			["Title"]		= "us.battle.net (簡單)"
			--Not supported
		}
	},--us.battle.net
	["asia.battle.net"] = { --kr.battle.net  (some HTTP, southeast asia, korean, china, taiwan)
		["enUS"] = { --English (United Kingdom) and English (United States) **Default locales**
			["Title"]		= "battle.net - Southeast Asia (simple)",				--Title in dropdown menu
			["Simple"]		= "https://sea.battle.net/wow/en-us/search?q=@ITEMID@",	--Simple search HTTPS link
			["ForceHTTPS"]	= false,												--Boolean. Will override user settings and always use https:// if set to true.
			["Advanced"]	= "item",												--Empty string or comma separated list with hyperlinks supported
			["Advanced-item"] = "https://sea.battle.net/wow/en-us/item/@ITEMID@"
		},--enUS
		["deDE"] = { --German (Germany)
			["Title"]		= "sea.battle.net (einfach)"
			--Not supported
		},
		["esES"] = { --Spanish (Spain)
			["Title"]		= "sea.battle.net (simple)"
			--Not supported
		},
		["esMX"] = { --Spanish (Mexico)
			["Title"]		= "sea.battle.net (simple)"
			--Not supported
		},
		["frFR"] = { --French (France)
			["Title"]		= "sea.battle.net (simple)"
			--Not supported
		},
		["itIT"] = { --Italian (Italy)
			["Title"]		= "sea.battle.net (semplice)"
			--Not supported
		},
		["koKR"] = { --Korean (Korea)
			["Title"]		= "kr.battle.net (심플)",
			["Simple"]		= "https://kr.battle.net/wow/ko-kr/search?q=@ITEMID@",
			["Advanced-item"] = "https://kr.battle.net/wow/ko-kr/item/@ITEMID@"
		},
		["ptBR"] = { --Portuguese (Brazil)
			["Title"]		= "sea.battle.net (simples)"
			--Not supported
		},
		["ruRU"] = { --Russian (Russia)
			["Title"]		= "sea.battle.net (простой)"
			--Not supported
		},
		["zhCN"] = { --Chinese (Simplified, PRC)
			["Title"]		= "battlenet.com.cn (简单)";
			["Simple"]		= "http://battlenet.com.cn/wow/zh-cn/search?q=@ITEMID@", --only HTTP
			["Advanced-item"] = "http://battlenet.com.cn/wow/zh-cn/item/@ITEMID@"
		},
		["zhTW"] = { --Chinese (Traditional, Taiwan)
			["Title"]		= "tw.battle.net (簡單)";
			["Simple"]		= "https://tw.battle.net/wow/zh-tw/search?q=@ITEMID@",
			["Advanced-item"] = "https://tw.battle.net/wow/zh-tw/item/@ITEMID@"
		}
	},--asia.battle.net
--]]--
}--CONST_Provider


--[[Code used for BETA/PTR server
if (IsTestBuild() == true) then
	--Override links for wowhead.enUS with different links if it's a testbuild
	CONST_Provider["wowhead"]["enUS"] = { --English (United Kingdom) and English (United States) **Default locales**
		["Title"]		= "PTR Wowhead (simple & advanced)",			--Title in dropdown menu
		["Simple"]		= "https://ptr.wowhead.com/?search=@ITEMID@",	--Simple search HTTPS link
		["ForceHTTPS"]	= false,										--Boolean. Will override user settings and always use https:// if set to true.
		["Advanced"]	= "item,spell,achievement,currency,faction,quest,garrmission,garrfollower,garrfollowerability,battlepetabil,npc", --Empty string or comma separated list with hyperlinks supported
		["Bonus-Delimiter"]			= ":",								--Delimiter used with bonus data
		["Advanced-item"]			= "https://ptr.wowhead.com/item=@ITEMID@",
		["Advanced-item-bonus"]		= "https://ptr.wowhead.com/item=@ITEMID@&bonus=@BONUS@",
		["Advanced-spell"]			= "https://ptr.wowhead.com/spell=@ITEMID@",
		["Advanced-achievement"]	= "https://ptr.wowhead.com/achievement=@ITEMID@",
		["Advanced-currency"]		= "https://ptr.wowhead.com/currency=@ITEMID@",
		["Advanced-faction"]		= "https://ptr.wowhead.com/faction=@ITEMID@",
		["Advanced-quest"]			= "https://ptr.wowhead.com/quest=@ITEMID@",
		["Advanced-garrmission"]	= "https://ptr.wowhead.com/mission=@ITEMID@",
		["Advanced-garrfollower"]	= "https://ptr.wowhead.com/follower=@ITEMID@",
		["Advanced-garrfollowerability"] = "https://ptr.wowhead.com/garrisonability=@ITEMID@",
		["Advanced-battlepetabil"]	= "https://ptr.wowhead.com/petability=@ITEMID@",
		["Advanced-npc"]			= "https://ptr.wowhead.com/npc=@ITEMID@"
	};--enUS

	--Override links for wowdb.enUS with different links if it's a testbuild
	CONST_Provider["wowdb"]["enUS"] = { --English (United Kingdom) and English (United States) **Default locales**
		["Title"]		= "BETA WowDB.com (simple & advanced)",				--Title in dropdown menu
		["Simple"]		= "https://beta.wowdb.com/search?search=@ITEMID@",	--Simple search HTTPS link
		["ForceHTTPS"]	= false,											--Boolean. Will override user settings and always use https:// if set to true.
		["Advanced"]	= "item,spell,achievement,currency,faction,quest,garrmission,garrfollower,garrfollowerability,battlepetabil,npc", --Empty string or comma separated list with hyperlinks supported
		["Bonus-Delimiter"]			= ",",									--Delimiter used with bonus data
		["Advanced-item"]			= "https://beta.wowdb.com/items/@ITEMID@",
		["Advanced-item-bonus"]		= "https://beta.wowdb.com/items/@ITEMID@?bonusIDs=@BONUS@",
		["Advanced-spell"]			= "https://beta.wowdb.com/spells/@ITEMID@",
		["Advanced-achievement"]	= "https://beta.wowdb.com/achievements/@ITEMID@",
		["Advanced-currency"]		= "https://beta.wowdb.com/currencies/@ITEMID@",
		["Advanced-faction"]		= "https://beta.wowdb.com/factions/@ITEMID@",
		["Advanced-quest"]			= "https://beta.wowdb.com/quests/@ITEMID@",
		["Advanced-garrmission"]		= "https://beta.wowdb.com/garrison/missions/@ITEMID@",
		["Advanced-garrfollower"]		= "https://beta.wowdb.com/garrison/followers/@ITEMID@",
		["Advanced-garrfollowerability"]= "https://beta.wowdb.com/garrison/abilities/@ITEMID@",
		["Advanced-battlepetabil"]	= "https://beta.wowdb.com/pet-abilities/@ITEMID@",
		["Advanced-npc"]			= "http://beta.wowdb.com/npcs/@ITEMID@"
	};--enUS
end--if IsTestBuild()]]


--####################################################################################
--####################################################################################
--Public
--####################################################################################


--Initalizes the provider table structure that we will use later
function SearchProvider:InitializeProvider(booEnglish)
	if (booEnglish ~= true) then booEnglish = false; end --Boolean

	local L = cache_GameLocale; --Localization to the current game-client language
	if (L == "enGB") then L = "enUS"; end
	if (booEnglish) then L = "enUS"; end --Always use english search providers.
	if (cache_Provider ~= nil and cache_Provider_Locale == L) then return cache_Provider; end --If the table is cached from earlier call then return that
	local res = {};
	for providerKey,locale in pairs(CONST_Provider) do --key = "provider uniqe name", value = table with localized provider data
		providerKey = strlower(providerKey);
		res[providerKey] = {};

		for k,v in pairs(locale.enUS) do
			if not locale[L][k] or locale[L][k] == false then
				res[providerKey][k] = locale.enUS[k]; --We use the default enUS localization strings if nothing else is defined
			else
				res[providerKey][k] = locale[L][k];
			end--if
		end--for locale.enUS
	end--for CONST_Provider

	cache_Provider = res; --Store for later
	cache_Provider_Locale = L;
	return cache_Provider;
end


--Returns true/false if a provider exists at all
function SearchProvider:ProviderExists(strProvider)
	if (strProvider == nil) then return false; end
	strProvider = strlower(tostring(strProvider));

	if (CONST_Provider[strProvider] ~= nil) then return true; end
	return false;
end


--Returns nil or the data for a given search provider ("all" == return all providers).
function SearchProvider:GetProvider(strProvider)
	if (cache_Provider == nil) then error("Search provider table not initalized"); end

	if (strProvider == nil) then return false; end
	strProvider = strlower(tostring(strProvider));
	if (strProvider == "all") then return cache_Provider, CONST_Provider_Sorted; end
	return cache_Provider[strProvider];
end


--####################################################################################
--####################################################################################
