#Requires -RunAsAdministrator

$rootPath = [System.IO.Path]::GetFullPath((split-path $SCRIPT:MyInvocation.MyCommand.Path -parent))

&"c:\Program Files\git\usr\bin\patch" --binary --forward -r - "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\MSBuild\Sdks\Microsoft.Docker.Sdk\build\Microsoft.Docker.targets" $rootPath\docker-tools-disable-publish-tweak\Microsoft.Docker.targets.patch