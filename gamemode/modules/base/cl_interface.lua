FrenchRP.PLAYER.isInRoom = FrenchRP.stub{
    name = "isInRoom",
    description = "Whether the player is in the same room as the LocalPlayer.",
    parameters = {},
    returns = {
        {
            name = "inRoom",
            description = "Whether the player is in the same room.",
            type = "boolean"
        }
    },
    metatable = FrenchRP.PLAYER
}

FrenchRP.deLocalise = FrenchRP.stub{
    name = "deLocalise",
    description = "Makes sure the string will not be localised when drawn or printed.",
    parameters = {
        {
            name = "text",
            description = "The text to delocalise.",
            type = "string",
            optional = false
        }
    },
    returns = {
        {
            name = "text",
            description = "The delocalised text.",
            type = "string"
        }
    },
    metatable = FrenchRP
}

FrenchRP.textWrap = FrenchRP.stub{
    name = "textWrap",
    description = "Wrap a text around when reaching a certain width.",
    parameters = {},
    returns = {
        {
            name = "text",
            description = "The text to wrap.",
            type = "string"
        },
        {
            name = "font",
            description = "The font of the text.",
            type = "string"
        },
        {
            name = "width",
            description = "The maximum width in pixels.",
            type = "number"
        }
    },
    metatable = FrenchRP
}

FrenchRP.setPreferredJobModel = FrenchRP.stub{
    name = "setPreferredJobModel",
    description = "Set the model preferred by the player (if the job allows multiple models).",
    parameters = {
        {
            name = "teamNr",
            description = "The team number of the job.",
            type = "number",
            optional = false
        },
        {
            name = "model",
            description = "The preferred model for the job.",
            type = "string",
            optional = false
        }
    },
    returns = {
    },
    metatable = FrenchRP
}

FrenchRP.getPreferredJobModel = FrenchRP.stub{
    name = "getPreferredJobModel",
    description = "Get the model preferred by the player (if the job allows multiple models).",
    parameters = {
        {
            name = "teamNr",
            description = "The team number of the job.",
            type = "number",
            optional = false
        }
    },
    returns = {
        {
            name = "model",
            description = "The preferred model for the job.",
            type = "string"
        }
    },
    metatable = FrenchRP
}

FrenchRP.hookStub{
    name = "teamChanged",
    description = "When your team is changed.",
    deprecated = "Use the OnPlayerChangedTeam hook instead.",
    parameters = {
        {
            name = "before",
            description = "The team before the change.",
            type = "number"
        },
        {
            name = "after",
            description = "The team after the change.",
            type = "number"
        }
    },
    returns = {

    }
}
