# Backwashing Solver Failure Analysis

## Problem Summary

`SWROwBackwashing.slx` fails when the applied pressure ramps down and the net driving pressure (NDP) crosses zero in the last membrane unit(s). The solver hits minimum step size and either gets stuck indefinitely or accumulates large effective tolerance errors.

The failure occurs ~7 seconds into the 60-second pressure ramp-down, at the point where the last unit membrane's NDP reverses (osmotic pressure exceeds applied pressure due to concentration buildup over ~5.9 hours of RO operation).

`SWRO.slx` works because it never reverses pressure — it only ramps up to steady state.

---

## Root Causes Identified

### 1. `P_diff_bound` transition width in `scaling_eqs.ssc` (line 181)

**Original:**
```matlab
P_diff_bound = simscape.function.blend(P_diff, {0,'Pa'}, {-1e-3,'Pa'}, {0,'Pa'}, P_diff);
```

**Problem:** The blend transitions over **1 milliPascal** — essentially a step function relative to the ~3.45 MPa operating pressure. When transmembrane pressure crosses zero, the detachment term snaps on/off over this impossibly narrow range.

**Fix applied:**
```matlab
P_diff_bound = simscape.function.blend(P_diff, {0,'Pa'}, {-1000,'Pa'}, {0,'Pa'}, P_diff);
```

**Rationale:** 1000 Pa ≈ 0.15 psi is a physically reasonable transition width for "detachment turns off near zero pressure." This is still tiny relative to operating conditions (500 psi) but gives the solver 6 orders of magnitude more room to resolve the transition.

---

### 2. `smooth_sign` thresholds in `scaling_eqs.ssc` (lines 118, 167)

**Original:**
```matlab
Mdot == simscape.function.blend({0,'kg/s'}, Mdot_unbounded, -2, -1,
    smooth_sign(M_scale-M_min, M_nucelation/10) + smooth_sign(Mdot_unbounded, {1e-15,'g/s'}));
```

**Problem:** The smoothing widths are:
- `M_nucelation/10` ≈ 4e-17 kg (for mass threshold)
- `1e-15 g/s` = 1e-18 kg/s (for growth rate threshold)

These make `smooth_sign` behave as a hard step function. During backwashing, when `Mdot_unbounded` passes through zero (growth stops, dissolution begins), the solver must resolve a transition that's 1e-18 kg/s wide — driving minimum step size violations.

**Fix applied:**
```matlab
Mdot == simscape.function.blend({0,'kg/s'}, Mdot_unbounded, -2, -1,
    smooth_sign(M_scale-M_min, M_nucelation) + smooth_sign(Mdot_unbounded, {1e-10,'g/s'}));
```

**Rationale:**
- `M_nucelation` (no /10): still sub-nucleation scale, just 10x wider for the solver
- `1e-10 g/s` = 1e-13 kg/s: still negligible relative to actual growth rates, but 100,000x wider than before for the solver to resolve

Same change for solute y on line 167.

---

### 3. Exponential polarization blow-up at low crossflow (the remaining issue)

**Location:** `pipe.ssc` lines 449-450

```matlab
X == x_I * exp(J_effective_x / k_x);
```

**Problem:** The mass transfer coefficient `k` depends on the Sherwood number:
```matlab
Sh = 0.14 * Re^0.64 * Sc^0.24
k = Sh * D / Dh
```

The `Re` is floored at `Re_min = 0.1` via a blend. At that floor:
- `k` drops to ~1.9e-7 m/s (vs ~1.6e-5 at normal operation)
- Even a small remaining flux gives `J/k` >> 1
- `exp(J/k)` can exceed **6000x** polarization — physically meaningless

