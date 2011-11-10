Welcome to Scratch 1.4

This README file is intended primarily to help system administrators install and configure Scratch in networked settings.


SYSTEM REQUIREMENTS

  OS: Windows 2000, Windows XP, Windows Vista, Mac OS X 10.4 or later
  Display: 800x480 or larger, thousands or millions of colors (16-bit color or greater)
  Disk: At least 120 megabytes of free space to install Scratch
  Sound (optional): Speakers or headphones; microphone for recording


NETWORK INSTALLATION AND CUSTOMIZATION

You can customize the Scratch 1.4 installation to suit your specific needs. For example, you may be installing Scratch on a school network and need to control where user Scratch projects are stored, or what drives should be visible. You may need to change settings for a proxy server. Or you may want to change the default sprite, default language, or default project notes.

If you are looking to customize your Scratch installation, first download Scratch and navigate to the /Scratch application folder.  There you will find the file: Scratch.ini .  This is the main files you will modify.


Where to install Scratch

Scratch looks for various files and folders within the Scratch folder. The Scratch folder is the the folder than contains the Scratch application (Scratch.exe or Scratch.app) and Scratch.image file (even if the folder name is different). Some of the folders Scratch looks for in the Scratch folder are the Help, Media, and Projects folders. Scratch keeps its settings in the file Scratch.ini in the Scratch folder.

It's best to keep the Scratch folder structure intact and not rename any of its subfolders.


Shared Drive or MSI Installer

In some networked installations, you may want to install a single copy of Scratch on a networked drive. In other cases, you may want to install Scratch on every machine. In the latter case, the MSI installer available on the download page may help you automate the installation process.


Customizing the default home folder

By default, Scratch assumes that the user folder is on the local C: drive. However, in networked settings, user folders are often kept on a networked drive. Adding this to the Scratch.ini file:

 Home=J:\MySchool\Students\Grade5\*

will tell Scratch that user folders are kept in the folder J:\MySchool\Students\Grade5\. Note that the asterisk is replaced by the name of the logged in user. You may omit the asterisk if you want all users to share the same folder for their Scratch projects. That might be done to facilitate students working together.


Hiding drives

NOTE: Hiding drives only works on Windows. 

In network Windows settings, it is sometimes useful to limit which drives are visible to the user. This can by done by adding a line such as:

 VisibleDrives=J:,M:

to the Scratch.ini file. If visible drives are set, users will not be able to see any other drives (including USB drives), and they won't be able to navigate up the file hierarchy to parts of the disk outside of the Scratch folder and their home folder.


Disabling the 'Share' buttons

In some cases, you may not want users to share their Scratch projects online at all. Adding the following line to Scratch.ini will hide the "Share" menu and button:

 Share=0 


Customizing the default language

Scratch starts using the language specified by the "locale" of the computer, but this can be overridden. In Scratch.ini file add the line:

 Language = [ISO-639-2 code]

Note that this setting will be changed whenever the user changes the language setting (if the Scratch.ini file is writeable) so that Scratch will start up in the language that was last in use.


About proxy servers

Proxy server settings can be specified in the .ini file using the following entries:

 ProxyServer=[server name or IP address]
 ProxyPort=[port number]


Customizing the default sprite

You can replace the default cat sprite with a sprite of your own. You default sprite can include multiple costumes, sounds, and even scripts. To set this up, just create your sprite and export it. (To export, right-click on the sprite and choose "export this sprite."). Then rename it "default.sprite" and place it in the Costumes folder.


Customizing the default project notes

Some people have asked for a way to provide some guiding questions or instructions to users when they first edit the notes for a project. Just make a text file with your default notes, save it with UTF8 encoding, name it defaultNotes.txt, and put it into the Scratch folder.

If the user does not edit the default notes text then nothing is saved in the project notes. This is to prevent lots of projects with default notes text from appearing on the Scratch website. The user has to change at least one character for the notes to be saved in the project.


FURTHER INFORMATION

For additional information, please see http://scratch.mit.edu
