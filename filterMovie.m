function resMovie = filterMovie(movie,kSize,fType)
% resMovie = filterMovie(movie,kSize,fType)
%
% 2D spatial filter for ios
%
% movie = 3d ios movie
% kSize = filter definitions [hsize] and [hsize sigma] for gaussian
% fType = filer type [see fspecial]
%
%

if nargin <3
    fType = 'average';
end

if nargin < 2
    kSize = 1;
end

frames = size(movie,3);

if strcmpi(fType,'average')
    h = fspecial(fType,kSize);
elseif strcmpi(fType,'gaussian')
    h = fspecial(fType,kSize(1),kSize(2));
end

for i = 1 : frames
    resMovie(:,:,i) =imfilter(movie(:,:,i),h);
end


