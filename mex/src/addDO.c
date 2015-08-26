#include <mex.h>
#include <nidaqmx.h>

#define FUNCTION  "addDO"
#include "err.c"

void mexFunction(int nlhs,mxArray *plhs[], int nrhs,const mxArray*prhs[]) {
    TaskHandle *task=0;
    char buf[1024]={0};

    check(nlhs==1);
    check(nrhs==2);
    checktype(prhs[0],mxCHAR_CLASS);   /* the channel name */
    checktype(prhs[1],mxUINT8_CLASS); /* the initial voltage */

    { 
        mwSize dims[]={1};
        plhs[0]=mxCreateNumericArray(1,dims,mxUINT64_CLASS,mxREAL);
        nierr(DAQmxCreateTask(NULL,task=(TaskHandle*)mxGetData(plhs[0])));
    }

    mxGetString(prhs[0],buf,sizeof(buf));
    withtask(*task,DAQmxCreateDOChan(*task,buf,0,DAQmx_Val_ChanForAllLines));
    withtask(*task,DAQmxStartTask(*task));
    withtask(*task,DAQmxWriteDigitalLines(*task,1,0,DAQmx_Val_WaitInfinitely,DAQmx_Val_GroupByChannel,(uInt8*)mxGetData(prhs[1]),NULL,NULL));
}
