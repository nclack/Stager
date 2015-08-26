cd build
write-host "Building ..."
MSBuild.exe INSTALL.vcxproj /m /nologo /clp:"Verbosity=minimal;ShowTimestamp;" /property:"Configuration=Release"
write-host "...Done"
cd ..

