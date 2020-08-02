drvNm='C:\Users\hazhi\Dropbox (MIT)\COVID-19-TestHealth\Models and Analysis\V54\D_IterCal';
flNm={'Base','PolicyA','PolicyB','PolicyC','PolicyD'};
prfNm={'D_final_','D_sens_'};
scnNm='MainV54';
plcNm='D_PolicyResponse.tab';
testFracNm='D_TestFraction_sens.tab';

%which graphs to draw and what to save
gon=[0 0 0 0 0 0 0 0 0 0 0 0]; %zeros(1,12);%ones(1,12);%ones(1,12);%[0 1 0 0 0 0 0 0 0 0 0 0];%
repOn=1;
svGrph=1;
readDt=0; importData=0;
varNum=524;
varNumPlc=752;
crnDay=248;

%cntNm={'Germany','Iran','Italy','SouthKorea','USA'};%{'Austria','Bangladesh','Belarus','Belgium','Canada','Chile','Colombia','Denmark','Ecuador','France','India','Indonesia','Iran','Ireland','Israel','Italy','Japan','Mexico','Netherlands','Pakistan','Peru','Philippines','Poland','Portugal','Qatar','Romania','Russia','Serbia','SouthAfrica','SouthKorea','Switzerland','Turkey','UK','Ukraine','USA'};
cntNm={...
    'Albania','Argentina','Armenia','Australia','Austria','Azerbaijan','Bahrain','Bangladesh','Belarus','Belgium',...
    'Bolivia','Bosnia','Bulgaria','Canada','Chile','Colombia','CostaRica','Croatia','Cuba','CzechRepublic',...
    'Denmark','Ecuador','ElSalvador','Estonia','Ethiopia','Finland','France','Germany','Ghana','Greece',...
    'Hungary','Iceland','India','Indonesia','Iran','Ireland','Israel','Italy','Japan','Kazakhstan',...
    'Kenya','Kuwait','Kyrgyzstan','Latvia','Lithuania','Luxembourg','Malaysia','Maldives','Mexico','Morocco','Nepal','Netherlands','NewZealand','Nigeria',...
    'NorthMacedonia','Norway','Pakistan','Panama','Paraguay','Peru','Philippines','Poland','Portugal','Qatar',...
    'Romania','Russia','SaudiArabia','Senegal','Serbia','Singapore','Slovakia','Slovenia','SouthAfrica','SouthKorea',...
    'Spain','Sweden','Switzerland','Thailand','Tunisia','Turkey','UAE','UK','Ukraine','USA'...
    };

g1Cnm=cntNm;%{'USA'};%{'France','Germany','UK','USA','Iran','Sweden','Italy','SouthKorea','Australia'};
vmarker={'o','s','d','^','v','*'};
vcolor={'blue','red','green','black','magenta','cyan'};
vstyle = {'-','--',':','-.','-'}';

% visualization choices
mxPrc=99; %the percentile to use for maximum of graphs
minInf=5;   %minimum number of daily infections to include in the graph (in thousands)
minCml=500;  % minimum number of cumulative cases to include in the graph
CL='%2.5';  %Lower confidence interval width of interest
CH='%97.5'; %Upper confidence interval width of interest
left_color=[0 0 1];
right_color=[1 0 0];
flwSl=[1000 1]; %scale factor for flows
cmlSl=[1e6 1000]; % scale factor for cumulative values





%% setting up basics
cd(drvNm);


%% read data
if readDt
    
    Bt=[];
    Dt=[];
    Pt=[];
    Tt=[];
    for i=1:numel(flNm)
        opts = delimitedTextImportOptions('NumVariables',varNum,'Delimiter','\t');
        opts.VariableTypes(2:end)={'double'};
        Bt{i}=readtable([prfNm{1} flNm{i} '.tab'],opts);
        Bt{i}(:,varNum+1:end)=[];
        Dt{i}=readtable([prfNm{2} flNm{i} '.tab'],opts);
        Dt{i}(:,varNum+1:end)=[];
    end
    opts = delimitedTextImportOptions('Delimiter','\t','NumVariables',varNumPlc);
    opts.VariableTypes(2:end)={'double'};
    Pt=readtable(plcNm,opts);
    Tt=readtable(testFracNm,'FileType','text','Delimiter','\t');
    save(['InputData' scnNm],'Bt','Dt','Tt','Pt');
end
if importData
    load(['InputData' scnNm]);
end
initD=datetime(2019,10,15);

%% getting country samples in place
pop=[];
rpInf=[];
for i=1:numel(cntNm)
    pop(i)=Bt{1}{contains(Bt{1}.Var1,['Initial Population[' cntNm{i}]),2};
    rpInf(i)=max(getVenData(Bt{1},'DataCmltOverTime',cntNm{i},'Infection'));
    rpDth(i)=max(getVenData(Bt{1},'DataCmltOverTime',cntNm{i},'Death'));
end
cntInx=(pop>6e7 & rpInf>5e4); %index of countries for main graph

