function [h, outputFile] = plotCorrelationHeatmap(results, outputPath)
%==========================================================================
% plotCorrelationHeatmap.m
%
% Creates a heatmap of Pearson correlation coefficients and saves it as
% a .jpg file in the 'CorrelationResults' folder (same one used by
% saveCorrelationResults.m). Asks the user for a file name and appends
% a timestamp automatically.
%
% INPUT
% -----
% results    : table returned by runCorrelations.m (debe contener columnas
%              XVariable, YVariable, r, p)
% outputPath : carpeta base donde vive (o se creará) 'CorrelationResults'
%
% OUTPUT
% ------
% h          : handle de la figura
% outputFile : ruta completa del archivo .jpg guardado
%
%==========================================================================
%% Check / create CorrelationResults folder
if nargin < 2 || isempty(outputPath)
    error('You must provide an output folder to save the heatmap.');
end
if ~exist(outputPath,'dir')
    error('Output directory does not exist.');
end

resultsFolder = fullfile(outputPath,'CorrelationResults');
if ~exist(resultsFolder,'dir')
    mkdir(resultsFolder);
end

%% Ask for file name
answer = inputdlg( ...
    'Enter a name for the heatmap file:', ...
    'Heatmap file', ...
    [1 60], ...
    {'CorrelationHeatmap'});
if isempty(answer)
    error('Heatmap saving cancelled by user.');
end
baseName = strtrim(answer{1});
if isempty(baseName)
    baseName = 'CorrelationHeatmap';
end

%% Timestamp
timestamp = datetime("now","Format","uuuuMMdd'T'HHmmss");
fileName = sprintf('%s_%s.jpg',baseName,timestamp);
outputFile = fullfile(resultsFolder,fileName);


%% Obtain variable names
xNames = unique(results.XVariable,'stable');
yNames = unique(results.YVariable,'stable');

%% Create correlation and p-value matrices
R = nan(length(yNames),length(xNames));
P = nan(length(yNames),length(xNames));
for i = 1:height(results)
    ix = find(strcmp(xNames,results.XVariable{i}));
    iy = find(strcmp(yNames,results.YVariable{i}));
    R(iy,ix) = results.r(i);
    P(iy,ix) = results.p(i);   % asume que existe columna p
end

nX = length(xNames);
nY = length(yNames);

%% Figure - tamaño fijo en pulgadas para que el export sea predecible
h = figure('Units','inches','Position',[1 1 10 12]);
set(h,'PaperUnits','inches','PaperPosition',[0 0 10 12],'PaperSize',[10 12]);

imagesc(R);
axis equal
axis tight

%% Colormap simétrico
colormap(redBlueMap(256));
caxis([-1 1]);
cb = colorbar;
cb.Label.String = 'Pearson r';

%% Tamaño de letra de las etiquetas (adaptativo)
fontSizeLabels = max(6, min(11, 300/max(nX,nY)));

set(gca,'XTick',1:nX)
set(gca,'XTickLabel',xNames)
xtickangle(45)

set(gca,'YTick',1:nY)
set(gca,'YTickLabel',yNames)
set(gca,'FontSize',fontSizeLabels)

%xlabel('X variables')
%ylabel('Y variables')
title(baseName)

%% Anotar celdas con |r| > 0.6 (independientemente de p)
hold on

drawnow
axPos = get(gca,'Position');
set(h,'Units','pixels');
figPosPx = get(h,'Position');
set(h,'Units','inches');

axWidthPx  = axPos(3)*figPosPx(3);
axHeightPx = axPos(4)*figPosPx(4);

cellWidthPx  = axWidthPx  / nX;
cellHeightPx = axHeightPx / nY;
cellSizePx   = min(cellWidthPx, cellHeightPx);

fontSizeR = max(4, min(12, cellSizePx*0.25));

for iy = 1:nY
    for ix = 1:nX
        if ~isnan(R(iy,ix)) && abs(R(iy,ix)) > 0.6
            if ~isnan(P(iy,ix)) && P(iy,ix) < 0.05
                txt = sprintf('%.2f*', R(iy,ix));
            else
                txt = sprintf('%.2f', R(iy,ix));
            end
            text(ix, iy, txt, ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'FontSize', fontSizeR, ...
                'Color', 'k');
        end
    end
end
hold off

%% Guardar como .jpg
exportgraphics(h, outputFile, 'Resolution', 300);

%% Display message
fprintf('Heatmap saved:\n%s\n', outputFile);

end
%% ========================================================================
function cmap = redBlueMap(n)
% Blue - White - Red colormap, simétrico
if nargin<1
    n=256;
end
half = floor(n/2);
blue = [linspace(0,1,half)' ...
        linspace(0,1,half)' ...
        ones(half,1)];
red  = [ones(n-half,1) ...
        linspace(1,0,n-half)' ...
        linspace(1,0,n-half)'];
cmap = [blue; red];
end