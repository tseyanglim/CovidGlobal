function dta=getVenData(dtNm,varNm,cNm,tpNm)
if isempty(tpNm)
    vNm=[varNm '[' cNm ];
else
    vNm=[varNm '[' cNm ',' tpNm];
end
dta=table2array(dtNm(contains(dtNm.Var1,vNm),2:end));
end