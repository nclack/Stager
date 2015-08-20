function gui=aoguitest

configs=struct();

% function out=aogui(getRoiNames,getConfigForROIByName,setConfigForROIByName,start,stop,varargin)
gui=aogui(...
    @() fieldnames(configs),...
    @get,...
    @set,...
    @start,...
    @stop);

    function value=get(key)
        if isfield(configs,key)
            value=configs.(key);
        else
            value=[];
        end
    end

    function set(key,value)
        configs.(key)=value;
    end

    function start
        disp('start')
        wait(0.5);
        gui.notifyIsRunning(true);
    end

    function stop
        disp('start')
    end

end