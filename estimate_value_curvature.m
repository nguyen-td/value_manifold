% Estimate value manifold curvature from neural data.

%% Setup
clear all
close all
clc

dat_path = '/Users/tn22693/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Studium/UT/Research/Goris/Projects/Value Manifolds/Neural data';
region = 'vmPFC'; % vmPFC, OFC, PCC, VS

%% Load data
neuron_idx =  5;
monkey_id = 'Batman'; % Batman, Hobbes
neural_data = load(fullfile(dat_path, [region '_psth_rebinned_20ms_original.mat']));
bin_size = neural_data.data.data_params.bin_size * 1e-3; % in seconds

val_data = load(fullfile(dat_path, [region '_Trial_Vars.mat']));
val = val_data.Trial_Vars.subj_ID.(monkey_id){neuron_idx}.vars(:, 30);

%% Parameters
n_bins = 30;
n_knot_locs = 40;
spline_order = 4;

%% Compute tuning curve and get single-trial spike counts

% create value tuning curve
fr = mean(neural_data.data.subj_ID.(monkey_id){neuron_idx}.psth(:, 151:200), 2); 
spk_counts = sum(neural_data.data.subj_ID.(monkey_id){neuron_idx}.psth(:, 151:200), 2);

prc_edges = unique(prctile(val, linspace(0, 100, n_bins + 1)));
n_bins_actual = length(prc_edges) - 1;
% if n_bins_actual < 10; continue; end

[~, ~, bin_idx] = histcounts(val, prc_edges);
bin_centers = (prc_edges(1:end-1) + prc_edges(2:end)) / 2;

trials_by_bin = cell(n_bins_actual, 1);
mean_fr = nan(n_bins_actual, 1);
for b = 1:n_bins_actual
    trials_by_bin{b} = find(bin_idx == b);
    if ~isempty(trials_by_bin{b})
        mean_fr(b) = mean(spk_counts(trials_by_bin{b}), 'omitnan');
    end
end

valid_mask = ~isnan(mean_fr);
% if sum(valid_mask) < 10; continue; end
valid_fr = mean_fr(valid_mask);
valid_centers = bin_centers(valid_mask);

[sort_val, sort_idx] = sort(val);
sort_spk_counts = spk_counts(sort_idx);

%% Fit modulated Poisson model

% set up spline fitting
knots = linspace(min(sort_val), max(sort_val), n_knot_locs);
augknots = augknt(knots, spline_order);
n_basis_func = length(augknots) - spline_order;
basis_spline = spmak(augknots, eye(n_basis_func));
X = fnval(basis_spline, sort_val)';

log_var_G_init = 1; % ensures that r > 0
w_init = ones(size(X, 2), 1);

params_init = zeros(1 + numel(w_init), 1);
params_init(1) = log_var_G_init;
params_init(2:end) = w_init;

options  = optimset('MaxIter', 10000, 'MaxFunEvals', 10^5);
obj_fun = @(params) getNLL(params, X, sort_spk_counts, bin_size);
est_params = fminsearch(obj_fun, params_init, options);

function nll = getNLL(params_init, X, spk_counts, bin_size)
    
    log_var_G = params_init(1);
    w = params_init(2:end);

    r_ = 1 / exp(log_var_G); % ensures that r > 0
    r = repmat(r_, size(X, 1), 1);
    s = exp(log_var_G) * exp(X * w) * bin_size;

    nll = -sum((gammaln(spk_counts + 1) - gammaln(spk_counts + r) - gammaln(r) + spk_counts .* log(s) - (spk_counts + r) .* log(1 + s)));
end

% get spike count mean and variance
r_est = 1 / exp(est_params(1));
s_est = exp(est_params(1)) * exp(X * est_params(2:end)) * bin_size;
mean_est = r_est * s_est;
var_est = r_est.*s_est + r_est.*s_est.^2;
figure; 
scatter(mean_est, var_est); 
xlabel('Mean (spikes)'); ylabel('Variance (spikes^2)'), 
xlim([0, max([mean_est, var_est], [], 'all')]); ylim([0, max([mean_est, var_est], [], 'all')])
xscale log; yscale log
axis square

% create tuning curve
est_fr = exp(X * est_params(2:end));

trials_by_bin = cell(n_bins_actual, 1);
mean_fr = nan(n_bins_actual, 1);
for b = 1:n_bins_actual
    trials_by_bin{b} = find(bin_idx == b);
    if ~isempty(trials_by_bin{b})
        mean_fr(b) = mean(est_fr(trials_by_bin{b}), 'omitnan');
    end
end

figure; plot(valid_centers, valid_fr);
hold on
plot(valid_centers, mean_fr)