inxDys=table2array(Bt{1}(1,2:end))<crnDay;
inxDay=sum(inxDys); % finding last historial data point
inxDys2=table2array(Dt{1}(1,2:end))<crnDay;
inxDay2=sum(inxDys2); % finding last historical data point
fgr=fopen(['GReport2' scnNm '.txt'],'a'); %file id for recording numbers associated with graphs


%% graph 1: comparing model and output
if gon(1)
    g1Vnm={'SimFlowOverTime','DataFlowOverTime'};
    for k=1:2
        g1=figure;
        if k==1
            g1Cnm=cntNm;
        else
            g1Cnm={cntNm{cntInx}};
        end
        numR=floor(numel(g1Cnm)^0.5-0.001)+1;
        numRw=numR+1;
        numCl=numR-2+k-1;
        x_width=numCl*2.5 ;y_width=numRw*1.5;
        set(g1,'Units','inches','Position',[0 0 x_width+1 y_width+1]);
        set(g1,'PaperSize',[x_width+1 y_width+1]);
        ax=[];
        Y1=[];
        for i=1:numel(g1Cnm)
            ax{i}=subplot(numRw,numCl,i);
            %    set(fig,'defaultAxesColorOrder',[left_color; right_color]);
            for j=1:numel(g1Vnm)
                Y1(j,:)=getVenData(Bt{1},g1Vnm{j},g1Cnm{i},'Infection');
            end
            inx=Y1(2,:)>minInf;
            X=table2array(Bt{1}(1,inx));
            
            %dates=initD+X;
            dates=X-78;
            
            
            plot(dates,Y1(2,inx)/flwSl(1),'k:','LineWidth',1);
            hold on
            plot(dates,Y1(1,inx)/flwSl(1),'b','LineWidth',1.5)
            ylim([0 prctile(Y1(:,inx),mxPrc,'all')/flwSl(1)])
            xlim([dates(1) dates(end)]);
            for j=1:numel(g1Vnm)
                Y1(j,:)=getVenData(Bt{1},g1Vnm{j},g1Cnm{i},'Death');
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
            sgtitle('Model Fit');
        end
        if svGrph
            set(g1, 'PaperUnits', 'inches');
            
            set(g1, 'PaperPosition', [0 0 x_width y_width]); %
            saveas(g1,['g1-' num2str(k) '-' scnNm '.jpg']);
        end
    end
end

%% figure 2: prediction intervals and % tests positive
if gon(2)
    g2Vnm={'Cumulative Cases','Cumulative Deaths'};%'FractionTestsPositiveData','FractionTestsPositive'};
    for k=1:2
        if k==1
            g1Cnm=cntNm;
        else
            g1Cnm={cntNm{cntInx}};
        end
        g2=figure;
        numR=floor(numel(g1Cnm)^0.5-0.001)+1;
        numRw=numR+1;
        numCl=numR-2+k-1;
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
                Y1(j,:)=getVenData(Bt{1},g2Vnm{j},g1Cnm{i},[]);
                ZC1(j,:)=getVenData(Dt{1},g2Vnm{j},g1Cnm{i},CL);
                ZC2(j,:)=getVenData(Dt{1},g2Vnm{j},g1Cnm{i},CH);
                
            end
            inx=Y1(1,:)>minCml & inxDys;
            X=table2array(Bt{1}(1,inx));
            dates=X-78;
            d2=table2array(Dt{1}(1,2:end))-78;
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
            
            if k==1
                sgtitle('Estimated Epidemic Size across All Countries');
            else
                sgtitle('Estimated Epidemic Size');
            end
            if svGrph
                set(g2, 'PaperUnits', 'inches');
                set(g2, 'PaperPosition', [0 0 x_width y_width]); %
                saveas(g2,['g2-' num2str(k) '-' scnNm '.jpg']);
            end
        end
    end
end

