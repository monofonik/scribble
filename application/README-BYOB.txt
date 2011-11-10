BYOB3 Release Notes

	- Windows installer
	- Localization
	- Debugger
	- Screensaver
	- Mesh
	- Nested Sprites
	- Elements

-------------------------------

Windows installer:

It's best not to select an installation folder under "\program files" (e.g. C:\program files\BYOB) but to select some other folder that is not a subfolder of Vista's paranoid UAC system. BYOB will run fine from C:\program files\BYOB, but editing the source code and trying to open Elements may lead to strange, Vista-related error messages. These don't happen if you select another folder. The installer offers C:\BYOB as default. 

Uninstaller:

Be sure to backup all files that you're storing in the installation folder or in a subfolder of the installation directory (e.g. BYOB\Projects) before uninstalling BYOB, otherwise any such files will be deleted by the uninstaller.

-------------------------------


Localization:

This release aims to provide more or less full localization support. We're attaching three files that go into the "locale" folder:

    * BYOB.pot — a template of all strings that can currently be localized, the
 	BYOB-specific strings are right at the top.
    * de.po — a sample German translation file 
    * it.po - a sample Italian translation file

You should be able to beef up existing Scratch pootle files by just copying and pasting the BYOB section of the .pot file into them, and adding the new translations.

Please note, that all .po files must be UT8 encoded, and that certain BYOB-specific blocks (CALL, RUN, etc) have to maintain the order of their arguments to work correctly.

Also please note that RTL-languages are currently not supported in BYOB.
This means we're now actively seeking translators! (If anyone comes up with a better German translation, please do not hesitate to send us an edited version).

---------------------------------

Debugger:

This release is my first shot at a minimal debugger. I'm hoping it's mostly self-explanatory :-)

Anyway, here's how it works:

Breakpoints

In the controls palette (at the bottom) there are two new blocks, both named
    DEBUG
a command and a reporter that takes an argument.

These blocks represent breakpoints. When a breakpoint gets evaluated all threads are paused and a little modeless Debugger dialog opens on the following block, i.e. you can edit anywhere and switch between sprites while the Debugger is open and threads are paused.

Inspecting

The Debugger focuses on letting you inspect the stuff that's normally invisible inside a custom block definition, i.e.:

    * a picture of the current block and its following ones,
    * script variables and variable frames (in case of recursion or closures)
    * return values (of reporter blocks) 

If there are any values that can be inspected a button named "variables" is shown. Pressing it invokes a menu on all inspectable values. Hovering over the variable names displays their value in speech bubbles next to the menu. Clicking a menu item simply closes the menu. The Debugger can be resized to better view very big blocks. Its title shows either the name of the sprite the inspected block refers to, or the name of an "invisible" variable in case of getters/setter to temporaries or block vars.

Stepping

The Debugger currently has three buttons for navigation:
>   resumes all threads 
>|  resumes all threads and again pauses at the next block in the current thread 
>>  resumes all threads, run the next complete command (e.g., an entire repeated 
	loop) without pausing, then pause at the following command.
 
Reporter blocks are stepped through twice: When entering and when exiting the block. Exiting the block is indicated by the ^ sign next to the Debugger's window label.

Command blocks only trigger a single step.

Overriding

Breakpoints are ignored in presentation mode. That way you can debug in edit mode and test in presentation mode without having to remove all breakpoints and put them back in again.

Pressing the Stop sign also closes the Debugger. If you're inside a loop and want to stop debugging, just press stop :-)

Needless to say this is all very experimental, still buggy and in flux. 

---------------------------------

Screensaver:

This is a little Windows screensaver that will be installed by the Setup program.

Note: The Screensaver only works if you have at some point installed BYOB via the Windows setup program (because it requires registry entries made by the installer).

To test the screensaver

   1. copy the BYOB.scr file into your Windows\system32 directory
   2. make sure there is a folder named "Projects" (without quotation marks) in your BYOB installation folder
   3. add one or more . ypr or .sb files to the Projects directory
   4. fire up your Windows screen settings and choose the BYOB screensaver 

the Screensaver starts BYOB in presentation mode with a random project from the Projects folder. If you want to always run the same project (your own special screensaver) be sure to just put that one into the Projects folder (you can put other projects into subfolders, in this case they won't be used as screensavers). Like a "compiled" standalone project the screensaver exits back to Windows once the user presses Esc or exits from presentation mode. The Screensaver also makes sures that only a single instance of itself always runs. 

---------------------------------

Mesh, Nested Sprites:

for these features please refer to the enclosed document: BYOB 2.0.pdf

---------------------------------

Elements:

for this feature please refer to the enclosed document: Elements090224.pdf
