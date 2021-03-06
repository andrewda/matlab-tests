function varargout = bird_gui(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @bird_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @bird_gui_OutputFcn, ...
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


% --- Executes just before bird_gui is made visible.
function bird_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to bird_gui (see VARARGIN)

% Choose default command line output for bird_gui
handles.output = hObject;
handles.birds = readtable('./birds.csv', 'Delimiter', ',');

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = bird_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in audio_list.
function audio_list_Callback(hObject, eventdata, handles)
% hObject    handle to audio_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get the selected audio file
selected = get(hObject, 'Value');
files = get(hObject, 'String');
path = strcat('../src_wavs/', char(files(selected)));

box_file = split(files(selected), '.');
box_path = strcat('../hja_iris_rects/', char(box_file(1)), '.txt');

% Reset audio slider
set(handles.audio_slider, 'Value', 0);

% Check if media player exists, and stop it if it does
if any(strcmp('player', fieldnames(handles)))
    stop(handles.player);
end

try
    % Read audio file and create audio plater
    [y, Fs] = audioread(path);
    handles.player = audioplayer(y, Fs);
    handles.next_position = -1;
    
    % Read box positions
    data = load(box_path);

    % Generate spectrogram
    s = create_spectrogram(y, Fs);
    w = whiten_spectrogram(s);

    colormap(gray)
    
    % Display initial spectrogram
    axes(handles.spectrogram);
    imagesc(w);
    
    axes(handles.segment);
    imagesc(w);
    hold on;
    
    % Label spectrogram
    birds_list = {};
    handles.current_birds = [];
        
    for i = 1:size(data, 1)    
        % x,y,w,h
        rect = [data(i, 1), ...
                data(i, 2), ...
                data(i, 3) - data(i, 1), ...
                data(i, 4) - data(i, 2)];
            
        rectangle('Position', rect, 'EdgeColor', 'red')
        
        handles.size = size(w, 2);
        % Bird, Start, End
        handles.current_birds = [handles.current_birds; {char(table2cell(handles.birds(data(i, 5), 2))), data(i, 1), data(i, 3)}];
        
        birds_list{end+1} = char(table2cell(handles.birds(data(i, 5), 2)));
    end
    
    % Display bird names
    set(handles.bird_names, 'String', sort(unique(birds_list(:))));

    guidata(hObject, handles);
catch
    % Create zeros matrix
    s = zeros(233, 624);
    
    colormap(gray);
    
    % Display black boxes if spectrograms fail
    axes(handles.spectrogram);
    imagesc(s);
    axes(handles.segment);
    imagesc(s);
end


% --- Executes during object creation, after setting all properties.
function audio_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to audio_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Get all wav files in src directory
files = struct2dataset(dir('../src_wavs/*.wav'));

% Set list of audio files
set(hObject, 'String', ['Select File'; files.name]);

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end


% --- Executes on slider movement.
function audio_slider_Callback(hObject, eventdata, handles)
% hObject    handle to audio_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get position of audio slider
playerinfo = get(handles.player);
position = playerinfo.TotalSamples * get(hObject, 'Value');

% Update audio position
if strcmp(get(handles.player, 'Running'), 'on')
    stop(handles.player);
    play(handles.player, round(position));
else
    handles.next_position = round(position);
    guidata(hObject, handles);
end


% --- Executes during object creation, after setting all properties.
function audio_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to audio_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', [.9 .9 .9]);
end


% --- Executes on button press in pause.
function pause_Callback(hObject, eventdata, handles)
% hObject    handle to pause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Pause the audio if it's running
if strcmp(get(handles.player, 'Running'), 'on')
    pause(handles.player);
end


% --- Executes on button press in play.
function play_Callback(hObject, eventdata, handles)
% hObject    handle to play (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Play the audio if it's not already running
if strcmp(get(handles.player, 'Running'), 'off')
    if handles.next_position >= 0
        play(handles.player, handles.next_position);

        handles.next_position = -1;
        guidata(hObject, handles);
    else
        resume(handles.player);
    end
    
    % Update audio slider every .5 seconds
    while strcmp(get(handles.player, 'Running'), 'on')
        playerinfo = get(handles.player);
        position = playerinfo.CurrentSample / playerinfo.TotalSamples;
        set(handles.audio_slider, 'Value', position);
        
        pixel_position = handles.size * position;
        set_bird = false;
        
        for i = 1:size(handles.current_birds)
            if pixel_position > cell2mat(handles.current_birds(i, 2)) && pixel_position < cell2mat(handles.current_birds(i, 3))
                set_bird = true;
                set(handles.bird_name, 'String', handles.current_birds(i, 1))
            end
        end
        
        if ~set_bird
            set(handles.bird_name, 'String', 'No Bird');
        end

        pause(0.25);
    end
end


% --- Executes on selection change in labels_list.
function labels_list_Callback(hObject, eventdata, handles)
% hObject    handle to labels_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function labels_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to labels_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor', 'white');
end
