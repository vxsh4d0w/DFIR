# DFIR Windows
This folder contain what ypou need to create your unattended Win10 configuration to build your own version of the Microsoft OS with several tools useful for Dfir tasks.
Basically, the idea is to create a machine based on WIN-FOR (https://github.com/digitalsleuth/win-for), by digitalsleuth (https://github.com/digitalsleuth), including also
chocolately to easily install any other tool or package by cli. 

**Sections**

1. Unattended File
2. Powershell configuration script (based on the one provided by https://github.com/tinohager)

## 2. Powershell Configuration Script ##
This section contains a powershell script, based on Tino Hager customization, executed after first logon, that runs several steps like:
- Customize Power Plan
- NuGet installation
- Windows Updates installation
- Chocolately package manager installation (and several applications)
