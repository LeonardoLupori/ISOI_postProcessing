function movie = roiMovie(movie,mask)
% res = roiMovie(movie,mask)
%apply a maskROI to a movie
%
%

for i = 1:size(movie,3)
    temp = movie(:,:,i);
    temp(~mask)=NaN;
    movie(:,:,i)=temp;
end

end