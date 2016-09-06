% This script replicates the balancing results for the Helen dataset 
% depicted in the paper 
% V. Vonikakis, R. Subramanian, S. Winkler. (2016). "Shaping Datasets: 
% Optimal Data Selection for Specific Target Distributions". 
% Proc. ICIP2016, Phoenix, USA, Sept. 25-28.
% 
% 6 different image attributes are used: timestamp, colorfulness, sharpness, 
% exposure, contrast and in/out. The original data are quantized before the 
% MILP optimization. A subset of N different images is selected out of the 
% total K images of the dataset.
%
% The original images of the Helen dataset can be found in:
% http://www.ifp.illinois.edu/~vuongle2/helen/


clear all;
close all;
load HELEN;%load data


%--------------------------------------------------------------loading data

A=cell2mat(DATA(2:end,2:end));%keeping only the raw data
legend=DATA(1,1:end);%keeping the labels for displaying later





N=500; %total number of selected observations to be included in the subset
H=7; %number of quantization bins in each dimension (attribute)
M=size(A,2);%total number of dimensions
K=size(A,1);%total number of available observations
xbins = 1:H;

%------------------------------------------ defining objective distribution

%uniform distribution
distribution_objective=ones(H,1); 

%normalizing distribution
distribution_objective=distribution_objective./sum(distribution_objective);



%---------------------------------------------------- scaling data to [0,1]


%---------pitch------------
q=A(:,1);
q(q>30)=30;
q(q<-30)=-30;
q=q+30;
q=q./60;
A(:,1)=q;

%---------yaw------------
q=A(:,2);
q(q>30)=30;
q(q<-30)=-30;
q=q+30;
q=q./60;
A(:,2)=q;

%---------roll------------
q=A(:,3);
q(q>30)=30;
q(q<-30)=-30;
q=q+30;
q=q./60;
A(:,3)=q;


%------------------------------------------ quantizing attributes into bins

A_quantized=A;
A_quantized=A_quantized.*H;
A_quantized=floor(A_quantized);
A_quantized=A_quantized+1;
A_quantized(A_quantized==H+1)=H;

%------------------------------------- displaying the initial distributions

figure;
distribution_original=(hist(A_quantized(:,1:M),xbins))';
ymax=max(max(distribution_original));

for i=1:M
    
    subplot(2,3,i), bar(distribution_original(i,:));
    
    title(['Original ' legend{i+1}]);
    h = findobj(gca,'Type','patch');
    set(h,'FaceColor','b','EdgeColor','k')
    ylim([0 ymax]);%same scale on Y axis
    hold on;
    
    %drawing the distribution objective on the original distributions to
    %show whether there is availability of data on each bin
    for n=1:H  %across all quantization bins
        q=ceil(distribution_objective(n)*N);%required number of data in this bin
        line([n-0.5 n+0.5],[q q],'Color',[1 0 1]);%new setlevel
    end
    
    hold off;
    
end


%------------------------------------------------ Running MILP optimization

%getting the indexes of the observations that will be used in the subset
x  = SHAPE_DATASET(A_quantized,N,H,distribution_objective);


%--------------------------------------- Displaying the final distributions


%getting the final subset based on the indexes provided by the optimizaiton
A_reduced=A_quantized(x,:);

%getting the list of selected images out of the original data
DATA_reduced=DATA([false ;x],:);
DATA_reduced=[DATA(1,:) ; DATA_reduced];

%estimating the distribution of the subset
distribution_final=(hist(A_reduced(:,1:M),xbins))';
ymax=max(max(distribution_final));

%disaplying the new distributions of the subset
for i=1:M
    
    subplot(2,3,i+M), bar(distribution_final(i,:));
    title(['Subset ' legend{i+1}]);
    h = findobj(gca,'Type','patch');
    set(h,'FaceColor','r','EdgeColor','k')
    ylim([0 ymax]);%same scale on Y axis
    
end


