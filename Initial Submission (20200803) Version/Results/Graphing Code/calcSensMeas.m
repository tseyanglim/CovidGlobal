function [cntMeas,glbMeas]=calcSensMeas(dtIn,cntVarIn,glbVarIn,cntLst,tmsOut)
glbMeas=[];
cntMeas=[];
for j=1:numel(tmsOut)
    for i=1:numel(cntVarIn)
        vnms=split(cntVarIn{i},'[');
        varNm=vnms{1};
        tpNm=[];
        if numel(vnms)>1
            tpNm=vnms{2};
        end
        for k=1:numel(cntLst)
            varIn=getVenData(dtIn,varNm,cntLst{k},tpNm);
            if isempty(varIn)
                cntMeas(j,i,k)=NaN;
            else
                cntMeas(j,i,k)=varIn(tmsOut(j));
            end
        end
    end
    for i=1:numel(glbVarIn)
        varIn=dtIn{contains(dtIn.Var1,glbVarIn{i}),2:end};
        glbMeas(j,i)=varIn(tmsOut(j));
    end
end


end