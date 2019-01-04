function playMovie(movie,ax,clims,fps)

%%
if nargin<2 || isempty(ax)
    ax = axes;
end
if nargin<3 || isempty(clims)
   clims=[min(movie(:)) max(movie(:))];
end
if nargin<3 || isempty(fps)
   fps=10;
end

inc=1;
while ishandle(ax)
    imagesc(movie(:,:,inc),'parent',ax)
    title(['Frame number:' num2str(inc)])
    set(ax,'clim',clims)
%     colormap(ax,jet)
%     colorbar
    if inc<size(movie,3)
        inc=inc+1;
    else
        inc=1;
    end
    drawnow
    pause(1/fps)
end