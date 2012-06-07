****************************************
SCRIBBLE - DEVELOPMENT README
****************************************

Configuring

- Copy BaseScribble.image and BaseScribble.changes to Scribble.image and Scribble.changes
- Run cellular_development (Mac) or cellular_development.bat (Windows)
- Follow instructions within Squeak Image to import classes from version control

During development, left-click the background and select Save to save the current state of the Squeak image. Note that the base image (BaseScribble.image / BaseScribble.changes) should not be modified, in order to prevent the need for committing large files to version control.

Exporting to version control

- From within Squeak image, select <Shift> File, export to version control. This will export all modified classes to the ./Classes directory
- Commit to GitHub as normal

Releasing

- In the Squeak class browser, select "ScratchFrameMorph - Class - All - version:"
- Uncomment the first line of text, increment the version number
- Select the first line of text, press <Ctrl> D
- Re-comment the first line of text
- Select <Shift> Edit - "Save image for end user". The Squeak image will be saved in the release state and closed.
- Run ./copyforrelease.sh
- Run deployment/mac/compile.sh to create Mac disk image (From Mac only)
- Run deployment/windows/installer.nsi to create Windows installer (From Windows only - requires NSI)