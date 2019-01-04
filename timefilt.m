function filtMovie = timefilt(movie,amount)

filtMovie = zeros(size(movie));
for i = 1:size(movie,1)
    for j = 1: size(movie,2)
        filtMovie(i,j,:) = medfilt1(movie(i,j,:),amount);
    end
end