function [u,fval,isFinished,optimState,displayFormat] = evalinitmesh(u0,funwrapper,SkipInitPoint,optimState,options,prnt)
%EVALINITMESH Evaluate initial mesh.

LB = optimState.LB;
UB = optimState.UB;
PLB = optimState.PLB;
PUB = optimState.PUB;
MeshSize = optimState.meshsize;

if SkipInitPoint && options.Ninit < 1
    error('If the initial point X0 is not specified, OPTIONS.Ninit needs to be > 0.');
end

% Evaluate starting point (if specified)
if ~SkipInitPoint
    [fval,optimState] = funlogger(funwrapper,u0,optimState,'iter');
else
    fval = Inf;
end
optimState.fval = fval;

% Display format depends whether the objective is noisy
if prnt > 2
    if optimState.UncertaintyHandling
        displayFormat = ' %5.0f       %5.0f    %12.6g    %12.6g    %12.6g    %20s    %s\n';
        fprintf(' Iteration    f-count      E[f(x)]        SD[f(x)]      MeshScale          Method          Actions\n');
    else
        displayFormat = ' %5.0f       %5.0f    %12.6g    %12.6g    %20s    %s\n';
        fprintf(' Iteration    f-count          f(x)          MeshScale          Method          Actions\n');
    end
else
    displayFormat = [];
end

if prnt > 2 && ~SkipInitPoint
    if optimState.UncertaintyHandling
        fprintf(displayFormat, 0, optimState.funccount, fval, NaN, MeshSize, '', '');
    else
        fprintf(displayFormat, 0, optimState.funccount, fval, MeshSize, '', '');
    end
end

% Only one function evaluation!
if ~SkipInitPoint && options.MaxFunEvals == 1
    u = u0;
    isFinished = 1;
    return;
end

% Additional initial points
if options.Ninit > 0

    % Evaluate initial points but not more than OPTIONS.MaxFunEvals
    Ninit = min(options.Ninit, options.MaxFunEvals - double(~SkipInitPoint));

    % Call initialization function
    u1 = options.InitFcn(u0,LB,UB,PLB,PUB,Ninit,optimState,options);

    % Enforce periodicity
    u1 = periodCheck(u1,LB,UB,optimState);

    % Force points to be on the search grid
    u1 = force2grid(u1, optimState);

    % Ignore duplicates, vectors outside bounds or previously evaluated
    u1 = uCheck(u1,optimState.TolMesh,optimState,1);

    % Evaluate all points
    for i = 1:size(u1,1)
        [fval(i+1),optimState] = funlogger(funwrapper,u1(i,:),optimState,'iter');
    end

    if all(~isfinite(fval)); error('Cannot find valid starting point.'); end

    [fval,idx] = min(fval);
    u1 = [u0; u1];
    u = u1(idx,:);

    if prnt > 2
        if optimState.UncertaintyHandling
            fprintf(displayFormat, 0, optimState.funccount, fval, NaN, MeshSize, 'Initial mesh', '');            
        else
            fprintf(displayFormat, 0, optimState.funccount, fval, MeshSize, 'Initial mesh', '');
        end
    end
else
    u = u0;
end

isFinished = 0;