function maen=calcFitMeas(simIn,dtIn,varSimIn,varDtIn,periodIn,cntNm,subNm)

for j=1:numel(cntNm)
    for m=1:max(1,numel(subNm))
        %calculating measures of fit
        dtout=getVenData(dtIn,varDtIn,cntNm{j},subNm{m});
        stout=getVenData(simIn,varSimIn,cntNm{j},subNm{m});
        if isempty(stout)
            maen(m,j)=NaN;
        else
        inxDt=false(size(dtout(1,:)));
        inxDt(periodIn(1):periodIn(2))=true;
        maen(m,j)=nanmean(abs(dtout(inxDt)-stout(inxDt)))/nanmean(dtout(inxDt));
        end
    end
end
end