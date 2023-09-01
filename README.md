# Intro

A simple bash shell script for syncing files/directories between remote and local machines based on [rsync](https://linux.die.net/man/1/rsync).

Works on both Windows (using WSL) and macOS (natively).

# Prerequisites (only for Windows OS)

- Follow the instructions on this [page](https://ubuntu.com/wsl) to get Ubuntu (or any distro) installed in Windows WSL. This allows you to run bash shell scripts on Windows OS.
- Run `sudo apt install rsync openssh-client` command in the newly installed WSL Ubuntu shell to install `rsync` utility.
- Optionally, install [dos2unix on Ubuntu WSL](https://askubuntu.com/questions/1117623/how-to-install-dos2unix-on-a-ubuntu-app-on-a-windows-10-machine)

# Installation

- Clone/download the repo.
- Run `dos2unix /<script-root-directory>/*.sh`
- Optionally, you can avoid entering the remote server password every time you run the scripts by setting up a [password-less ssh in 3-easy steps](https://www.tecmint.com/ssh-passwordless-login-using-ssh-keygen-in-5-easy-steps/). Skip this step if you're OK with entering password everytime you run the script.

# Usage

## Download files (local <-- remote)

    ./download.sh`<download-list-file-name>` `<download-exceptions-list-file-name>` `<optional-local-root-directory>` `<optional-remote-root-directory>`

### Arguments

- `<download-list-file-name>`: A file containing the list of directories that need to be downloaded along with server details
  * Format: `<your-id>@<your-server.demo.com>:/home/user/some-solution > /mnt/C/some-solution`
  * If you want to sync the contents of a remote directory to a local directory with a different name, use the following:
    * Format: `<your-id>@<your-server.demo.com>:/home/user/some-solution/ > /mnt/C/some-solution/dummy-folder-name` (please note the trailing slash (`/`) at the end of the remote directory path specification and the  `dummy-folder-name)`
- `<download-exceptions-list-file-name>`: A file containing the list of files/directories that needs to be excluded from download operation
  * Example: `.git`
- `<optional-local-root-directory>`: (Optional) Root directory on your local machine
- `<optional-remote-root-directory>`: (Optional) Root directory on your remote machine

## Upload files (local --> remote)

    ./upload.sh`<upload-list-file-name>` `<upload-exceptions-list-file-name>` `<optional-local-root-directory>` `<optional-remote-root-directory>`

### Arguments

- `<upload-list-file-name>`: A file containing the list of directories that need to be uploaded along with server details
  * Format: `/mnt/C/some-solution > <your-id>@<your-server.demo.com>:/home/user/some-solution`
  * If you want to sync the contents of a remote directory to a local directory with a different name, use the following:* Format: `/mnt/C/some-solution/ > <your-id>@<your-server.demo.com>:/home/user/some-other-folder-name/dummy-folder-name` (please note the trailing slash (`/`) at the end of the remote directory path specification and the  `dummy-folder-name)`
- `<upload-exceptions-list-file-name>`: A file containing the list of files/directories that needs to be excluded from upload operation
  * Example: `.git`
- `<optional-local-root-directory>`: (Optional) Root directory on your local machine
- `<optional-remote-root-directory>`: (Optional) Root directory on your remote machine

# Useful info

- To enable verbose mode, just append `--debug` at the invocation command (e.g.: `./download.sh --debug <download-list-file-name> <download-exceptions-list-file-name>`)
- `~/.tmp` contains sync timestamps, remove this folder to reset everything!

# Resources

- [Understanding the output of rsync --itemize-changes](http://web.archive.org/web/20160904174444/http://andreafrancia.it/2010/03/understanding-the-output-of-rsync-itemize-changes.html)
