function [ x, xslack ] = SHAPE_DATASET(A,N,H,distribution_objective)


% SHAPE_DATASET: Mixed Integer Linear Programming for selecting subsets of 
% observations with particular target distributions in each dimension.
% The code uses Matlab's "intlinprog" solver, which is part of the 
% optimization toolbox. 
% 
% Supplementary material for the paper: 
% V. Vonikakis, R. Subramanian, S. Winkler. (2016). "Shaping Datasets: 
% Optimal Data Selection for Specific Target Distributions". 
% Proc. ICIP2016, Phoenix, USA, Sept. 25-28.
% 
% -------------------------------------------------------------------------
% INPUTS
% 
% A: matrix of quantized data coming from the original large dataset. 
%    Rows represent observations, columns represent dimensions. Data are 
%    considered to be integer and in the interval [1,H].
%    Advice: 
%    Normalizing the data: You may use different techniques for normalizing 
%    your data before quantizing them, like 'standard score' or 'min-max' 
%    normalization. 
%    Mapping the data: the more the data span the whole quantized range in 
%    each dimension, the better the chances that the final output will 
%    closely approximate the target distribution. If your data do not span 
%    uniformly the whole range, you may consider some form of non-linear 
%    mapping that undoes the non-linearity of your data (e.g. logarithmic).
% N: the number of observations to be included in the subset, with 
%    N<<size(A,1).
% H: the number of quantization bins according to which A is quantized.
% distribution_objective: vector with the target distribution that the 
%                         subset should have.
% 
%--------------------------------------------------------------------------
% OUTPUTS
% 
% x: logical vector of size size(A,1), showing which observations should be
%    included in the final subset
% xslack: vector showing how close the algorithm got to the actual target
%         distributions. All zeros indicate perfect match with the target
%         distribution. Larger numbers indicate deviation from it.
%
%--------------------------------------------------------------------------
% CITATION
%
% If you use this script in your research, please cite our paper:
% V. Vonikakis, R. Subramanian, S. Winkler. (2016). "Shaping Datasets: 
% Optimal Data Selection for Specific Target Distributions". 
% Proc. ICIP2016, Phoenix, USA, Sept. 25-28.



K=size(A,1);%total number of observations
M=size(A,2);%total number of dimensions


%---------------------------------------------- constructing the bin matrix

B=cell(1,size(A,2));

for j=1:size(A,2) %accross all dimensions
  
    b=logical(zeros(H,size(A,1)));

    for i=1:size(A,1) %accross all observations
        
        b(A(i,j),i)=true; 
        
    end

    B{1,j}=b;
end



%------------------------------------------- filling the objective matrices



%objective function
f=zeros(1,K);%the original indexes
ff=ones(1,M*H);%indexes of the slack variables
c=[f ff]'; %cT


%equality constraints ( implementing them as two <= >= )
%alternatively, equality constraints may be directly represented with the
% Aeq, beq matrices in intlinprog (see later) 
A=zeros(2*H*M+2,K+M*H);%2 for every absolute value + 2 for the equality constraints
b=zeros(2*H*M+2,1);

x1=ones(1,K);
A(1,:)=[x1 zeros(1,M*H)];
b(1)=N;
A(2,:)=-A(1,:);
b(2)=-N;

k=3; %counter for adding more after the equality constraints


%distribution constraints

for m=1:M   %accross all dimensions
    
    ATR=double(B{1,m});
    
    for n=1:H  %across all quantization bins
        
        q=ceil(distribution_objective(n)*N); 
        
        z=(m-1)*H+n;%2d to 1d
        
        a=zeros(1,M*H);
        a(z)=-1;
        
        %upper bound
        A(k,:)=[ATR(n,:) a];
        b(k)=q;
        k=k+1;
        %lower bound
        A(k,:)=[-ATR(n,:) a];
        b(k)=-q;
        
        k=k+1;

    end
    
end


clearvars ATR B f ff %no need for these any more...

%--------------------------------------------------------------------------
%-------------------------------------------- optimization using intlinprog
%--------------------------------------------------------------------------


%here we don't use the equality matrices. intlinprog provides the option of
%separately using equality constraints. However, we have already implemented
%them as two <= >=
Aeq = [];
beq= [];


%ranges of variables
lb=zeros(K+M*H,1);%lower bound (we want 0)
ub=[ones(K,1);inf(M*H,1)];%upper bound (we want 1)
intcon=K+M*H;%all of them integers

x=intlinprog(c,intcon,A,b,Aeq,beq,lb,ub);%running the optimization 

%spliting vector x into the slack variable and the actual selection variables
xslack=x(K+1:size(x,1));%slack variables
x=x(1:K);%the actual selection variables



%selecting the top N highest values (the output may not necessarily be 
%binary if the obective cannot be met!)
[~,idx]=sort(x,'descend');

% reconstructing the binary selection vector
x=zeros(K,1);
x(idx(1:N))=1;
x=logical(x);


end

