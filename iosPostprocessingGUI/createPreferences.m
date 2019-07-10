function createPreferences()
% createPreferences creater a matfile with default preferences in the
% current path.
% You can call createPreferences to restore default preferences in case the
% preferences file is corrupted.

defaultSpaceFilter = 30;
save('iosPostprocessing_preferences.mat','defaultSpaceFilter');
m = matfile('iosPostprocessing_preferences.mat','writable',true);

% m.defaultAvgStart = 1;
m.defaultPath = 'C:\';
m.currentFile = [];
% m.defaultSpaceFilter = 30;




