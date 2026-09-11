Run the shell command `ss` to grab the current image from the Windows clipboard and save it to ~/tmp/ss.png.

Check the output:
- If it prints "~/tmp/ss.png updated" → success, proceed to read ~/tmp/ss.png and analyze it
- If it prints "No image in clipboard" → tell the user there was no image found in the clipboard, and ask them to copy an image first (e.g. Win+Shift+S to screenshot, or right-click copy image)
- If the command fails for any other reason → report the error output to the user

If successful and the user provided additional instructions via $ARGUMENTS, apply them to the analysis of the image. Otherwise, describe what you see in the screenshot and ask what they'd like to do with it.
