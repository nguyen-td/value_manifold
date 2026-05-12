% Construct subjective value (SU) matrices to use for perceptual trajectory
% estimation.

%% Setup
clear all
close all
clc

load('vmPFC_Trial_Vars_shared.mat') % load data

%% Get range of subjective utility values for binning
monkeys = {'Batman', 'Hobbes'};
bin_edge_factor = 6; % bin edges are multiples of the original bin edges estimated by the histogram
monkey_id = 2;
% offer_id = 1; % used for plotting psychometric curve

all_SU = {};
offer_choices = {};
subj_utilities = {};

for imonkey = 1:numel(monkeys)
    n_neurons = length(newTrial_Vars.subj_ID.(monkeys{imonkey}));
    for ineuron = 1:n_neurons
        vars = newTrial_Vars.subj_ID.(monkeys{imonkey}){ineuron}.vars;
        subj_values = vars(:, 4:5);
        all_SU{imonkey, ineuron} = subj_values(:);
        subj_utilities{imonkey, ineuron} = vars(:, 4:5);

        % store choices for constructing matrix
        offer_choices{imonkey, ineuron} = vars(:, 1);
    end
end
% h1 = histogram(vertcat(all_SU{1, :})); axis square, box off
% h2 = histogram(vertcat(all_SU{2, :})); axis square, box off
h = histogram(vertcat(all_SU{monkey_id, :})); axis square, box off
h_bin_edges = h.BinEdges;
bin_edges = linspace(h_bin_edges(1), h_bin_edges(end), round(numel(h_bin_edges) / bin_edge_factor));
n_reps = h.Values;

% construct matrices
corr_offer_mat = zeros(length(bin_edges) - 1, length(bin_edges) - 1);
total_offer_mat = zeros(length(bin_edges) - 1, length(bin_edges) - 1);
n_offer_1_mat = zeros(length(bin_edges) - 1, length(bin_edges) - 1);

for ineuron = 1:numel(newTrial_Vars.subj_ID.(monkeys{monkey_id})) % run for each monkey separately
    su_bins = discretize(subj_utilities{monkey_id, ineuron}, bin_edges);
    su1_minus_su2 = subj_utilities{monkey_id, ineuron}(:, 1) - subj_utilities{monkey_id, ineuron}(:, 2); % compute SU_1 - SU_2
    for ibin = 1:size(su_bins, 1)
        total_offer_mat(su_bins(ibin, 1), su_bins(ibin, 2)) = total_offer_mat(su_bins(ibin, 1), su_bins(ibin, 2)) + 1;

        if (su1_minus_su2(ibin) > 0) && (offer_choices{monkey_id, ineuron}(ibin) == 1) % if SU_1 > SU_2 and choice = 1
            corr_offer_mat(su_bins(ibin, 1), su_bins(ibin, 2)) = corr_offer_mat(su_bins(ibin, 1), su_bins(ibin, 2)) + 1;
        elseif (su1_minus_su2(ibin) < 0) && (offer_choices{monkey_id, ineuron}(ibin) == 0) % if SU_1 < SU_2 and choice = 2
            corr_offer_mat(su_bins(ibin, 1), su_bins(ibin, 2)) = corr_offer_mat(su_bins(ibin, 1), su_bins(ibin, 2)) + 1;
        end

        % % store probability of choosing offer 1 for psychometric curve
        % if offer_choices{monkey_id, ineuron}(ibin) == offer_id
        %     n_offer_1_mat(su_bins(ibin, 1), su_bins(ibin, 2)) = n_offer_1_mat(su_bins(ibin, 1), su_bins(ibin, 2)) + 1;
        % end
    end
end
prop_corr_offer = corr_offer_mat ./ total_offer_mat;
disp(['Average proportion correct: ' num2str(mean(prop_corr_offer, 'all', 'omitnan'))])

%% Plot matrix

% plot matrices
% h = imagesc(bin_edges(1:50), bin_edges(1:50), prop_corr_offer(1:50, 1:50)); 
h = imagesc(bin_edges, bin_edges, prop_corr_offer); 

figure(1)
c = colorbar;
c.Label.String = 'Proportion correct';
title(['Monkey' num2str(monkey_id)], 'FontSize', 13)
set(gca, 'YDir', 'normal', 'FontSize', 12);
xlabel('Subjective utility offer 1')
ylabel('Subjective utility offer 2')
colormap gray
axis square
% set(h, 'AlphaData', ~isnan(prop_corr_offer)); % make nan transparent
% set(gca, 'Color', [0.8 0 0]); 

