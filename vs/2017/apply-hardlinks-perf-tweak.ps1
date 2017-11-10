#Requires -RunAsAdministrator

$rootPath = [System.IO.Path]::GetFullPath((split-path $SCRIPT:MyInvocation.MyCommand.Path -parent))

&"c:\Program Files\git\usr\bin\patch" --binary --forward -r - "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\Microsoft.Common.CurrentVersion.targets" $rootPath\hardlinks-perf-tweak\Microsoft.Common.CurrentVersion.targets.patch

&"c:\Program Files\git\usr\bin\patch" --binary --forward -r - "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\amd64\Microsoft.Common.CurrentVersion.targets" $rootPath\hardlinks-perf-tweak\amd64\Microsoft.Common.CurrentVersion.targets.patch