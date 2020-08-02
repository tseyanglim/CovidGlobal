%% CODE TO GENERATE THE GRAPHS FOR THE PAPER "ESTIMATING THE GLOBAL SPREAD OF COVID-19"
%V56 UPDATES: ADDING GRAPH WITH INSET FOR ZERO INFLATED POISSON
%DISTRIBUTION; ENHANCED REPORTING AND ADDITIONAL GRAPH 11, 12, AND VARIOUS
%OUTPUTS FOR V2 OF THE PAPER;


drvNm='C:\Users\hazhi\Dropbox (MIT)\COVID-19-TestHealth\Models and Analysis\V56\K_IterCal'; %CHANGE THIS TO ACTIVE DRIVE
flNm={'Base','PolicyA','PolicyB','PolicyC','PolicyD'}; %CHANGE THESE TO ACTIVE CIN FILES, IF CHANGED, IN THE SAME ORDER
valFlNm={'D_final_Base.tab'};       %NAME OF THE VALIDATION FILE (OLD SIMULATION FROM V54)
synFlNm={'KSyn_final_Base.tab','KSyn_sens_Base.tab'};   %NAME OF THE SYNTHETIC DATA ANALYSIS FILES
prfx='K';               %SET THIS TO THE RUN NAME
scnNm='MainV56K';        %SET A NEW NAME FOR SAVING GRAPHS
basePol=1;  %run number to be used for extracing variable values for base run

%which graphs to draw and what to save
gon=zeros(1,12);%WHICH GRAPHS TO DRAW; THERE ARE 12 BELOW [0 0 0 0 0 0 0 0 0 0 0 0]; %zeros(1,12);%ones(1,12);%[0 1 0 0 0 0 0 0 0 0 0 0];%
gon([4])=0;
repOn=1;        %WHETHER TO GENERATE THE MAIN REPORT FILE
validAnal=0;    %WHETHER TO RUN THE VALIDATION ANALYSIS REPORT
sensAnal=0;     %WHETHER TO RUN SENSITIVITY ANALYSIS REPORT
svGrph=0;       %WHETHER TO SAVE GRAPHS
ntrRep=0;       %WEATHER TO GENERATE REPORT FOR NATURE
rplcRpt=[1,0];      %WHETHER TO REPLACE THE REPORTS OR APPEND TO THEM (FIRST ELEMENT FOR REPORT; SECOND FOR GRAPH REPORTS)
readDt=0; importData=0; %WHEATHER TO READ DATA, OR IMPORT DATA THAT IS ALREADY SAVED IN THE FOLDER
varNum=524;             %THE LENGTH OF MAIN SIMULATION (ASSUMING 523 DAYS)+1
varNumPlc=752;          %THE SIZE OF THE DATA FILE
crnDay=269;             %THE LAST DAY CONSIDERED CURRENT IN THE DATASET (247 FOR JUNE 18; 267 FOR JULY 10th)
valDay=247;             %THE LAST DAY FOR RESTRICTED VALIDATION RUN
newPolDay=277;          %THE FIRST DAY OF NEW POLICY ON JULY 16

%  set file names to be used
prfNm={[prfx '_final_'],[prfx '_sens_']};
plcNm=[prfx '_PolicyResponse_base.tab'];
testFracNm=[prfx '_TestFraction_sens.tab'];

% set list of countries
cntNm={...
    'Albania','Argentina','Armenia','Australia','Austria','Azerbaijan','Bahrain','Bangladesh','Belarus','Belgium',...
    'Bolivia','Bosnia','Bulgaria','Canada','Chile','Colombia','CostaRica','Croatia','Cuba','Cyprus','CzechRepublic',...
    'Denmark','Ecuador','ElSalvador','Estonia','Ethiopia','Finland','France','Germany','Ghana','Greece',...
    'Hungary','Iceland','India','Indonesia','Iran','Ireland','Israel','Italy','Japan','Kazakhstan',...
    'Kenya','Kuwait','Kyrgyzstan','Latvia','Lithuania','Luxembourg','Malaysia','Maldives','Mexico','Morocco','Nepal','Netherlands','NewZealand','Nigeria',...
    'NorthMacedonia','Norway','Pakistan','Panama','Paraguay','Peru','Philippines','Poland','Portugal','Qatar',...
    'Romania','Russia','Rwanda','SaudiArabia','Senegal','Serbia','Singapore','Slovakia','Slovenia','SouthAfrica','SouthKorea',...
    'Spain','Sweden','Switzerland','Thailand','Tunisia','Turkey','UAE','UK','Ukraine','USA'...
    };
% set coloring and market parameters
vmarker={'o','s','d','^','v','*'};
vcolor={'blue','red','green','black','magenta','cyan'};
vstyle = {'-','--',':','-.','-'}';

% visualization choices
mxPrc=99; %the percentile to use for maximum of graphs
minInf=5;   %minimum number of daily infections to include in the graph
minCml=500;  % minimum number of cumulative cases to include in the graph
CL='%2.5';  %Lower confidence interval width of interest
CH='%97.5'; %Upper confidence interval width of interest
left_color=[0 0 1];
right_color=[1 0 0];
flwSl=[1000 1]; %scale factor for flows (per day)
cmlSl=[1e6 1000]; % scale factor for cumulative values


%% setting up basics
% getting the sensitivity file list from Checks folder
cd([drvNm '\Checks']);
listing=dir('*.tab');
sensFlNm={listing.name};
sensFlNm=sensFlNm(contains(sensFlNm,'Base')); %limiting it to those ending in Base
sensFlNm=sort(sensFlNm);        %getting everything sorted so same parameters follow each other
sensSet=ones(size(sensFlNm));   %subset of parameters focused on sensitivity analysis
sensSet([5,14,15,16,17,18])=0;        %those not parameteric sensitivity based
cd(drvNm);


%% read data
if readDt
    
    Bt=[];
    Dt=[];
    Pt=[];
    Tt=[];
    Vt=[];
    St=[];
    PSRF=[];
    Syt=[];
    opts = delimitedTextImportOptions('NumVariables',varNum,'Delimiter','\t');
    opts.VariableTypes(2:end)={'double'};
    for i=1:numel(flNm)
        
        Bt{i}=readtable([prfNm{1} flNm{i} '.tab'],opts);
        Bt{i}(:,varNum+1:end)=[];
        Dt{i}=readtable([prfNm{2} flNm{i} '.tab'],opts);
        Dt{i}(:,varNum+1:end)=[];
    end
    
    
    for i=1:numel(sensFlNm)
        St{i}=readtable(['Checks/' sensFlNm{i}],opts);
        St{i}(:,varNum+1:end)=[];
    end
    Vt{1}=readtable(valFlNm{1},opts);
    Vt{1}(:,varNum+1:end)=[];
    Vt{2}=St{5};
    
    for i=1:numel(synFlNm)
        Syt{i}=readtable(['K_Syn_IterCal/' synFlNm{i}],opts);
    end
    
    
    optsPBase = delimitedTextImportOptions('Delimiter','\t');%,'NumVariables',101);
    
    for i=1:numel(cntNm)
        xx=readtable(['PSRF/' prfx '_' cntNm{i} '_MC_MCMC_stats.tab'],optsPBase);
        optsP = delimitedTextImportOptions('Delimiter','\t','NumVariables',size(xx,2));
        optsP.VariableTypes(2:end)={'double'};
        PSRF{i}=readtable(['PSRF/' prfx '_' cntNm{i} '_MC_MCMC_stats.tab'],optsP);
    end
    
    opts = delimitedTextImportOptions('Delimiter','\t','NumVariables',varNumPlc);
    opts.VariableTypes(2:end)={'double'};
    Pt=readtable(plcNm,opts);
    Tt=readtable(testFracNm,'FileType','text','Delimiter','\t');
    
    save(['InputData' scnNm],'Bt','Dt','Tt','Pt','Vt','St','sensFlNm','PSRF','Syt');
end
if importData
    load(['InputData' scnNm]);
end
initD=datetime(2019,10,15);

%% getting country samples in place
pop=[];
rpInf=[];
rpDth=[];

inxDys=table2array(Bt{basePol}(1,2:end))<=crnDay;
inxDay=sum(inxDys); % finding last historial data point
inxDys2=table2array(Dt{basePol}(1,2:end))<=crnDay;
inxDay2=sum(inxDys2); % finding last historical data point

for i=1:numel(cntNm)
    pop(i)=Bt{basePol}{contains(Bt{basePol}.Var1,['Initial Population[' cntNm{i}]),2};
    rpIn=getVenData(Bt{basePol},'DataCmltOverTime',cntNm{i},'Infection');
    rpDt=getVenData(Bt{basePol},'DataCmltOverTime',cntNm{i},'Death');
    rpInf(i)=rpIn(inxDay);
    rpDth(i)=rpDt(inxDay);
end
cntInx=(pop>3e7 & rpInf>3e4); %index of countries for main graph; these need to be adjusted to give us 12 countries

if rplcRpt(2)
    
    fgr=fopen(['GReport' scnNm '.txt'],'w'); %file id for recording numbers associated with graphs
    
else
    fgr=fopen(['GReport' scnNm '.txt'],'a'); %file id for recording numbers associated with graphs
end


if ntrRep
    ntr=fopen(['NatureData' scnNm '.txt'],'w');
end

%% graph 1: comparing model and output generates two graphs, one in the paper and one in appendix
if gon(1)
    g1Cnm=cntNm;
    g1Vnm={'SimFlowOverTime','DataFlowOverTime'};
    for k=1:2
        g1=figure;
        if k==1
            g1Cnm=cntNm;
            numRw=11;
        else
            g1Cnm={cntNm{cntInx}};
            numRw=4;
        end
        
        numCl=floor((numel(g1Cnm)-0.001)/numRw)+1;
        
        x_width=numCl*2.5 ;y_width=numRw*1.5;
        set(g1,'Units','inches','Position',[0 0 x_width+1 y_width+1]);
        set(g1,'PaperSize',[x_width+1 y_width+1]);
        ax=[];
        Y1=[];
        for i=1:numel(g1Cnm)
            ax{i}=subplot(numRw,numCl,i);
            %    set(fig,'defaultAxesColorOrder',[left_color; right_color]);
            for j=1:numel(g1Vnm)
                Y1(j,:)=getVenData(Bt{basePol},g1Vnm{j},g1Cnm{i},'Infection');
            end
            inx=cumsum(Y1(2,:),'omitnan')>minCml & inxDys;
            X=table2array(Bt{basePol}(1,inx));
            
            %dates=initD+X;
            dates=X-78;
            
            
            plot(dates,Y1(2,inx)/flwSl(1),'k:','LineWidth',1);
            hold on
            plot(dates,Y1(1,inx)/flwSl(1),'b','LineWidth',1.5)
            ylim([0 prctile(Y1(:,inx),mxPrc,'all')/flwSl(1)])
            xlim([dates(1) dates(end)]);
            for j=1:numel(g1Vnm)
                Y1(j,:)=getVenData(Bt{basePol},g1Vnm{j},g1Cnm{i},'Death');
            end
            yyaxis 'right'
            
            plot(dates,Y1(2,inx)/flwSl(2),'k--','LineWidth',1)
            plot(dates,Y1(1,inx)/flwSl(2),'r','LineWidth',1.5)
            ylim([0 prctile(Y1(:,inx),mxPrc,'all')*3/flwSl(2)])
            title(g1Cnm{i});
            ax{i}.YAxis(1).Color = 'b';
            ax{i}.YAxis(2).Color = 'r';
            set(ax{i},'XTick',[dates(1) dates(round(end/2)) dates(end)])
            datetick(ax{i},'x','mmm','keeplimits')
            
        end
        if k==1
            sgtitle('Model Fit across All Countries');
        else
            sgtitle('Model Fit for a Sample of Countries');
        end
        if svGrph
            set(g1, 'PaperUnits', 'inches');
            
            set(g1, 'PaperPosition', [0 0 x_width y_width]); %
            print(g1,['g1-' num2str(k) '-' scnNm ],'-djpeg','-r300');
        end
    end
end

