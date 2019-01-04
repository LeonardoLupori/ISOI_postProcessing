function statusBar(handle,string,color)
% statusBar(handle)
% statusBar(handle,string)
% statusBar(handle,string,color)
% 
% statusBar update a textbox in a GUI with a provided
% string and color
% 
% INPUT
% handle: handle to the textbox
% string(optional): a string to be displayed in the textbox
% color(optional): the color of the box [R G B]

if nargin==1
    string = 'Ready';
    color = [0.7 1 0.7];
end
if nargin==2
    color = [1 1 .7];
end
set(handle,'string',string,'BackgroundColor',color)
drawnow;