errors = {
    "genericError": {
        "title": "Error",
        "body": "An unexpected error occurred."
    },
    "couldNotParseScene": {
        "title": "Could not load scene",
        "body": "The requested scene file could not be parsed. This may be because the file is corrupt, or because it is not a proper scene file.\n\n(Remember, other files, such as prefabs and scripts, may also use the .lua extension.)"
    },
    "couldNotLoadScene": {
        "title": "Could not load scene",
        "body": "The requested scene file could not be loaded."
    },
    "couldNotParsePrefab": {
        "title": "Could not load prefab",
        "body": "The requested prefab file could not be parsed. This may be because the file is corrupt, or because it is not a proper prefab file.\n\n(Remember, other files, such as scenes and scripts, may also use the .lua extension.)"
    },
    "couldNotLoadPrefab": {
        "title": "Could not load prefab",
        "body": "The requested prefab file could not be loaded."
    },
    "couldNotOpenProject": {
        "title": "Could not open project",
        "body": "An error occurred while trying to open the project:\n\n{}"
    },
    "couldNotPerformActionWithoutProject": {
        "title": "No project",
        "body": "You cannot perform this action because you haven't opened or created a project yet."
    },
    "couldNotImportAsset": {
        "title": "Import failed",
        "body": "An error occurred while trying to import the asset:\n\n{}"
    }
}
alerts = {
    "confirmImportAsset": {
        "title": "External file",
        "body": "You are attempting to open a file that exists outside of the current project. To do so, you will need to import it. This will copy the file to the project's \"src\" directory, unless there is a name conflict.\n\nDo you want to import the file?"
    }
}