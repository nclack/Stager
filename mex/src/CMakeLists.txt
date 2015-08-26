include(cmake/matlab-config.cmake)
include(cmake/MatlabMexMacro.cmake)
include(cmake/daqmx-config.cmake)


foreach(tgt
    destroy
    addAO
    addDO
    writeAO
    writeDO
    deviceNames
    taskNames)
    
    add_mex_file(${tgt} ${tgt}.c)
    target_add_nidaqmx(${tgt})
    target_compile_options(${tgt} BEFORE PUBLIC /MT)

    # used to copy built targets to proper place in the stager package
    # expects install prefix to be the stager root directory
    install(TARGETS ${tgt} DESTINATION +devices/private) 

endforeach()
