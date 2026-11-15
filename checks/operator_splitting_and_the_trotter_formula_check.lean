-- Splitting: for bounded parts whose evolutions never grow in size, alternating short steps of each converges to the combined evolution with error at most t²/(2n) times the commutator, and the river's drift and spread have commutator 2β times the spread.
import Mathlib.Analysis.Normed.Algebra.Exponential
import Mathlib.Analysis.Normed.Operator.NormedSpace
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Tactic

/-! The state space `E` is a real Banach space; a matrix acting on `ℝ^N` with any norm is a case.
The parts of the motion are bounded operators `A B : E →L[ℝ] E`, and `exp (s • A)` is Mathlib's
`NormedSpace.exp`, the evolution `e^{sA}` for time `s`. "Never grows in size" means
`‖exp (s • A)‖ ≤ 1` for every `s ≥ 0` (a contraction semigroup). One split step of length `t / n`
is `exp ((t / n) • B) * exp ((t / n) • A)`: drift `A` first, then spread `B`.
The commutator `[A, B]` is `A * B - B * A`. -/

open NormedSpace Filter Topology


section helpers
open Set
variable {𝔸 : Type*} [NormedRing 𝔸] [NormedAlgebra ℝ 𝔸] [CompleteSpace 𝔸]

theorem trotter_aux_comm (A B : 𝔸)
    (hB : ∀ s : ℝ, 0 ≤ s → ‖exp (s • B)‖ ≤ 1) (s : ℝ) (hs : 0 ≤ s) :
    ‖exp (s • B) * A - A * exp (s • B)‖ ≤ ‖A * B - B * A‖ * s := by
  set g : ℝ → 𝔸 := fun r => exp (r • B) * A * exp ((s - r) • B) with hg
  have hd : ∀ r, HasDerivAt g (exp (r • B) * (B * A - A * B) * exp ((s - r) • B)) r := by
    intro r
    have h1 := hasDerivAt_exp_smul_const B r
    have h2 : HasDerivAt (fun r : ℝ => exp ((s - r) • B)) (-(B * exp ((s - r) • B))) r := by
      have := (hasDerivAt_exp_smul_const' (𝕂 := ℝ) B (s - r)).scomp r
        ((hasDerivAt_const r s).sub (hasDerivAt_id r))
      exact this.congr_deriv (by simp)
    have := (h1.mul_const A).mul h2
    convert this using 1
    noncomm_ring
  have key := norm_image_sub_le_of_norm_deriv_right_le_segment (f := g) (a := 0) (b := s)
    (C := ‖A * B - B * A‖)
    (fun r _ => (hd r).continuousAt.continuousWithinAt)
    (fun r _ => (hd r).hasDerivWithinAt)
    (by
      intro r hr
      have hr0 : 0 ≤ r := hr.1
      have hsr : 0 ≤ s - r := by linarith [hr.2]
      calc ‖exp (r • B) * (B * A - A * B) * exp ((s - r) • B)‖
          ≤ ‖exp (r • B)‖ * ‖B * A - A * B‖ * ‖exp ((s - r) • B)‖ := by
            refine (norm_mul_le _ _).trans ?_
            gcongr
            exact norm_mul_le _ _
        _ ≤ 1 * ‖B * A - A * B‖ * 1 := by
            gcongr
            · exact hB r hr0
            · exact hB _ hsr
        _ = ‖A * B - B * A‖ := by rw [norm_sub_rev]; ring) s ⟨hs, le_rfl⟩
  simpa [g, exp_zero] using key

theorem trotter_aux_step (A B : 𝔸)
    (hA : ∀ s : ℝ, 0 ≤ s → ‖exp (s • A)‖ ≤ 1)
    (hB : ∀ s : ℝ, 0 ≤ s → ‖exp (s • B)‖ ≤ 1)
    (hAB : ∀ s : ℝ, 0 ≤ s → ‖exp (s • (A + B))‖ ≤ 1) (h : ℝ) (hh : 0 ≤ h) :
    ‖exp (h • (A + B)) - exp (h • B) * exp (h • A)‖ ≤ h ^ 2 / 2 * ‖A * B - B * A‖ := by
  set C := ‖A * B - B * A‖ with hC
  set f : ℝ → 𝔸 := fun s => exp ((h - s) • (A + B)) * (exp (s • B) * exp (s • A)) with hf
  have hd : ∀ s, HasDerivAt f (exp ((h - s) • (A + B)) *
      (exp (s • B) * A - A * exp (s • B)) * exp (s • A)) s := by
    intro s
    have h1 : HasDerivAt (fun s : ℝ => exp ((h - s) • (A + B)))
        (-(exp ((h - s) • (A + B)) * (A + B))) s := by
      have := (hasDerivAt_exp_smul_const (𝕂 := ℝ) (A + B) (h - s)).scomp s
        ((hasDerivAt_const s h).sub (hasDerivAt_id s))
      exact this.congr_deriv (by simp)
    have h2 := hasDerivAt_exp_smul_const' (𝕂 := ℝ) B s
    have h3 := hasDerivAt_exp_smul_const' (𝕂 := ℝ) A s
    have := h1.fun_mul (h2.fun_mul h3)
    convert this using 1
    noncomm_ring
  let F : ℝ → 𝔸 := fun s => f s - f 0
  have hF : ∀ s, HasDerivAt F (exp ((h - s) • (A + B)) *
      (exp (s • B) * A - A * exp (s • B)) * exp (s • A)) s := by
    intro s
    simpa [F] using (hd s).sub_const (f 0)
  have hBd : ∀ s : ℝ, HasDerivAt (fun s : ℝ => s ^ 2 / 2 * C) (s * C) s := by
    intro s
    have := ((hasDerivAt_pow 2 s).div_const 2).mul_const C
    convert this using 1
    push_cast
    ring
  have key := image_norm_le_of_norm_deriv_right_le_deriv_boundary (f := F) (a := 0) (b := h)
    (fun r _ => (hF r).continuousAt.continuousWithinAt)
    (fun r _ => (hF r).hasDerivWithinAt)
    (by simp [F]) hBd
    (by
      intro r hr
      have hr0 : 0 ≤ r := hr.1
      have hsr : 0 ≤ h - r := by linarith [hr.2]
      calc ‖exp ((h - r) • (A + B)) * (exp (r • B) * A - A * exp (r • B)) * exp (r • A)‖
          ≤ ‖exp ((h - r) • (A + B))‖ * ‖exp (r • B) * A - A * exp (r • B)‖ *
              ‖exp (r • A)‖ := by
            refine (norm_mul_le _ _).trans ?_
            gcongr
            exact norm_mul_le _ _
        _ ≤ 1 * (C * r) * 1 := by
            gcongr
            · exact hAB _ hsr
            · exact trotter_aux_comm A B hB r hr0
            · exact hA r hr0
        _ = r * C := by ring) ⟨hh, le_rfl⟩
  have e1 : f h = exp (h • B) * exp (h • A) := by simp [f]
  have e0 : f 0 = exp (h • (A + B)) := by simp [f]
  rw [norm_sub_rev]
  simpa [F, e1, e0] using key

theorem trotter_aux_exp_nsmul (n : ℕ) (x : 𝔸) : exp (n • x) = exp x ^ n := by
  induction n with
  | zero => simp [exp_zero]
  | succ n ih =>
    rw [succ_nsmul, pow_succ, ← ih]
    exact exp_add_of_commute_of_mem_ball (𝕂 := ℝ) ((Commute.refl x).smul_left n)
      ((expSeries_radius_eq_top ℝ 𝔸).symm ▸ edist_lt_top _ _)
      ((expSeries_radius_eq_top ℝ 𝔸).symm ▸ edist_lt_top _ _)

omit [NormedAlgebra ℝ 𝔸] [CompleteSpace 𝔸] in
theorem trotter_aux_pow (S T : 𝔸) (h1 : ‖(1 : 𝔸)‖ ≤ 1) (hS : ‖S‖ ≤ 1) (hT : ‖T‖ ≤ 1)
    (n : ℕ) : ‖T ^ n - S ^ n‖ ≤ n * ‖T - S‖ := by
  have hSn : ∀ m : ℕ, ‖S ^ m‖ ≤ 1 := by
    intro m
    induction m with
    | zero => simpa using h1
    | succ m ih =>
      rw [pow_succ]
      calc ‖S ^ m * S‖ ≤ ‖S ^ m‖ * ‖S‖ := norm_mul_le _ _
        _ ≤ 1 * 1 := by gcongr
        _ = 1 := by ring
  induction n with
  | zero => simp
  | succ n ih =>
    have e : T ^ (n + 1) - S ^ (n + 1) = T * (T ^ n - S ^ n) + (T - S) * S ^ n := by
      rw [pow_succ', pow_succ']
      noncomm_ring
    rw [e]
    calc ‖T * (T ^ n - S ^ n) + (T - S) * S ^ n‖
        ≤ ‖T‖ * ‖T ^ n - S ^ n‖ + ‖T - S‖ * ‖S ^ n‖ := by
          refine (norm_add_le _ _).trans ?_
          gcongr <;> exact norm_mul_le _ _
      _ ≤ 1 * (n * ‖T - S‖) + ‖T - S‖ * 1 := by
          gcongr
          exact hSn n
      _ = ((n + 1 : ℕ) : ℝ) * ‖T - S‖ := by push_cast; ring

end helpers

#print axioms trotter_aux_comm
#print axioms trotter_aux_step
#print axioms trotter_aux_exp_nsmul
#print axioms trotter_aux_pow


variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [CompleteSpace E]

theorem trotter_aux_error (A B : E →L[ℝ] E)
    (hA : ∀ s : ℝ, 0 ≤ s → ‖exp (s • A)‖ ≤ 1)
    (hB : ∀ s : ℝ, 0 ≤ s → ‖exp (s • B)‖ ≤ 1)
    (hAB : ∀ s : ℝ, 0 ≤ s → ‖exp (s • (A + B))‖ ≤ 1)
    (t : ℝ) (ht : 0 ≤ t) (n : ℕ) (hn : 0 < n) :
    ‖exp (t • (A + B)) - (exp ((t / n) • B) * exp ((t / n) • A)) ^ n‖ ≤
      t ^ 2 / (2 * n) * ‖A * B - B * A‖ := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  set h : ℝ := t / n with hh
  have h0 : 0 ≤ h := div_nonneg ht hn'.le
  have hT : exp (t • (A + B)) = exp (h • (A + B)) ^ n := by
    rw [← trotter_aux_exp_nsmul, ← Nat.cast_smul_eq_nsmul ℝ, smul_smul]
    congr 2
    rw [hh]
    field_simp
  rw [hT]
  have hS : ‖exp (h • B) * exp (h • A)‖ ≤ 1 := by
    calc ‖exp (h • B) * exp (h • A)‖ ≤ ‖exp (h • B)‖ * ‖exp (h • A)‖ := norm_mul_le _ _
      _ ≤ 1 * 1 := by gcongr; exacts [hB h h0, hA h h0]
      _ = 1 := by ring
  have hpow := trotter_aux_pow _ _ ContinuousLinearMap.norm_id_le hS (hAB h h0) n
  have hstep := trotter_aux_step A B hA hB hAB h h0
  calc ‖exp (h • (A + B)) ^ n - (exp (h • B) * exp (h • A)) ^ n‖
      ≤ n * ‖exp (h • (A + B)) - exp (h • B) * exp (h • A)‖ := hpow
    _ ≤ n * (h ^ 2 / 2 * ‖A * B - B * A‖) := by gcongr
    _ = t ^ 2 / (2 * n) * ‖A * B - B * A‖ := by
        rw [hh]
        field_simp

#print axioms trotter_aux_error

/-- Trotter's product formula: if the evolutions of `A`, of `B` and of `A + B` never increase
size, then for every starting state `u₀` and time `t ≥ 0`, `n` alternating steps of length `t / n`
(first `A`, then `B`) converge, as `n → ∞`, to the combined evolution `e^{t(A+B)} u₀`. -/
theorem trotter_product_formula (A B : E →L[ℝ] E)
    (hA : ∀ s : ℝ, 0 ≤ s → ‖exp (s • A)‖ ≤ 1)
    (hB : ∀ s : ℝ, 0 ≤ s → ‖exp (s • B)‖ ≤ 1)
    (hAB : ∀ s : ℝ, 0 ≤ s → ‖exp (s • (A + B))‖ ≤ 1)
    (t : ℝ) (ht : 0 ≤ t) (u₀ : E) :
    Tendsto (fun n : ℕ => ((exp ((t / n) • B) * exp ((t / n) • A)) ^ n) u₀)
      atTop (𝓝 (exp (t • (A + B)) u₀)) := by
  have hlim : Tendsto (fun n : ℕ => (t ^ 2 / 2 * ‖A * B - B * A‖ * ‖u₀‖) / (n : ℝ)) atTop
      (𝓝 0) := tendsto_const_div_atTop_nhds_zero_nat _
  rw [tendsto_iff_norm_sub_tendsto_zero]
  refine squeeze_zero' (Eventually.of_forall fun n => norm_nonneg _) ?_ hlim
  filter_upwards [eventually_gt_atTop 0] with n hn
  have hb := trotter_aux_error A B hA hB hAB t ht n hn
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  calc ‖((exp ((t / n) • B) * exp ((t / n) • A)) ^ n) u₀ - (exp (t • (A + B))) u₀‖
      = ‖(exp (t • (A + B)) - (exp ((t / n) • B) * exp ((t / n) • A)) ^ n) u₀‖ := by
        rw [norm_sub_rev]; rfl
    _ ≤ ‖exp (t • (A + B)) - (exp ((t / n) • B) * exp ((t / n) • A)) ^ n‖ * ‖u₀‖ :=
        ContinuousLinearMap.le_opNorm _ _
    _ ≤ t ^ 2 / (2 * n) * ‖A * B - B * A‖ * ‖u₀‖ := by gcongr
    _ = (t ^ 2 / 2 * ‖A * B - B * A‖ * ‖u₀‖) / (n : ℝ) := by
        field_simp

/-- The splitting error bound: if the evolutions of `A`, of `B` and of `A + B` never increase
size, then `n` split steps over total time `t ≥ 0` miss the true evolution by at most the square
of the time, over twice the number of steps, times the size of the commutator `[A, B]`. -/
theorem trotter_error_le_commutator (A B : E →L[ℝ] E)
    (hA : ∀ s : ℝ, 0 ≤ s → ‖exp (s • A)‖ ≤ 1)
    (hB : ∀ s : ℝ, 0 ≤ s → ‖exp (s • B)‖ ≤ 1)
    (hAB : ∀ s : ℝ, 0 ≤ s → ‖exp (s • (A + B))‖ ≤ 1)
    (t : ℝ) (ht : 0 ≤ t) (n : ℕ) (hn : 0 < n) :
    ‖exp (t • (A + B)) - (exp ((t / n) • B) * exp ((t / n) • A)) ^ n‖ ≤
      t ^ 2 / (2 * n) * ‖A * B - B * A‖ := by
  exact trotter_aux_error A B hA hB hAB t ht n hn

/-- The river's drift: `A u = -(c u)'` with water speed `c(x) = c₀ + β x`. -/
noncomputable def riverDrift (c₀ β : ℝ) (u : ℝ → ℝ) : ℝ → ℝ :=
  fun x => -deriv (fun y => (c₀ + β * y) * u y) x

/-- The river's spreading: `B u = κ u''`. -/
noncomputable def riverSpread (κ : ℝ) (u : ℝ → ℝ) : ℝ → ℝ :=
  fun x => κ * iteratedDeriv 2 u x

/-- The river's commutator: for a load `u` with three continuous derivatives, drift with speed
`c(x) = c₀ + β x` and spreading with coefficient `κ` satisfy `[A, B] u = 2 β κ u'' = 2 β (B u)`;
with `β = 0` the parts commute. -/
theorem river_commutator_eq_two_beta_spread (c₀ β κ : ℝ) (u : ℝ → ℝ) (hu : ContDiff ℝ 3 u)
    (x : ℝ) :
    riverDrift c₀ β (riverSpread κ u) x - riverSpread κ (riverDrift c₀ β u) x =
      2 * β * riverSpread κ u x := by
  have hd0 : ∀ y, HasDerivAt u (deriv u y) y := fun y =>
    ((hu.differentiable (by norm_num)) y).hasDerivAt
  have hd1' : Differentiable ℝ (deriv u) := by
    have := hu.differentiable_iteratedDeriv 1 (by norm_num)
    simpa [iteratedDeriv_eq_iterate] using this
  have hd2' : Differentiable ℝ (deriv (deriv u)) := by
    have := hu.differentiable_iteratedDeriv 2 (by norm_num)
    simpa [iteratedDeriv_eq_iterate] using this
  have hd1 : ∀ y, HasDerivAt (deriv u) (deriv (deriv u) y) y := fun y => (hd1' y).hasDerivAt
  have hd2 : ∀ y, HasDerivAt (deriv (deriv u)) (deriv (deriv (deriv u)) y) y :=
    fun y => (hd2' y).hasDerivAt
  have hc : ∀ y : ℝ, HasDerivAt (fun y => c₀ + β * y) β y := by
    intro y
    simpa using ((hasDerivAt_id y).const_mul β).const_add c₀
  set u1 := deriv u
  set u2 := deriv u1
  set u3 := deriv u2
  have hit2 : ∀ g : ℝ → ℝ, iteratedDeriv 2 g = deriv (deriv g) := by
    intro g
    simp [iteratedDeriv_eq_iterate]
  -- the spread of `u`
  have hS : riverSpread κ u = fun y => κ * u2 y := by
    funext y
    simp [riverSpread, hit2, u2, u1]
  -- first term: drift of the spread
  have t1 : riverDrift c₀ β (riverSpread κ u) x =
      -(β * (κ * u2 x) + (c₀ + β * x) * (κ * u3 x)) := by
    rw [hS, riverDrift]
    have : HasDerivAt (fun y => (c₀ + β * y) * (κ * u2 y))
        (β * (κ * u2 x) + (c₀ + β * x) * (κ * u3 x)) x := (hc x).mul ((hd2 x).const_mul κ)
    rw [this.deriv]
  -- the drift of `u`
  have hD : riverDrift c₀ β u = fun y => -(β * u y + (c₀ + β * y) * u1 y) := by
    funext y
    have : HasDerivAt (fun y => (c₀ + β * y) * u y) (β * u y + (c₀ + β * y) * u1 y) y :=
      (hc y).mul (hd0 y)
    rw [riverDrift, this.deriv]
  have hD1 : deriv (riverDrift c₀ β u) =
      fun y => -(β * u1 y + (β * u1 y + (c₀ + β * y) * u2 y)) := by
    funext y
    rw [hD]
    have : HasDerivAt (fun y => -(β * u y + (c₀ + β * y) * u1 y))
        (-(β * u1 y + (β * u1 y + (c₀ + β * y) * u2 y))) y :=
      (((hd0 y).const_mul β).add ((hc y).mul (hd1 y))).neg
    rw [this.deriv]
  have hD2 : deriv (deriv (riverDrift c₀ β u)) x =
      -(β * u2 x + (β * u2 x + (β * u2 x + (c₀ + β * x) * u3 x))) := by
    rw [hD1]
    have : HasDerivAt (fun y => -(β * u1 y + (β * u1 y + (c₀ + β * y) * u2 y)))
        (-(β * u2 x + (β * u2 x + (β * u2 x + (c₀ + β * x) * u3 x)))) x :=
      (((hd1 x).const_mul β).add (((hd1 x).const_mul β).add ((hc x).mul (hd2 x)))).neg
    rw [this.deriv]
  have t2 : riverSpread κ (riverDrift c₀ β u) x =
      κ * -(β * u2 x + (β * u2 x + (β * u2 x + (c₀ + β * x) * u3 x))) := by
    rw [riverSpread, hit2, hD2]
  rw [t1, t2, hS]
  ring

-- Worked numbers: starting squared width 200² m², and the spread step 2κΔt in m².
example : (200 : ℕ) ^ 2 = 40000 := by norm_num
example : 2 * 20 * 600 = (24000 : ℕ) := by norm_num
-- One hour in six steps of 600 s.
example : (3600 : ℕ) / 6 = 600 := by norm_num
-- With c₀ = 1/2 m/s, β = 1/10000 per s, κ = 20 m²/s, Δt = 600 s:
-- c₀/β = 5000 m, κ/β = 200000 m², βΔt = 0.06, and 2βκ = 0.004 (the commutator column × h²).
example : (1 / 2 : ℚ) / (1 / 10000) = 5000 := by norm_num
example : (20 : ℚ) / (1 / 10000) = 200000 := by norm_num
example : (1 / 10000 : ℚ) * 600 = 3 / 50 := by norm_num
example : 2 * (1 / 10000 : ℚ) * 20 = 1 / 250 := by norm_num

#print axioms trotter_product_formula
#print axioms trotter_error_le_commutator
#print axioms river_commutator_eq_two_beta_spread
