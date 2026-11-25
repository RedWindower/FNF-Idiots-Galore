@echo off
color 0a
cd ..
echo BUILDING GAME
set VCToolsVersion=14.44.35207
set WindowsSDKVersion=10.0.26100.0
set VSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\
set VCINSTALLDIR=%VSINSTALLDIR%VC\
set VCToolsInstallDir=%VCINSTALLDIR%Tools\MSVC\%VCToolsVersion%\
set WindowsSdkDir=C:\Program Files (x86)\Windows Kits\10\
set INCLUDE=%VCToolsInstallDir%include;%WindowsSdkDir%Include\%WindowsSDKVersion%\ucrt;%WindowsSdkDir%Include\%WindowsSDKVersion%\shared;%WindowsSdkDir%Include\%WindowsSDKVersion%\um;%WindowsSdkDir%Include\%WindowsSDKVersion%\winrt
set LIB=%VCToolsInstallDir%lib\x64;%WindowsSdkDir%Lib\%WindowsSDKVersion%\ucrt\x64;%WindowsSdkDir%Lib\%WindowsSDKVersion%\um\x64
set PATH=%VCToolsInstallDir%bin\Hostx64\x64;%WindowsSdkDir%bin\%WindowsSDKVersion%\x64;%PATH%
set HXCPP_MSVC_CUSTOM=1
set HXCPP_NO_COLOUR=1
cd /d C:\Users\jjwil\Downloads\FNF-Idiots-Galore
lime test windows
echo.
echo done.
pause