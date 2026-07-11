on run arguments
    if (count of arguments) is not 5 then error "expected RAW, output name, quality, session directory, and session name"

    set rawPath to item 1 of arguments
    set outputName to item 2 of arguments
    set jpegQuality to (item 3 of arguments) as integer
    set sessionDirectory to item 4 of arguments
    set sessionName to item 5 of arguments
    set recipeName to sessionName & " JPEG"

    tell application "Capture One"
        set sessionDocument to make new document with properties {name:sessionName, path:sessionDirectory, kind:session}
        tell sessionDocument
            set exportRecipe to make new recipe with properties {name:recipeName}
            tell exportRecipe
                set output format to JPEG
                set JPEG quality to jpegQuality
                set output name format to outputName
                set existing files to overwrite
                set sharpening to no output sharpening
            end tell
            set processing queue enabled to true
        end tell

        set jobIdentifier to process POSIX file rawPath recipe recipeName
        if jobIdentifier starts with "ERROR" then error jobIdentifier
        return jobIdentifier
    end tell
end run