%% figure 2: prediction intervals and % tests positive
if gon(2)
    g2Vnm={'Cumulative Cases','Cumulative Deaths'};%'FractionTestsPositiveData','FractionTestsPositive'};
    for k=1:2
        if k==1
            g1Cnm=cntNm;
            numRw=11;
        else
            g1Cnm={cntNm{cntInx}};
            numRw=4;
        end
        g2=figure;
        %numR=floor(numel(g1Cnm)^0.5-0.001)+1;
        %numRw=numR+1;
        numCl=floor((numel(g1Cnm)-0.001)/numRw)+1;
        x_width=numCl*2.5 ;y_width=numRw*1.5;
        set(g2,'Units','inches','Position',[0 0 x_width+1 y_width+1]);
        set(g2,'PaperSize',[x_width+1 y_width+1]);
        ax=[];
        Y1=[];
        ZC1=[];
        ZC2=[];
        
        for i=1:numel(g1Cnm)
            ax{i}=subplot(numRw,numCl,i);
            
            for j=1:numel(g2Vnm)
                Y1(j,:)=getVenData(Bt{basePol},g2Vnm{j},g1Cnm{i},[]);
                ZC1(j,:)=getVenData(Dt{basePol},g2Vnm{j},g1Cnm{i},CL);
                ZC2(j,:)=getVenData(Dt{basePol},g2Vnm{j},g1Cnm{i},CH);
                
            end
            inx=Y1(1,:)>minCml & inxDys;
            X=table2array(Bt{basePol}(1,inx));
            dates=X-78;
            d2=table2array(Dt{basePol}(1,2:end))-78;
            inx2=(d2>=dates(1) & d2<=dates(end));
            dates2=d2(inx2);
            plot(dates,Y1(1,inx)/cmlSl(1),'b','LineWidth',1.5);
            xlim([dates(1) dates(end)]);
            set(ax{i},'XTick',[dates(1) dates(round(end/2)) dates(end)])
            datetick(ax{i},'x','mmm','keeplimits')
            hold on
            
            
            %graph with confidence intervals
            
            plot(dates2,ZC1(1,inx)/cmlSl(1),'b:','LineWidth',1);
            plot(dates2,ZC2(1,inx)/cmlSl(1),'b:','LineWidth',1);
            
            
            yyaxis 'right'
            
            plot(dates,Y1(2,inx)/cmlSl(2),'r','LineWidth',1.5)
            
            plot(dates2,ZC1(2,inx)/cmlSl(2),'r:','LineWidth',1);
            plot(dates2,ZC2(2,inx)/cmlSl(2),'r:','LineWidth',1);
            
            ylim([0 prctile(Y1(2,inx)/cmlSl(2),mxPrc,'all')*3])
            title(g1Cnm{i});
            
            
            
            
            ax{i}.YAxis(1).Color = 'b';
            ax{i}.YAxis(2).Color = 'r';
            
            
        end
        if k==1
            sgtitle('Estimated Epidemic Size across All Countries');
        else
            sgtitle('Estimated Epidemic Size');
        end
        if svGrph
            set(g2, 'PaperUnits', 'inches');
            set(g2, 'PaperPosition', [0 0 x_width y_width]); %
            print(g2,['g2-' num2str(k) '-' scnNm ],'-djpeg','-r300');
        end
    end
end

%% bar chart with ratio of estimated to official number of cases and deaths
if gon(3)
    g3Vnm={'Cumulative Cases','Cumulative Deaths','DataCmltOverTime[Infection','DataCmltOverTime[Death'};
    Y=[];
    C1=[];
    C2=[];
    Fi=[];
    IQ=[];
    dOut=[];
    p1Out=[];
    p2Out=[];
    for i=1:numel(cntNm)
        for j=1:numel(g3Vnm)
            vnms=split(g3Vnm{j},'[');
            varNm=vnms{1};
            tpNm=[];
            if numel(vnms)>1
                tpNm=vnms{2};
            end
            dOut(j,:)=getVenData(Bt{basePol},varNm,cntNm{i},tpNm);
            cOt=getVenData(Dt{basePol},varNm,cntNm{i},tpNm);
            if numel(tpNm)>0
                tpNm=[tpNm ','];
            end
            if j<3
                p1Out(j,:)=getVenData(Dt{basePol},varNm,cntNm{i},[tpNm CL]);
                p2Out(j,:)=getVenData(Dt{basePol},varNm,cntNm{i},[tpNm CH]);
                q1Out(j,:)=getVenData(Dt{basePol},varNm,cntNm{i},[tpNm '%25.0']);
                q2Out(j,:)=getVenData(Dt{basePol},varNm,cntNm{i},[tpNm '%75.0']);
            end
            
        end
        
        Y(i,:)=dOut(1:2,inxDay)./dOut(3:4,inxDay);
        C1(i,:)=p1Out(1:2,inxDay)./dOut(3:4,inxDay);
        C2(i,:)=p2Out(1:2,inxDay)./dOut(3:4,inxDay);
        IQ(i,:)=q2Out(1:2,inxDay)./dOut(3:4,inxDay)-q1Out(1:2,inxDay)./dOut(3:4,inxDay);
        Fi(i)=dOut(1,inxDay)./pop(i)*100;
        STS(i,:)=dOut(:,inxDay)';
    end
    [~,inx]=sort(Y(:,1));
    g3=figure;
    
    h=errorbar(1:numel(cntNm), Y(inx,1), Y(inx,1)-C1(inx,1),C2(inx,1)-Y(inx,1),'o','MarkerEdgeColor','blue','MarkerFaceColor','blue');
    ylabel('Ratio of Estimated to Reported (Log Scale)','fontsize',13);
    xlim([0 numel(cntNm)+1]);
    ax = ancestor(h, 'axes');
    set(ax, 'YScale', 'log')
    set(ax, 'XTick',[], 'XTickLabel',[], 'TickLabelInterpreter','none')
    xtickangle(90);
    title('Estimated vs. Reported Cases and Deaths','fontsize',15);
    ax.YGrid = 'on';
    ax.YMinorGrid='off';
    
    hold on
    errorbar(1:numel(cntNm), Y(inx,2), Y(inx,2)-C1(inx,2),C2(inx,2)-Y(inx,2),'s','MarkerEdgeColor','red','MarkerFaceColor','red')
    ymin=min(C1(inx(1),1:2));
    
    for i=1:numel(cntNm)
        xt=i;
        if rem(i, 2) == 1
            yt=max(0.1,min(C1(inx(i),1:2))*0.6^numel(cntNm{inx(i)}));
        else
            yt=max(C2(inx(i),1:2))*1.3;
        end
        text(xt,yt,cntNm(inx(i)),'Rotation',90,'FontSize',9);
    end
    ax.YLim=[0.1 ax.YLim(2)*5];
    if svGrph
        print(g3,['g3-' scnNm  ],'-djpeg','-r300');
    end
    
    fprintf(fgr,'\r\n90 Percentile and 10 percentile of actual to reported cases and deaths:\t%.2f\t%.2f\t%.2f\t%.2f\r\n',...
        Y(inx(round(0.10*numel(cntNm))),1),Y(inx(round(0.90*numel(cntNm))),1),Y(inx(round(0.10*numel(cntNm))),2),Y(inx(round(0.90*numel(cntNm))),2));
    
    fprintf(fgr,'IQR with countries, Median, and mean for ratio of actual to reported infection:\t%.3g\t%s\t%.3g\t%s\t%.3g\t%.3g\r\n',...
        Y(inx(round(0.25*numel(cntNm))),1),cntNm{inx(round(0.25*numel(cntNm)))},Y(inx(round(0.75*numel(cntNm))),1),cntNm{inx(round(0.75*numel(cntNm)))},median(Y(:,1)),mean(Y(:,1)));
    [~,inx2]=sort(Y(:,2));
    
    fprintf(fgr,'IQR with countries, Median, and mean for ratio of actual to reported deaths:\t%.3g\t%s\t%.3g\t%s\t%.3g\t%.3g\r\n',...
        Y(inx2(round(0.25*numel(cntNm))),2),cntNm{inx2(round(0.25*numel(cntNm)))},Y(inx2(round(0.75*numel(cntNm))),2),cntNm{inx2(round(0.75*numel(cntNm)))},median(Y(:,2)),mean(Y(:,2)));
    
    [~,inxPopFrc]=sort(Fi,'descend');
    fprintf(fgr,'\r\nTop fractions of population currently infected:\r\n');
    for j=1:10
        fprintf(fgr,'%.3g\t%s\r\n',Fi(inxPopFrc(j)),cntNm{inxPopFrc(j)});
    end
    
    if ntrRep
        fprintf(ntr,'Estimated vs. Reported Cases and Deaths Until July 10, 2020\r\n');
        fprintf(ntr,'Country\tEstimated cases (person)\tReported cases (person)\tEstimated to Reported Cases (ratio)\tEstimated Deaths (Person)\tReported Deaths (Person)\tEstimated to Reported Deaths (person)\r\n');
        for i=1:numel(cntNm)
            fprintf(ntr,'%s\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\r\n',cntNm{i},STS(i,1),STS(i,3),Y(i,1),STS(i,2),STS(i,4),Y(i,2));
        end
        fprintf(ntr,'Totals across 86 countries:\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\r\n',sum(STS(:,1)),sum(STS(:,3)),sum(STS(:,1))/sum(STS(:,3)),sum(STS(:,2)),sum(STS(:,4)),sum(STS(:,2))/sum(STS(:,4)));
        fprintf(ntr,'\r\nInfection fatality rate across 86 countries:\t%.3g\r\n',sum(STS(:,2))/sum(STS(:,1)));
    end
    
end

%%	A phase plot with test per million and infections per million, showing the control trajectories feasible by testing

