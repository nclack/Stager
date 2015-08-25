#include <mex.h>
#include <nidaqmx.h>

#define FUNCTION  "addAO"
#include "err.c"

void mexFunction(int nlhs,mxArray *plhs[], int nrhs,const mxArray*prhs[]) {
    char buf[1024]={0};
    TaskHandle *task=0;

    check(nlhs==1);
    check(nrhs==2);
    checktype(prhs[0],mxCHAR_CLASS);   /* the channel name */
    checktype(prhs[1],mxDOUBLE_CLASS); /* the initial voltage */

    { 
        mwSize dims[]={1};
        plhs[0]=mxCreateNumericArray(1,dims,mxUINT64_CLASS,mxREAL);
        nierr(DAQmxCreateTask(PROJECT,task=(TaskHandle*)mxGetData(plhs[0])));
    }
    mxGetString(prhs[0],buf,sizeof(buf));
    withtask(*task,DAQmxCreateAOVoltageChan(*task,buf,0,-10,10,DAQmx_Val_Volts,0));
    withtask(*task,DAQmxStartTask(*task));
    withtask(*task,DAQmxWriteAnalogF64(*task,1,0,DAQmx_Val_WaitInfinitely,DAQmx_Val_GroupByChannel,mxGetData(prhs[1]),0,0));
}
