% 8/6/13
% mainLoad.m
% generates an optimal trajectory through a set of keyframes
% allows for specficiation of points where the cable load becomes slack
% an implementation of techniques described in "Minimum Snap Trajectory Generation 
% and Control for Quadrotors", Mellinger and Kumar 
%
% indices convention: 
% for a polynominal of order n, its coefficients are:
%       x(t) = c_n t^n + c_[n-1] t^(n-1) + ... + c_1 t + c_0
% for m keyframes, the times of arrival at keyframes are t0, t1, ..., tm
% the polynominal segment between keyframe 0 and 1 is x1, 1 and 2 is x2,
%   ... m-1 and m is xm
%
% Dependencies: findTraj.m, plotTraj.m, findTrajCorr.m, evaluateTraj.m
%   findContConstraints.m, findFixedConstraints.m, findDerivativeCoeff.m, findCostMatrix.m




close all
clear all
clc

% constants
g = 9.81; %m/s/s
mQ = 0.5; %mass of quadrotor, kg
mL = 0.08; %mass of load, kg
IQ = [2.32e-3,0,0;0,2.32e-3,0;0,0,4e-3] ;
JQ = IQ(2,2) ;
l = 1; %length of cable, m

%%%
% set up problem
r = 6; %derivative to minimize in cost function
n = 11; %order of desired trajectory
m = 2; %number of pieces in trajectory
d = 1; %dimensions

% specify the m+1 keyframes
tDes = [0; 1; 1.4515]; %specify desired arrival times at keyframes
TDes = [Inf; 0; Inf]; %specify keyframes where you want tension to be 0
% specify desired positions and/or derivatives at keyframes, 
% Inf represents unconstrained values
% r x (m+1) x d, where each row i is the value the (i-1)th derivative of keyframe j for dimensions k 
posDes = zeros(r, m+1, d);
posDes(:, :, 1) = [-1 0 -1; 0 Inf 0; 0 -g*tDes(2, 1)^2 0; 0 0 0; 0 0 0; 0 0 0];
[i, j, k] = size(posDes);
p = length(tDes);


% specify s corridor constraints
ineqConst.numConst = 0; %integer, number of constraints 
ineqConst.start = 2; %sx1 matrix of keyframes where constraints begin
ineqConst.nc = 20; %sx1 matrix of numbers of intermediate points
ineqConst.delta = 0.05; %sx1 matrix of maximum distnaces
ineqConst.dim = [1 2]; %sxd matrix of dimensions that each constraint applies to


%%%
% verify that the problem is well-formed

% polynominal trajectories must be at least of order 2r-1 to have all derivatives lower than r defined
if (n < (2*r-p)) 
    error('trajectory is not of high enough order for derivative optimized')
end

if (i < r),
    error('not enough contraints specified: to minimize kth derivative, constraints must go up to the (k-1)th derivative');
end

if (j < m+1 || p < m+1), % must specify m+1 keyframes for m pieces of trajectory
    error('minimum number of keyframes not specified');
end

if (ismember(Inf, posDes(:, 1, :)) || ismember(Inf, posDes(:, m+1, :)) )
    error('endpoints must be fully constrained');
end

if (k < d)
    error('not enough dimensions specified');
end





%%% 
% find trajectories for each dimension, nondimensionalized in time

% xT holds all coefficents for all trajectories
% row i is the ith coefficient for the column jth trajectory in dimension k
xT = zeros(n+1, m, d); 
xT2 = zeros(n+1, m, d); 
%for i = 1:d,
   %xT(:, :, i) = findTraj(r, n, m, i, tDes, posDes);
   %xT2(:, :, i) = findTrajJoint(r, n, m, i, tDes, posDes);
%end


%xT3 = findTrajCorr(r, n, m, d, tDes, posDes, ineqConst);
[xTL, xTQ, mode, mNew] = findTrajLoad1D(r, n, m, d, tDes, posDes, TDes, g, l, mL, mQ)


% look at l
t = 0:0.01:tDes(m+1); %construct t vector 
len = zeros(1, length(t));
der2 = zeros(1, length(t));
for i = 1:length(t),
    [dxTL, ~] = evaluateTraj(t(i), n, m, d, xTL, tDes, 2, []);
    [dxTQ, ~] = evaluateTraj(t(i), n, m, d, xTQ, tDes, 2, []);
    len(1, i) = dxTQ(1, 1) - dxTL(1, 1);
    
    der2(1, i) = dxTL(2, 1);
end

figure()
plot(t, len);
title('distance between quad and load');
ylabel('len (m)');
xlabel('time');

figure()
plot(t, mL*(der2+g));
title('tension');
ylabel('len (m)');
xlabel('time');


%%% 
% plot the trajectory

% create legend labels for dimensions, must correspond to order of m
dimLabels{3} = 'z (m)'; 
plotDim = [];
%plotDim = [1 2]; %if you want to plot two dimensions against each other, specify here 
    % nxm matrix, creates n plots of column 1 vs. column 2
    
plotTraj(xTL, n, 2, d, tDes, posDes, 0.01, dimLabels, plotDim);
plotTraj(xTQ, n, 2, d, tDes, posDes, 0.01, dimLabels, plotDim);


