  Legion Go ACPI Call Installer

  This repository provides an automated installer for the acpi_call kernel module on SteamOS.

  Installation Steps

   1. Download: Download the files from this repository.
   2. Move files:
      - Move acpi-install.sh to your home folder (/home/deck/).
      - Move acpi-install.desktop to your Desktop.
   3. Permissions:
      - Right-click acpi-install.sh -> Properties -> Permissions -> Check "Is executable".
      - Right-click acpi-install.desktop on your Desktop -> Properties -> Permissions -> Check "Is
        executable".
   4. Password: If you haven't set a user password, go to System Settings -> Users -> Change Password.
   5. Run: Double-click the "Install ACPI Call" icon on your Desktop. Provide your password when
      prompted.

 Important Notes
System Updates: Because SteamOS uses an immutable root filesystem, you must re-run this script after every system update, as updates will wipe the installed module.
