#include <mex.h>
#include <nidaqmx.h>
#include <stdint.h>

#define FUNCTION  "destroy"
#include "err.c"


void mexFunction(int nlhs,mxArray *plhs[], int nrhs,const mxArray*prhs[]) {
    TaskHandle task;
    (void)nlhs; (void) plhs;
    check(nrhs==1);
    checktype(prhs[0],mxUINT64_CLASS); /* the task handle */
    if((task=*(TaskHandle*)mxGetData(prhs[0]))) {
        nierr(DAQmxClearTask(task));
        *(uint64_t*)mxGetData(prhs[0])=0;
    }
}
