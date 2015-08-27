function out=startStandAloneNIDAQMX

out=controller(devices.nidaqmxDevice(),@view);