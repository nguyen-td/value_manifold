from pathlib import Path
import numpy as np
import torch
from scipy.io import loadmat
import time
from sklearn.decomposition import PCA

from perceptual_straightening.modules.elbo import ELBO

# load data
data_path = Path('data')
save_params_path = Path('fitted_parameters')
monkey_id = 1

n_corr_obs = np.array(loadmat(Path(data_path) / f'n_corr_obs_monkey{monkey_id}.mat')['corr_offer_mat'], dtype=np.float32)
n_total_obs = np.array(loadmat(Path(data_path) / f'n_total_obs_monkey{monkey_id}.mat')['total_offer_mat'], dtype=np.float32)
n_bins = n_total_obs.shape[0]
n_dim = n_bins - 1

# run algorithm
t = time.perf_counter
elbo = ELBO(n_dim, n_corr_obs, n_total_obs)
c_est, p, _, _, _, _, _, _, _, _, _ = elbo.optimize_ELBO_SGD()
elapsed = time.perf_counter() - t
print(f'Finished in {elapsed:.2f} sec')

# print results
print(f'Estimated global curvature (estimated from most likely trajectory): {torch.rad2deg(torch.mean(c_est))} degrees')

# save parameters
out_pkl = Path(save_params_path) / f"value_manifold_monkey{monkey_id}_params.pkl"