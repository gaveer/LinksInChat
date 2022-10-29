--####################################################################################
--####################################################################################
--Locale
--####################################################################################
--Dependencies: none

local Localization = {
	["enUS"] = { --English (United Kingdom) and English (United States) **Default locales**
		["Translator info"] = "", --Blank for enUS
		--## Title: Links in Chat
		--## Notes: Shows a popup window when clicking web-links in chat.
		--Copy frame
		["CopyFrame Title"] = "Links in Chat",
		["CopyFrame Info1"] = "Press ".. (IsMacClient() and "Cmd-C" or "Ctrl-C") .." to copy the link.",
		["CopyFrame Info2"] = "Press ESC to close window.",
		--Settings frame
		["Settings Title"] = "Links in Chat "..GetAddOnMetadata("LinksInChat", "Version").." ",
		["Settings Info1"] = "Clicking on web-links (http:// or www.) will open a window to copy the link to your clipboard.\nMumble, Teamspeak, Ventrilo, Skype, e-mail and BattleTags are also supported.\nShift-clicking a web link will copy it into chat.\n\nYou can also type '/link' in chat and get a link for your current target or \nmouseover npc/object/item.",
		["Settings Info2"] = "You can also Alt-click hyperlinks (items, spells, etc) in chat to make web-links for them.",
		["Provider Info1"] = "Not all search-providers can do advanced-search, and not all hyperlink-types are supported. \nIn those cases simple-search will be used.",
		["Button Web link color"] = "Web link color...",
		["Check Ignore hyperlinks"] = "Ignore hyperlinks (items, spells, achievement, etc).",
		["Check Extra"] = "Enable Alt-clicking in bank, character frame, auction house, achievement frames, etc.",
		["Check Simple search"] = "Always simple-search (search for hyperlinks only by name and not by spell-Id etc).",
		["Check Use HTTPS"] = "Use HTTPS (recommended) instead of HTTP with search providers.",
		["Check Always English"] = "Always English search providers (changes with game-client language otherwise).",
		["Label Search provider"] = "Search provider for hyperlinks",
		--Auto hide dropdown values
		["Label Hide window after"] = "Hide window after...",
		["Dropdown Options Autohide"] = {
			["none"] = "Don't hide",
			["3sec"] = "3 seconds",
			["5sec"] = "5 seconds",
			["7sec"] = "7 seconds",
			["10sec"] = "10 seconds"
		},
		--[[ ["Dropdown Options KeyModifier"] = {
			["ALT"]		= "ALT",
			["CTRL"]	= "CTRL",
			["SHIFT"]	= "SHIFT"
		}]]--
	},--enUS
	["deDE"] = { --German (Deutsch)
		["Translator info"] = "Translated by pas06 @ Curseforge.", --Last updated: 2016-01-04
		--## Title-deDE: Links in Chat
		--## Notes-deDE: Zeigt beim Klicken auf Chatlinks ein Pop-up-Fenster.
		--Copy frame
		--["CopyFrame Title"] = "Links in Chat",
		["CopyFrame Info1"] = "Drücke ".. (IsMacClient() and "Cmd-C" or "Strg-C") ..", um den Link zu kopieren.",
		["CopyFrame Info2"] = "Drücke ESC, um das Fenster zu schließen.",
		--Settings frame
		--["Settings Title"] = "Links in Chat "..GetAddOnMetadata("LinksInChat", "Version").." ",
		["Settings Info1"] = "Klicks auf Weblinks (http:// or www.) öffnen ein Fenster, um den Link in deine Zwischenablage zu kopieren.\nMumble, Teamspeak, Ventrilo, Skype, E-Mail and BattleTags werden auch unterstützt.\nPer Shift-Klick auf einen Weblink wird dieser in den Chat kopiert.\n\nDu kannst ebenso in den Chat '/link' eingeben, um einen Link für dein aktuelles Ziel oder \nMouseover-NPC/Objekt/Gegenstand zu erhalten.",
		["Settings Info2"] = "Du kannst auch durch Alt-Klick auf Hyperlinks im Chat(Gegenstände, Zauber etc.) Weblinks erzeugen.",
		["Provider Info1"] = "Nicht alle Suchanbieter können eine fortgeschrittene Suche durchführen und nicht alle Hyperlink-Typen werden unterstützt. \nIn diesen Fällen wird eine einfache Suche verwendet.",
		["Button Web link color"] = "Weblink-Farbe...",
		["Check Ignore hyperlinks"] = "Hyperlinks ignorieren (Gegenstände, Zauber, Erfolge etc.).",
		["Check Extra"] = "Alt-Klick im Bank-, Charakterfenster, Auktionshaus, Erfolgsfenster etc. aktivieren.",
		["Check Simple search"] = "Nur einfache Suche (Sucht nach Hyperlinks nur per Namen und nicht per Zauber-ID etc.)",
		["Check Use HTTPS"] = "HTTS (empfohlen) anstatt HTTP bei der Kommunikation mit Suchanbietern verwenden.",
		["Check Always English"] = "Immer Englische Suchanbieter verwenden (andernfalls wird die Sprache des Spiels verwendet).",
		["Label Search provider"] = "Suchanbieter für Hyperlinks",
		--Auto hide dropdown values
		["Label Hide window after"] = "Fenster ausblenden nach...",
		["Dropdown Options Autohide"] = {
			["none"] = "Nicht ausblenden",
			["3sec"] = "3 Sekunden",
			["5sec"] = "5 Sekunden",
			["7sec"] = "7 Sekunden",
			["10sec"] = "10 Sekunden"
		},
		--[[ ["Dropdown Options KeyModifier"] = {
			["ALT"]		= "ALT",
			["CTRL"]	= "STRG",
			["SHIFT"]	= "SHIFT"
		}]]--
	},--deDE
	["esES"] = { --Spanish (Spain)
		["Translator info"] = "Spanish (spain) translation: Looking for volunteers."
	},--esES
	["esMX"] = { --Spanish (Mexico)
		["Translator info"] = "Translated by Lawghter @ Curseforge.",
		--## Title: Links in Chat
		--## Notes-esMX: Muestra una ventana emergente al hacer click sobre un link en el chat.
		--Copy frame
		--["CopyFrame Title"] = "Links in Chat",
		["CopyFrame Info1"] = "Presiona ".. (IsMacClient() and "Cmd-C" or "Ctrl-C") .." para copiar un link.",
		["CopyFrame Info2"] = "Presiona ESC para cerrar la ventana.",
		--Settings frame
		--["Settings Title"] = "Links in Chat "..GetAddOnMetadata("LinksInChat", "Version").." ",
		["Settings Info1"] = "Al hacer click en una dirección web (http:// o www.) se abrirá una ventana para copiarla en el portapapeles.\nTambién es compatible con Mumble, Teamspeak, Ventrilo, Skype, e-mail y BattleTags.\nPara copiar una dirección web en el chat, hazle click mientras presionas la telca Shift.\n\nTambién puedes escribir '/link' en el chat y generar una dirección web para tu objetivo actual o \ncualquier PNJ/objeto/item sobre el que tengas situado el cursor.",
		["Settings Info2"] = "En el chat, haz click sobre el link de un item/hechizo/etc mientras presionas la tecla Alt para generar su dirección web.",
		["Provider Info1"] = "No todos los buscadores ofrecen una búsqueda avanzada, y no todos los hipervínculos son compatibles. \nEn tales casos se empleará una búsqueda simple.",
		["Button Web link color"] = "Color del link...",
		["Check Ignore hyperlinks"] = "Ignorar hipervínculos (items, hechizos, logros, etc).",
		["Check Extra"] = "Permitir Alt+Click en el banco, retrato del personaje, casa de subastas, marcos de logro, etc.",
		["Check Simple search"] = "Emplear siempre una búsqueda simple (buscar solo por nombre, no por ID de hechizo, etc).",
		["Check Use HTTPS"] = "Usar HTTPS (recomendado) en vez de HTTP en los buscadores.",
		["Check Always English"] = "Emplear siempre buscadores en inglés (de lo contrario, se usará el idioma del juego).",
		["Label Search provider"] = "Buscador para hipervínculos",
		--Auto hide dropdown values
		["Label Hide window after"] = "Ocultar ventana después de...",
		["Dropdown Options Autohide"] = {
			["none"] = "No ocultar",
			["3sec"] = "3 segundos",
			["5sec"] = "5 segundos",
			["7sec"] = "7 segundos",
			["10sec"] = "10 segundos"
		},
		--[[ ["Dropdown Options KeyModifier"] = {
			["ALT"]		= "ALT",
			["CTRL"]	= "CTRL",
			["SHIFT"]	= "SHIFT"
		}]]--
	},--esMX
	["frFR"] = { --French (France)
		["Translator info"] = "Traduction Française: Lassai sur Chants éternels.", --Last updated: 2014-05-15
		--## Title-frFR: Liens dans le tchat
		--## Notes-frFR: Fais apparaitre une fenetre quand l'utilisateur clique sur un lien.
		--Copy frame
		--["CopyFrame Title"] = "Liens dans la fenetre de discussion",
		["CopyFrame Info1"] = "Utilisez ".. (IsMacClient() and "Cmd-C" or "Ctrl-C") .." pour copier le lien.",
		["CopyFrame Info2"] = "Appuyez ESC pour fermer la fenetre.",
		--Settings frame
		--["Settings Title"] = "Lien dans la fenetre de discussion "..GetAddOnMetadata("LinksInChat", "Version").." ",
		["Settings Info1"] = "En cliquant sur un lien web (http:// ou www.) vous accederez a une fenetre ou vous pourrez le \ncopier dans votre presse-papier. Mumble, Teamspeak, Ventrilo, Skype, e-mail et BattleTags \nsont aussi supportes.\nShift-cliquer un lien web le copie dans la fenetre de discussion.\n\nVous pouvez aussi ecrire '/link' en chat pour recevoir un lien pour votre objectif actuelle ou \nsursouris npc/objet/article.",
		["Settings Info2"] = "Vous pouvez egalement utiliser Alt-clique sur un lien de jeu (sorts, objets...) \ndans la fenetre de dialogue pour en faire un lien web.",
		["Provider Info1"] = "Certains sites supportent les recherches basees sur l'id d'un objet du jeu (sort, equippement, hf, ...). \nDans le cas contraire, une recherche basee sur le nom de l'objet est utilisee.",
		["Button Web link color"] = "Couleur des liens",
		["Check Ignore hyperlinks"] = "Ignorer les liens bases sur l'ID des objets (equippement, sort, hf, etc).",
		["Check Extra"] = "Activer l'alt-clique dans la page du bank, perso, l'HdV et les HF, etc.",
		["Check Simple search"] = "Utiliser le nom des objets et non leur id pour les recherches.",
		["Check Use HTTPS"] = "Utiliser HTTPS (recommende) au lieu de HTTP.",
		["Check Always English"] = "Rechercher en anglais (ou dans la langue du client WOW).",
		["Label Search provider"] = "Recherche fournisseur", --Rechercher les objets par leur ID
		--Auto hide dropdown values
		["Label Hide window after"] = "Cache la fenetre apres...",
		["Dropdown Options Autohide"] = {
			["none"] = "Jamais",
			["3sec"] = "3 secondes",
			["5sec"] = "5 secondes",
			["7sec"] = "7 secondes",
			["10sec"] = "10 secondes"
		}
	},--frFR
	["itIT"] = { --Italian (Italy)
		["Translator info"] = "Traduzione in Italiano: Cassiopea a Doomhammer.", --Last updated: 2014-05-15
		--## Title-itIT: Collegamento in chat
		--## Notes-itIT: Mostra una finestra popup quando si clicca un collegamento nella chat.
		--Copy frame
		--["CopyFrame Title"] = "Collegamento in chat",
		["CopyFrame Info1"] = "Premere ".. (IsMacClient() and "Cmd-C" or "Ctrl-C") .." per copiare il collegamento.",
		["CopyFrame Info2"] = "Premere ESC per chiudere la finestra.",
		--Settings frame
		--["Settings Title"] = "Collegamento in chat "..GetAddOnMetadata("LinksInChat", "Version").." ",
		["Settings Info1"] = "Cliccare su un collegamento web (http:// or www.) aprirà una finestra per copiare il collegamento \nnei tuoi appunti. Mumble, Teamspeak, Ventrilo, Skype, e-mail e BattleTags sono supportati.\nShift-clicking un collegamento web lo copierà nella chat.\n\nÉ possible anche digitare '/link' in chat per ottenere il link dell'attuale target o \nmouseover npc/object/item.",
		["Settings Info2"] = "Facendo Alt-click su un collegamento ipertestuale (items, spells, etc) \nin chat puoi creare un collegamento web.",
		["Provider Info1"] = "Non tutti i motori di ricerca posssono fare una ricerca avanzata, e non tutti i collegamenti \nipertestuali sono supportati. In questi casi verrà utilizzata una ricerca standard.",
		["Button Web link color"] = "Colori dei link...",
		["Check Ignore hyperlinks"] = "Ignora collegamenti ipertestuali (items, spells, achievement, etc).",
		["Check Extra"] = "Attiva Alt-click nel info la banca, del personaggio, nelle case d'aste e nelle imprese, etc.",
		["Check Simple search"] = "Utilizzare i nomi degli oggetti e non il loro id per la ricerca.",
		["Check Use HTTPS"] = "Usa HTTPS (recomandato) al posto di HTTP con i motori di ricerca.",
		["Check Always English"] = "Motori di ricerca in Inglese (o nella lingua del cliente di WOW).",
		["Label Search provider"] = "Provider di ricerca",
		--Auto hide dropdown values
		["Label Hide window after"] = "Nascondi la finestra dopo...",
		["Dropdown Options Autohide"] = {
			["none"] = "Non nascondere",
			["3sec"] = "3 secondi",
			["5sec"] = "5 secondi",
			["7sec"] = "7 secondi",
			["10sec"] = "10 secondi"
		}
	},--itIT
	["koKR"] = { --Korean (Korea)
		["Translator info"] = "Korean translation: Looking for volunteers."
	},--koKR
	["ptBR"] = { --Portuguese (Brazil)
		["Translator info"] = "Portugese translation: Looking for volunteers."
	},--ptBR
	["ruRU"] = { --Russian (Russia)
		["Translator info"] = "Перевод на русский язык: Тасден @ Борейская тундра.", --Last updated: 2017-01-15
		--## Title: Links in Chat
		--## Notes-ruRU: Отображает всплывающее окно при нажатии на веб-ссылки в чате.
		--Copy frame
		--["CopyFrame Title"] = "Links in Chat",
		["CopyFrame Info1"] = "Чтобы скопировать ссылку, нажмите ".. (IsMacClient() and "Cmd-C" or "Ctrl-C") ..".",
		["CopyFrame Info2"] = "Чтобы закрыть окно, нажмите ESC.",
		--Settings frame
		--["Settings Title"] = "Links in Chat "..GetAddOnMetadata("LinksInChat", "Version").." ",
		["Settings Info1"] = "При нажатии на веб-ссылку (http:// или www.) откроется окно, позволяющее скопировать ссылку в буфер обмена.\nТакже поддерживаются ссылки Mumble, Teamspeak, Ventrilo, Skype, e-mail и BattleTag.\nShift+щелчок по веб-ссылке скопирует её в чат.\n\nКроме того, можно ввести в чат '/link' и получить ссылку на существо/объект/предмет, который является вашей \nтекущей целью или на который наведён курсор.",
		["Settings Info2"] = "Вы можете Alt+щёлкать по гиперссылкам (предметам, заклинаниям и т.п.) в чате, чтобы создать ссылки на них.",
		["Provider Info1"] = "Не все поисковики поддерживают расширенный поиск, и не все типы гиперссылок поддерживаются модификацией. \nВ таких случаях будет осуществлён простой поиск.",
		["Button Web link color"] = "Цвет веб-ссылок...",
		["Check Ignore hyperlinks"] = "Игнорировать гиперссылки (на предметы, заклинания, достижения).",
		["Check Extra"] = "Включить Alt+щелчок в банке, окне персонажа, на аукционе, в окне достижений и т.п.",
		["Check Simple search"] = "Простой поиск (искать только по имени, а не по ID).",
		["Check Use HTTPS"] = "При создании веб-ссылок использовать HTTPS (рекомендуется) вместо HTTP.",
		["Check Always English"] = "Всегда использовать англоязычные поисковики (иначе, в соответствии с языком клиента игры).",
		["Label Search provider"] = "Поисковик для создания ссылок",
		--Auto hide dropdown values
		["Label Hide window after"] = "Скрывать окно через...",
		["Dropdown Options Autohide"] = {
			["none"] = "Не скрывать",
			["3sec"] = "3 секунды",
			["5sec"] = "5 секунд",
			["7sec"] = "7 секунд",
			["10sec"] = "10 секунд"
		},
		--[[ ["Dropdown Options KeyModifier"] = {
			["ALT"]		= "ALT",
			["CTRL"]	= "CTRL",
			["SHIFT"]	= "SHIFT"
		}]]--
	},--ruRU
	["zhCN"] = { --Chinese (Simplified, PRC)
		["Translator info"] = "简体中文翻译: 闪光的百式@斩魔者", --Translated by aenerv7 @ Curseforge. Last updated: 2016-08-02
		--## Title-zhCN: Links in Chat
		--## Notes-zhCN: 在聊天中点击网页连接时显示一个弹出窗口
		--Copy frame
		--["CopyFrame Title"] = "Links in Chat",
		["CopyFrame Info1"] = "按下 ".. (IsMacClient() and "Cmd-C" or "Ctrl-C") .." 来复制链接",
		["CopyFrame Info2"] = "按下 ESC 来关闭窗口",
		--Settings frame
		--["Settings Title"] = "Links in Chat "..GetAddOnMetadata("LinksInChat", "Version").." ",
		["Settings Info1"] = "点击网页链接 (http:// 或是 www.) 将会打开一个窗口来复制链接到剪切板\nMumble, Teamspeak, Ventrilo, Skype, 电子邮件地址和战网标签同样也被支持\n按住 Shift 再点击一个网页链接将会复制链接到聊天\n\n你也可以在聊天里输入 '/link' 来获得一个你当前目标或是鼠标选中的NPC/对象/物品的链接",
		["Settings Info2"] = "你也可以按住 Alt 并点击聊天中的超链接 (物品, 法术等) 来为它们创建一个网页链接",
		["Provider Info1"] = "并不是所有的搜索引擎都可以执行高级搜索, 也不是所有类型的超链接都被支持\n在这些情况下将会使用简单搜索",
		["Button Web link color"] = "网页链接颜色...",
		["Check Ignore hyperlinks"] = "忽略超链接 (物品链接, 法术链接, 成就链接等)",
		["Check Extra"] = "在银行, 角色, 拍卖行, 成就等界面中启用按住 Alt 点击功能",
		["Check Simple search"] = "总是使用简单搜索 (只根据名字来搜索超链接而不是根据法术 ID 等)",
		["Check Use HTTPS"] = "使用 HTTPS (推荐) 代替 HTTP",
		["Check Always English"] = "总是使用英文搜索引擎 (否则根据客户端语言改变)",
		["Label Search provider"] = "超链接的搜索引擎",
		--Auto hide dropdown values
		["Label Hide window after"] = "在...秒后隐藏窗口",
		["Dropdown Options Autohide"] = {
			["none"] = "不自动隐藏",
			["3sec"] = "3 秒",
			["5sec"] = "5 秒",
			["7sec"] = "7 秒",
			["10sec"] = "10 秒"
		},
		--[[ ["Dropdown Options KeyModifier"] = {
			["ALT"]		= "ALT",
			["CTRL"]	= "CTRL",
			["SHIFT"]	= "SHIFT"
		}]]--
	},--zhCN
	["zhTW"] = { --Chinese (Traditional, Taiwan)
		["Translator info"] = "Chinese (Taiwan) translation: Looking for volunteers."
	}--zhTW
}--Localization

------------------------------------------------------------------------------------------
local currentLocale = {};
local L = GetLocale(); --Localization to the current game-client language
if (L == "enGB") then L = "enUS"; end
do
	for k,v in pairs(Localization.enUS) do
		if not Localization[L][k] or Localization[L][k] == false then
			currentLocale[k] = Localization.enUS[k]; --We use the default enUS localization strings if nothing else is defined
		else
			currentLocale[k] = Localization[L][k];
		end
	end
end
Localization = nil; --cleanup

--Global Declaration
LinksInChat_Locale = currentLocale; --Global declaration

--####################################################################################
--####################################################################################