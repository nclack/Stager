/* Don't compile me.  include me! 

    Before including me do something like:

        #include <mex.h>
        #include <nidaqmx.h>
        #define FUNCTION  "MyFunMexFunction"

    Including this file into another c-source will define a few static symbols and macros.
    Namely:

      Macros
        PROJECT
        check(e)
        checktype(e,type)

      Functions
        static void nierr(int)

    The PROJECT and FUNCTION macros are used to setup matlab exception-handling message id's.
*/

#define PROJECT   "Stager"

static void nierr(int code) {
    char buf[1024]={0};
    if(!code) return;
    nierr(DAQmxGetErrorString(code,buf,sizeof(buf)));
    mexErrMsgIdAndTxt(PROJECT ":DaqmxError",buf);
}

static void clear(TaskHandle task) {
    char buf[1024]={0};
    DAQmxGetTaskName(task,buf,sizeof(buf));
    mexPrintf("Clearing task: %s\n",buf);
    nierr(DAQmxClearTask(task));
}

#define withtask(task,e) do{ int ecode=(e); if(ecode) { clear(task); nierr(ecode); (task)=0;}}while(0)

#define check(e) do{if(!(e)) {mexErrMsgIdAndTxt(PROJECT ":" FUNCTION,"Assertion failed: \n\t" #e "\n\tSource: %s\n\tLine %d\n",__FILE__,__LINE__);}} while(0)
#define checktype(e,type) do{if(mxGetClassID(e)!=(type)) {mexErrMsgIdAndTxt(PROJECT ":" FUNCTION,"Type check failed: \n\tExpected " #type " for " #e "\n\tSource: %s\n\tLine %d\n",__FILE__,__LINE__);}} while(0)