%% Plot performance curve
% build empirical performance curve
value_bin_diff = [];
k = [];   % successes
n = [];   % trials

for i = 1:size(n_offer_1_mat, 1)
    for j = 1:size(n_offer_1_mat, 2)
        if total_offer_mat(i,j) > 0
            value_bin_diff(end+1) = abs(i - j);

            k(end+1) = corr_offer_mat(i,j);
            n(end+1) = total_offer_mat(i,j);
        end
    end
end

% average proportion correct for each unique value bin difference ('marginalize' over individual trials)
unique_diffs = unique(value_bin_diff);
k_grouped = arrayfun(@(d) sum(k(value_bin_diff == d)), unique_diffs);
n_grouped = arrayfun(@(d) sum(n(value_bin_diff == d)), unique_diffs);
prop_offer_grouped = k_grouped ./ n_grouped;

% % plot
% figure(2);
% scatter(unique_diffs, prop_offer_grouped, 'LineWidth', 1.5);
% xlabel('SU bin difference');
% ylabel('Probability correct');
% title('Performance curve');
% axis square;
% grid on;

% %% Fit and plot psychometric function
% 
% % build empirical performance curve
% value_bin_diff = [];
% k = [];   % successes
% n = [];   % trials
% 
% for i = 1:size(n_offer_1_mat, 1)
%     for j = 1:size(n_offer_1_mat, 2)
% 
%         if total_offer_mat(i,j) > 0
% 
%             value_bin_diff(end+1) = bin_edges(i+1) - bin_edges(j+1);
% 
%             k(end+1) = n_offer_1_mat(i,j);
%             n(end+1) = total_offer_mat(i,j);
% 
%         end
%     end
% end
% 
% % average proportion correct for each unique value bin difference ('marginalize' over individual trials)
% unique_diffs = unique(value_bin_diff);
% k_grouped = arrayfun(@(d) sum(k(value_bin_diff == d)), unique_diffs);
% n_grouped = arrayfun(@(d) sum(n(value_bin_diff == d)), unique_diffs);
% 
% mean_prop_offer_1 = k_grouped ./ n_grouped;
% 
% fit psychometric function
gamma = 0.5;             % guess rate, lower bounds the psychometric curve

psycho_fun = @(lambda, mu, sigma) gamma + (1 - gamma - lambda) * normcdf(unique_diffs, mu, sigma); % cf. Wichmann & Hill (2001), Eq. 1
nll = @(params) -sum((k_grouped .* log(psycho_fun(params(1), params(2), params(3)))) + (n_grouped - k_grouped) .* log(1 - psycho_fun(params(1), params(2), params(3))), 'omitnan'); % Eq. 2  

params_init = [0.02, 0, 1]; % lambda, mu, sigma
lb = [0,   min(vertcat(all_SU{:})), min(vertcat(all_SU{:}))]; % constrain lambda (lapse, stimulus-independent mistakes) to be [0, 0.06]
ub = [0.06, max(vertcat(all_SU{:})),  max(vertcat(all_SU{:}))]; 

options  = optimset('Display', 'iter', 'MaxIter', 1000);
params = fmincon(nll, params_init, [], [], [], [], lb, ub, [], options);
disp(['Optimal parameters: lambda = ' num2str(params(1)) ', mu = ' num2str(params(2)) ', sigma = ' num2str(params(3))])

% report threshold and slope
p = psycho_fun(params(1), params(2), params(3));

% plot
figure;
plot(unique_diffs, p, '-', 'LineWidth', 2);
hold on;
scatter(unique_diffs, prop_offer_grouped, 'k', 'filled')
xlabel('|SU bin 1 - SU bin 2|');
ylabel('Proportion correct');
title('Fitted psychometric function');
axis square;
grid on;
 
%% Save matrices
save(['data/n_corr_obs_monkey' num2str(monkey_id) '_' num2str(numel(bin_edges)) 'bins'], 'corr_offer_mat')
save(['data/n_total_obs_monkey' num2str(monkey_id) '_' num2str(numel(bin_edges)) 'bins'], 'total_offer_mat')