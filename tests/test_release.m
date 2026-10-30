function test_release
%TEST_RELEASE Small release check; no paper dataset or optimization required.
repo = fileparts(fileparts(mfilename('fullpath')));
oldDir = pwd;
oldPath = path;
workDir = tempname;
mkdir(workDir);
cleanup = onCleanup(@() restore_environment(oldDir, oldPath, workDir));
addpath(repo, '-begin');

% Check all shipped spectral initializations.
files = dir(fullfile(repo, 'p_fit5_result_*.mat'));
assert(numel(files) == 8);
for k = 1:numel(files)
    data = load(fullfile(files(k).folder, files(k).name), 'p_fit');
    assert(numel(data.p_fit) == 15 && all(isfinite(data.p_fit(:))));
end

% Recover concentrations from a small synthetic broadband forward model.
gH = [0.1; 0.3; 0.6; 0.9; 0.5];
gE = [0.7; 0.8; 0.4; 0.2; 0.1];
gMat = [0.1 0.2 0.9; 0.2 0.7 0.8; 0.5 1 0.3; 1 0.5 0.1; 0.8 0.1 0.1];
den = sum(gMat, 1)';
truth = [0 0.1 0.4 0.8 1.2 0.5; 0 0.7 0.2 0.5 0.1 1.0];
OD = -log10((gMat' * 10.^(-[gH gE] * truth)) ./ den);
opts = struct('maxIter', 30, 'chunkSize', 2, 'cMax', 4);
[h, e] = solve_concentration_fast_GN_patch(OD', gH, gE, gMat, den, opts);
assert(max(abs([h'; e'] - truth), [], 'all') < 1e-4);
[hImage, eImage] = solve_concentration_fast_GN_patch( ...
    reshape(OD', 2, 3, 3), gH, gE, gMat, den, opts);
assert(isequal(size(hImage), [2 3]) && isequal(size(eImage), [2 3]));
assert(max(abs(hImage(:) - h)) < 1e-10);
assert(max(abs(eImage(:) - e)) < 1e-10);
opts.cH_init = h;
opts.cE_init = e;
[hInit, eInit] = solve_concentration_fast_GN_patch_init( ...
    OD', gH, gE, gMat, den, opts);
assert(max(abs([hInit'; eInit'] - truth), [], 'all') < 1e-4);
rgb = reshape([0 15 64 128 240 255], 2, 3);
assert(max(abs(od2rgb(rgb2od(rgb)) - rgb), [], 'all') < 1e-10);

% Isolate the entry point from expensive optimization with a solver stub.
codeDir = fullfile(workDir, 'code');
callerDir = fullfile(workDir, 'caller');
mkdir(codeDir);
mkdir(callerDir);
mkdir(fullfile(callerDir, 'inputs'));
copyfile(fullfile(repo, 'run_example.m'), codeDir);
imwrite(uint8(ones(2, 2, 3) * 128), fullfile(callerDir, 'ref.png'));
fid = fopen(fullfile(codeDir, 'he_spectral_decomposition.m'), 'w');
assert(fid ~= -1);
fprintf(fid, '%s\n', ...
    'function he_spectral_decomposition(ref, inputs, output, varargin)', ...
    'assert(isfile(ref) && isfolder(inputs));', ...
    'assert(java.io.File(char(output)).isAbsolute());', ...
    'if endsWith(output, ''fail''), error(''test:expected'', ''Expected failure''); end', ...
    'mkdir(output);', ...
    'end');
fclose(fid);
addpath(codeDir, '-begin');
cd(callerDir);
clear run_example he_spectral_decomposition
run_example('ref.png', 'inputs', 'results');
assert(strcmp(pwd, callerDir));
assert(isfolder(fullfile(callerDir, 'results')));
try
    run_example('ref.png', 'inputs', 'fail');
    error('test:missingError', 'Expected solver failure was not raised.');
catch err
    assert(strcmp(err.identifier, 'test:expected'));
end
assert(strcmp(pwd, callerDir));
clear cleanup
fprintf('Release checks passed.\n');
end

function restore_environment(oldDir, oldPath, workDir)
cd(oldDir);
path(oldPath);
clear run_example he_spectral_decomposition
assert(startsWith(workDir, tempdir));
rmdir(workDir, 's');
end
