#include <mex.h>
#include <nidaqmx.h>

#define FUNCTION  "deviceNames"
#include "err.c"

static int ndevices(const char* names) {
    int ncommas=0;
    if(!*names) return 0;
    for(;*names;++names)
        ncommas+=(*names==',');
    return ncommas+1;
}

void mexFunction(int nlhs,mxArray *plhs[], int nrhs,const mxArray *prhs[]) {
    char buf[4096]={0};

    (void)nlhs;
    (void)prhs;
    check(nrhs==0); 

    nierr(DAQmxGetSysDevNames(buf,sizeof(buf)));
    {
        mwSize dims[]={ndevices(buf)},i=0;
        char *b=buf,*c=buf;
        plhs[0]=mxCreateCellArray(1,dims);
        while(*c) {
            while(*c && *c!=',') ++c;
            if(*c==',') {
                *c='\0';
                do ++c; while(*c==' ');
            }
            mxSetCell(plhs[0],i,mxCreateString(b));
            b=c;
            ++i;
        }
    }
}