%% bar chart with ratio of estimated to official number of cases and deaths
if gon(3)
    g3Vnm={'Cumulative Cases','Cumulative Deaths','DataCmltOverTime[Infection','DataCmltOverTime[Death'};
    Y=[];
    C1=[];
    C2=[];
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
            dOut(j,:)=getVenData(Bt{1},varNm,cntNm{i},tpNm);
            cOt=getVenData(Dt{1},varNm,cntNm{i},tpNm);
            if numel(tpNm)>0
                tpNm=[tpNm ','];
            end
            if j<3
                p1Out(j,:)=getVenData(Dt{1},varNm,cntNm{i},[tpNm CL]);
                p2Out(j,:)=getVenData(Dt{1},varNm,cntNm{i},[tpNm CH]);
            end
            
        end
        [~,inxd]=max(dOut(4,:));
        Y(i,:)=dOut(1:2,inxd)./dOut(3:4,inxd);
        C1(i,:)=p1Out(1:2,inxd)./dOut(3:4,inxd);
        C2(i,:)=p2Out(1:2,inxd)./dOut(3:4,inxd);
        Fi(i)=dOut(1,inxd)./pop(i)*100;
    end
    [~,inx]=sort(Y(:,1));
    figure;
    
    h=errorbar(1:numel(cntNm), Y(inx,1), Y(inx,1)-C1(inx,1),C2(inx,1)-Y(inx,1),'o','MarkerEdgeColor','blue','MarkerFaceColor','blue');
    ylabel('Ratio of Estimated to Reported (Log Scale)','fontsize',13);
    xlim([0 numel(cntNm)+1]);
    ax = ancestor(h, 'axes');
    set(ax, 'YScale', 'log')
    
    
    %xrule = ax.XAxis;
    %xrule.FontSize=6;
    set(ax, 'XTick',[], 'XTickLabel',[], 'TickLabelInterpreter','none')
    xtickangle(90);
    
    title('Estimated vs. Reported Cases and Deaths','fontsize',15);
    ax.YGrid = 'on';
    ax.YMinorGrid='off';
    
    hold on
    %yyaxis 'right'
    errorbar(1:numel(cntNm), Y(inx,2), Y(inx,2)-C1(inx,2),C2(inx,2)-Y(inx,2),'s','MarkerEdgeColor','red','MarkerFaceColor','red')
    % ylim([0 15]);
    
    
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
        saveas(ax,['g3-' scnNm '.jpg']);
    end
    fprintf(fgr,'Min and max ratio of actual to reported infection:\t%f(%f-%f)\t(%s)\t%f(%f-%f)\t(%s)\r\n',...
        Y(inx(1),1),C1(inx(1),1),C2(inx(1),1),cntNm{inx(1)},Y(inx(end),1),C1(inx(end),1),C2(inx(end),1),cntNm{inx(end)});
    [~,inx2]=sort(Y(:,2));
    fprintf(fgr,'Min and max ratio of actual to reported death:\t%f(%f-%f)\t(%s)\t%f(%f-%f)\t(%s)\r\n\r\n',...
        Y(inx2(1),2),C1(inx2(1),2),C2(inx2(1),2),cntNm{inx2(1)},Y(inx2(end),2),C1(inx2(end),2),C2(inx2(end),2),cntNm{inx2(end)});
    
    [~,inxPopFrc]=sort(Fi,'descend');
    for j=1:10
        fprintf(fgr,'Top fractions of population infected: %f\t%s\r\n',Fi(inxPopFrc(j)),cntNm{inxPopFrc(j)});
    end
end

%%	A phase plot with test per million and infections per million, showing the control trajectories feasible by testing