This creates an unstable algebraic loop:
```
X = x_I * exp(J(X) / k)
```
where J depends on membrane flux which depends on X (the polarized concentration). As flow slows:
1. Re → Re_min → k drops 80x
2. exp(J/k) explodes → X increases massively
3. Higher X → higher osmotic pressure → NDP goes more negative → flux reverses more
4. But reverse flux gives negative J → exp(negative) → X drops below x_I
5. Lower X → lower osmotic → NDP increases → flux tries to go forward again
6. → **Oscillation** between forward and reverse states

This is why the solver oscillates with effective tolerance ~0.0024 alternating with ~0.0048 at t=43202.

**Why it gets through the first backwash but not the second:** After 12 hours there's more salt buildup and more units are near the NDP zero-crossing simultaneously, creating a stiffer coupled system.

---

## Proposed Solutions for the Polarization Issue

### Option A: Cap the J/k ratio (recommended)

Film theory is invalid when `J/k > ~1-2` anyway (the boundary layer assumption breaks down). Cap the exponent argument:

```matlab
intermediates (ExternalAccess = none)
    Jk_x = simscape.function.blend(J_effective_x/k_x, {2,'1'}, {1.5,'1'}, {2,'1'}, J_effective_x/k_x);
    Jk_y = simscape.function.blend(J_effective_y/k_y, {2,'1'}, {1.5,'1'}, {2,'1'}, J_effective_y/k_y);
end
equations
    X == x_I*exp(Jk_x);
    Y == y_I*exp(Jk_y);
end
```

**Pros:** Physically justified (film theory limit), preserves negative J behavior, simple  
**Cons:** Slightly modifies steady-state at very high polarization conditions

### Option B: Raise Re_min

Increasing `Re_min` from 0.1 to something like 10-50 would keep `k` higher during low-flow conditions.

**Pros:** Simple parameter change, no code changes  
**Cons:** Changes steady-state Sherwood number for all low-flow conditions, might over-estimate mass transfer when flow is genuinely slow

### Option C: Use a separate k floor

Add a direct floor on `k` rather than relying on the Re floor:

```matlab
k_x_bounded = simscape.function.blend(k_min, k_x, k_min, 2*k_min, k_x);
```

where `k_min` is chosen so that `J_max/k_min` ≈ 1-2.

**Pros:** Decouples the polarization cap from the Sherwood correlation  
**Cons:** Introduces another tuning parameter

### Option D: Blend X toward x_I as flux approaches zero

```matlab
X == x_I * simscape.function.blend({1,'1'}, exp(J_effective_x/k_x), {0,'m/s'}, {J_threshold,'m/s'}, abs(J_effective_x));
```

This smoothly transitions from polarized to unpolarized as flux drops, regardless of k.

**Pros:** Physically intuitive (no polarization without flux), handles both signs of J  
**Cons:** Introduces a threshold that needs tuning; may hide real polarization at low but non-zero flux

---

## Configuration Difference: `dynamic_compressibility`

SWRO uses `dynamic_compressibility = true`; the original SWROwBackwashing had it `false`. With `true`, pressure is a state variable with its own dynamics, which adds natural damping to pressure transients. This was an important baseline fix — without it, pressure changes propagate algebraically (instantaneously) through the network, making zero-crossing transitions even sharper.

---

## Summary of Changes Made

| File | Change | Status |
|------|--------|--------|
| `scaling_eqs.ssc:181` | P_diff_bound: 1e-3 Pa → 1000 Pa | Applied |
| `scaling_eqs.ssc:118` | smooth_sign Mdot width: 1e-15 g/s → 1e-10 g/s | Applied |
| `scaling_eqs.ssc:118` | smooth_sign M width: M_nuc/10 → M_nuc | Applied |
| `scaling_eqs.ssc:167` | Same two changes for solute y | Applied |
| `pipe.ssc:449` | Cap J/k ratio | **Not yet applied** |
| Model | dynamic_compressibility = true | Done by user |

With fixes 1 and 2 only, the simulation gets through the first backwash cycle (t=21300) but fails at the second (t=43200). The polarization fix (item 3) is needed to fully resolve the issue.
