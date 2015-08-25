#include <mex.h>
#include <nidaqmx.h>

#define FUNCTION  "writeDO"
#include "err.c"

void mexFunction(int nlhs,mxArray *plhs[], int nrhs,const mxArray*prhs[]) {
    (void)nlhs; (void)plhs;
    check(nrhs==2);
    checktype(prhs[0],mxUINT64_CLASS); /* the task handle */
    checktype(prhs[1],mxUINT8_CLASS); /* the state */

    TaskHandle task=*(TaskHandle*)mxGetData(prhs[0]);
    nierr(DAQmxWriteDigitalLines(task,1,0,DAQmx_Val_WaitInfinitely,DAQmx_Val_GroupByChannel,(uInt8*)mxGetData(prhs[1]),NULL,NULL));
}
