

include(cmake/matlab-config.cmake)
include(cmake/MatlabMexMacro.cmake)
include(cmake/daqmx-config.cmake)

foreach(tgt
    destroy
    addAO
    addDO
    writeAO
    writeDO
    deviceNames)

    add_mex_file(${tgt} ${tgt}.c)
    target_add_nidaqmx(${tgt})
    target_compile_options(${tgt} BEFORE PUBLIC /MT)

endforeach()
