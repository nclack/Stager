cd build
write-host "Building ..."
MSBuild.exe .\devices.sln /m /nologo /clp:"Verbosity=minimal;ShowTimestamp;" /property:"Configuration=Release"
write-host "...Done"
cd ..

