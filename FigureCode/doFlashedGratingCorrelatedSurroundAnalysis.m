function doFlashedGratingCorrelatedSurroundAnalysis(node,varargin)
    ip = inputParser;
    expectedMetrics = {'integrated','peak'};
    ip.addRequired('node',@(x)isa(x,'edu.washington.rieke.jauimodel.AuiEpochTree'));
    addParameter(ip,'metric','integrated',...
        @(x) any(validatestring(x,expectedMetrics)));
    addParameter(ip,'exportFigs',true,@islogical);

    ip.parse(node,varargin{:});
    node = ip.Results.node;
    metric = ip.Results.metric;
    exportFigs = ip.Results.exportFigs;
    
    
    targetContrast = 0.5;
    targetIntensityValues = [0.3 0.4 0.5 0.6];
    
    egIntensityValue = 0.3;
        
    figure; clf; fig2=gca; initFig(fig2,'Relative center Intensity','NLI') % mean NLI vs. int for diff surrounds
    
    figure; clf; fig3=gca; initFig(fig3,'Time','trial') % Raster: grating, none
    figure; clf; fig4=gca; initFig(fig4,'Time','trial') % Raster: grating, corr
    figure; clf; fig5=gca; initFig(fig5,'Time','trial') % Raster: grating, acorr
 
    figure; clf; fig6=gca; initFig(fig6,'Time','trial') % Raster: disc, none
    figure; clf; fig7=gca; initFig(fig7,'Time','trial') % Raster: disc, corr
    figure; clf; fig8=gca; initFig(fig8,'Time','trial') % Raster: disc, acorr
    
    figure; clf; fig9=gca; initFig(fig9,'Time','Sp/s') % PSTH: none
    figure; clf; fig10=gca; initFig(fig10,'Time','Sp/s') % PSTH: corr
    figure; clf; fig11=gca; initFig(fig11,'Time','Sp/s') % PSTH: acorr
        
    populationNodes = {};
    ct = 0;
    for nn = 1:node.descendentsDepthFirst.length
        if strcmp(node.descendentsDepthFirst(nn).splitKey,...
                'protocolSettings(gratingContrast)') && node.descendentsDepthFirst(nn).custom.get('isSelected')
            ct = ct + 1;
            populationNodes(ct) = node.descendentsDepthFirst(nn); %#ok<AGROW>
        end
    end

    nliMat = [];
    diffMat = [];

    for pp = 1:length(populationNodes)
        cellNode = populationNodes{pp};
        cellInfo = getCellInfoFromEpochList(cellNode.epochList);
        recType = getRecordingTypeFromEpochList(cellNode.epochList);
        
        gratingNode = cellNode.childBySplitValue(targetContrast);
            
        respMat = nan(length(targetIntensityValues), 3, 2); %intensity x surroundType x image/disc;
        for ii = 1:length(targetIntensityValues)%for each currentIntensity
            
            intensityNode = gratingNode.childBySplitValue(targetIntensityValues(ii));

            for ss = 1:3 %for each surround type (acorr, corr, none)
                switch ss
                    case 1
                        surroundNode = intensityNode.childBySplitValue('acorr');
                    case 2
                        surroundNode = intensityNode.childBySplitValue('corr');
                    case 3
                        surroundNode = intensityNode.childBySplitValue('none');
                end
                

                imageResp = getResponseAmplitudeStats(surroundNode.childBySplitValue('image').epochList,recType);
                discResp = getResponseAmplitudeStats(surroundNode.childBySplitValue('intensity').epochList,recType);
                
                if cellNode.custom.get('isExample') & (intensityNode.splitValue == egIntensityValue) %#ok<AND2>
                    imageTrace = getMeanResponseTrace(surroundNode.childBySplitValue('image').epochList,...
                        recType,'attachSpikeBinary',true,'PSTHsigma',10);
                    discTrace = getMeanResponseTrace(surroundNode.childBySplitValue('intensity').epochList,...
                        recType,'attachSpikeBinary',true,'PSTHsigma',10);
                    switch ss
                        case 1 %acorr
                            addRastersToFigure(imageTrace.binary,fig5)
                            addRastersToFigure(discTrace.binary,fig8)
                            
                            addLineToAxis(imageTrace.timeVector,imageTrace.mean,'image',fig11,'k','-','none')
                            addLineToAxis(discTrace.timeVector,discTrace.mean,'disc',fig11,[0.4 0.4 0.4],'-','none')
                        case 2 %corr
                            addRastersToFigure(imageTrace.binary,fig4)
                            addRastersToFigure(discTrace.binary,fig7)
                            
                            addLineToAxis(imageTrace.timeVector,imageTrace.mean,'image',fig10,'k','-','none')
                            addLineToAxis(discTrace.timeVector,discTrace.mean,'disc',fig10,[0.4 0.4 0.4],'-','none')
                        case 3 %none
                            addRastersToFigure(imageTrace.binary,fig3)
                            addRastersToFigure(discTrace.binary,fig6)
                            
                            addLineToAxis(imageTrace.timeVector,imageTrace.mean,'image',fig9,'k','-','none')
                            addLineToAxis(discTrace.timeVector,discTrace.mean,'disc',fig9,[0.4 0.4 0.4],'-','none')
                    end
                    
                end

                respMat(ii,ss,1) = imageResp.(metric).mean;
                respMat(ii,ss,2) = discResp.(metric).mean;

            end %end for surroundTag
        end %end for currentIntensity      
        
        diffMat(:,:,pp) = (respMat(:,:,1) - respMat(:,:,2)); %#ok<AGROW>
        nliMat(:,:,pp) = (respMat(:,:,1) - respMat(:,:,2)) ./ (respMat(:,:,1) + respMat(:,:,2)); %#ok<AGROW>
    end %end for cell
    
    %NLI stat calcs:
    nMat = sum(~isnan(nliMat),3);
    meanMat = nanmean(nliMat,3);
    errMat = nanstd(nliMat,[],3) ./ sqrt(nMat);
    intValues = (targetIntensityValues - 0.5) / 0.5;

    addLineToAxis(intValues,meanMat(:,1),'acorr',fig2,'r','-','o')
    addLineToAxis(intValues,meanMat(:,1) + errMat(:,1),'acorr_eUp',fig2,'r','--','none')
    addLineToAxis(intValues,meanMat(:,1) - errMat(:,1),'acorr_eDown',fig2,'r','--','none')

    addLineToAxis(intValues,meanMat(:,2),'corr',fig2,'g','-','o')
    addLineToAxis(intValues,meanMat(:,2) + errMat(:,2),'corr_eUp',fig2,'g','--','none')
    addLineToAxis(intValues,meanMat(:,2) - errMat(:,2),'corr_eDown',fig2,'g','--','none')
    
    addLineToAxis(intValues,meanMat(:,3),'none',fig2,'k','-','o')
    addLineToAxis(intValues,meanMat(:,3) + errMat(:,3),'none_eUp',fig2,'k','--','none')
    addLineToAxis(intValues,meanMat(:,3) - errMat(:,3),'none_eDown',fig2,'k','--','none')
    
    
    if (exportFigs)
        makeAxisStruct(fig2,'FGcorrS_summary' ,'RFSurroundFigs')
        
        makeAxisStruct(fig3,'FGcorrS_rast_gn' ,'RFSurroundFigs')
        makeAxisStruct(fig4,'FGcorrS_rast_gc' ,'RFSurroundFigs')
        makeAxisStruct(fig5,'FGcorrS_rast_ga' ,'RFSurroundFigs')
        
        makeAxisStruct(fig6,'FGcorrS_rast_dn' ,'RFSurroundFigs')
        makeAxisStruct(fig7,'FGcorrS_rast_dc' ,'RFSurroundFigs')
        makeAxisStruct(fig8,'FGcorrS_rast_da' ,'RFSurroundFigs')
        
        makeAxisStruct(fig9,'FGcorrS_psth_none' ,'RFSurroundFigs')
        makeAxisStruct(fig10,'FGcorrS_psth_corr' ,'RFSurroundFigs')
        makeAxisStruct(fig11,'FGcorrS_psth_acorr' ,'RFSurroundFigs')
    end
end