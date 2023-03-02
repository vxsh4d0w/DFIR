# DFIR Windows
This folder contain what ypou need to create your unattended Win10 configuration to build your own version of the Microsoft OS with several tools useful for Dfir tasks.
Basically, the idea is to create a machine based on WIN-FOR (https://github.com/digitalsleuth/win-for), by digitalsleuth (https://github.com/digitalsleuth), including also
chocolately to easily install any other tool or package by cli. 

**Sections**

1. Unattended File
2. Powershell configuration script (based on the one provided by https://github.com/tinohager)


## 1. Unattended Installation File ##
This section provides a copy of the xml configuration file that should be included within the root folder of Win10 iso image to be executed to automate each
installation and configuration step.
1. Download a copy of Windows 10 iso
2. Install AnyBurn (https://anyburn.com/)
3. Run AnyBurn and select "Edit image file"
4. Select the iso image file to be edited
5. Add autounattend.xml within root folder
6. Add any other folder or files needed to customize the installation
7. Create new image


## 2. Powershell Configuration Script ##
This section contains a powershell script, based on Tino Hager customization, executed after first logon, that runs several steps like:
- Customize Power Plan
- NuGet installation
- Windows Updates installation
- Chocolately package manager installation (and several applications)
