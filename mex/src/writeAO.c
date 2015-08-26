#include <mex.h>
#include <nidaqmx.h>

#define FUNCTION  "writeAO"
#include "err.c"

void mexFunction(int nlhs,mxArray *plhs[], int nrhs,const mxArray*prhs[]) {
    (void)nlhs; (void)plhs;
    check(nrhs==2);
    checktype(prhs[0],mxUINT64_CLASS); /* the task handle */
    checktype(prhs[1],mxDOUBLE_CLASS); /* the initial voltage */

    TaskHandle task=*(TaskHandle*)mxGetData(prhs[0]);
    nierr(DAQmxWriteAnalogF64(task,1,0,DAQmx_Val_WaitInfinitely,DAQmx_Val_GroupByChannel,mxGetData(prhs[1]),0,0));
}
