# Backwashing Solver — Session Notes 2026-07-28

Continuation of `docs/backwashing_solver_failure_analysis.md`. That doc identified three root causes (P_diff_bound width, smooth_sign widths, exponential polarization); items 1 and 2 were applied, item 3 (Jk cap) was not yet in place at session start.

## Where we started

Failing model: `examples/SWROwBackwashing.slx` on branch `solute-y`. The three-way interaction (scaling + exponential polarization + backwashing) grinds and dies around t ≈ 28560 s. Any two of the three works. Simlog `simlog.mat` from the prior run showed the first grind at t ≈ 28507 and a second at t ≈ 28553.

## Findings across runs

### Grind 1 — sequential NDP zero-crossings (t ≈ 28507.1 → 28508.2)

Units 10 → 1 cross NDP = 0 sequentially, one every ~130 ms:

| unit | t at NDP=0 |
|---|---|
| 10 | 28507.107 |
| 9 | 28507.235 |
| 8 | 28507.364 |
| ... | ... |
| 2 | 28508.118 |
| 1 | 28508.195 |

At each crossing, `Mdot_detach` for that unit switches from ~0 to a full-strength Q_b·√A term (a ~10× step in |Mdot_y|). The solver micro-steps through each crossing.

**Why this is a knife-edge**, even after the earlier P_diff_bound widening from 1e-3 Pa → 1000 Pa:

- `P_diff_bound = blend(P_diff, 0, -1000, 0, P_diff)` — is 0 for P_diff ≥ 0, only starts departing from 0 as P_diff dips negative. Near P_diff = 0 the Hermite slope is small, so P_diff_bound stays close to 0 for the first tens of Pa of negative P_diff.
- `Mdot_detach = blend(Q_b_term, 0, -F_detach, ..., A_max * P_diff_bound)` — with `A_max = 7.4 m²` and `F_detach = 1 N`, the detach blend's `[-1, 0]` N window corresponds to `P_diff_bound ∈ [-0.135, 0]` Pa, which corresponds to P_diff roughly in `[-30, 0]` Pa.
- Effective transition width: **~30 Pa**, against NDP swings of ±50 kPa. Still a knife edge dressed up as two composed blends.

Simlog confirmation for unit 1: `Mdot_detach` is exactly 0 for t < 28508.20, then abruptly ramps to 1.75e-7 kg/s by t = 28508.67.

### Grind 2 — cap cascade at t ≈ 28550.5 → 28553.6

As Re falls from ~2 to ~0.16, `Jk_y` rises and hits its +2 cap in units 1..5 sequentially between t=28550.61 and t=28553.60, each cap-hit a derivative discontinuity. Separately, in the pre-Jk-cap simlog, `Jk_x` reached -6.09 in unit 1 (no lower cap existed), producing X/x_I ≈ 0.25% — unphysical film-theory extrapolation.

### Grind 3 — final (new after Jk clamp)

After the Jk lower clamp was applied, a fresh very-tight micro-grind of ~9 samples appears at t ≈ 28560.28 where all three near-singular directions coincide in unit 1: `Jk_x` at -2 (lower cap), `Jk_y` at +2 (upper cap), `Re` at 0.157 (right at the Re_min knee). Three of the model's clamps simultaneously saturated in one unit.

## Fixes applied this session

### 1. Two-sided ±2 clamp on Jk_x and Jk_y in `pipe.ssc`

The upper cap (Option A from the earlier analysis doc) had been discussed but not applied. `Jk_x` also had no lower bound — at low Re the mass transfer coefficient k drops, so `J/k` can go arbitrarily negative during backwash (reverse flux). Applied a two-sided clamp:

```matlab
Jk_x_lower = simscape.function.blend({-2,'1'}, J_effective_x/k_x, {-2,'1'}, {-1.5,'1'}, J_effective_x/k_x);
Jk_x       = simscape.function.blend(Jk_x_lower, {2,'1'}, {1.5,'1'}, {2,'1'}, Jk_x_lower);
Jk_y_lower = simscape.function.blend({-2,'1'}, J_effective_y/k_y, {-2,'1'}, {-1.5,'1'}, J_effective_y/k_y);
Jk_y       = simscape.function.blend(Jk_y_lower, {2,'1'}, {1.5,'1'}, {2,'1'}, Jk_y_lower);
```

Cap verified working from `simlog_lowerjkbound.mat` — `Jk_x` never dips below -2, `Jk_y` capped at +2 in units 1-10.

**Result:** grind 2 sample count halved (387 → 120), min dt improved 1e-10 → 2e-7. Grind 1 unchanged as expected. Sim advanced 0.4 s further (28559.88 → 28560.28) before dying.

### 2. Widened Re_min blend in `pipe.ssc:441-442`

Changed the Sherwood blend from `[Re_min, 1.1·Re_min]` (a 10% window, effectively a step) to `[Re_min, 10·Re_min]` (i.e. `[0.1, 1.0]`). Physical justification: the Sherwood correlation is invalid below Re ≈ 1 anyway; a wider blend just makes the transition solvable without changing behavior in the physically valid regime.