if gon(4)
    g4Vnm={'Active Test Rate','Infection Rate'};
    g4cntNm={'USA','India','SouthKorea','Australia','Germany','Mexico'};
    g4scl=1e5;
    Z=[];
    zOut=[];
    
    Xrng=table2array(unique(Tt(:,6)));
    Yrng=table2array(unique(Tt(:,7)));
    [X,Y]=meshgrid(Xrng,Yrng);
    ZC=[];
    for i=1:numel(Xrng)
        for j=1:numel(Yrng)
            ZC(j,i)=Tt{Tt{:,6}==Xrng(i) & Tt{:,7}==Yrng(j),5};
        end
    end
    
    figure
    contourf(Y,X,ZC,[0 0.01 0.03 0.05 0.1 0.15 0.2 0.25 0.3],'LineStyle','none');%,'showtext','on')
    
    hold on
    for i=1:numel(g4cntNm)
        pop1=getVenData(Bt{1},'Initial Population',g4cntNm{i},[]);
        pop1=max(pop1);
        for j=1:numel(g4Vnm)
            vnms=split(g4Vnm{j},'[');
            varNm=vnms{1};
            tpNm=[];
            if numel(vnms)>1
                tpNm=vnms{2};
            end
            zOut(j,:)=getVenData(Bt{1},varNm,g4cntNm{i},tpNm);
        end
        % make the plot
        inx=inxDys;
        winLen=15;
        
        h=plot(movmean(zOut(1,inx)*g4scl/pop1,winLen),movmean(zOut(2,inx)*g4scl/pop1,winLen),'-',...
            'Marker',vmarker{i},'linewidth',1,'markersiz',4,'color',vcolor{i},'MarkerFaceColor',vcolor{i},'MarkerIndices', 1:7:sum(inx));
    end
    title('Testing, Infection, and Detection','fontsize',14);
    xlabel('Daily Tests per 100,000');
    ylabel('(Estimated) Daily Infections per 100,000');
    legend([{''},g4cntNm(:)'],'location','bestoutside')
    ax = ancestor(h, 'axes');
    set(ax, 'YScale', 'log');
    set(ax, 'XScale', 'log');
    xlim([min(X,[],'all') max(X,[],'all')]);
    ylim([min(Y,[],'all') max(Y,[],'all')]);
    colormap('summer')
    c=colorbar('southoutside');
    c.Label.String = 'Fraction of True Infections Identified';
    c.Label.FontSize=11;
    % set(ax,'ColorScale','log')
    if svGrph
        saveas(ax,['g4-' scnNm '.jpg']);
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
            dOut(j,:)=getVenData(Bt{1},varNm,cntNm{i},tpNm);
            cOt=getVenData(Dt{1},varNm,cntNm{i},tpNm);
            if numel(tpNm)>0
                tpNm=[tpNm ','];
            end
            p1Out(j,:)=getVenData(Dt{1},varNm,cntNm{i},[tpNm CL]);
            p2Out(j,:)=getVenData(Dt{1},varNm,cntNm{i},[tpNm CH]);
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
    figure
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
        saveas(ax,['g5-' scnNm '.jpg']);
    end
    fprintf(fgr,'time to herd immunity current rates:\t%f(%f-%f)\t(%s)\t%f(%f-%f)\t(%s)\r\n',...
        Y(inx(1),1),C1(inx(1),1),C2(inx(1),1),cntNm{inx(1)},Y(inx(end),1),C1(inx(end),1),C2(inx(end),1),cntNm{inx(end)});
    [~,inx2]=sort(Y(:,2));
    fprintf(fgr,'time to herd immunity max rates:\t%f(%f-%f)\t(%s)\t%f(%f-%f)\t(%s)\r\n\r\n',...
        Y(inx2(1),2),C1(inx2(1),2),C2(inx2(1),2),cntNm{inx2(1)},Y(inx2(end),2),C1(inx2(end),2),C2(inx2(end),2),cntNm{inx2(end)});
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
            dOut(j,:)=getVenData(Bt{1},varNm,cntNm{i},tpNm);
            cOt=getVenData(Dt{1},varNm,cntNm{i},tpNm);
            if numel(tpNm)>0
                tpNm=[tpNm ','];
            end
            p1Out(j,:)=getVenData(Dt{1},varNm,cntNm{i},[tpNm CL]);
            p2Out(j,:)=getVenData(Dt{1},varNm,cntNm{i},[tpNm CH]);
        end
        
        Y(i,1)=100*(dOut(:,inxDay));
        C1(i,1)=100*(p1Out(:,inxDay2));
        C2(i,1)=100*(p2Out(:,inxDay2));
        
    end
    [~,inx]=sort(Y(:,1));
    figure
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
    ax.YTick=[0 1 2 3 4 5 6]
    
    title('Fatality Rate','fontsize',15);
    ylabel('Infection Fatality Rate (%)','fontsize',13);
    if svGrph
        saveas(ax,['g6-' scnNm '.jpg']);
    end
    fprintf(fgr,'infection fatality rates (min/max/median):\t%f(%f-%f)\t(%s)\t%f(%f-%f)\t(%s)\t%f(%f-%f)\t(%s)\r\n',...
        Y(inx(1),1),C1(inx(1),1),C2(inx(1),1),cntNm{inx(1)},Y(inx(end),1),C1(inx(end),1),C2(inx(end),1),cntNm{inx(end)},...
        Y(inx(round(end/2)),1),C1(inx(round(end/2)),1),C2(inx(round(end/2)),1),cntNm{inx(round(end/2))});
end

%% global cases under different scenarios
g7Vnm={'Global Cases','Global Deaths'};
g7Ttl={'Past', ' and Counter-factual';'Scenarios for Projected',''};
g7Plc={[1 2],[1 3 4]};
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
            
            fprintf(fgr,'%s in scen %d:\t%f(%f-%f)\r\n',g7Vnm{1},k,max(Y1(j,inx)),max(ZC1(inx2)),max(ZC2(inx2)));
            
        end
        xlim([dates(1) dates(end)]);
        set(ax{axNum},'XTick',[dates(1) dates(round(end/2)) dates(end)])
        datetick(ax{axNum},'x','mmm','keeplimits')
        title([g7Ttl{g,1} ' Cases' g7Ttl{g,2}]);
        ylabel('Global cases (millions)');
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
            
            fprintf(fgr,'%s in scen %d:\t%f(%f-%f)\r\n',g7Vnm{2},k,max(Y1(j,inx)),max(ZC1(inx2)),max(ZC2(inx2)));
            
            
        end
        xlim([dates(1) dates(end)]);
        set(ax{axNum},'XTick',[dates(1) dates(round(end/2)) dates(end)])
        datetick(ax{axNum},'x','mmm','keeplimits')
        title([g7Ttl{g,1} ' Deaths' g7Ttl{g,2}]);
        ylabel('Global deaths (millions)');
    end
    
    
    if svGrph
        saveas(g7,['g7-' scnNm '.jpg']);
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
            dOut(j,:)=getVenData(Bt{1},varNm,cntNm{i},tpNm);
            
            cOt=getVenData(Dt{1},varNm,cntNm{i},tpNm);
            if numel(tpNm)>0
                tpNm=[tpNm ','];
            end
            p1Out(j,:)=getVenData(Dt{1},varNm,cntNm{i},[tpNm CL]);
            p2Out(j,:)=getVenData(Dt{1},varNm,cntNm{i},[tpNm CH]);
        end
        if prcBased
            Y(i,1)=prctile(dOut(1,inxDys),R0Pct);
            C1(i,1)=prctile(p1Out(1,inxDys2),R0Pct);
            C2(i,1)=prctile(p2Out(1,inxDys2),R0Pct);
        else
            infOut=getVenData(Bt{1},'Infection Rate',cntNm{i},tpNm);
            [~,inxMxI]=max(infOut);
            inxMxI=inxMxI-7;
            Y(i,1)=dOut(1,inxMxI);
            C1(i,1)=p1Out(1,inxMxI);
            C2(i,1)=p2Out(1,inxMxI);
        end
    end
    [~,inx]=sort(Y(:,1));
    figure
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
        saveas(ax,['g8-' scnNm '.jpg']);
    end
    fprintf(fgr,'basic reproduction rates (min/max/median):\t%f(%f-%f)\t(%s)\t%f(%f-%f)\t(%s)\t%f(%f-%f)\t(%s)\r\n',...
        Y(inx(1),1),C1(inx(1),1),C2(inx(1),1),cntNm{inx(1)},Y(inx(end),1),C1(inx(end),1),C2(inx(end),1),cntNm{inx(end)},...
        Y(inx(round(end/2)),1),C1(inx(round(end/2)),1),C2(inx(round(end/2)),1),cntNm{inx(round(end/2))});
    
end

%% graph with policy/behavioral response for multiple countries
if gon(9)
    g9Vnm={'Contacts Relative to Normal','Perceived Hazard of Infection'};
    g9Cnt={'USA','Japan','SouthKorea','UK','India'};
    Y=[];
    for i=1:numel(g9Cnt)
        Y(i,:)=getVenData(Pt,g9Vnm{1},g9Cnt{i},[]);
    end
    figure
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
        saveas(ax,['g9-' scnNm '.jpg']);
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
        xx=getVenData(Bt{1},g10Vnm{1},cntNm{i},[]);
        XDth(i)=xx(1);
        getVenData(Bt{1},g10Vnm{2},cntNm{i},[]);
        XDthE(i)=xx(1);
        xx=getVenData(Bt{1},g10Vnm{3},cntNm{i},[]);
        XDthS(i)=xx(1);
    end
    Xcnt=XDth>50;
    XDth=XDth(Xcnt);
    XDthE=XDthE(Xcnt);
    XDthS=XDthS(Xcnt);
    cntXList=cntNm(Xcnt);
    for i=1:numel(cntXList)
        xx=getVenData(Bt{1},g10Vnm{4},cntXList{i},[]);
        Y(i)=xx(end)/XDth(i);
        xx=getVenData(Dt{1},g10Vnm{4},cntXList{i},CL);
        C1(i)=xx(end)/XDth(i);
        xx=getVenData(Dt{1},g10Vnm{4},cntXList{i},CH);
        C2(i)=xx(end)/XDth(i);
    end
    [~,inx]=sort(XDth);
    figure;
    
    h=errorbar(1:numel(cntXList), Y(inx), Y(inx)-C1(inx),C2(inx)-Y(inx),'o','MarkerEdgeColor','blue','MarkerFaceColor','blue');
    ylabel('Estimated to Reported Excess Death Ratio','fontsize',13);
    xlim([0 numel(cntXList)+1]);
    ax = ancestor(h, 'axes');
    %set(ax, 'YScale', 'log')
    set(ax, 'XTick',[1:numel(cntXList)],'XTickLabel',cntXList(inx), 'TickLabelInterpreter','none')
    xtickangle(90);
    title('Estimated to Reported Excess Deaths','fontsize',15);
    
    if svGrph
        saveas(ax,['g10-' scnNm '.jpg']);
    end
    
end


%% bar chart with totoal cases and deaths by end of winter 2021
if gon(11)
    plcNum=5;  %this is the main scenaior to report
    g11Vnm={'Cumulative Cases','Cumulative Deaths'};
    Y=[];
    C1=[];
    C2=[];
    dOut=[];
    p1Out=[];
    p2Out=[];
    for i=1:numel(cntNm)
        for j=1:numel(g11Vnm)
            varNm=g11Vnm{j};
            
            tpNm=[];
            
            dOut(j,:)=getVenData(Bt{plcNum},varNm,cntNm{i},tpNm);
            %cOt=getVenData(Dt{1},varNm,cntNm{i},tpNm);
            
            
            p1Out(j,:)=getVenData(Dt{plcNum},varNm,cntNm{i},[tpNm CL]);
            p2Out(j,:)=getVenData(Dt{plcNum},varNm,cntNm{i},[tpNm CH]);
            
        end
        
        Y(i,:)=dOut(1:2,end)/pop(i)*100;
        C1(i,:)=p1Out(1:2,end)/pop(i)*100;
        C2(i,:)=p2Out(1:2,end)/pop(i)*100;
    end
    [~,inx]=sort(Y(:,1));
    figure;
    
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
            yt=ymin*1.05;
        else
            yt=ymax*0.78^(numel(cntNm{inx(i)}));
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
        saveas(ax,['g11-' scnNm '.jpg']);
    end
    %
    prjI=[Y(:,1)'.*pop/100; C1(:,1)'.*pop/100; C2(:,1)'.*pop/100];
    prjD=[Y(:,2)'.*pop/100; C1(:,2)'.*pop/100; C2(:,2)'.*pop/100];
    fprintf(fgr,'Min and max infection projections:\t%f(%f-%f)\t(%s)\t%f(%f-%f)\t(%s)\r\n',...
        Y(inx(1),1),C1(inx(1),1),C2(inx(1),1),cntNm{inx(1)},Y(inx(end),1),C1(inx(end),1),C2(inx(end),1),cntNm{inx(end)});
    [~,inx2]=sort(Y(:,2));
    fprintf(fgr,'Min and max death projections:\t%f(%f-%f)\t(%s)\t%f(%f-%f)\t(%s)\r\n\r\n',...
        Y(inx2(1),2),C1(inx2(1),2),C2(inx2(1),2),cntNm{inx2(1)},Y(inx2(end),2),C1(inx2(end),2),C2(inx2(end),2),cntNm{inx2(end)});
    
    
    [~,inx3]=sort(prjD(1,:),'descend');
    for i=1:10
        fprintf(fgr,'%s Infections and Deaths:\t%d(%d-%d)\t%d(%d-%d)\t\r\n',cntNm{inx3(i)},prjI(1,inx3(i)),prjI(2,inx3(i)),prjI(3,inx3(i)),prjD(1,inx3(i)),prjD(2,inx3(i)),prjD(3,inx3(i)));
    end
    fprintf(fgr,'Global Infections and Deaths:\t%d(%d-%d)\t%d(%d-%d)\t\r\n',sum(prjI(1,:)),sum(prjI(2,:)),sum(prjI(3,:)),sum(prjD(1,:)),sum(prjD(2,:)),sum(prjD(3,:)));
    
    
    %creating the numbers for baseline with no change
    plcNum=1;
    for i=1:numel(cntNm)
        for j=1:numel(g11Vnm)
            varNm=g11Vnm{j};
            
            tpNm=[];
            
            dOut(j,:)=getVenData(Bt{plcNum},varNm,cntNm{i},tpNm);
            %cOt=getVenData(Dt{1},varNm,cntNm{i},tpNm);
            
            
            p1Out(j,:)=getVenData(Dt{plcNum},varNm,cntNm{i},[tpNm CL]);
            p2Out(j,:)=getVenData(Dt{plcNum},varNm,cntNm{i},[tpNm CH]);
            
        end
        
        
        Y(i,:)=dOut(1:2,end);
        C1(i,:)=p1Out(1:2,end);
        C2(i,:)=p2Out(1:2,end);
    end
    prjI=[Y(:,1)'; C1(:,1)'; C2(:,1)'];
    prjD=[Y(:,2)'; C1(:,2)'; C2(:,2)'];
    
    [~,inx3]=sort(prjI(1,:),'descend');
    for i=1:10
        fprintf(fgr,'%s NoChange Infections and Deaths:\t%d(%d-%d)\t%d(%d-%d)\t\r\n',cntNm{inx3(i)},prjI(1,inx3(i)),prjI(2,inx3(i)),prjI(3,inx3(i)),prjD(1,inx3(i)),prjD(2,inx3(i)),prjD(3,inx3(i)));
    end
    
    
end

%% graph 12: future projections
if gon(12)
    g12Vnm={'Infection Rate','Death Rate'};
    sNum=5; %scenario number to be used for these graphs
    
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
    ZC1=[];
    ZC2=[];
    for i=1:numel(g12Cnm)
        ax{i}=subplot(numRw,numCl,i);
        
        for j=1:numel(g12Vnm)
            Y1(j,:)=getVenData(Bt{sNum},g12Vnm{j},g12Cnm{i},[]);
            ZC1(j,:)=getVenData(Dt{sNum},g12Vnm{j},g12Cnm{i},CL);
            ZC2(j,:)=getVenData(Dt{sNum},g12Vnm{j},g12Cnm{i},CH);
        end
        inx=Y1(1,:)>minInf;
        X=table2array(Bt{sNum}(1,inx));
        
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
        saveas(g12,['g12-' scnNm '.jpg']);
    end
    
end




fclose(fgr);
%% generating report with various numbers
if repOn
    calstats=1;
    fid=fopen(['rep' scnNm '.txt'],'a');
    fprintf(fid,'Total Countries Covered: %d \r\n',numel(cntNm));
    fprintf(fid,'Total Population Covered: %d \r\n',sum(pop));
    
    %find parameter distributions
    prmNm={'Base Fatality Rate for Unit Acuity','Baseline Daily Fraction Susceptible Seeking Tests','Confirmation Impact on Contact',...
        'Covid Acuity Relative to Flu','Dread Factor in Risk Perception',...
        'Impact of Population Density on Hospital Availability','Impact of Treatment on Fatality Rate','Max COVID Hospitalization Fraction Tested',...
        'Min Contact Fraction','Multiplier Recent Infections to Test','Multiplier Transmission Risk for Asymptomatic','Patient Zero Arrival Time',...
        'Reference Force of Infection','Sensitivity of Fatality Rate to Acuity','Sensitivity of Contact Reduction to Utility',...
        'Time to Downgrade Risk','Time to Upgrade Risk',...
        'Total Asymptomatic Fraction','Weight on Reported Probability of Infection'};
    prmLb={'f_b','n_{ST}','m_T','\alpha_C','\lambda','s_{DH}','s_{HF}','r_H','c_{Min}','m_{IT}','m_a','T_0','\beta','s_f','s_C','\tau_{RD}','\tau_{RU}','a','w_R'};
    if calstats
        trsDt=[10,5;50,10];
        msDvNm={'DataCmltOverTime','DataFlowOverTime'};
        msSvNm={'SimCmltOverTime','SimFlowOverTime'};
        subNm={'Infection','Death'};
        parB=[];
        inqR=[];
        mae=[];
        for j=1:numel(cntNm)
            for i=1:numel(prmNm)
                
                parB(i,j)=Bt{1}{contains(Bt{1}.Var1,[prmNm{i} '[' cntNm{j}]),2};
                inqR(i,j)=Dt{1}{contains(Dt{1}.Var1,[prmNm{i} '[' cntNm{j} ',%75.0']),2}-Dt{1}{contains(Dt{1}.Var1,[prmNm{i} '[' cntNm{j} ',%25.0']),2};
                parC1(i,j)=Dt{1}{contains(Dt{1}.Var1,[prmNm{i} '[' cntNm{j} ',' CL]),2};
                parC2(i,j)=Dt{1}{contains(Dt{1}.Var1,[prmNm{i} '[' cntNm{j} ',' CH]),2};
            end
            dtout=[];
            stout=[];
            inxDt=[];
            for k=1:numel(msDvNm)
                for m=1:numel(subNm)
                    %calculating measures of fit
                    dtout(k,m,:)=getVenData(Bt{1},msDvNm{k},cntNm{j},subNm{m});
                    stout(k,m,:)=getVenData(Bt{1},msSvNm{k},cntNm{j},subNm{m});
                    inxDt=squeeze(dtout(1,1,:)>max(50,0.001*rpInf(j)));% & squeeze(dtout(k,m,:))>0;
                    mae(k,m,j)=mean(abs(dtout(k,m,inxDt)-stout(k,m,inxDt)))/mean(dtout(k,m,inxDt));
                    crr(k,m,j)=(corr(squeeze(dtout(k,m,inxDt)),squeeze(stout(k,m,inxDt))))^2;
                    if j==1
                        dtoutg(k,m,:)=nansum(Bt{1}{contains(Bt{1}.Var1,msDvNm{k}) & contains(Bt{1}.Var1,subNm{m}),2:end},1);
                        stoutg(k,m,:)=nansum(Bt{1}{contains(Bt{1}.Var1,msSvNm{k}) & contains(Bt{1}.Var1,subNm{m}),2:end},1);
                        inxDt=squeeze(dtoutg(1,1,:)>max(50,0.001*rpInf(j)));
                        maeg(k,m)=mean(abs(dtoutg(k,m,inxDt)-stoutg(k,m,inxDt)))/mean(dtoutg(k,m,inxDt));
                        crrg(k,m)=(corr(squeeze(dtoutg(k,m,inxDt)),squeeze(stoutg(k,m,inxDt))))^2;
                    end
                end
            end
            
        end
    end
    
    ffit=fopen('FitStats.txt','a');
    fprintf(ffit,'Country\tmae CmlInf\tmae CmlDth\tmae FlwInf\tmae FlwDth\tcrr CmlInf\tcrr CmlDth\tcrr FlwInf\tcrr FlwDth\r\n');
    for i=1:size(mae,3)
        fprintf(ffit,'%s\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\t%.3g\r\n',cntNm{i},mae(1,1,i),mae(1,2,i),mae(2,1,i),mae(2,2,i),crr(1,1,i),crr(1,2,i),crr(2,1,i),crr(2,2,i));
    end
    fclose(ffit);
    
    fprintf(fid,'\r\nFit stats for \t cumulative infection\t (median)\t cumulative death\t (median)\t flow of infection\t (median)\t flow of death\t (median)\r\n');
    fprintf(fid,'MAE Normalized: \t%f\t(%f)\t%f\t(%f)\t%f\t(%f)\t%f\t(%f)\r\n',maeg(1,1),median(mae(1,1,:)),maeg(1,2),median(mae(1,2,:)),maeg(2,1),median(mae(2,1,:)),maeg(2,2),median(mae(2,2,:)));
    fprintf(fid,'r-squared: \t%f\t(%f)\t%f\t(%f)\t%f\t(%f)\t%f\t(%f)\r\n',crrg(1,1),median(crr(1,1,:)),crrg(1,2),median(crr(1,2,:)),crrg(2,1),median(crr(2,1,:)),crrg(2,2),median(crr(2,2,:)));
    fprintf(fid,'r-squared above 0.9 for %f of sample\r\n\r\n',sum(crr>0.9,'all')/sum(crr>0,'all'));
    
    inxPoorfit=squeeze(mae(1,2,:)>0.4);
    fprintf(fid,'poor fit for fatality (more than 0.4 MAE) in:%s\r\n\r\n',cntNm{inxPoorfit});
    
    glbI=Bt{1}{contains(Bt{1}.Var1,'Global Cases'),2:end};
    glbIC1=Dt{1}{contains(Dt{1}.Var1,['Global Cases[' CL]),2:end};
    glbIC2=Dt{1}{contains(Dt{1}.Var1,['Global Cases[' CH]),2:end};
    glbD=Bt{1}{contains(Bt{1}.Var1,'Global Deaths'),2:end};
    glbDC1=Dt{1}{contains(Dt{1}.Var1,['Global Deaths[' CL]),2:end};
    glbDC2=Dt{1}{contains(Dt{1}.Var1,['Global Deaths[' CH]),2:end};
    fprintf(fid,'\r\ncovered population:\t%d\ttotal infections:\t%d (%d-%d)\ttotal deaths:\t%d (%d-%d)\r\n',sum(pop),max(glbI(inxDys)),max(glbIC1(inxDys2)),max(glbIC2(inxDys2)),...
        max(glbD(inxDys)),max(glbDC1(inxDys2)),max(glbDC2(inxDys2)));
    fprintf(fid,'Ratio to reported numbers is: %f for infections and %f for deaths\r\n\r\n',max(glbI(inxDys))/sum(rpInf),max(glbD(inxDys))/sum(rpDth));
    
    
    %
    
    glbIFR=Bt{1}{contains(Bt{1}.Var1,'Global IFR'),2:end};
    glbIFR=glbIFR(inxDys);
    glbIFRC1=Dt{1}{contains(Dt{1}.Var1,['Global IFR[' CL]),2:end};
    glbIFRC1=glbIFRC1(inxDys2);
    glbIFRC2=Dt{1}{contains(Dt{1}.Var1,['Global IFR[' CH]),2:end};
    glbIFRC2=glbIFRC2(inxDys2);
    fprintf(fid,'Global Infection Fatality Rate: %f (%f-%f)\r\n\r\n',glbIFR(end),glbIFRC1(end),glbIFRC2(end));
    %
    
    fprintf(fid,'Parameter\t mean\t std\t mean of interquartile range\r\n');
    for i=1:numel(prmNm)
        
        fprintf(fid,'%s:\t%d\t%d\t%d\r\n',prmNm{i},mean(parB(i,:)),std(parB(i,:)),mean(inqR(i,:)));
    end
    
    %add global rates at the end for the likely scanario
    scnNum=5;
    
    clear gI gIC1 gIC2 gD gDC1 gDC2;
    for i=1:numel(cntNm)
        gI(i,:)=getVenData(Bt{scnNum},'Infection Rate',cntNm{i},[]);
        %
        gIC1(i,:)=getVenData(Dt{scnNum},'Infection Rate',cntNm{i},CL);
        gIC2(i,:)=getVenData(Dt{scnNum},'Infection Rate',cntNm{i},CH);
        gD(i,:)=getVenData(Bt{scnNum},'Death Rate',cntNm{i},[]);
        gDC1(i,:)=getVenData(Dt{scnNum},'Death Rate',cntNm{i},CL);
        gDC2(i,:)=getVenData(Dt{scnNum},'Death Rate',cntNm{i},CH);
        %
    end
    popCoef=sum(pop)/100;
    fprintf(fid,'\r\nFinal Infection Rates Baseline Scenario:\t%f (%f-%f)\r\n',sum(gI(:,end))/popCoef,sum(gIC1(:,end))/popCoef,sum(gIC2(:,end))/popCoef);
    fprintf(fid,'Final Death Rates Baseline Scenario:\t%f (%f-%f)\r\n',sum(gD(:,end))/popCoef,sum(gDC1(:,end))/popCoef,sum(gDC2(:,end))/popCoef);
    [~,inxFr]=sort(gI(:,end),'descend');
    for i=1:10
        fprintf(fid,'Top final infection rates: \t%f\t%s\r\n',gI(inxFr(i),end),cntNm{inxFr(i)});
    end
    j=sum(contains(cntNm,'USA').*(1:numel(cntNm)));
    [usI,usDt]=max(gI(j,:));
    fprintf(fid,'\r\nmax USA infection:%d\t%d\r\n',usI,usDt);
    
    %additional stats for abstract 
    cntLst={'Ecuador','Chile','Mexico','Iran','USA','UK','Iceland','NewZealand'};
    repVars={'Cumulative Cases','Cumulative Death Fraction'};
    Y=[];
    fprintf(fid,'\r\n');
    for i=1:numel(cntLst)
      pcnt=Bt{1}{contains(Bt{1}.Var1,['Initial Population[' cntLst{i}]),2};
        Y(1,:)=getVenData(Bt{scnNum},repVars{1},cntLst{i},[]);
        Y(2,:)=getVenData(Bt{scnNum},repVars{2},cntLst{i},[]);
        Yo=Y(:,inxDay);
        
        fprintf(fid,'%s\t%f\t%f\r\n',cntLst{i},Yo(1)/pcnt*100,Yo(2)*100);
    end
    
    
    
    fclose(fid);
    
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
            saveas(gp,['gp-' num2str(k) '-' scnNm '.jpg']);
        end
        
    end
    
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