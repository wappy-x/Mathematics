-- Discontinuous Galerkin: for advection on a periodic ring of cells, the semi-discrete DG energy changes at the rate minus the flux mix times the speed times the sum of squared edge jumps, so with the upwind flux it never rises, and with one number per cell an Euler step is exactly the upwind step.
import Mathlib.Algebra.Polynomial.Derivative
import Mathlib.Analysis.Calculus.Deriv.Polynomial
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Data.Fin.Basic
import Mathlib.Topology.Algebra.Polynomial

open Polynomial Finset

/-! ### How the card's objects are written here

* The ring is cut into `N` cells, numbered by `Fin N`; addition and subtraction in `Fin N` wrap
  round, so cell `j + 1` is the downstream neighbour and cell `j - 1` the upstream one, and the
  ring has no boundary.
* Inside each cell the position is the local coordinate `ξ ∈ [-1, 1]`, with `dx = (h/2) dξ`.
  The DG answer on cell `j` is a real polynomial in `ξ` of degree at most `p`.
* `u t j` is the DG answer on cell `j` at time `t`; `w j` is its rate of change in time
  (the polynomial `u_t`) at the instant considered.
* The right edge of cell `j` is edge `j + 1/2`. There `u^- = (u j).eval 1` comes from cell `j`
  and `u^+ = (u (j + 1)).eval (-1)` from cell `j + 1`; the jump is `[u] = u^+ - u^-`.
* `F j` is the numerical flux at edge `j + 1/2`, so `F (j - 1)` is the flux at edge `j - 1/2`.
* `dgWeakForm` is the card's cell equation of Step 1, written in the local coordinate:
  for every test polynomial `v` of degree at most `p`,
  `(h/2) ∫ u_t v dξ = c ∫ u v_ξ dξ - F_{j+1/2} v(1) + F_{j-1/2} v(-1)`.
* `fluxMix c β a b = c ((a + b)/2 - (β/2)(b - a))` is the card's flux with mix `β`, with `a = u^-`
  and `b = u^+`; `β = 1` gives the upwind flux `c u^-`, `β = 0` the central flux,
  `β = -1` the downwind flux.
* `dgEnergy h u t = Σ_j (h/2) ∫_{-1}^{1} (u t j)^2 dξ` is the energy `E = ∫_0^1 u_h^2 dx`.
* `jumpSq q = Σ_j (u^+ - u^-)^2` is the sum over every edge of the squared jump. -/

/-- The card's flux with mix `β` at an edge with left value `a = u^-` and right value `b = u^+`:
`F = c ((u^- + u^+)/2 - (β/2) [u])`. -/
noncomputable def fluxMix (c β a b : ℝ) : ℝ := c * ((a + b) / 2 - β / 2 * (b - a))

/-- The DG cell equations (Step 1 of the card): on every cell `j`, for every test polynomial `v`
of degree at most `p`, `(h/2) ∫ u_t v dξ = c ∫ u v_ξ dξ - F_{j+1/2} v(1) + F_{j-1/2} v(-1)`. -/
def dgWeakForm {N : ℕ} [NeZero N] (p : ℕ) (h c : ℝ) (F : Fin N → ℝ)
    (u w : Fin N → ℝ[X]) : Prop :=
  ∀ j : Fin N, ∀ v : ℝ[X], v.natDegree ≤ p →
    h / 2 * ∫ ξ in (-1:ℝ)..1, (w j).eval ξ * v.eval ξ =
      c * (∫ ξ in (-1:ℝ)..1, (u j).eval ξ * (derivative v).eval ξ)
        - F j * v.eval 1 + F (j - 1) * v.eval (-1)

/-- The energy `E(t) = ∫_0^1 u_h^2 dx`, added cell by cell: `Σ_j (h/2) ∫_{-1}^{1} u_j^2 dξ`. -/
noncomputable def dgEnergy {N : ℕ} (h : ℝ) (u : ℝ → Fin N → ℝ[X]) (t : ℝ) : ℝ :=
  ∑ j : Fin N, h / 2 * ∫ ξ in (-1:ℝ)..1, ((u t j).eval ξ) ^ 2

