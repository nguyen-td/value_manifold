% Construct subjective value (SU) matrices to use for perceptual trajectory
% estimation.

%% Setup
clear all
close all
clc

load('vmPFC_Trial_Vars_shared.mat') % load data

%% Get range of subjective utility values for binning
monkeys = {'Batman', 'Hobbes'};

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
h = histogram(vertcat(all_SU{:})); axis square, box off
bin_edges = h.BinEdges;

% construct matrices
monkey_id = 1;

corr_offer_mat = zeros(numel(bin_edges), numel(bin_edges));
total_offer_mat = zeros(numel(bin_edges), numel(bin_edges));

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
    end
end
prop_corr_offer_mat = corr_offer_mat ./ total_offer_mat;

%% Plot matrices
% h = imagesc(bin_edges(1:50), bin_edges(1:50), prop_corr_offer_mat(1:50, 1:50)); 
h = imagesc(bin_edges, bin_edges, prop_corr_offer_mat); 

c = colorbar;
c.Label.String = 'Proportion correct';
title(['Monkey' num2str(monkey_id)], 'FontSize', 13)
set(gca, 'YDir', 'normal', 'FontSize', 12);
xlabel('Subjective utility offer 1')
ylabel('Subjective utility offer 2')
colormap gray
axis square
set(h, 'AlphaData', ~isnan(prop_corr_offer_mat)); % make nan transparent
set(gca, 'Color', [0.8 0 0]); 

%% Save matrices
save(['data/n_corr_obs_monkey' num2str(monkey_id)], 'corr_offer_mat')
save(['data/n_total_obs_monkey' num2str(monkey_id)], 'total_offer_mat')