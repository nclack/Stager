function varargout = roiSelector(varargin)
% ROISELECTOR MATLAB code for roiSelector.fig
%      ROISELECTOR, by itself, creates a new ROISELECTOR or raises the existing
%      singleton*.
%
%      H = ROISELECTOR returns the handle to a new ROISELECTOR or the handle to
%      the existing singleton*.
%
%      ROISELECTOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ROISELECTOR.M with the given input arguments.
%
%      ROISELECTOR('Property','Value',...) creates a new ROISELECTOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before roiSelector_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to roiSelector_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help roiSelector

% Last Modified by GUIDE v2.5 09-Jun-2015 16:32:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @roiSelector_OpeningFcn, ...
                   'gui_OutputFcn',  @roiSelector_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before roiSelector is made visible.
function roiSelector_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to roiSelector (see VARARGIN)

% Choose default command line output for roiSelector
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes roiSelector wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = roiSelector_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function sldr_channel_Callback(hObject, eventdata, handles)
% hObject    handle to sldr_channel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles.hROISelector.updateModel;

% --- Executes during object creation, after setting all properties.
function sldr_channel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sldr_channel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sldr_zPlane_Callback(hObject, eventdata, handles)
% hObject    handle to sldr_zPlane (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles.hROISelector.updateModel();

% --- Executes during object creation, after setting all properties.
function sldr_zPlane_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sldr_zPlane (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes when pnl_tiffDisplay is resized.
function pnl_tiffDisplay_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to pnl_tiffDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mnu_File_Callback(hObject, eventdata, handles)
% hObject    handle to mnu_File (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mnu_stager_Callback(hObject, eventdata, handles)
% hObject    handle to mnu_stager (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Untitled_1_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pb_addROI.
function pb_addROI_Callback(hObject, eventdata, handles)
% hObject    handle to pb_addROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hROISelector.addROI();



% --- Executes on slider movement.
function sldr_frame_Callback(hObject, eventdata, handles)
% hObject    handle to sldr_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles.hROISelector.updateModel();

% --- Executes during object creation, after setting all properties.
function sldr_frame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sldr_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in pb_removeROI.
function pb_removeROI_Callback(hObject, eventdata, handles)
% hObject    handle to pb_removeROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hROISelector.removeROI();


% --- Executes on button press in pb_registerStack.
function pb_registerStack_Callback(hObject, eventdata, handles)
% hObject    handle to pb_registerStack (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hStager.registerStack;
handles.hROISelector.updateModel();

% --- Executes on button press in pb_createTemplates.
function pb_createTemplates_Callback(hObject, eventdata, handles)
% hObject    handle to pb_createTemplates (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hStager.generateTemplates;
handles.hROISelector.updateModel();

% --- Executes on button press in rb_viewRaw.
function rb_viewRaw_Callback(hObject, eventdata, handles)
% hObject    handle to rb_viewRaw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_viewRaw
val = get(hObject,'Value');
if val == 1
    set(handles.rb_viewTemplate,'Value',0);
    set(handles.rb_viewRegistered,'Value',0);
end
handles.hROISelector.updateModel();

% --- Executes on button press in rb_viewTemplate.
function rb_viewTemplate_Callback(hObject, eventdata, handles)
% hObject    handle to rb_viewTemplate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_viewTemplate
val = get(hObject,'Value');
if val == 1
    set(handles.rb_viewRaw,'Value',0);
    set(handles.rb_viewRegistered,'Value',0);
end
handles.hROISelector.updateModel();

% --- Executes on button press in rb_viewRegistered.
function rb_viewRegistered_Callback(hObject, eventdata, handles)
% hObject    handle to rb_viewRegistered (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_viewRegistered
val = get(hObject,'Value');
if val == 1
    set(handles.rb_viewRaw,'Value',0);
    set(handles.rb_viewTemplate,'Value',0);
end
handles.hROISelector.updateModel();


% --------------------------------------------------------------------
function mnu_file_Callback(hObject, eventdata, handles)
% hObject    handle to mnu_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mnu_loadTiff_Callback(hObject, eventdata, handles)
% hObject    handle to mnu_loadTiff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hStager.loadStack();
handles.hROISelector.updateModel();

% --- Executes on button press in pb_plotROIs.
function pb_plotROIs_Callback(hObject, eventdata, handles)
% hObject    handle to pb_plotROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hStager.plotStackROI();

% --- Executes on button press in pb_clearROIs.
function pb_clearROIs_Callback(hObject, eventdata, handles)
% hObject    handle to pb_clearROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hStager.clearROIArray();

% --------------------------------------------------------------------
function mnu_loadRois_Callback(hObject, eventdata, handles)
% hObject    handle to mnu_loadRois (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pb_siGrabStack.
function pb_siGrabStack_Callback(hObject, eventdata, handles)
% hObject    handle to pb_siGrabStack (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hStager.siGrabStack();
handles.hROISelector.updateModel();

% --- Executes on button press in pb_siConnect.
function pb_siConnect_Callback(hObject, eventdata, handles)
% hObject    handle to pb_siConnect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hStager.siConnect();
handles.hROISelector.updateModel();

% --- Executes on button press in pb_siAbort.
function pb_siAbort_Callback(hObject, eventdata, handles)
% hObject    handle to pb_siAbort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hStager.siAbort();
handles.hROISelector.updateModel();


% --- Executes on button press in pb_loadTiff.
function pb_loadTiff_Callback(hObject, eventdata, handles)
% hObject    handle to pb_loadTiff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hStager.loadStack();
handles.hROISelector.updateModel();

% --- Executes on button press in pb_saveROIs.
function pb_saveROIs_Callback(hObject, eventdata, handles)
% hObject    handle to pb_saveROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hStager.saveROIs();

% --- Executes on button press in pb_loadROIs.
function pb_loadROIs_Callback(hObject, eventdata, handles)
% hObject    handle to pb_loadROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hStager.loadROIs();


% --- Executes on button press in pushbutton21.
function pushbutton21_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton22.
function pushbutton22_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton23.
function pushbutton23_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_siViewStack.
function pb_siViewStack_Callback(hObject, eventdata, handles)
% hObject    handle to pb_siViewStack (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hStager.siViewStack();