/-- The sum over every edge of the ring of the squared jump `(u^+ - u^-)^2`. -/
noncomputable def jumpSq {N : ℕ} [NeZero N] (q : Fin N → ℝ[X]) : ℝ :=
  ∑ j : Fin N, ((q (j + 1)).eval (-1) - (q j).eval 1) ^ 2

lemma dg_eval_eq_sum {p : ℕ} (q : ℝ[X]) (hq : q.natDegree ≤ p) (x : ℝ) :
    q.eval x = ∑ k ∈ range (p + 1), q.coeff k * x ^ k :=
  eval_eq_sum_range' (by omega) x

lemma dg_integral_eval_mul {p : ℕ} (q r : ℝ[X]) (hq : q.natDegree ≤ p) (hr : r.natDegree ≤ p) :
    ∫ ξ in (-1:ℝ)..1, q.eval ξ * r.eval ξ =
      ∑ k ∈ range (p + 1), ∑ l ∈ range (p + 1),
        q.coeff k * r.coeff l * ∫ ξ in (-1:ℝ)..1, ξ ^ k * ξ ^ l := by
  have hfun : (fun ξ : ℝ => q.eval ξ * r.eval ξ) = fun ξ => ∑ k ∈ range (p + 1),
      ∑ l ∈ range (p + 1), q.coeff k * r.coeff l * (ξ ^ k * ξ ^ l) := by
    funext ξ
    rw [dg_eval_eq_sum q hq, dg_eval_eq_sum r hr, Finset.sum_mul_sum]
    exact Finset.sum_congr rfl fun k _ => Finset.sum_congr rfl fun l _ => by ring
  rw [hfun, intervalIntegral.integral_finsetSum]
  · refine Finset.sum_congr rfl fun k _ => ?_
    rw [intervalIntegral.integral_finsetSum]
    · exact Finset.sum_congr rfl fun l _ => intervalIntegral.integral_const_mul _ _
    · intro l _
      exact (by fun_prop : Continuous fun ξ : ℝ =>
        q.coeff k * r.coeff l * (ξ ^ k * ξ ^ l)).intervalIntegrable _ _
  · intro k _
    exact (by fun_prop : Continuous fun ξ : ℝ => ∑ l ∈ range (p + 1),
      q.coeff k * r.coeff l * (ξ ^ k * ξ ^ l)).intervalIntegrable _ _