if gon(4)
    g4Vnm={'Active Test Rate','Infection Rate'};
    g4cntNm={'USA','India','SouthKorea','Australia','Germany','Mexico'};
    g4scl=1e5;
    Z=[];
    zOut=[];
    h=[];
    Xrng=table2array(unique(Tt(:,6)));
    Yrng=table2array(unique(Tt(:,7)));
    [X,Y]=meshgrid(Xrng,Yrng);
    ZC=[];
    for i=1:numel(Xrng)
        for j=1:numel(Yrng)
            ZC(j,i)=1/(Tt{Tt{:,6}==Xrng(i) & Tt{:,7}==Yrng(j),5});
        end
    end
    
    g4=figure;
    levels=[2 4 5 10 15 30 70 200 500];
    [C,cg]=contourf(Y,X,ZC,(levels),'LineStyle','none');%,'showtext','on')
    clabel(C);
    %cg.Annotation.LegendInformation.IconDisplayStyle = 'off';
    hold on
    for i=1:numel(g4cntNm)
        pop1=getVenData(Bt{basePol},'Initial Population',g4cntNm{i},[]);
        pop1=max(pop1);
        for j=1:numel(g4Vnm)
            vnms=split(g4Vnm{j},'[');
            varNm=vnms{1};
            tpNm=[];
            if numel(vnms)>1
                tpNm=vnms{2};
            end
            zOut(j,:)=getVenData(Bt{basePol},varNm,g4cntNm{i},tpNm);
        end
        % make the plot
        inx=inxDys;
        winLen=15;
        xvin=movmean(zOut(1,inx)*g4scl/pop1,winLen);
        yvin=movmean(zOut(2,inx)*g4scl/pop1,winLen);
        h(i)=plot(xvin,yvin,'-',...
            'Marker',vmarker{i},'linewidth',1,'markersiz',4,'color',vcolor{i},'MarkerFaceColor',vcolor{i},'MarkerIndices', 1:7:sum(inx));
        p=plot(xvin(end),yvin(end),'Marker','p','markersiz',10,'color',[0.5 0.5 0.5],'MarkerFaceColor',[0.5 0.5 0.5]);
        set(get(get(p,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    end
    title('Testing, Infection, and Under-counts','fontsize',13);
    xlabel('Daily Tests per 100,000 (Log)');
    ylabel('True Daily Infections per 100,000 (Log)');
    legend(h,[g4cntNm(:)'],'location','bestoutside')
    ax = ancestor(h(i), 'axes');
    set(ax, 'YScale', 'log');
    set(ax, 'XScale', 'log');
    set(ax,'ColorScale','log');
    caxis(([3 500]))
    ax.XLim(1)=min(X,[],'all')*15;
    ax.YLim(1)=min(Y,[],'all');
    %    xlim([min(X,[],'all')*15 max(X,[],'all')*1.1]);
    %   ylim([min(Y,[],'all') max(Y,[],'all')*1.1]);
    colormap(flipud(summer))
    c=colorbar('southoutside');
    c.Label.String = 'Ratio of True Infections to Confirmed (Log Scale)';
    c.Label.FontSize=11;
    

    set( c, 'YDir', 'reverse' );
    
    if svGrph
        print(g4,['g4-' scnNm  ],'-djpeg','-r300');
    end
end

%% bar chart with time to herd immunity and minimum time to herd immunity
if gon(5)
    g5Vnm={'Time to Herd Immunity'};
    Y=[];
    C1=[];
    C2=[];
    dOut=[];
    p1Out=[];
    p2Out=[];
    for i=1:numel(cntNm)
        for j=1:numel(g5Vnm)
            vnms=split(g5Vnm{j},'[');
            varNm=vnms{1};
            tpNm=[];
            if numel(vnms)>1
                tpNm=vnms{2};
            end
            dOut(j,:)=getVenData(Bt{basePol},varNm,cntNm{i},tpNm);
            cOt=getVenData(Dt{basePol},varNm,cntNm{i},tpNm);
            if numel(tpNm)>0
                tpNm=[tpNm ','];
            end
            p1Out(j,:)=getVenData(Dt{basePol},varNm,cntNm{i},[tpNm CL]);
            p2Out(j,:)=getVenData(Dt{basePol},varNm,cntNm{i},[tpNm CH]);
        end
        
        Y(i,1)=abs(dOut(:,inxDay));
        C1(i,1)=abs(p1Out(:,inxDay2));
        C2(i,1)=abs(p2Out(:,inxDay2));
        inx=dOut(:,1:inxDay)>0;
        inx2=p1Out(:,1:inxDay2)>0;
        Y(i,2)=abs(min(dOut(inx)));
        C1(i,2)=abs(min(p1Out(inx2)));
        C2(i,2)=abs(min(p2Out(inx2)));
    end
    [~,inx]=sort(Y(:,1));
    g5=figure;
    hold on
    for j=1:size(Y,2)
        h=errorbar(1:numel(cntNm), Y(inx,j), Y(inx,j)-C1(inx,j),C2(inx,j)-Y(inx,j),vmarker{j},'MarkerEdgeColor',vcolor{j},'MarkerFaceColor',vcolor{j});
    end
    ax = ancestor(h, 'axes');
    %xrule = ax.XAxis;
    % xrule.FontSize=6;
    xlim([0 numel(cntNm)+1]);
    set(ax, 'XTick',[], 'XTickLabel',[], 'TickLabelInterpreter','none')
    %xtickangle(90);
    set(ax, 'YScale', 'log')
    title('Time to Herd Immunity','fontsize',15);
    ylabel('Estimated Days to Herd Immunity (Log Scale)','fontsize',13);
    
    ymin=min(C1(inx(1),1:2));
    
    for i=1:numel(cntNm)
        xt=i;
        if rem(i, 2) == 1
            yt=50;%max(30,min(C1(inx(i),1:2))*0.5^numel(cntNm{inx(i)}));
        else
            yt=max(C2(inx(i),1:2))*3;
        end
        text(xt,yt,cntNm(inx(i)),'Rotation',90,'FontSize',9);
    end
    ax.YLim=[30 ax.YLim(2)*5];
    
    
    if svGrph
        print(g5,['g5-' scnNm  ],'-djpeg','-r300');
    end
    fprintf(fgr,'time to herd immunity current rates:\t%.3g\t%.3g\t%.3g\t%s\t%.3g\t%.3g\t%.3g\t%s\r\n',...
        Y(inx(1),1),C1(inx(1),1),C2(inx(1),1),cntNm{inx(1)},Y(inx(end),1),C1(inx(end),1),C2(inx(end),1),cntNm{inx(end)});
    [~,inx2]=sort(Y(:,2));
    fprintf(fgr,'time to herd immunity max rates:\t%.3g\t%.3g\t%.3g\t%s\t%.3g\t%.3g\t%.3g\t%s\r\n\r\n',...
        Y(inx2(1),2),C1(inx2(1),2),C2(inx2(1),2),cntNm{inx2(1)},Y(inx2(end),2),C1(inx2(end),2),C2(inx2(end),2),cntNm{inx2(end)});
    
    
    if ntrRep
        fprintf(ntr,'\r\nTime to Herd Immunity based on 80 percent threshold for herd immunity\r\n');
        fprintf(ntr,'Country\tTime to herd immunity with current rates (95 percent credible interval)\t\t\tTime to herd immunity with maximum rates(95 percent credible interval)\r\n');
        for i=1:numel(cntNm)
            fprintf(ntr,'%s\t%.2g\t%.2g\t%.2g\t%.2g\t%.2g\t%.2g\r\n',cntNm{i},Y(i,1),C1(i,1),C2(i,1),Y(i,2),C1(i,2),C2(i,2));
        end
    end
end

%% case fatality rate graph
if gon(6)
    g6Vnm={'Cumulative Death Fraction'};
    Y=[];
    C1=[];
    C2=[];
    dOut=[];
    p1Out=[];
    p2Out=[];
    for i=1:numel(cntNm)
        for j=1:numel(g6Vnm)
            vnms=split(g6Vnm{j},'[');
            varNm=vnms{1};
            tpNm=[];
            if numel(vnms)>1
                tpNm=vnms{2};
            end
            dOut(j,:)=getVenData(Bt{basePol},varNm,cntNm{i},tpNm);
            cOt=getVenData(Dt{basePol},varNm,cntNm{i},tpNm);
            if numel(tpNm)>0
                tpNm=[tpNm ','];
            end
            p1Out(j,:)=getVenData(Dt{basePol},varNm,cntNm{i},[tpNm CL]);
            p2Out(j,:)=getVenData(Dt{basePol},varNm,cntNm{i},[tpNm CH]);
        end
        
        Y(i,1)=100*(dOut(:,inxDay));
        C1(i,1)=100*(p1Out(:,inxDay2));
        C2(i,1)=100*(p2Out(:,inxDay2));
        
    end
    [~,inx]=sort(Y(:,1));
    g6=figure;
    hold on
    for j=1:size(Y,2)
        h=errorbar(1:numel(cntNm), Y(inx,j), Y(inx,j)-C1(inx,j),C2(inx,j)-Y(inx,j),vmarker{j},'MarkerEdgeColor',vcolor{j},'MarkerFaceColor',vcolor{j});
    end
    ax = ancestor(h, 'axes');
    ax.YLim=[-1 ax.YLim(2)+0.5];
    ymin=min(C1(inx(1),1));
    for i=1:numel(cntNm)
        xt=i;
        if rem(i, 2) == 1
            yt=max(-0.9,min(C1(inx(i),1))-0.15*numel(cntNm{inx(i)}));
        else
            yt=max(C2(inx(i),1))+0.2;
        end
        text(xt,yt,cntNm(inx(i)),'Rotation',90,'FontSize',9);
    end
    %xrule = ax.XAxis;
    %xrule.FontSize=6;
    xlim([0 numel(cntNm)+1]);
    set(ax, 'XTick',[], 'XTickLabel',[])
    ax.YTick=[0 1 2 3 4 5 6];
    
    title('Estimated Infection Fatality Rates','fontsize',15);
    ylabel('Infection Fatality Rate (%)','fontsize',13);
    if svGrph
        print(g6,['g6-' scnNm  ],'-djpeg','-r300');
    end
    fprintf(fgr,'infection fatality rates (min/max/median with 95 CI):\t%.3g\t%.3g\t%.3g\t%s\t%.3g\t%.3g\t%.3g\t%s\t%.3g\t%.3g\t%.3g\t%s\r\n',...
        Y(inx(1),1),C1(inx(1),1),C2(inx(1),1),cntNm{inx(1)},Y(inx(end),1),C1(inx(end),1),C2(inx(end),1),cntNm{inx(end)},...
        Y(inx(round(end/2)),1),C1(inx(round(end/2)),1),C2(inx(round(end/2)),1),cntNm{inx(round(end/2))});
    
    if ntrRep
        fprintf(ntr,'\r\nInfection Fatality Rates Until July 10, 2020\r\n');
        fprintf(ntr,'Country\tEstimated IFR (95 percent credible interval)\r\n');
        for i=1:numel(cntNm)
            fprintf(ntr,'%s\t%.2g\t%.2g\t%.2g\r\n',cntNm{i},Y(i,1),C1(i,1),C2(i,1));
        end
        
    end
    
end

%% global cases under different scenarios
g7Vnm={'Global Cases','Global Deaths'};
g7Ttl={'Past', ' and Counter-factual';'Scenarios for Projected',''};
g7Plc={[1 2],[1 3 5]};
if gon(7)
    g7=figure;
    numRw2=2;
    ax={};
    Y1=[];
    Z1=[];
    
    for g=1:2
        axNum=1+(g-1)*2;
        ax{axNum}=subplot(numRw2,2,axNum);
        
        for j=1:numel(g7Plc{g})
            k=g7Plc{g}(j);
            Y1(j,:)=table2array(Bt{k}(contains(Bt{k}.Var1,g7Vnm{1}),2:end));
            inx=Y1(j,:)>minCml*100 & inxDys*(g==1)+~(g==1)*1e6;
            X=table2array(Bt{k}(1,inx));
            dates=X-78;
            
            plot(dates,Y1(j,inx)/cmlSl(1),'b','LineStyle',vstyle{j},'LineWidth',2);
            hold on
            
            ZC1=table2array(Dt{k}(contains(Dt{k}.Var1,[g7Vnm{1} '[' CL]),2:end));
            ZC2=table2array(Dt{k}(contains(Dt{k}.Var1,[g7Vnm{1} '[' CH]),2:end));
            d2=table2array(Dt{k}(1,2:end))-78;
            inx2=(d2>=dates(1) & d2<=dates(end));
            dates2=d2(inx2);
            
            %graph with confidence intervals
            
            plot(dates2,ZC1(inx2)/cmlSl(1),'b','LineStyle',vstyle{j},'LineWidth',0.5);
            plot(dates2,ZC2(inx2)/cmlSl(1),'b','LineStyle',vstyle{j},'LineWidth',0.5);
            fprintf(fgr,'estimates for day %d \r\n',find(inx,1,'last'));
            fprintf(fgr,'%s in scen %s:\t%.3g\t%.3g\t%.3g\r\n',g7Vnm{1},flNm{k},max(Y1(j,inx)),max(ZC1(inx2)),max(ZC2(inx2)));
            
        end
        xlim([dates(1) dates(end)]);
        set(ax{axNum},'XTick',[dates(1) dates(round(end/2)) dates(end)])
        datetick(ax{axNum},'x','mmm','keeplimits')
        title([g7Ttl{g,1} ' Cases' g7Ttl{g,2}]);
        ylabel('Cases: all Countries (millions)','fontsize',9);
        initDay=dates(1);
        axNum=2+(g-1)*2;
        ax{axNum}=subplot(numRw2,2,axNum);
        for j=1:numel(g7Plc{g})
            k=g7Plc{g}(j);
            Y1(j,:)=table2array(Bt{k}(contains(Bt{k}.Var1,g7Vnm{2}),2:end));
            inx=table2array(Bt{k}(1,2:end))-78>=initDay & inxDys*(g==1)+~(g==1)*1e6;
            X=table2array(Bt{k}(1,inx));
            dates=X-78;
            
            plot(dates,Y1(j,inx)/cmlSl(1),'r','LineStyle',vstyle{j},'LineWidth',2);
            hold on
            
            ZC1=table2array(Dt{k}(contains(Dt{k}.Var1,[g7Vnm{2} '[' CL]),2:end));
            ZC2=table2array(Dt{k}(contains(Dt{k}.Var1,[g7Vnm{2} '[' CH]),2:end));
            d2=table2array(Dt{k}(1,2:end))-78;
            inx2=(d2>=dates(1) & d2<=dates(end));
            dates2=d2(inx2);
            
            %graph with confidence intervals
            
            plot(dates2,ZC1(inx2)/cmlSl(1),'r','LineStyle',vstyle{j},'LineWidth',0.5);
            plot(dates2,ZC2(inx2)/cmlSl(1),'r','LineStyle',vstyle{j},'LineWidth',0.5);
            fprintf(fgr,'estimates for day %d \r\n',find(inx,1,'last'));
            fprintf(fgr,'%s in scen %s:\t%.3g\t%.3g\t%.3g\r\n',g7Vnm{2},flNm{k},max(Y1(j,inx)),max(ZC1(inx2)),max(ZC2(inx2)));
            
            
        end
        xlim([dates(1) dates(end)]);
        set(ax{axNum},'XTick',[dates(1) dates(round(end/2)) dates(end)])
        datetick(ax{axNum},'x','mmm','keeplimits')
        title([g7Ttl{g,1} ' Deaths' g7Ttl{g,2}]);
        ylabel('Deaths: all Countries (millions)','fontsize',9);
    end
    
    
    if svGrph
        print(g7,['g7-' scnNm  ],'-djpeg','-r300');
    end
    
end

%% errorbar charts with reproduction numbers

if gon(8)
    g8Vnm={'R Effective Reproduction Rate'};
    R0Pct=90;
    prcBased=1;
    Y=[];
    C1=[];
    C2=[];
    dOut=[];
    p1Out=[];
    p2Out=[];
    for i=1:numel(cntNm)
        for j=1:numel(g8Vnm)
            vnms=split(g8Vnm{j},'[');
            varNm=vnms{1};
            tpNm=[];
            if numel(vnms)>1
                tpNm=vnms{2};
            end
            dOut(j,:)=getVenData(Bt{basePol},varNm,cntNm{i},tpNm);
            
            cOt=getVenData(Dt{basePol},varNm,cntNm{i},tpNm);
            if numel(tpNm)>0
                tpNm=[tpNm ','];
            end
            p1Out(j,:)=getVenData(Dt{basePol},varNm,cntNm{i},[tpNm CL]);
            p2Out(j,:)=getVenData(Dt{basePol},varNm,cntNm{i},[tpNm CH]);
            q1Out(j,:)=getVenData(Dt{basePol},varNm,cntNm{i},[tpNm '%25.0']);
            q2Out(j,:)=getVenData(Dt{basePol},varNm,cntNm{i},[tpNm '%75.0']);
        end
        if prcBased
            Y(i,1)=prctile(dOut(1,inxDys),R0Pct);
            C1(i,1)=prctile(p1Out(1,inxDys2),R0Pct);
            C2(i,1)=prctile(p2Out(1,inxDys2),R0Pct);
            CQ(i,1)=prctile(q2Out(1,inxDys2),R0Pct)-prctile(q1Out(1,inxDys2),R0Pct);
            
        else
            infOut=getVenData(Bt{basePol},'Infection Rate',cntNm{i},tpNm);
            [~,inxMxI]=max(infOut);
            inxMxI=inxMxI-7;
            Y(i,1)=dOut(1,inxMxI);
            C1(i,1)=p1Out(1,inxMxI);
            C2(i,1)=p2Out(1,inxMxI);
        end
    end
    [~,inx]=sort(Y(:,1));
    g8=figure;
    hold on
    for j=1:size(Y,2)
        h=errorbar(1:numel(cntNm), Y(inx,j), Y(inx,j)-C1(inx,j),C2(inx,j)-Y(inx,j),vmarker{j},'MarkerEdgeColor',vcolor{j},'MarkerFaceColor',vcolor{j});
    end
    ax = ancestor(h, 'axes');
    ax.YLim=[0 ax.YLim(2)];
    ymin=min(C1(inx(1),1));
    for i=1:numel(cntNm)
        xt=i;
        if rem(i, 2) == 1
            yt=max(0.1,min(C1(inx(i),j))-0.25*numel(cntNm{inx(i)}));
        else
            yt=max(C2(inx(i),j))+0.5;
        end
        text(xt,yt,cntNm(inx(i)),'Rotation',90,'FontSize',9);
    end
    %xrule = ax.XAxis;
    %xrule.FontSize=6;
    xlim([0 numel(cntNm)+1]);
    set(ax, 'XTick',[], 'XTickLabel',[], 'TickLabelInterpreter','none')  %[cntNm(inx),{''}], 1:numel(cntNm)+1
    xtickangle(90);
    title('Maximum Reproduction Number','fontsize',15);
    ylabel('Secondary Infections per Index Case','fontsize',13);
    if svGrph
        print(g8,['g8-' scnNm  ],'-djpeg','-r300');
    end
    fprintf(fgr,'basic reproduction rates (Min, Max, Median, followed by mean, Sigma MIQR and IQR):\t%.3g\t%.3g\t%.3g\t%s\t%.3g\t%.3g\t%.3g\t%s\t%.3g\t%.3g\t%.3g\t%s\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\r\n',...
        Y(inx(1),1),C1(inx(1),1),C2(inx(1),1),cntNm{inx(1)},Y(inx(end),1),C1(inx(end),1),C2(inx(end),1),cntNm{inx(end)},...
        Y(inx(round(end/2)),1),C1(inx(round(end/2)),1),C2(inx(round(end/2)),1),cntNm{inx(round(end/2))},...
        mean(Y(:,1)),std(Y(:,1)),mean(CQ(:,1)),Y(inx(round(0.25*numel(cntNm))),1),Y(inx(round(0.75*numel(cntNm))),1));
    
end

%% graph with policy/behavioral response for multiple countries
if gon(9)
    g9Vnm={'Contacts Relative to Normal','Perceived Hazard of Infection'};
    g9Cnt={'USA','Japan','SouthKorea','UK','India'};
    Y=[];
    for i=1:numel(g9Cnt)
        Y(i,:)=getVenData(Pt,g9Vnm{1},g9Cnt{i},[]);
    end
    g9=figure;
    hold on
    for i=1:numel(g9Cnt)
        plot(Y(i,:)','Color',vcolor{i},'LineStyle',vstyle{i},'LineWidth',1)
    end
    ylabel({'Effective Contact Rate';'(fraction of base)'});
    yyaxis 'right'
    Z=getVenData(Pt,g9Vnm{2},g9Cnt{1},[]);
    h=plot(Z*100000,'r-','LineWidth',4);
    ax = ancestor(h, 'axes');
    set(ax, 'YScale', 'log')
    ax.YAxis(2).Color = 'r';
    xlim([0 800]);
    legend(g9Cnt,'location','southeast')
    title('Responses to Risk','fontsize',15);
    xlabel('Days');
    ylabel({'Perceived Infection Rate';'(per 100,000 per day; log scale)'});
    
    if svGrph
        print(g9,['g9-' scnNm  ],'-djpeg','-r300');
    end
    
    
end

%% bar chart for excess death
if gon(10)
    g10Vnm={'Data Excess Deaths','Excess Death End Count','Excess Death Start Count','Cumulative Missed Death'};
    Y=[];
    C1=[];
    C2=[];
    dOut=[];
    p1Out=[];
    p2Out=[];
    for i=1:numel(cntNm)
        xx=getVenData(Bt{basePol},g10Vnm{1},cntNm{i},[]);
        XDth(i)=xx(1);
        getVenData(Bt{basePol},g10Vnm{2},cntNm{i},[]);
        XDthE(i)=xx(1);
        xx=getVenData(Bt{basePol},g10Vnm{3},cntNm{i},[]);
        XDthS(i)=xx(1);
    end
    Xcnt=XDth>50;
    XDth=XDth(Xcnt);
    XDthE=XDthE(Xcnt);
    XDthS=XDthS(Xcnt);
    cntXList=cntNm(Xcnt);
    for i=1:numel(cntXList)
        xx=getVenData(Bt{basePol},g10Vnm{4},cntXList{i},[]);
        Y(i)=xx(end)/XDth(i);
        xx=getVenData(Dt{basePol},g10Vnm{4},cntXList{i},CL);
        C1(i)=xx(end)/XDth(i);
        xx=getVenData(Dt{basePol},g10Vnm{4},cntXList{i},CH);
        C2(i)=xx(end)/XDth(i);
    end
    [~,inx]=sort(XDth);
    g10=figure;
    
    h=errorbar(1:numel(cntXList), Y(inx), Y(inx)-C1(inx),C2(inx)-Y(inx),'o','MarkerEdgeColor','blue','MarkerFaceColor','blue');
    ylabel('Estimated to Reported Excess Death Ratio','fontsize',13);
    xlim([0 numel(cntXList)+1]);
    ax = ancestor(h, 'axes');
    %set(ax, 'YScale', 'log')
    set(ax, 'XTick',[1:numel(cntXList)],'XTickLabel',cntXList(inx), 'TickLabelInterpreter','none')
    xtickangle(90);
    title('Estimated to Reported Excess Deaths','fontsize',15);
    
    if svGrph
        print(g10,['g10-' scnNm  ],'-djpeg','-r300');
    end
    
end


%% bar chart with totoal cases and deaths by end of winter 2021
if gon(11)
    numCntInc=30;   %number of countries to include in the comparative graph
    g11Vnm={'Cumulative Cases','Cumulative Deaths','R Effective Reproduction Rate'};
    
    Y=[];
    C1=[];
    C2=[];
    dOut=[];
    p1Out=[];
    p2Out=[];
    p3Out=[];
    for i=1:numel(cntNm)
        for j=1:numel(g11Vnm)
            varNm=g11Vnm{j};
            
            tpNm=[];
            
            dOut(j,:)=getVenData(Bt{basePol},varNm,cntNm{i},tpNm);
            %cOt=getVenData(Dt{basePol},varNm,cntNm{i},tpNm);
            
            
            p1Out(j,:)=getVenData(Dt{basePol},varNm,cntNm{i},[tpNm CL]);
            p2Out(j,:)=getVenData(Dt{basePol},varNm,cntNm{i},[tpNm CH]);
            p3Out(j,:)=getVenData(Dt{basePol},varNm,cntNm{i},[tpNm '%50.0']);
            
        end
        numDays=size(dOut,2);
        Y(i,:)=[p3Out(1:2,end)/pop(i)*100;p3Out(3,newPolDay);dOut(1:2,end)/pop(i)*100];
        C1(i,:)=[p1Out(1:2,end)/pop(i)*100;p1Out(3,newPolDay)];
        C2(i,:)=[p2Out(1:2,end)/pop(i)*100;p1Out(3,newPolDay)];
    end
    [~,inx]=sort(Y(:,1));
    g11=figure;
    
    h=errorbar(1:numel(cntNm), Y(inx,1), Y(inx,1)-C1(inx,1),C2(inx,1)-Y(inx,1),'o','MarkerEdgeColor','blue','MarkerFaceColor','blue');
    ylabel('Cumulative Infection % (Log Scale)','fontsize',13);
    xlim([0 numel(cntNm)+1]);
    ax = ancestor(h, 'axes');
    set(ax, 'YScale', 'log')
    %ylim([0.001 150])
    
    %xrule = ax.XAxis;
    %xrule.FontSize=6;
    set(ax, 'XTick',[], 'XTickLabel',[], 'TickLabelInterpreter','none')
    xtickangle(90);
    
    title('Projected Cases and Deaths, 3/20/2021','fontsize',15);
    
    ax.YLim=[ax.YLim(1)*0.1 ax.YLim(2)*10];
    ymin=ax.YLim(1);
    ymax=ax.YLim(2);
    for i=1:numel(cntNm)
        xt=i;
        if rem(i, 2) == 1
            yt=ymin*1.1;
        else
            yt=ymax*0.6^(numel(cntNm{inx(i)})^0.7);
        end
        text(xt,yt,cntNm(inx(i)),'Rotation',90,'FontSize',9);
    end
    ax.YGrid = 'on';
    ax.YMinorGrid='off';
    
    hold on
    yyaxis 'right'
    h2=errorbar(1:numel(cntNm), Y(inx,2), Y(inx,2)-C1(inx,2),C2(inx,2)-Y(inx,2),...
        's','MarkerEdgeColor','red','MarkerFaceColor','red');
    ax = ancestor(h2, 'axes');
    set(ax, 'YScale', 'log');
    ax.YLim=[ax.YLim(1)*0.1 ax.YLim(2)*10];
    ylabel('Cumulative Death % (Log Scale)','fontsize',13);
    ax.YGrid = 'on';
    ax.YMinorGrid='off';
    if svGrph
        print(g11,['g11-' scnNm  ],'-djpeg','-r300');
    end
    %
    prjI=[Y(:,1)'.*pop/100; C1(:,1)'.*pop/100; C2(:,1)'.*pop/100; Y(:,4)'.*pop/100];
    prjD=[Y(:,2)'.*pop/100; C1(:,2)'.*pop/100; C2(:,2)'.*pop/100; Y(:,5)'.*pop/100];
    fprintf(fgr,'Min and max (median 95 CI modes at the end; country) infection projections:\t%.3g\t%.3g\t%.3g\t%s\t%.3g\t%.3g\t%.3g\t%s\t%.3g\t%.3g\r\n',...
        Y(inx(1),1),C1(inx(1),1),C2(inx(1),1),cntNm{inx(1)},Y(inx(end),1),C1(inx(end),1),C2(inx(end),1),cntNm{inx(end)},Y(inx2(1),4),Y(inx2(end),4));
    [~,inx2]=sort(Y(:,2));
    fprintf(fgr,'Min and max (median 95 CI modes at the end; country) death projections:\t%.3g\t%.3g\t%.3g\t%s\t%.3g\t%.3g\t%.3g\t%s\t%.3g\t%.3g\r\n\r\n',...
        Y(inx2(1),2),C1(inx2(1),2),C2(inx2(1),2),cntNm{inx2(1)},Y(inx2(end),2),C1(inx2(end),2),C2(inx2(end),2),cntNm{inx2(end)},Y(inx2(1),5),Y(inx2(end),5));
    
    
    [~,inx3]=sort(prjI(1,:),'descend');
    fprintf(fgr,'\r\nTop ten projections for day %d from scenario (median, 95p, mode for both at the end) %s\r\n',numDays,flNm{basePol});%need replication
    for i=1:10
        fprintf(fgr,'%s Infections and Deaths:\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\r\n',cntNm{inx3(i)},prjI(1,inx3(i)),prjI(2,inx3(i)),prjI(3,inx3(i)),prjD(1,inx3(i)),prjD(2,inx3(i)),prjD(3,inx3(i)),prjI(4,inx3(i)),prjD(4,inx3(i)));
    end
    fprintf(fgr,'Global Infections and Deaths:\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\r\n\r\n',sum(prjI(1,:)),sum(prjI(2,:)),sum(prjI(3,:)),sum(prjD(1,:)),sum(prjD(2,:)),sum(prjD(3,:)));
    
    
    %creating the numbers for alternative scenario
    YB=Y; C1B=C1; C2B=C2;
    Y=[]; C1=[]; C2=[];
    newPol=5;       %scenario number to be used
    
    for i=1:numel(cntNm)
        for j=1:numel(g11Vnm)
            varNm=g11Vnm{j};
            
            tpNm=[];
            dOut(j,:)=getVenData(Bt{newPol},varNm,cntNm{i},tpNm);
            p1Out(j,:)=getVenData(Dt{newPol},varNm,cntNm{i},[tpNm CL]);
            p2Out(j,:)=getVenData(Dt{newPol},varNm,cntNm{i},[tpNm CH]);
            p3Out(j,:)=getVenData(Dt{newPol},varNm,cntNm{i},[tpNm '%50.0']);
        end
        numDays=size(dOut,2);
        Y(i,:)=[p3Out(1:2,end)/pop(i)*100;dOut(3,newPolDay);dOut(1:2,end)/pop(i)*100];
        C1(i,:)=[p1Out(1:2,end)/pop(i)*100;p1Out(3,newPolDay)];
        C2(i,:)=[p2Out(1:2,end)/pop(i)*100;p1Out(3,newPolDay)];
    end
    
    prjI=[Y(:,1)'; C1(:,1)'; C2(:,1)'; Y(:,4)'].*pop/100;
    prjD=[Y(:,2)'; C1(:,2)'; C2(:,2)'; Y(:,5)'].*pop/100;
    fprintf(fgr,'Top ten projections for day %d from scenario (median, 95 percent, most likely for both infections and deaths at the end) %s\r\n',numDays,flNm{newPol});
    [~,inx3]=sort(prjI(1,:),'descend');
    for i=1:10
        fprintf(fgr,'%s Infections and Deaths:\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\r\n',cntNm{inx3(i)},prjI(1,inx3(i)),prjI(2,inx3(i)),prjI(3,inx3(i)),prjD(1,inx3(i)),prjD(2,inx3(i)),prjD(3,inx3(i)),prjI(4,inx3(i)),prjD(4,inx3(i)));
    end
    
    if ntrRep
        fprintf(ntr,'\r\nProjected Cases and Deaths Until March 20, 2021 with modest improvement in response\r\n');
        fprintf(ntr,'Country\tEstimated cases (person)\tLower confidence bound\tUpper confidence bound\tEstimated deaths(person)\tLower confidence bound\tUpper confidence bound\r\n');
        for i=1:numel(cntNm)
            fprintf(ntr,'%s\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\r\n',cntNm{i},prjI(1,i),prjI(2,i),prjI(3,i),prjD(1,i),prjD(2,i),prjD(3,i));
        end
        fprintf(ntr,'Across 86 countries:\t%.3g\r\n',sum(prjI(1,:)),sum(prjI(2,:)),sum(prjI(3,:)),sum(prjD(1,:)),sum(prjD(2,:)),sum(prjD(3,:)));
    end
    
    % The change values versions
    YC=YB-Y;
    C1C=C1B-Y(:,1:3);
    C2C=C2B-Y(:,1:3);
    fprintf(fgr,'Contact Reduction percent from base in new policy (mean,sigma):\t%.3g\t%.3g\r\n',...
        mean(YC(:,3)./YB(:,3))*100,std(YC(:,3)./YB(:,3))*100);
    [~,inx]=sort(YC(:,1),'descend');
    inx=inx(1:numCntInc);
    g112=figure;
    
    h=errorbar(1:numCntInc, YC(inx,1), YC(inx,1)-C1C(inx,1),C2C(inx,1)-YC(inx,1),'o','MarkerEdgeColor','blue','MarkerFaceColor','blue');
    ylabel('Reduction in % Cumulative Infection','fontsize',13);
    xlim([0 numCntInc+1]);
    ax = ancestor(h, 'axes');
    %set(ax, 'YScale', 'log')
    ylim([0 ax.YLim(2)]);
    
    %xrule = ax.XAxis;
    %xrule.FontSize=6;
    set(ax, 'XTick',[], 'XTickLabel',[], 'TickLabelInterpreter','none')
    xtickangle(90);
    
    title({'Infection Reduction Opportunities';'from Stronger Response'},'fontsize',15);
    
    %ax.YLim=[ax.YLim(1)*0.1 ax.YLim(2)*10];
    ymin=ax.YLim(1);
    ymax=ax.YLim(2);
    for i=1:numCntInc
        xt=i;
        if i<numCntInc/2
            yt=ymin+2;
        else
            yt=ymax-4*(numel(cntNm{inx(i)}))^0.7;
        end
        text(xt,yt,cntNm(inx(i)),'Rotation',90,'FontSize',10);
    end
    
    
    yyaxis right
    h=errorbar(1:numCntInc, YC(inx,3)./YB(inx,3)*100, (YC(inx,3)-C1C(inx,3))./YB(inx,3)*100,(C2C(inx,3)-YC(inx,3))./YB(inx,3)*100,'s','MarkerEdgeColor','red','MarkerFaceColor','red');
    ylabel('Reduction in Contacts (%)','fontsize',13);
    ylim([0 100]);
    
    %ax.YGrid = 'on';
    %ax.YMinorGrid='off';
    
    if svGrph
        print(g112,['g11-2-' scnNm  ],'-djpeg','-r300');
    end
    
    
    
    fprintf(fgr,'top 10 countries in cumulative reduction (percentage of population) by better response\r\n');
    for i=1:10
        fprintf(fgr,'%s\t%.0f\t\r\n',cntNm{inx(i)},YC(inx(i),1));
    end
    
    
    
    %% graph 12: future projections
    
    g12Vnm={'Infection Rate','Death Rate'};
    dyInx=varNum-1;  %day from which to take the data
    g12=figure;
    
    g12Cnm=cntNm;
    numR=floor(numel(g12Cnm)^0.5-0.001)+1;
    numRw=numR+1;
    numCl=numR-2;
    x_width=numCl*2.5 ;y_width=numRw*1.5;
    set(g12,'Units','inches','Position',[0 0 x_width+1 y_width+1]);
    set(g12,'PaperSize',[x_width+1 y_width+1]);
    
    ax=[];
    Y1=[];
    Y1e=[];
    ZC1e=[];
    ZC2e=[];
    ZC1=[];
    ZC2=[];
    
    for i=1:numel(g12Cnm)
        ax{i}=subplot(numRw,numCl,i);
        
        for j=1:numel(g12Vnm)
            %Y1(j,:)=getVenData(Bt{basePol},g12Vnm{j},g12Cnm{i},[]);
            Y1(j,:)=getVenData(Dt{basePol},g12Vnm{j},g12Cnm{i},'%50.0');
            ZC1(j,:)=getVenData(Dt{basePol},g12Vnm{j},g12Cnm{i},CL);
            ZC2(j,:)=getVenData(Dt{basePol},g12Vnm{j},g12Cnm{i},CH);
            % calculating end percentage flows (last month)
            Y1e(i,j)=mean(Y1(j,dyInx-30:dyInx))/pop(i)*100000;
            ZC1e(i,j)=mean(ZC1(j,dyInx-30:dyInx))/pop(i)*100000;
            ZC2e(i,j)=mean(ZC2(j,dyInx-30:dyInx))/pop(i)*100000;
        end
        if i==1
            glbRt=Y1;
            glbRC1=ZC1;
            glbRC2=ZC2;
        else
            glbRt=glbRt+Y1;
            glbRC1=glbRC1+ZC1;
            glbRC2=glbRC2+ZC2;
        end
        
        
        inx=cumsum(Y1(1,:),'omitnan')>minCml;
        X=table2array(Bt{basePol}(1,inx));
        
        dates=X-78;
        
        
        plot(dates,Y1(1,inx)/flwSl(1),'b','LineWidth',1.5);
        xlim([dates(1) dates(end)]);
        set(ax{i},'XTick',[dates(1) dates(round(end/2)) dates(end)])
        datetick(ax{i},'x','mmm','keeplimits')
        hold on
        
        plot(dates,ZC1(1,inx)/flwSl(1),'b:','LineWidth',1);
        plot(dates,ZC2(1,inx)/flwSl(1),'b:','LineWidth',1);
        yyaxis 'right'
        
        plot(dates,Y1(2,inx)/flwSl(2),'r','LineWidth',1.5)
        plot(dates,ZC1(2,inx)/flwSl(2),'r:','LineWidth',1);
        plot(dates,ZC2(2,inx)/flwSl(2),'r:','LineWidth',1);
        ylim([0 prctile(Y1(2,inx),mxPrc)/flwSl(2)*3])
        
        
        title(g12Cnm{i});
        ax{i}.YAxis(1).Color = 'b';
        ax{i}.YAxis(2).Color = 'r';
        
        
    end
    
    sgtitle('Projections until end of Winter 2021');
    
    if svGrph
        
        
        set(g12, 'PaperUnits', 'inches');
        set(g12, 'PaperPosition', [0.5 0.5 x_width y_width]); %
        print(g12,['g12-' scnNm  ],'-djpeg','-r300');
    end
    fprintf(fgr,'\r\nEnd Time Global Cases and Deaths as fraction of Population\r\n');
    totPop=sum(pop);
    fprintf(fgr,'%.3g\t%.3g\t%.3g\t\t%.3g\t%.3g\t%.3g\r\n',glbRt(1,end)/totPop,glbRC1(1,end)/totPop,glbRC2(1,end)/totPop,glbRt(2,end)/totPop,glbRC1(2,end)/totPop,glbRC2(2,end)/totPop);
    
    
    g122=figure;
    [~,inx]=sort(Y1e(:,1));
    
    h=errorbar(1:numel(cntNm), Y1e(inx,1), Y1e(inx,1)-ZC1e(inx,1),ZC2e(inx,1)-Y1e(inx,1),'o','MarkerEdgeColor','blue','MarkerFaceColor','blue');
    ylabel('Daily Infections per 100K (Log Scale)','fontsize',13);
    xlim([0 numel(cntNm)+1]);
    ax = ancestor(h, 'axes');
    set(ax, 'YScale', 'log')
    %ylim([0.001 150])
    
    %xrule = ax.XAxis;
    %xrule.FontSize=6;
    set(ax, 'XTick',[], 'XTickLabel',[], 'TickLabelInterpreter','none')
    xtickangle(90);
    
    title('Projected Infection and Death Rates, Late Winter 2021','fontsize',15);
    
    ax.YLim=[ax.YLim(1)*0.1 ax.YLim(2)*10];
    ymin=ax.YLim(1);
    ymax=ax.YLim(2);
    for i=1:numel(cntNm)
        xt=i;
        if rem(i, 2) == 1
            yt=ymin*1.1;
        else
            yt=ymax*0.55^(numel(cntNm{inx(i)})^0.75);
        end
        text(xt,yt,cntNm(inx(i)),'Rotation',90,'FontSize',9);
    end
    ax.YGrid = 'on';
    ax.YMinorGrid='off';
    
    hold on
    yyaxis 'right'
    h2=errorbar(1:numel(cntNm), Y1e(inx,2), Y1e(inx,2)-ZC1e(inx,2),ZC2e(inx,2)-Y1e(inx,2),...
        's','MarkerEdgeColor','red','MarkerFaceColor','red');
    ax = ancestor(h2, 'axes');
    set(ax, 'YScale', 'log');
    ax.YLim=[ax.YLim(1)*0.1 ax.YLim(2)*10];
    ylabel('Daily Deaths per 100K (Log Scale)','fontsize',13);
    ax.YGrid = 'on';
    ax.YMinorGrid='off';
    if svGrph
        print(g122,['g12-2-' scnNm  ],'-djpeg','-r300');
    end
    
    
    
    fprintf(fgr,'\r\nSome Countries with major variance in winter 2021 infection rates in baseline (infection rate per 100k, Re)\r\n');
    lrgCnt=(pop>3e7).*Y1e(:,1)';
    numCnt=sum(lrgCnt>0);
    [~,inx4]=sort(lrgCnt,'descend');
    for i=1:3:numCnt
        fprintf(fgr,'%s\t%.3g\t%.3g\r\n',cntNm{inx4(i)},Y1e(inx4(i),1), YB(inx4(i),3));
    end
    
    
end
fclose(fgr);
if ntrRep
    fclose(ntr);
end
%% graph for poisson distribution
if gon(12)
    % This section graphs the number of people who do and do not have Covid
    % for 0-12 symptoms. It also has the number of people within each group of
    % missing 1 symptom in the testing decision
    % Input Arguments:
    
    m = 6;% mean of poisson
    r = 9;%ratio of Covid negative to positive
    N = 100/(1+r);% total Covid positive count
    f0 =0.55;% proportion of Covid positive that has no symptoms
    % p1 = probability of 1 missing symptom in the testing decision
    p1=0.95; p2=0.8;
    mxSymp=14;
    
    %making sure p1 is greater than p2 (needed for code to perform properly%
    if p2>p1
        [p2, p1] = deal(p1, p2);
    end
    
    %Ranges of Symptoms%
    total_symptoms= 0:mxSymp;
    inset_symptoms=5:mxSymp;
    
    %Counts for Covid Negative%
    no_covid = r*N./factorial(total_symptoms)./exp(1);
    no_covid_inset = r*N./factorial(inset_symptoms)./exp(1);
    
    %Counts for Covid Positive%
    covid = N*(1-f0)*poisspdf(total_symptoms,m);
    covid(1) = N*f0;
    covid_inset = N*(1-f0)*poisspdf(inset_symptoms,m);
    
    
    %Counts for p1 Negative%
    p1_negative = no_covid.*(1-(p1.^total_symptoms));
    p1_negative = covid+p1_negative;
    p1_negative_inset = no_covid_inset.*(1-(p1.^inset_symptoms));
    p1_negative_inset = covid_inset+p1_negative_inset;
    
    %Counts for p1 Positive%
    p1_positive = covid.*(1-(p1.^total_symptoms));
    p1_positive = covid - p1_positive;
    p1_positive_inset = covid_inset.*(1-(p1.^inset_symptoms));
    p1_positive_inset = covid_inset - p1_positive_inset;
    
    %Counts for p2 Negative%
    p2_negative = no_covid.*(1-(p2.^total_symptoms));
    p2_negative = p1_positive+p2_negative;
    p2_negative_inset = no_covid_inset.*(1-(p2.^inset_symptoms));
    p2_negative_inset = p1_positive_inset+p2_negative_inset;
    
    %Counts for p1 Positive%
    p2_positive = covid.*(1-(p2.^total_symptoms));
    p2_positive = covid - p2_positive;
    p2_positive_inset = covid_inset.*(1-(p2.^inset_symptoms));
    p2_positive_inset = covid_inset - p2_positive_inset;
    
    %Assigning Colors%
    
    c1 = [0,0,1]; %Solid Blue, Covid Neg for p1%
    c2 = [.4,.4,1]; %Light Blue, Covid Neg for p2%
    c3 = [1,0,0]; %Solid Red, Covid Pos for p1%
    c4 = [1,0.6,0.6]; %Light Red, Covid Pos for p2%
    
    %This makes the original graph%
    
    g13=figure;
    
    hold on
    
    bar(total_symptoms, no_covid+covid,'Facecolor', [1,1,1], 'Edgecolor', c1);
    bar(total_symptoms, p2_negative,'Facecolor', c2, 'Edgecolor', c2);
    bar(total_symptoms, p1_negative,'Facecolor', c1, 'Edgecolor', c1);
    bar(total_symptoms, covid, 'Facecolor', c3, 'Edgecolor', c3);
    bar(total_symptoms, p1_positive, 'Facecolor', c4, 'Edgecolor', c4);
    bar(total_symptoms, p2_positive, 'Facecolor', [1,1,1], 'Edgecolor', c3);
    title({'\fontsize{15}True Positives and Negatives from Testing';['\fontsize{13}True Prevelance ' num2str(round(100*1/(r+1))) '%; \alpha_{C}=' num2str(m)]})
    ylabel('% of Population','fontsize',13);
    xlabel('Number of Symptoms','fontsize',13);
    legend({'Not Tested, Negative', ...
        ['Tested, Negative; p_{MS}= ', num2str(p2)], ...
        ['Tested, Negative; p_{MS}= ', num2str(p1)],...
        ['Tested, Positive; p_{MS}= ', num2str(p1)],...
        ['Tested, Positive; p_{MS}= ', num2str(p2)],'Not Tested, Positive'})
    
    %This makes the inset%
    
    axes('Position',[.45 .2 .45 .3])
    title('Those with More Symptoms')
    hold on
    box on
    bar(inset_symptoms, no_covid_inset+covid_inset,'Facecolor', [1,1,1], 'Edgecolor', c1);
    bar(inset_symptoms, p2_negative_inset,'Facecolor', c2, 'Edgecolor', c2);
    bar(inset_symptoms, p1_negative_inset,'Facecolor', c1, 'Edgecolor', c1);
    bar(inset_symptoms, covid_inset, 'Facecolor', c3, 'Edgecolor', c3);
    bar(inset_symptoms, p1_positive_inset, 'Facecolor', c4, 'Edgecolor', c4);
    bar(inset_symptoms, p2_positive_inset, 'Facecolor', [1,1,1], 'Edgecolor', c3);
    
    if svGrph
        print(g13,['g13-' scnNm  ],'-djpeg','-r300');
    end
end





%% generating report with various numbers
if repOn
    calstats=1;
    if rplcRpt(1)
        fid=fopen(['rep' scnNm '.txt'],'w');
    else
        fid=fopen(['rep' scnNm '.txt'],'a');
    end
    fprintf(fid,'Total Countries Covered:\t%d \r\n',numel(cntNm));
    fprintf(fid,'Total Population Covered:\t%d \r\n',sum(pop));
    
    %parameter distributions
    prmNm={'Base Fatality Rate for Unit Acuity','Baseline Daily Fraction Susceptible Seeking Tests','Confirmation Impact on Contact',...
        'Covid Acuity Relative to Flu','Dread Factor in Risk Perception',...
        'Impact of Population Density on Hospital Availability','Impact of Treatment on Fatality Rate','Reference COVID Hospitalization Fraction Confirmed',...
        'Min Contact Fraction','Multiplier Recent Infections to Test','Multiplier Transmission Risk for Asymptomatic','Patient Zero Arrival Time',...
        'Reference Force of Infection','Sensitivity of Fatality Rate to Acuity','Sensitivity of Contact Reduction to Utility',...
        'Time to Downgrade Risk','Time to Upgrade Risk',...
        'Total Asymptomatic Fraction','Weight on Reported Probability of Infection'};
    prmLb={'f_b','n_{ST}','m_T','\alpha_C','\lambda','s_{DH}','s_{HF}','r_H','c_{Min}','m_{IT}','m_a','T_0','\beta','s_f','s_C','\tau_{RD}','\tau_{RU}','a','w_R'};
    varRepNm={'R Effective Reproduction Rate','Infection Rate','Death Rate'};
    varNorm=[0,1,1];
    dyInx=varNum-1;  %final day from which to take the data
    if calstats
        
        msDvNm={'DataCmltOverTime','DataFlowOverTime'};
        msSvNm={'SimCmltOverTime','SimFlowOverTime'};
        subNm={'Infection','Death'};
        parB=[];
        parC1=[];
        parC2=[];
        psyB=[];
        psyC1=[];
        psyC2=[];
        inqR=[];
        mae=[];
        crr=[];
        varB=[];
        inqVR=[];
        CLR={'%1.0','%2.5','%5.0','%10.0','%25.0'};
        CHR={'%99.0','%97.5','%95.0','%90.0','%75.0'};
        for j=1:numel(cntNm)
            for i=1:numel(prmNm)
                
                parB(i,j)=Bt{basePol}{contains(Bt{basePol}.Var1,[prmNm{i} '[' cntNm{j}]),2};
                inqR(i,j)=Dt{basePol}{contains(Dt{basePol}.Var1,[prmNm{i} '[' cntNm{j} ',%75.0']),2}-Dt{basePol}{contains(Dt{basePol}.Var1,[prmNm{i} '[' cntNm{j} ',%25.0']),2};
                parC1(i,j)=Dt{basePol}{contains(Dt{basePol}.Var1,[prmNm{i} '[' cntNm{j} ',' CL]),2};
                parC2(i,j)=Dt{basePol}{contains(Dt{basePol}.Var1,[prmNm{i} '[' cntNm{j} ',' CH]),2};
                
                psyB(i,j)=Syt{1}{contains(Syt{1}.Var1,[prmNm{i} '[' cntNm{j}]),2};
                for k=1:numel(CLR)
                    psyC1(i,j,k)=Syt{2}{contains(Syt{2}.Var1,[prmNm{i} '[' cntNm{j} ',' CLR{k}]),2};
                    psyC2(i,j,k)=Syt{2}{contains(Syt{2}.Var1,[prmNm{i} '[' cntNm{j} ',' CHR{k}]),2};
                end
                
            end
            
            for i=1:numel(varRepNm)
                
                varIn=getVenData(Bt{basePol},varRepNm{i},cntNm{j},[]);
                varB(i,j)=mean(varIn(dyInx-30:dyInx))*(1-varNorm(i)+varNorm(i)/pop(j)*100);
                varIn=getVenData(Dt{basePol},varRepNm{i},cntNm{j},'%75.0')-getVenData(Dt{basePol},varRepNm{i},cntNm{j},'%25.0');
                inqVR(i,j)=mean(varIn(dyInx-30:dyInx))*(1-varNorm(i)+varNorm(i)/pop(j)*100);
            end
            
            
            
            dtout=[];
            stout=[];
            inxDt=[];
            
            for k=1:numel(msDvNm)
                for m=1:numel(subNm)
                    %calculating measures of fit
                    dtout(k,m,:)=getVenData(Bt{basePol},msDvNm{k},cntNm{j},subNm{m});
                    stout(k,m,:)=getVenData(Bt{basePol},msSvNm{k},cntNm{j},subNm{m});
                    inxDt=squeeze(dtout(1,1,:)>max(50,0.001*rpInf(j)));%this is the inclusion criteria from model
                    mae(k,m,j)=mean(abs(dtout(k,m,inxDt)-stout(k,m,inxDt)))/mean(dtout(k,m,inxDt));
                    crr(k,m,j)=(corr(squeeze(dtout(k,m,inxDt)),squeeze(stout(k,m,inxDt))))^2;
                    if j==1
                        dtoutg(k,m,:)=nansum(Bt{basePol}{contains(Bt{basePol}.Var1,msDvNm{k}) & contains(Bt{basePol}.Var1,subNm{m}),2:end},1);
                        stoutg(k,m,:)=nansum(Bt{basePol}{contains(Bt{basePol}.Var1,msSvNm{k}) & contains(Bt{basePol}.Var1,subNm{m}),2:end},1);
                        inxDt=squeeze(dtoutg(1,1,:)>max(50,0.001*rpInf(j))); %this is the inclusion criteria from model
                        maeg(k,m)=mean(abs(dtoutg(k,m,inxDt)-stoutg(k,m,inxDt)))/mean(dtoutg(k,m,inxDt));
                        crrg(k,m)=(corr(squeeze(dtoutg(k,m,inxDt)),squeeze(stoutg(k,m,inxDt))))^2;
                    end
                end
            end
            dtNow(j,:)=squeeze(dtout(1,:,inxDay));
        end
    end
    
    ffit=fopen('FitStats.txt','w');
    fprintf(ffit,'Country\tmae CmlInf\tmae CmlDth\tmae FlwInf\tmae FlwDth\tcrr CmlInf\tcrr CmlDth\tcrr FlwInf\tcrr FlwDth\r\n');
    for i=1:size(mae,3)
        fprintf(ffit,'%s\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\r\n',cntNm{i},mae(1,1,i),mae(1,2,i),mae(2,1,i),mae(2,2,i),crr(1,1,i),crr(1,2,i),crr(2,1,i),crr(2,2,i));
    end
    
    fclose(ffit);
    
    fprintf(fid,'\r\nFit stats for \t cumulative infection\t (median)\t cumulative death\t (median)\t flow of infection\t (median)\t flow of death\t (median)\r\n');
    fprintf(fid,'MAE Normalized: \t%.3g\t(%.3g)\t%.3g\t(%.3g)\t%.3g\t(%.3g)\t%.3g\t(%.3g)\r\n',maeg(1,1),median(squeeze(mae(1,1,:))),maeg(1,2),median(mae(1,2,:)),maeg(2,1),median(mae(2,1,:)),maeg(2,2),median(mae(2,2,:)));
    fprintf(fid,'r-squared: \t%.3g\t(%.3g)\t%.3g\t(%.3g)\t%.3g\t(%.3g)\t%.3g\t(%.3g)\r\n',crrg(1,1),median(crr(1,1,:)),crrg(1,2),median(crr(1,2,:)),crrg(2,1),median(crr(2,1,:)),crrg(2,2),median(crr(2,2,:)));
    fprintf(fid,'r-squared above 0.9 and 0.5 (fraction of sample)\t%.3g\t%.3g\r\n\r\n',sum(crr>0.9,'all')/sum(crr>0,'all'),sum(crr>0.5,'all')/sum(crr>0,'all'));
    
    
    [maeVals,inxPr]=sort(squeeze(mae(1,2,:)),'descend');
    for i=1:10
        fprintf(fid,'poor fit for fatality in:%s at %.3f MAE\r\n',cntNm{inxPr(i)},maeVals(i));
    end
    glbI=Bt{basePol}{contains(Bt{basePol}.Var1,'Global Cases'),2:end};
    glbIC1=Dt{basePol}{contains(Dt{basePol}.Var1,['Global Cases[' CL]),2:end};
    glbIC2=Dt{basePol}{contains(Dt{basePol}.Var1,['Global Cases[' CH]),2:end};
    glbD=Bt{basePol}{contains(Bt{basePol}.Var1,'Global Deaths'),2:end};
    glbDC1=Dt{basePol}{contains(Dt{basePol}.Var1,['Global Deaths[' CL]),2:end};
    glbDC2=Dt{basePol}{contains(Dt{basePol}.Var1,['Global Deaths[' CH]),2:end};
    fprintf(fid,'\r\ncovered population:\t%d\ttotal infections:\t%d\t%d\t%d\ttotal deaths:\t%d\t%d\t%d\r\n',sum(pop),max(glbI(inxDys)),max(glbIC1(inxDys2)),max(glbIC2(inxDys2)),...
        max(glbD(inxDys)),max(glbDC1(inxDys2)),max(glbDC2(inxDys2)));
    fprintf(fid,'Ratio to reported numbers is:\t%.3g\tfor infections and\t%.3g\tfor deaths\r\n\r\n',...
        glbI(inxDay)/sum(rpInf),glbD(inxDay)/sum(rpDth));
    
    
    %
    
    glbIFR=Bt{basePol}{contains(Bt{basePol}.Var1,'Global IFR'),2:end};
    glbIFR=glbIFR(inxDys);
    glbIFRC1=Dt{basePol}{contains(Dt{basePol}.Var1,['Global IFR[' CL]),2:end};
    glbIFRC1=glbIFRC1(inxDys2);
    glbIFRC2=Dt{basePol}{contains(Dt{basePol}.Var1,['Global IFR[' CH]),2:end};
    glbIFRC2=glbIFRC2(inxDys2);
    fprintf(fid,'Global Infection Fatality Rate:\t%.3g\t%.3g\t%.3g\r\n\r\n',glbIFR(end),glbIFRC1(end),glbIFRC2(end));
    %
    
    fprintf(fid,'Parameter\t mean\t std\t mean of interquartile range\r\n');
    for i=1:numel(prmNm)
        
        fprintf(fid,'%s:\t%d\t%d\t%d\r\n',prmNm{i},mean(parB(i,:)),std(parB(i,:)),mean(inqR(i,:)));
    end
    
    %location of threshold 8 in the percentile distribution
    perc = prctile(parB(15,:),1:100);
    [c index] = min(abs(perc'-8));
    xx = index+1;
    fprintf(fid,'\r\nvalue of 8 is at percentile:\t%d\r\n',xx);
    
    %add global rates at the end for the likely scanario
    
    clear gI gIC1 gIC2 gD gDC1 gDC2;
    for i=1:numel(cntNm)
        gI(i,:)=getVenData(Bt{basePol},'Infection Rate',cntNm{i},[]);
        %
        gIC1(i,:)=getVenData(Dt{basePol},'Infection Rate',cntNm{i},CL);
        gIC2(i,:)=getVenData(Dt{basePol},'Infection Rate',cntNm{i},CH);
        gD(i,:)=getVenData(Bt{basePol},'Death Rate',cntNm{i},[]);
        gDC1(i,:)=getVenData(Dt{basePol},'Death Rate',cntNm{i},CL);
        gDC2(i,:)=getVenData(Dt{basePol},'Death Rate',cntNm{i},CH);
        %
    end
    popCoef=sum(pop)/100;
    fprintf(fid,'\r\nFinal Infection Rates Baseline Scenario:\t%.3g\t%.3g\t%.3g\r\n',sum(gI(:,end))/popCoef,sum(gIC1(:,end))/popCoef,sum(gIC2(:,end))/popCoef);
    fprintf(fid,'Final Death Rates Baseline Scenario:\t%.3g\t%.3g\t%.3g\r\n',sum(gD(:,end))/popCoef,sum(gDC1(:,end))/popCoef,sum(gDC2(:,end))/popCoef);
    [~,inxFr]=sort(gI(:,end),'descend');
    for i=1:10
        fprintf(fid,'Top final infection rates: \t%.3g\t%s\r\n',gI(inxFr(i),end),cntNm{inxFr(i)});
    end
    j=sum(contains(cntNm,'USA').*(1:numel(cntNm)));
    [usI,usDt]=max(gI(j,:));
    fprintf(fid,'\r\nmax USA infection:\t%d\t%d\r\n',usI,usDt);
    
    %additional stats for abstract
    cntLst={'Chile','India','Iran','Mexico','NewZealand','Spain','UK','USA'};
    repVars={'Cumulative Cases','Cumulative Deaths'};
    Y=[];
    fprintf(fid,'\r\nInfection and IFR Percentage for a few countries\r\n');
    for i=1:numel(cntLst)
        pcnt=Bt{basePol}{contains(Bt{basePol}.Var1,['Initial Population[' cntLst{i}]),2};
        Y(1,:)=getVenData(Bt{basePol},repVars{1},cntLst{i},[]);
        Y(2,:)=getVenData(Bt{basePol},repVars{2},cntLst{i},[]);
        Yo=Y(:,inxDay);
        
        fprintf(fid,'%s\t%.3g\t%.3g\r\n',cntLst{i},Yo(1)/pcnt*100,Yo(2)/Yo(1)*100);
    end
    
    % reported numbers in V2 to be added
    atAll=[];
    for i=1:numel(cntNm)
        atr=getVenData(Bt{basePol},'Active Test Rate',cntNm{i},[]);
        infR=getVenData(Bt{basePol},'DataFlowOverTime',cntNm{i},'Infection');
        atAll(i,:)=atr(inxDys)/pop(i);
        atAll(i,isnan(infR(inxDys)) | infR(inxDys)<1)=NaN;
    end
    fprintf(fid,'\r\n95 percent range of testing rates (percent of population per day) in data:\t%.3g\t%.4f\r\n',prctile(atAll,5,'all')*100,prctile(atAll,95,'all')*100);
    
    fprintf(fid,'\r\nMean, stdev, MIQR for final 30 days of base projection\r\n');
    for i=1:numel(varRepNm)
        fprintf(fid,'%s\t%0.3g\t%0.3g\t%0.3g\r\n',varRepNm{i},mean(varB(i,:)),std(varB(i,:)),mean(inqVR(i,:)));
    end
    
    frcMae=sum(mae<0.2,3)/numel(cntNm);
    fprintf(fid,'\r\n\rFraction MAEN under 0.2\r\n');
    fprintf(fid,'Cml Infection\tCml Death\tFlow Infection\tFlow Death\r\n');
    fprintf(fid,'%.3g\t%.3g\t%.3g\t%.3g\r\n',frcMae(1,1),frcMae(1,2),frcMae(2,1),frcMae(2,2));
    
    
    fprintf(fid,'\r\nCumulative Case Range and Pseudo-CFR Range from Data\r\n');
    fprintf(fid,'Data: Cumulative Case Range\t%.3g\t%.3g\r\n',max(dtNow(:,1)./pop'*100000),min(dtNow(:,1)./pop'*100000));
    fprintf(fid,'Data: CFR Range\t%.3g\t%.3g\r\n',max(dtNow(:,2)./dtNow(:,1)),min(dtNow(:,2)./dtNow(:,1)));
    
    % reporting PSRF results
    psrf=[];
    cmcp=[];
    for i=1:numel(cntNm)
        psrf(:,i)=table2array(PSRF{i}(contains(PSRF{i}.Var1,'PSRF') & ~(contains(PSRF{i}.Var1,'PSRF Payoff')),end));
        cmcp(i)=table2array(PSRF{i}(contains(PSRF{i}.Var1,'CMCP'),end));
    end
    fprintf(fid,'\r\nFraction of PSRF below 1.2 and 1.1 (total number of parameters):\t%.2g\t%.2g\t%.3g\r\n',...
        100*(1-sum(psrf>1.2,'all')/numel(psrf)),100*(1-sum(psrf>1.1,'all')/numel(psrf)),numel(psrf));
    
    syIn=[];
    syNormDiff=[];
    for k=1:numel(CLR)
        syIn{k}=(parB<=psyC2(:,:,k)) & (parB>=psyC1(:,:,k));
        syNormDiff{k}=abs(parB-psyB)./(psyC2(:,:,k)-psyC1(:,:,k));
    end
    
    fprintf(fid,'\r\nSynthetic Analysis: Fraction of parameters in different intervals:\r\n')
    for k=1:numel(CLR)
        fprintf(fid,'%s to %s\t%.3g\r\n',CLR{k},CHR{k},sum(syIn{k},'all')/numel(parB));
    end
    fprintf(fid,'median distance to true value, in percent of 50, 90, and 95 percent CI:\t%.3g\t%.3g\t%.3g\r\n',...
        100*nanmedian(syNormDiff{5},'all'),100*nanmedian(syNormDiff{3},'all'),100*nanmedian(syNormDiff{2},'all'));
    fprintf(fid,'percent errors more than 20, 50, 80 percent of 95CI gap\t%.3g\t%.3g\t%.3g\r\n',...
        100*sum(syNormDiff{2}<0.2,'all')/numel(parB),100*sum(syNormDiff{2}<0.5,'all')/numel(parB),100*sum(syNormDiff{2}<0.8,'all')/numel(parB));
    
    sensW=Bt{basePol}{contains(Bt{basePol}.Var1,'Sensitivity to Weather'),2};
    fprintf(fid,'Sensitivity to weather:\t%.3g\r\n',sensW);
    
    fclose(fid);
    % graphs for parameters
    for k=1:2
        gp=figure;
        numRw=10;
        if k==1
            rows=[1:numRw];
        else
            rows=[numRw+1:size(parB,1)];
        end
        numCl=1;
        ax=[];
        for i=rows
            ax{i}=subplot(numel(rows),numCl,i-(k-1)*numRw);
            errorbar(1:numel(cntNm), parB(i,:), parB(i,:)-parC1(i,:),parC2(i,:)-parB(i,:),'o','MarkerEdgeColor','blue','MarkerFaceColor','blue','MarkerSize',3);
            %ylabel(prmNm{i},'fontsize',10);
            xlim([0 numel(cntNm)+1]);
            xrule = ax{i}.XAxis;
            xrule.FontSize=5;
            if i==rows(end)
                cntMrk=[];
                for j=1:numel(cntNm)
                    cntMrk{j}=[num2str(j) '-' cntNm{j}];
                end
                set(ax{i}, 'XTick',1:numel(cntNm), 'XTickLabel',cntMrk, 'TickLabelInterpreter','none')
                
            else
                set(ax{i}, 'XTick',1:numel(cntNm), 'XTickLabel',[1:numel(cntNm)], 'TickLabelInterpreter','none');
            end
            xtickangle(90);
            
            title([prmNm{i} ' (' prmLb{i} ')'],'fontsize',6);
        end
        if svGrph
            set(gp, 'PaperUnits', 'inches');
            x_width=5.5 ;y_width=9;
            set(gp, 'PaperPosition', [0 0 x_width y_width]); %
            print(gp,['gp-' num2str(k) '-' scnNm  ],'-djpeg','-r300');
        end
        
    end
    
    
    % graphs for synthetic parameters
    for k=1:2
        gsy=figure;
        numRw=10;
        if k==1
            rows=[1:numRw];
        else
            rows=[numRw+1:size(parB,1)];
        end
        numCl=1;
        ax=[];
        for i=rows
            ax{i}=subplot(numel(rows),numCl,i-(k-1)*numRw);
            errorbar(1:numel(cntNm), psyB(i,:), psyB(i,:)-psyC1(i,:,2),psyC2(i,:,2)-psyB(i,:),'o','MarkerEdgeColor','blue','MarkerFaceColor','blue','MarkerSize',3);
            hold on
            scatter(1:numel(cntNm),parB(i,:),"Xr");
            %ylabel(prmNm{i},'fontsize',10);
            xlim([0 numel(cntNm)+1]);
            xrule = ax{i}.XAxis;
            xrule.FontSize=5;
            if i==rows(end)
                cntMrk=[];
                for j=1:numel(cntNm)
                    cntMrk{j}=[num2str(j) '-' cntNm{j}];
                end
                set(ax{i}, 'XTick',1:numel(cntNm), 'XTickLabel',cntMrk, 'TickLabelInterpreter','none')
                
            else
                set(ax{i}, 'XTick',1:numel(cntNm), 'XTickLabel',[1:numel(cntNm)], 'TickLabelInterpreter','none');
            end
            xtickangle(90);
            
            title([prmNm{i} ' (' prmLb{i} ')'],'fontsize',6);
        end
        if svGrph
            set(gsy, 'PaperUnits', 'inches');
            x_width=5.5 ;y_width=9;
            set(gsy, 'PaperPosition', [0 0 x_width y_width]); %
            print(gsy,['gsy-' num2str(k) '-' scnNm  ],'-djpeg','-r300');
        end
        
    end
    
    
end

%% creating the validation run reports
if validAnal
    valT=[valDay+1 inxDay]; %validation time range; note that +1 is included because first day is "0"
    fvalf=fopen('validFit.txt','w');
    fprintf(fvalf,'Infection MAEN between days %d and %d for different countries:\tcurrent run\told run\told ratio\told data new test\told data new test ratio\r\n',valT(1),valT(2));
    crnFit=calcFitMeas(Bt{basePol},Bt{basePol},'SimFlowOverTime','DataFlowOverTime',valT,cntNm,{'Infection'});
    oldFit=calcFitMeas(Vt{1},Bt{basePol},'SimFlowOverTime','DataFlowOverTime',valT,cntNm,{'Infection'});
    oldFitTstDt=calcFitMeas(Vt{2},Bt{basePol},'SimFlowOverTime','DataFlowOverTime',valT,cntNm,{'Infection'});
    fitRto=crnFit./oldFit;
    fitRtoT=crnFit./oldFitTstDt;
    for i=1:numel(cntNm)
        fprintf(fvalf,'%s\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\r\n',cntNm{i},crnFit(i),oldFit(i),fitRto(i),oldFitTstDt(i),fitRtoT(i));
    end
    
    fprintf(fvalf,'\r\nMean Fit Ratio old and old with new test:\t%.3g\t%.3g\r\n',nanmean(fitRto),nanmean(fitRtoT));
    fclose(fvalf);
    
    gv1Cnm=cntNm;
    gv1Vnm={'SimFlowOverTime','DataFlowOverTime'};
    
    for j=1:size(Vt,2)
        
        gv1=figure;
        gv1Cnm=cntNm;
        numRw=11;
        
        numCl=floor((numel(gv1Cnm)-0.001)/numRw)+1;
        
        x_width=numCl*2.5 ;y_width=numRw*1.5;
        set(gv1,'Units','inches','Position',[0 0 x_width+1 y_width+1]);
        set(gv1,'PaperSize',[x_width+1 y_width+1]);
        ax=[];
        Y1=[];
        for i=1:numel(gv1Cnm)
            ax{i}=subplot(numRw,numCl,i);
            %    set(fig,'defaultAxesColorOrder',[left_color; right_color]);
            yout=getVenData(Vt{j},g1Vnm{1},gv1Cnm{i},'Infection');
            if numel(yout)>0
                Y1(1,:)=yout;
                Y1(2,:)=getVenData(Bt{basePol},g1Vnm{2},gv1Cnm{i},'Infection');
                
                inx=cumsum(Y1(2,:),'omitnan')>minCml & inxDys;
                X=table2array(Bt{basePol}(1,inx));
                
                %dates=initD+X;
                dates=X-78;
                
                
                plot(dates,Y1(2,inx)/flwSl(1),'k:','LineWidth',1);
                hold on
                plot(dates,Y1(1,inx)/flwSl(1),'b','LineWidth',1.5)
                ylim([0 prctile(Y1(:,inx),mxPrc,'all')/flwSl(1)])
                xlim([dates(1) dates(end)]);
                line([dates(end-(crnDay-valDay)) dates(end-(crnDay-valDay))],[ax{i}.YLim(1) ax{i}.YLim(2)]);
                
                
                Y1(1,:)=getVenData(Vt{j},g1Vnm{1},gv1Cnm{i},'Death');
                Y1(2,:)=getVenData(Bt{basePol},g1Vnm{2},gv1Cnm{i},'Death');
                yyaxis 'right'
                
                plot(dates,Y1(2,inx)/flwSl(2),'k--','LineWidth',1)
                plot(dates,Y1(1,inx)/flwSl(2),'r','LineWidth',1.5)
                ylim([0 prctile(Y1(:,inx),mxPrc,'all')*3/flwSl(2)])
                title(gv1Cnm{i});
                ax{i}.YAxis(1).Color = 'b';
                ax{i}.YAxis(2).Color = 'r';
                set(ax{i},'XTick',[dates(1) dates(round(end/2)) dates(end)])
                datetick(ax{i},'x','mmm','keeplimits')
            end
        end
        
        if j==1
            titStr='No Test Data';
        else
            titStr='With Test Data';
        end
        sgtitle(['Early Model Fit across All Countries: ' titStr]);
        
        if svGrph
            set(gv1, 'PaperUnits', 'inches');
            
            set(gv1, 'PaperPosition', [0 0 x_width y_width]); %
            print(gv1,['gv1-' num2str(j) '-' scnNm ],'-djpeg','-r300');
        end
    end
    
end

%% creating sensitivity analysis results
if sensAnal
    pChgPrnt=10;   %percentage of changes in parameters to calculate elasticities
    fitT=[1 inxDay];
    cntVarIn={'Cumulative Cases','Cumulative Deaths','DataCmltOverTime[Infection','DataCmltOverTime[Death','Infection Rate','Death Rate'};
    glbVarIn={'Global Cases','Global Deaths','Global IFR'};
    tmsOut=[inxDay varNum-1];
    cntMeas=[];
    glbMeas=[];
    cntMeasB=[];
    glbMeasB=[];
    frcCngG=[];
    frcCngC=[];
    allMeasC=[];
    allMeasG=[];
    % all sensitivity measures
    for i=1:numel(sensFlNm)
        [cntMeas{i},glbMeas{i}]=calcSensMeas(St{i},cntVarIn,glbVarIn,cntNm,tmsOut);
        cntFI=calcFitMeas(St{i},St{i},'SimFlowOverTime','DataFlowOverTime',fitT,cntNm,{'Infection'});
        cntFD=calcFitMeas(St{i},St{i},'SimFlowOverTime','DataFlowOverTime',fitT,cntNm,{'Death'});
        cntFitMeas{i}=[cntFI;cntFD];
    end
    [cntMeasB,glbMeasB]=calcSensMeas(Bt{basePol},cntVarIn,glbVarIn,cntNm,tmsOut); %baseline measures
    cntFI=calcFitMeas(Bt{basePol},Bt{basePol},'SimFlowOverTime','DataFlowOverTime',fitT,cntNm,{'Infection'});
    cntFD=calcFitMeas(Bt{basePol},Bt{basePol},'SimFlowOverTime','DataFlowOverTime',fitT,cntNm,{'Death'});
    cntFitMeasB=[cntFI;cntFD];
    allMeasBC=[squeeze(cntMeasB(1,1:2,:)./cntMeasB(1,3:4,:));squeeze(cntMeasB(2,5:6,:));cntFitMeasB];
    allMeasBG=[squeeze(glbMeasB(1,:,:)),squeeze(glbMeasB(2,:,:))];
    % calculate reports
    fsens=fopen('sensOutputs.txt','w');
    fsncmp=fopen('sensOutCompact.txt','w');
    fprintf(fsens,'Sensitivity analysis results\r\n\r\n');
    fprintf(fsens,'Country-level elasticity/sensitivity between two sensitivity runs (elasticities) or against base (sensitivities)\r\n');
    fprintf(fsncmp,'Elasticities and sensitivities (percentage) averaged over countries and for global measures\r\n\r\n');
    fprintf(fsncmp,'Run\tAve Case Undercount Ratio\tAve Death Undercount Ratio\tAve Final Infection Rate\tAve Final Death Rate\tAve MAEN Infection\tAve MAEN Death\r\n');
    fprintf(fsncmp,'Run\tCases Early\tDeaths Early\tIFR Early\tCases Proj.\tDeaths Proj.\tIFR Proj.\r\n');
    
    k=1;i=1;
    while i<=numel(sensFlNm)
        %creating measures: infection underreport, death underreport, final
        %infection rate, final death rate; global: cases, deaths, IFR
        
        allMeasC{i}=[squeeze(cntMeas{i}(1,1:2,:)./cntMeas{i}(1,3:4,:));squeeze(cntMeas{i}(2,5:6,:));cntFitMeas{i}];
        allMeasG{i}=[squeeze(glbMeas{i}(1,:,:)),squeeze(glbMeas{i}(2,:,:))];
        if sensSet(i)==1
            i=i+1;
            allMeasC{i}=[squeeze(cntMeas{i}(1,1:2,:)./cntMeas{i}(1,3:4,:));squeeze(cntMeas{i}(2,5:6,:));cntFitMeas{i}];
            allMeasG{i}=[squeeze(glbMeas{i}(1,:,:)),squeeze(glbMeas{i}(2,:,:))];
            frcCngC{k}=100*2*(allMeasC{i}-allMeasC{i-1})./(allMeasC{i}+allMeasC{i-1})/pChgPrnt;
            frcCngG{k}=100*2*(allMeasG{i}-allMeasG{i-1})./(allMeasG{i}+allMeasG{i-1})/pChgPrnt;
            sensNm=['Elasticities: ' sensFlNm{i} ' vs ' sensFlNm{i-1}];
            
        else
            
            frcCngC{k}=100*(allMeasC{i}-allMeasBC)./allMeasBC;
            frcCngG{k}=100*(allMeasG{i}-allMeasBG)./allMeasBG;
            sensNm=['sensitivities: ' sensFlNm{i}];
        end
        fprintf(fsens,'\r\n\r\n\r\n%s\r\n',sensNm);
        fprintf(fsens,'Country\tCase Undercount Ratio\tDeath Undercount Ratio\tFinal Infection Rate\tFinal Death Rate\tMAEN Infection\tMAEN Death\r\n');
        for j=1:numel(cntNm)
            fprintf(fsens,'%s\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\r\n',cntNm{j},frcCngC{k}(1,j),frcCngC{k}(2,j),frcCngC{k}(3,j),frcCngC{k}(4,j),frcCngC{k}(5,j),frcCngC{k}(6,j));
        end
        fprintf(fsens,'Average\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\r\n',nanmean(frcCngC{k}(1,:)),nanmean(frcCngC{k}(2,:)),nanmean(frcCngC{k}(3,:)),nanmean(frcCngC{k}(4,:)),nanmean(frcCngC{k}(5,:)),nanmean(frcCngC{k}(6,:)));
        fprintf(fsncmp,'Country Average %s\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\r\n',sensNm,nanmean(frcCngC{k}(1,:)),nanmean(frcCngC{k}(2,:))...
            ,nanmean(frcCngC{k}(3,:)),nanmean(frcCngC{k}(4,:)),nanmean(frcCngC{k}(5,:)),nanmean(frcCngC{k}(6,:)));
        fprintf(fsncmp,'Global %s\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\r\n',sensNm,frcCngG{k}(1),frcCngG{k}(2),frcCngG{k}(3),frcCngG{k}(4),frcCngG{k}(5),frcCngG{k}(6));
        fprintf(fsens,'\r\nGlobal Percentage Changes and Elasticities\r\n');
        fprintf(fsens,'Cases Early\tDeaths Early\tIFR Early\tCases Proj.\tDeaths Proj.\tIFR Proj.\r\n');
        fprintf(fsens,'%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\r\n',frcCngG{k}(1),frcCngG{k}(2),frcCngG{k}(3),frcCngG{k}(4),frcCngG{k}(5),frcCngG{k}(6));
        
        i=i+1;
        k=k+1;
        
    end
    
    
    fclose(fsncmp);
    fclose(fsens);
end


%% functions
function dta=getVenData(dtNm,varNm,cNm,tpNm)
if isempty(tpNm)
    vNm=[varNm '[' cNm ];
else
    vNm=[varNm '[' cNm ',' tpNm];
end
dta=table2array(dtNm(contains(dtNm.Var1,vNm),2:end));
end
