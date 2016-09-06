function [ x, xslack ] = SHAPE(A,A_quantized,N,H,distribution_objective,lamda)

% SHAPE:
% Mixed Integer Linear Prorgamming for selecting a subset of a dataset and
% enforcing at the same time a particular distribution in each dimension,
% while minimizing interdimensional correlations.
% The code uses Malab's "intlinprog" solver, which is part of the optimization toolbox. 
% 
% Supplementary material for the paper: 
% "A Probabilistic Approach to People-Centric Image Selection and Sequencing", 
% by Vassilios Vonikakis (2016)
% 
%--------------------------------------------------------------------------
% INPUTS
% 
% A: matrix of the original data. 
%    Rows represent observations, columns represent dimensions. 
%    Data are expected to be real numbers and in the interval [0,1].   
%    Advice: the more the data span the whole range in each dimension, the better the chances that the final output
%    will approximate closely the target distribution. If you have highly non-linear data, you could consider some form of
%    non-linear mapping that undoes the non-linearity of your data (e.g. logarithmic).
% A_quantized: matrix of quantized data coming from the original dataset. 
%    Data are expected to be integers and in the interval [1,H].
% N: the number of selected data points, with N<<size(A,1), since we want to create a subset.
% H: the number of quantization levels according to which A is quantized.
% distribution_objective: matrix with the target distribution that the output of subject should have.
% lamda: scalar that balances out the two objectives; distribution vs
%    interdimensional correlation. When lamba=0, the interdimensional
%    correlation objective is not applied. Higher lambas will icnrease its
%    contribution to the objective function. 
% 
%--------------------------------------------------------------------------
% OUTPUTS
% 
% x: logical vector of size size(A,1), showing which observations should be
%    included in the final subset
% xslack: vector showing how close the algorithm got to the actual target
%         distributions. All zeros indicate perfect match with the target
%         distribution. Larger numbers indicate deviation from it
%
%--------------------------------------------------------------------------
% CITATION
%
% If you use this code for research puproses please cite the following
% publications:
% 2. Vonikakis, V., et al (2016). "A Probabilistic Approach to People-Centric Image Selection and Sequencing".





K=size(A,1);%total number of observations
M=size(A,2);%total number of dimensions




%------- constructing the data for correlation minimization (2nd objective)

%estimating the final distribution in each dimension
avg=(((1:H)-0.5)./H)*distribution_objective;


for k=1:K
    kk=1;
    for i=1:M-1      
        for j=i+1:M
            
            qq(k,kk)=abs(A(k,i)-avg)*abs(A(k,j)-avg);

            kk=kk+1;
        end
    end
    v(k)=sum(qq(k,:));
end



%---------------------------------------------- constructing the bin matrix

B=cell(1,size(A_quantized,2));

for j=1:size(A_quantized,2) %accross all dimensions
  
    b=logical(zeros(H,size(A_quantized,1)));

    for i=1:size(A_quantized,1) %accross all observations
        
        b(A_quantized(i,j),i)=true; 
        
    end

    B{1,j}=b;
end



%------------------------------------------- filling the objective matrixes



%objective function
f=lamda*v;%2nd objective: minimization of correlation
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


clearvars ATR B f ff

%--------------------------------------------------------------------------
%-------------------------------------------- optimization using intlinprog
%--------------------------------------------------------------------------


%here we don't use the equality matrices. 
Aeq = [];
beq= [];


%ranges of variables
lb=zeros(K+M*H,1);%lower bound (we want 0)
ub=[ones(K,1);inf(M*H,1)];%upper bound (we want 1)
intcon=K+M*H;%all of them integers

x=intlinprog(c,intcon,A,b,Aeq,beq,lb,ub);%running optimization 

%spliting vector x into the slack variable and the actual selection variables
xslack=x(K+1:size(x,1));%slack variables
x=x(1:K);%the actual selection variables



%selecting the top N highest values (the output may not be necessarily binary!)

[q,idx]=sort(x);
idx=flipud(idx);

% reconstructing the selection vector
x=zeros(K,1);
x(idx(1:N))=1;
x=logical(x);


end