**Result from `simlog_expanded_reynolds_transition.mat`:** Re transitions smoothly through the widened floor (Re=2.14 → 1.48 → 0.94 → 0.49 → 0.18 with no micro-grind through the transition). Grind 2 slightly better still. But this doesn't help grind 1 because Jk_y hits +2 at Re=1.89, well before Re enters the widened window.

### 3. Widened detach blend in `scaling_eqs.ssc:108,157` — **KEEP THIS FIX UNDER REVIEW**

Both x and y detach blends changed from `[-F_detach, -F_detach+F_detach_buffer]` (1‰ knife-edge window) to `[-F_detach, 0]` (full-window):

```matlab
% Old:
Mdot_detach = blend(..., -F_detach, -F_detach+F_detach_buffer, A_max*P_diff_bound);
% New:
Mdot_detach = blend(..., -F_detach, {0,'N'}, A_max*P_diff_bound);
```

**Result from `simlog_wide_detach.mat`:** grind 1 got **worse** (1269 → 1771 samples). Why: the old narrow blend was sharp enough that Simscape's zero-crossing detection could step over it as an event; the widened blend is smooth enough that the solver tries to integrate through it instead, and there's still not enough physical room (~30 Pa effective P_diff width) to do that without micro-stepping. This edit is currently on disk but should probably be reverted as part of the next fix (below).

## Simulation summary

| Run | Fixes present | n samples | t_end | grind1 | grind2 |
|---|---|---|---|---|---|
| `simlog.mat` | scaling widths + P_diff_bound=1000 Pa | — | 28559.88 | 1585 samples, min dt 1e-10 | 387 samples, min dt 1e-10 |
| `simlog_lowerjkbound.mat` | + two-sided Jk clamp | 1996 | 28560.28 | 1589, 1e-10 | 144, 2e-7 |
| `simlog_expanded_reynolds_transition.mat` | + widened Re blend | 1675 | 28560.28 | 1269, 1e-10 | 143, 2.5e-7 |
| `simlog_wide_detach.mat` | + widened detach blend | 2175 | 28560.28 | **1771**, 1e-10 | 141, 2e-7 |

## Recommended next step — consolidate P_diff_bound and the detach blend

The detach blend is fundamentally sensitive to P_diff over a ~30 Pa window because of the composition:

- `P_diff_bound` maps P_diff into a bounded range but its Hermite slope near P_diff = 0 is small, so it doesn't provide the transition width we want.
- The detach blend then reads `A_max*P_diff_bound` (with A_max = 7.4 m²) and applies a `[-1, 0]` N window — meaning the effective P_diff window is set to `1/A_max` Pa ≈ 0.135 Pa of P_diff_bound, which back-maps to ~30 Pa of P_diff.

Proposal:

1. Delete `P_diff_bound` from `scaling_eqs.ssc` entirely.
2. Rewrite both detach lines to drive off P_diff directly, with the transition width as a physical parameter (P_detach, in Pa):

```matlab
Mdot_detach = blend(alpha*Q_b*rho*aspect*sqrt(A/(spa*A_max*pi)), {0,'kg/s'}, {-P_detach,'Pa'}, {0,'Pa'}, P_diff);
```

3. Choose `P_detach ≈ 10 kPa`. That's still small relative to operating pressures (~3.45 MPa) but gives the solver 300× more room than the current ~30 Pa effective width.
4. Revert the `-F_detach → 0` edit from this session, and consider removing the now-unused `F_detach`, `F_detach_buffer`, `alpha`(?) parameters (or keep for compatibility with existing mask bindings and mark unused).

This kills two knife-edges with one change: no more `P_diff_bound` Hermite compression near zero, and no more `A_max`-scaled N-to-Pa amplification of the blend window.

## Files touched this session

- `src/+customization/+solution/+elements/pipe.ssc` — two-sided Jk clamp added around lines 447-450; Re_min blend widened at 441-442
- `src/+customization/+scaling/scaling_eqs.ssc:108,157` — detach blend widened to `[-F_detach, 0]` (**candidate for revert** as part of consolidation fix)
- Plots (dark mode) in `docs/`: `diag_1_overview.png`, `diag_2_detach_blend.png`, `diag_3_zoom.png`, `diag_4_second_grind.png`, `diag_5_second_grind_culprits.png`, `diag_6_cap_cascade.png`, `diag_7_jk_negative.png`

## Simlogs available (not in git — local .mat)

- `simlog.mat` — baseline with earlier fixes
- `simlog_lowerjkbound.mat` — after two-sided Jk clamp
- `simlog_expanded_reynolds_transition.mat` — after Re blend widening
- `simlog_wide_detach.mat` — after detach blend widening (regression)
- `werid_numerical_issue_8980s.mat` — older, unrelated
