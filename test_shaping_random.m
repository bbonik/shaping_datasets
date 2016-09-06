% This script demonstrates the results of the dataset shaping technique on
% randomly generated data points from 5 different distributions. If you 
% use this code in your research, please cite our paper:
%
% V. Vonikakis, R. Subramanian, S. Winkler. (2016). "Shaping Datasets: 
% Optimal Data Selection for Specific Target Distributions". 
% Proc. ICIP2016, Phoenix, USA, Sept. 25-28.




clear all;
close all;
 


%-----------------------------------------------------------main parameters

K=3000; %total data points
N=100; %subset of selected data
H=10; %quantization levels (integer)

%-------------------------------------------defining objective distribution

%please uncomment the target distribution you would like the final subset
%to have.

%--uniform distribution (balancing effect)
distribution_objective=ones(H,1); 
distribution_objective=distribution_objective./sum(distribution_objective);


%--gaussian distribution
% pd = makedist('Normal','mu',H/2,'sigma',1);
% x=((1:H)-0.5);
% distribution_objective = pdf(pd,x);
% distribution_objective=distribution_objective';


%--weibull distribution
% pd = makedist('Weibull','a',5,'b',2);
% x=((1:H)-0.5);
% distribution_objective = pdf(pd,x);
% distribution_objective=distribution_objective';


%--------------------------------------------------------------- input data

% generating random points with different distributions for each dimension
% and performing min-max normalization

%1st dimension: gaussian
pd = makedist('Normal','mu',0,'sigma',1);
q = random(pd,K,1);
q=q-min(q);
q=q./max(q);
A(:,1)=q;

%2nd dimension: Pareto
pd = makedist('GeneralizedPareto','k',-0.5,'sigma',1,'theta',0);
q = random(pd,K,1);
q=q-min(q);
q=q./max(q);
A(:,2)=q;

%3rd dimension: Triangular
pd = makedist('Triangular');
q = random(pd,K,1);
q=q-min(q);
q=q./max(q);
A(:,3)=q;

%4th dimension: uniform
pd = makedist('Uniform');
q = random(pd,K,1);
q=q-min(q);
q=q./max(q);
A(:,4)=q;

%5th dimension: nakagami
pd = makedist('Nakagami');
q = random(pd,K,1);
q=q-min(q);
q=q./max(q);
A(:,5)=q;


M=size(A,2);%total dimensions

%------------------------------------------------ quantizing data into bins

A_quantized=A;
A_quantized=A_quantized.*H;
A_quantized=floor(A_quantized);
A_quantized=A_quantized+1;
A_quantized(A_quantized==H+1)=H;

%------------------------------------- displaying the initial distributions

figure, [S,AX,BigAx,HISTs,HAx]=plotmatrix(A,'r.');
set(S,'Color','b','MarkerSize',5);
set(HISTs,'FaceColor','b');
% set(AX,'XLim',[0 1],'YLim',[0 1]);
title(BigAx,'Original Dataset')
xlabel('Dataset dimensions');
ylabel('Dataset dimensions');

for i=1:M-1
    for j=i+1:M
        axes(AX(i,j));
        h=lsline;
        set(h,'LineWidth',1,'Color','k')
        [Rp,Pp]=corr([A(:,i) A(:,j)],'type','Pearson');
        text(0.01,0.99,[num2str(round_simple(Rp(1,2),2)) ' (' num2str(round_simple(Pp(1,2),2)) ')'],'FontSize',10,'FontWeight','bold');
        
        axes(AX(j,i));
        h=lsline;
        set(h,'LineWidth',1,'Color','k')
        [Rp,Pp]=corr([A(:,j) A(:,i)],'type','Pearson');
        text(0.01,0.99,[num2str(round_simple(Rp(1,2),2)) ' (' num2str(round_simple(Pp(1,2),2)) ')'],'FontSize',10,'FontWeight','bold');
    end
end


%------------------------------------------------ Running MILP optimization

%getting the indexes of the observations that will be used in the subset
x  = SHAPE_DATASET(A_quantized,N,H,distribution_objective);

%getting the final subset based on the indexes provided by the optimizaiton
A_reduced=A(x,:);

%------------------------------------ depicting the resulting distributions

figure, [S,AX,BigAx,HISTs,HAx]=plotmatrix(A_reduced,'r.');
set(S,'Color','r','MarkerSize',5);
set(HISTs,'FaceColor','r');
% set(AX,'XLim',[0 1],'YLim',[0 1]);
title(BigAx,'Reduced Dataset')
xlabel('Dataset dimensions');
ylabel('Dataset dimensions');

for i=1:M-1
    for j=i+1:M
        axes(AX(i,j));
        h=lsline;
        set(h,'LineWidth',1,'Color','k')
        [Rp,Pp]=corr([A_reduced(:,i) A_reduced(:,j)],'type','Pearson');
        text(0.01,0.99,[num2str(round_simple(Rp(1,2),2)) ' (' num2str(round_simple(Pp(1,2),2)) ')'],'FontSize',10,'FontWeight','bold');
        
        axes(AX(j,i));
        h=lsline;
        set(h,'LineWidth',1,'Color','k')
        [Rp,Pp]=corr([A_reduced(:,j) A_reduced(:,i)],'type','Pearson');
        text(0.01,0.99,[num2str(round_simple(Rp(1,2),2)) ' (' num2str(round_simple(Pp(1,2),2)) ')'],'FontSize',10,'FontWeight','bold');
    end
end
