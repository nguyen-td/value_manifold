% Plot psychometric curve

%% Setup
clear all
close all
clc

%% Load data
n_corr_obs = load('data/n_corr_obs_monkey1.mat');
n_total_obs = load('data/n_total_obs_monkey1.mat');

prop_corr = n_corr_obs.corr_offer_mat ./ n_total_obs.total_offer_mat;

%% Plot psychometric function
n_bins = size(prop_corr, 1);

% compute all possible frame differences
diffs = [];
props = [];

for i = 1:n_bins
    for j = 1:n_bins
        if i ~= j  % ignore diagonal (A == B)
            diffs(end+1) = abs(i - j);
            props(end+1) = prop_corr(i,j);
        end
    end
end

% average proportion correct for each unique difference
unique_diffs = unique(diffs);
mean_props = arrayfun(@(d) mean(props(diffs == d), 'omitnan'), unique_diffs);

% plot
figure;
plot(unique_diffs, mean_props, 'o-', 'LineWidth', 1.5);
xlabel('Frame difference (|A - B|)');
ylabel('Proportion correct');
title('Psychometric function');
axis square;
grid on;

disp(['Average proportion correct: ' num2str(mean(prop_corr, 'all', 'omitnan'))])