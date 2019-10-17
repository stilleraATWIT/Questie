QuestieOptionsMinimap = {...}
local optionsDefaults = QuestieOptionsDefaults:Load()


function QuestieOptionsMinimap:Initalize()
    return {
        name = function() return QuestieLocale:GetUIString('MINIMAP_TAB'); end,
        type = "group",
        order = 11,
        args = {
            minimap_options = {
                type = "header",
                order = 1,
                name = function() return QuestieLocale:GetUIString('MINIMAP_HEADER'); end,
            },
            alwaysGlowMinimap = {
                type = "toggle",
                order = 1.7,
                name = function() return QuestieLocale:GetUIString('MINIMAP_ALWAYS_GLOW_TOGGLE'); end,
                desc = function() return QuestieLocale:GetUIString('MINIMAP_ALWAYS_GLOW_TOGGLE_DESC'); end,
                width = "full",
                get = function(info) return QuestieOptions:GetGlobalOptionValue(info); end,
                set = function (info, value)
                    QuestieOptions:SetGlobalOptionValue(info, value)
                    QuestieFramePool:UpdateGlowConfig(true, value)
                end,
            },
            questMinimapObjectiveColors = {
                type = "toggle",
                order = 1.8,
                name = function() return QuestieLocale:GetUIString('MAP_QUEST_COLORS'); end,
                desc = function() return QuestieLocale:GetUIString('MAP_QUEST_COLORS_DESC'); end,
                width = "full",
                get = function(info) return QuestieOptions:GetGlobalOptionValue(info); end,
                set = function (info, value)
                    QuestieOptions:SetGlobalOptionValue(info, value)
                    QuestieFramePool:UpdateColorConfig(true, value)
                end,
            },
            Spacer_A = QuestieOptionsUtils:Spacer(2),
            globalMiniMapScale = {
                type = "range",
                order = 3,
                name = function() return QuestieLocale:GetUIString('MINIMAP_GLOBAL_SCALE'); end,
                desc = function() return QuestieLocale:GetUIString('MINIMAP_GLOBAL_SCALE_DESC', optionsDefaults.global.globalMiniMapScale); end,
                width = "double",
                min = 0.01,
                max = 4,
                step = 0.01,
                get = function(info) return QuestieOptions:GetGlobalOptionValue(info); end,
                set = function (info, value)
                    QuestieMap:RescaleIcons()
                    QuestieOptions:SetGlobalOptionValue(info, value)
                end,
            },
            fadeLevel = {
                type = "range",
                order = 12,
                name = function() return QuestieLocale:GetUIString('MINIMAP_FADING'); end,
                desc = function() return QuestieLocale:GetUIString('MINIMAP_FADING_DESC', optionsDefaults.global.fadeLevel); end,
                width = "double",
                min = 0.01,
                max = 5,
                step = 0.01,
                get = function(info) return QuestieOptions:GetGlobalOptionValue(info); end,
                set = function (info, value)
                    QuestieOptions:SetGlobalOptionValue(info, value)
                end,
            },
            Spacer_D = QuestieOptionsUtils:Spacer(13),
            fadeOverPlayer = {
                type = "toggle",
                order = 14,
                name = function() return QuestieLocale:GetUIString('MINIMAP_FADE_PLAYER'); end,
                desc = function() return QuestieLocale:GetUIString('MINIMAP_FADE_PLAYER_DESC'); end,
                width = "full",
                get = function(info) return QuestieOptions:GetGlobalOptionValue(info); end,
                set = function (info, value)
                    QuestieOptions:SetGlobalOptionValue(info, value)
                end,
            },
            fadeOverPlayerDistance = {
                type = "range",
                order = 15,
                name = function() return QuestieLocale:GetUIString('MINIMAP_FADE_PLAYER_DIST'); end,
                desc = function() return QuestieLocale:GetUIString('MINIMAP_FADE_PLAYER_DIST_DESC', optionsDefaults.global.fadeOverPlayerDistance); end,
                width = "double",
                min = 0.1,
                max = 0.5,
                step = 0.01,
                get = function(info) return QuestieOptions:GetGlobalOptionValue(info); end,
                disabled = function() return (not Questie.db.global.fadeOverPlayer); end,
                set = function (info, value)
                    QuestieOptions:SetGlobalOptionValue(info, value)
                end,
            },
            fadeOverPlayerLevel = {
                type = "range",
                order = 16,
                name = function() return QuestieLocale:GetUIString('MINIMAP_FADE_PLAYER_LEVEL'); end,
                desc = function() return QuestieLocale:GetUIString('MINIMAP_FADE_PLAYER_LEVEL_DESC', optionsDefaults.global.fadeOverPlayerLevel); end,
                width = "double",
                min = 0.1,
                max = 1,
                step = 0.1,
                disabled = function() return (not Questie.db.global.fadeOverPlayer); end,
                get = function(info) return QuestieOptions:GetGlobalOptionValue(info); end,
                set = function (info, value)
                    QuestieOptions:SetGlobalOptionValue(info, value)
                end,
            },
            Spacer_E = QuestieOptionsUtils:Spacer(20),
            fade_options = {
                type = "header",
                order = 21,
                name = function() return QuestieLocale:GetUIString('MINMAP_COORDS'); end,
            },
            Spacer_F = QuestieOptionsUtils:Spacer(22),
            minimapCoordinatesEnabled = {
                type = "toggle",
                order = 23,
                name = function() return QuestieLocale:GetUIString('ENABLE_COORDS'); end,
                desc = function() return QuestieLocale:GetUIString('ENABLE_COORDS_DESC'); end,
                width = "full",
                get = function(info) return QuestieOptions:GetGlobalOptionValue(info); end,
                set = function (info, value)
                    QuestieOptions:SetGlobalOptionValue(info, value)

                    if not value then
                        QuestieCoords.ResetMinimapText();
                    end
                end,
            },
        },
    }
end