lemma dg_integral_eval_mul_derivative (q : ℝ[X]) :
    ∫ ξ in (-1:ℝ)..1, q.eval ξ * (derivative q).eval ξ = (q.eval 1 ^ 2 - q.eval (-1) ^ 2) / 2 := by
  have hI := intervalIntegral.integral_eq_sub_of_hasDerivAt (f := fun ξ => q.eval ξ ^ 2 / 2)
    (f' := fun ξ => q.eval ξ * (derivative q).eval ξ) (a := -1) (b := 1)
    (fun x _ => by
      have hx := ((q.hasDerivAt x).pow 2).div_const 2
      convert hx using 1
      norm_num
      ring)
    ((q.continuous.mul (derivative q).continuous).intervalIntegrable _ _)
  rw [hI]
  ring

lemma dg_rate_natDegree_le {N : ℕ} (p : ℕ) (u : ℝ → Fin N → ℝ[X]) (w : Fin N → ℝ[X]) (t : ℝ)
    (hdeg : ∀ s j, (u s j).natDegree ≤ p)
    (hrate : ∀ j k, HasDerivAt (fun s => (u s j).coeff k) ((w j).coeff k) t) (j : Fin N) :
    (w j).natDegree ≤ p := by
  rw [Polynomial.natDegree_le_iff_coeff_eq_zero]
  intro k hk
  have h0 : (fun s => (u s j).coeff k) = fun _ => (0:ℝ) := by
    funext s
    exact coeff_eq_zero_of_natDegree_lt (lt_of_le_of_lt (hdeg s j) hk)
  have hk' := hrate j k
  rw [h0] at hk'
  exact hk'.unique (hasDerivAt_const t 0)

lemma dg_energy_hasDerivAt {N : ℕ} (p : ℕ) (h : ℝ) (u : ℝ → Fin N → ℝ[X]) (w : Fin N → ℝ[X])
    (t : ℝ) (hdeg : ∀ s j, (u s j).natDegree ≤ p) (hw : ∀ j, (w j).natDegree ≤ p)
    (hrate : ∀ j k, HasDerivAt (fun s => (u s j).coeff k) ((w j).coeff k) t) :
    HasDerivAt (dgEnergy h u)
      (∑ j : Fin N, 2 * (h / 2 * ∫ ξ in (-1:ℝ)..1, (w j).eval ξ * (u t j).eval ξ)) t := by
  have hE : dgEnergy h u = fun s => ∑ j : Fin N, h / 2 * ∑ k ∈ range (p + 1),
      ∑ l ∈ range (p + 1),
        (u s j).coeff k * (u s j).coeff l * ∫ ξ in (-1:ℝ)..1, ξ ^ k * ξ ^ l := by
    funext s
    unfold dgEnergy
    refine Finset.sum_congr rfl fun j _ => ?_
    rw [← dg_integral_eval_mul _ _ (hdeg s j) (hdeg s j)]
    congr 1
    refine intervalIntegral.integral_congr fun ξ _ => ?_
    ring
  rw [hE]
  have hd : HasDerivAt (fun s => ∑ j : Fin N, h / 2 * ∑ k ∈ range (p + 1),
      ∑ l ∈ range (p + 1),
        (u s j).coeff k * (u s j).coeff l * ∫ ξ in (-1:ℝ)..1, ξ ^ k * ξ ^ l)
      (∑ j : Fin N, h / 2 * ∑ k ∈ range (p + 1), ∑ l ∈ range (p + 1),
        ((w j).coeff k * (u t j).coeff l + (u t j).coeff k * (w j).coeff l) *
          ∫ ξ in (-1:ℝ)..1, ξ ^ k * ξ ^ l) t := by
    refine HasDerivAt.fun_sum fun j _ => ?_
    refine HasDerivAt.const_mul _ ?_
    refine HasDerivAt.fun_sum fun k _ => ?_
    refine HasDerivAt.fun_sum fun l _ => ?_
    exact ((hrate j k).mul (hrate j l)).mul_const _
  convert hd using 1
  refine Finset.sum_congr rfl fun j _ => ?_
  have h1 := dg_integral_eval_mul (w j) (u t j) (hw j) (hdeg t j)
  have h2 := dg_integral_eval_mul (u t j) (w j) (hdeg t j) (hw j)
  have h3 : ∫ ξ in (-1:ℝ)..1, (u t j).eval ξ * (w j).eval ξ =
      ∫ ξ in (-1:ℝ)..1, (w j).eval ξ * (u t j).eval ξ :=
    intervalIntegral.integral_congr fun ξ _ => mul_comm _ _
  have h4 : ∑ k ∈ range (p + 1), ∑ l ∈ range (p + 1),
        ((w j).coeff k * (u t j).coeff l + (u t j).coeff k * (w j).coeff l) *
          ∫ ξ in (-1:ℝ)..1, ξ ^ k * ξ ^ l =
      (∫ ξ in (-1:ℝ)..1, (w j).eval ξ * (u t j).eval ξ) +
        ∫ ξ in (-1:ℝ)..1, (u t j).eval ξ * (w j).eval ξ := by
    rw [h1, h2, ← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun k _ => ?_
    rw [← Finset.sum_add_distrib]
    exact Finset.sum_congr rfl fun l _ => by ring
  rw [h4, h3]
  ring

lemma dg_flux_sum {N : ℕ} [NeZero N] (c β : ℝ) (a b : Fin N → ℝ) :
    ∑ j : Fin N, 2 * (c * ((a j ^ 2 - b j ^ 2) / 2) - fluxMix c β (a j) (b (j + 1)) * a j
        + fluxMix c β (a (j - 1)) (b (j - 1 + 1)) * b j)
      = -(β * c * ∑ j : Fin N, (b (j + 1) - a j) ^ 2) := by
  have hshift : ∑ j : Fin N, (2 * fluxMix c β (a (j - 1)) (b (j - 1 + 1)) * b j - c * b j ^ 2)
      = ∑ j : Fin N, (2 * fluxMix c β (a j) (b (j + 1)) * b (j + 1) - c * b (j + 1) ^ 2) := by
    rw [← Equiv.sum_comp (Equiv.addRight (1 : Fin N))]
    simp only [Equiv.coe_addRight, add_sub_cancel_right]
  calc _ = ∑ j : Fin N, (c * a j ^ 2 - 2 * fluxMix c β (a j) (b (j + 1)) * a j)
        + ∑ j : Fin N, (2 * fluxMix c β (a (j - 1)) (b (j - 1 + 1)) * b j - c * b j ^ 2) := by
          rw [← Finset.sum_add_distrib]
          exact Finset.sum_congr rfl fun j _ => by ring
    _ = _ := by
      rw [hshift, ← Finset.sum_add_distrib, Finset.mul_sum, ← Finset.sum_neg_distrib]
      refine Finset.sum_congr rfl fun j _ => ?_
      unfold fluxMix
      ring

lemma dg_energy_rate_general {N : ℕ} [NeZero N] (p : ℕ) (h c β : ℝ)
    (u : ℝ → Fin N → ℝ[X]) (w : Fin N → ℝ[X]) (t : ℝ)
    (hdeg : ∀ s j, (u s j).natDegree ≤ p)
    (hrate : ∀ j k, HasDerivAt (fun s => (u s j).coeff k) ((w j).coeff k) t)
    (hweak : dgWeakForm p h c
      (fun j => fluxMix c β ((u t j).eval 1) ((u t (j + 1)).eval (-1))) (u t) w) :
    HasDerivAt (dgEnergy h u) (-(β * c * jumpSq (u t))) t := by
  have hw : ∀ j, (w j).natDegree ≤ p := dg_rate_natDegree_le p u w t hdeg hrate
  have hd := dg_energy_hasDerivAt p h u w t hdeg hw hrate
  convert hd using 1
  have hj : ∀ j : Fin N, 2 * (h / 2 * ∫ ξ in (-1:ℝ)..1, (w j).eval ξ * (u t j).eval ξ) =
      2 * (c * (((u t j).eval 1 ^ 2 - (u t j).eval (-1) ^ 2) / 2)
        - fluxMix c β ((u t j).eval 1) ((u t (j + 1)).eval (-1)) * (u t j).eval 1
        + fluxMix c β ((u t (j - 1)).eval 1) ((u t (j - 1 + 1)).eval (-1)) * (u t j).eval (-1)) := by
    intro j
    rw [hweak j (u t j) (hdeg t j), dg_integral_eval_mul_derivative]
  rw [Finset.sum_congr rfl fun j _ => hj j]
  exact (dg_flux_sum c β (fun j => (u t j).eval 1) (fun j => (u t j).eval (-1))).symm

#print axioms dg_eval_eq_sum
#print axioms dg_integral_eval_mul
#print axioms dg_integral_eval_mul_derivative
#print axioms dg_rate_natDegree_le
#print axioms dg_energy_hasDerivAt
#print axioms dg_flux_sum
#print axioms dg_energy_rate_general

/-- The card's main claim, the energy identity with the upwind flux. Discontinuous Galerkin for
`u_t + c u_x = 0` with steady speed `c > 0` on a periodic ring of cells, each cell carrying its
own polynomial of degree at most `p` and the cells joined only by the upwind flux `F = c u^-`:
the energy `E = ∫ u_h^2 dx` changes at the rate `dE/dt = -c Σ_edges [u]^2`, which is never
positive. -/
theorem upwind_dg_energy_rate_eq_neg_sum_sq_jumps {N : ℕ} [NeZero N] (p : ℕ) (h c : ℝ)
    (hc : 0 < c) (u : ℝ → Fin N → ℝ[X]) (w : Fin N → ℝ[X]) (t : ℝ)
    (hdeg : ∀ s j, (u s j).natDegree ≤ p)
    (hrate : ∀ j k, HasDerivAt (fun s => (u s j).coeff k) ((w j).coeff k) t)
    (hweak : dgWeakForm p h c (fun j => c * (u t j).eval 1) (u t) w) :
    HasDerivAt (dgEnergy h u) (-(c * jumpSq (u t))) t ∧ -(c * jumpSq (u t)) ≤ 0 := by
  have hF : (fun j => c * (u t j).eval 1) =
      (fun j => fluxMix c 1 ((u t j).eval 1) ((u t (j + 1)).eval (-1))) := by
    funext j
    unfold fluxMix
    ring
  rw [hF] at hweak
  have hd := dg_energy_rate_general p h c 1 u w t hdeg hrate hweak
  rw [one_mul] at hd
  refine ⟨hd, ?_⟩
  have hJ : 0 ≤ jumpSq (u t) := Finset.sum_nonneg fun j _ => sq_nonneg _
  have := mul_nonneg hc.le hJ
  linarith

/-- The energy identity for every flux mix (Step 3 and its detailed proof): with the flux
`F = c ((u^- + u^+)/2 - (β/2)[u])` at every edge, the energy changes at the rate
`dE/dt = -β c Σ_edges [u]^2`, for every `β` and every speed `c`. -/
theorem dg_energy_rate_eq_neg_beta_sum_sq_jumps {N : ℕ} [NeZero N] (p : ℕ) (h c β : ℝ)
    (u : ℝ → Fin N → ℝ[X]) (w : Fin N → ℝ[X]) (t : ℝ)
    (hdeg : ∀ s j, (u s j).natDegree ≤ p)
    (hrate : ∀ j k, HasDerivAt (fun s => (u s j).coeff k) ((w j).coeff k) t)
    (hweak : dgWeakForm p h c
      (fun j => fluxMix c β ((u t j).eval 1) ((u t (j + 1)).eval (-1))) (u t) w) :
    HasDerivAt (dgEnergy h u) (-(β * c * jumpSq (u t))) t := by
  exact dg_energy_rate_general p h c β u w t hdeg hrate hweak

/-- Step 2 of the card: piecewise-constant DG (`p = 0`) with the upwind flux is the upwind
finite-volume scheme. If each cell holds the constant `a_j` and its rate is the constant `r_j`,
the cell equations force `h r_j = -c (a_j - a_{j-1})`, so one Euler step of length `Δt` gives
`a_j - ν (a_j - a_{j-1})` with `ν = c Δt / h`. -/
theorem dg_degree_zero_euler_step_eq_upwind_step {N : ℕ} [NeZero N] (h c Δt : ℝ) (hh : 0 < h)
    (a r : Fin N → ℝ)
    (hweak : dgWeakForm 0 h c (fun j => c * a j) (fun j => C (a j)) (fun j => C (r j))) :
    ∀ j : Fin N, a j + Δt * r j = a j - c * Δt / h * (a j - a (j - 1)) := by
  intro j
  have hw := hweak j (C 1) (by simp)
  simp at hw
  have hr : r j = -(c * (a j - a (j - 1))) / h := by
    field_simp
    linarith
  rw [hr]
  field_simp
  ring

#print axioms upwind_dg_energy_rate_eq_neg_sum_sq_jumps
#print axioms dg_energy_rate_eq_neg_beta_sum_sq_jumps
#print axioms dg_degree_zero_euler_step_eq_upwind_step
