local addonName, NS = ...

function NS.InitSocialTheme()
    if not FriendsFrame then return end

    NS.CreateMainWindowBG(FriendsFrame, "ModernSocialMainBG", {
        portraits = { FriendsFramePortrait, FriendsFrameIcon },
        closeBtn = FriendsFrameCloseButton,
        titles = { FriendsFrameTitleText }
    })

    local subFrames = {
        FriendsListFrame, IgnoreListFrame, WhoFrame, GuildFrame,
        ChannelFrame, RaidFrame, RaidInfoFrame, GuildMemberDetailFrame, GuildInfoFrame
    }
    for _, sf in ipairs(subFrames) do
        NS.CleanFrameTextures(sf)
    end

    local innerBoxes = {
        FriendsFrameFriendsScrollFrame, FriendsFrameIgnoreScrollFrame, WhoListScrollFrame,
        GuildListScrollFrame, ChannelListScrollFrame, ChannelRosterScrollFrame
    }
    for _, box in ipairs(innerBoxes) do
        NS.StyleScrollFrameBox(box, 0.55)
    end

    NS.StyleTabs("FriendsFrameTab", 5, 0.90)
    NS.StyleTabs("FriendsTabHeaderTab", 2, 0.88)

    NS.TintButtons({
        FriendsFrameAddFriendButton, FriendsFrameSendMessageButton, FriendsFrameIgnorePlayerButton,
        FriendsFrameUnsquelchButton, WhoFrameWhoButton, WhoFrameAddFriendButton, WhoFrameGroupInviteButton,
        GuildFrameControlButton, GuildFrameAddMemberButton, GuildFrameGuildInformationButton,
        ChannelFrameNewButton, RaidFrameConvertToRaidButton, RaidFrameRaidInfoButton, WhoFrameDropDown
    })

    NS.StyleEditBox(WhoFrameEditBox)

    for _, popup in ipairs({ GuildMemberDetailFrame, GuildInfoFrame, RaidInfoFrame }) do
        if popup then
            NS.ApplyIceBackdrop(popup, 0.96)
            NS.AddTopGlow(popup, 30)
        end
    end
end
