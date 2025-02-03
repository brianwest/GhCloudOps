apt-get update

apt-get install -y wget

wget https://github.com/PowerShell/PowerShell/releases/download/v7.5.0/powershell_7.5.0-1.deb_amd64.deb

dpkg -i powershell_7.5.0-1.deb_amd64.deb

apt-get install -f

rm powershell_7.5.0-1.deb_amd64.deb

pwsh
