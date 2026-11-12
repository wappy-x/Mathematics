-- Trace and determinant: for a two-variable linear system x' = Ax, the eigenvalues add to the trace and multiply to the determinant, their signs follow from those two numbers, and off the line det = 0 the equilibrium is a saddle (unstable) when det < 0, attracting when det > 0 and trace < 0, repelling when det > 0 and trace > 0, and a centre (stable but not asymptotically stable) when det > 0 and trace = 0.
import Mathlib.LinearAlgebra.Matrix.Charpoly.Coeff
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Complex.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Linarith

open Filter Topology Matrix Polynomial

/-! ### How the card's objects are written here

The state is a pair of real numbers, `Fin 2 → ℝ`, and the rule is a constant real 2 × 2 matrix
`A = !![a, b; c, d]`. Its trace `A.trace` is `a + d` and its determinant `A.det` is `ad - bc`.
Distances use the plane's usual sup length `‖x‖ = max |x 0| |x 1|`; any other length gives the
same verdicts.

A solution of `x' = A x` is a path `x : ℝ → (Fin 2 → ℝ)` whose rate at every time `t` is
`A` times its state, `A *ᵥ x t`. The equilibrium is the rest state `0`.

The eigenvalues are the two complex roots `l1`, `l2` of the characteristic polynomial
`det (X·I - A)`, written as the factorisation `(X - l1)(X - l2)` over `ℂ`. -/

/-- `x` solves `x' = A x`: at every time `t` its rate is `A` times its state. -/
def SolvesLinear (A : Matrix (Fin 2) (Fin 2) ℝ) (x : ℝ → Fin 2 → ℝ) : Prop :=
  ∀ t : ℝ, HasDerivAt x (A *ᵥ x t) t

/-- Stable: starts close enough to rest stay within any chosen distance for all later time. -/
def EquilibriumStable (A : Matrix (Fin 2) (Fin 2) ℝ) : Prop :=
  ∀ ε > 0, ∃ δ > 0, ∀ x : ℝ → Fin 2 → ℝ, SolvesLinear A x → ‖x 0‖ < δ →
    ∀ t ≥ 0, ‖x t‖ < ε

/-- Asymptotically stable: stable, and starts close enough also return to rest in the long run. -/
def EquilibriumAsymptoticallyStable (A : Matrix (Fin 2) (Fin 2) ℝ) : Prop :=
  EquilibriumStable A ∧
    ∃ δ > 0, ∀ x : ℝ → Fin 2 → ℝ, SolvesLinear A x → ‖x 0‖ < δ → Tendsto x atTop (𝓝 0)

/-- Unstable: some starts, however close to rest, get carried a fixed distance away. -/
def EquilibriumUnstable (A : Matrix (Fin 2) (Fin 2) ℝ) : Prop :=
  ∃ ε > 0, ∀ δ > 0, ∃ x : ℝ → Fin 2 → ℝ, SolvesLinear A x ∧ ‖x 0‖ < δ ∧
    ∃ t ≥ 0, ε ≤ ‖x t‖

lemma solves_coord {A : Matrix (Fin 2) (Fin 2) ℝ} {x : ℝ → Fin 2 → ℝ} (hx : SolvesLinear A x)
    (t : ℝ) :
    HasDerivAt (fun s => x s 0) (A 0 0 * x t 0 + A 0 1 * x t 1) t ∧
      HasDerivAt (fun s => x s 1) (A 1 0 * x t 0 + A 1 1 * x t 1) t := by
  have h := hasDerivAt_pi.1 (hx t)
  exact ⟨by simpa [Matrix.mulVec, dotProduct, Fin.sum_univ_two] using h 0,
    by simpa [Matrix.mulVec, dotProduct, Fin.sum_univ_two] using h 1⟩

lemma solves_of_coord {A : Matrix (Fin 2) (Fin 2) ℝ} {x : ℝ → Fin 2 → ℝ}
    (h0 : ∀ t, HasDerivAt (fun s => x s 0) (A 0 0 * x t 0 + A 0 1 * x t 1) t)
    (h1 : ∀ t, HasDerivAt (fun s => x s 1) (A 1 0 * x t 0 + A 1 1 * x t 1) t) :
    SolvesLinear A x := by
  intro t
  rw [hasDerivAt_pi]
  intro i
  fin_cases i
  · simpa [Matrix.mulVec, dotProduct, Fin.sum_univ_two] using h0 t
  · simpa [Matrix.mulVec, dotProduct, Fin.sum_univ_two] using h1 t

lemma lyap_hasDerivAt {A : Matrix (Fin 2) (Fin 2) ℝ} {x : ℝ → Fin 2 → ℝ} (hx : SolvesLinear A x)
    (t : ℝ) :
    HasDerivAt (fun s => A.det * (x s 0 ^ 2 + x s 1 ^ 2) + (A 0 0 * x s 0 + A 0 1 * x s 1) ^ 2
        + (A 1 0 * x s 0 + A 1 1 * x s 1) ^ 2)
      (2 * A.trace * ((A 0 0 * x t 0 + A 0 1 * x t 1) ^ 2
        + (A 1 0 * x t 0 + A 1 1 * x t 1) ^ 2)) t := by
  obtain ⟨hu, hw⟩ := solves_coord hx t
  have h := ((((hu.pow 2).add (hw.pow 2)).const_mul A.det).add
    (((hu.const_mul (A 0 0)).add (hw.const_mul (A 0 1))).pow 2)).add
    (((hu.const_mul (A 1 0)).add (hw.const_mul (A 1 1))).pow 2)
  convert h using 1
  rw [trace_fin_two, det_fin_two]
  norm_num
  ring

lemma ysq_le (a b c d u w : ℝ) :
    (a * u + b * w) ^ 2 + (c * u + d * w) ^ 2 ≤
      (a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2) * (u ^ 2 + w ^ 2) := by
  nlinarith [sq_nonneg (a * w - b * u), sq_nonneg (c * w - d * u)]

lemma det_sq_le (a b c d u w : ℝ) :
    (a * d - b * c) ^ 2 * (u ^ 2 + w ^ 2) ≤
      (a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2) * ((a * u + b * w) ^ 2 + (c * u + d * w) ^ 2) := by
  nlinarith [sq_nonneg (b * (a * u + b * w) + d * (c * u + d * w)),
    sq_nonneg (a * (a * u + b * w) + c * (c * u + d * w))]

lemma sq_add_sq_le_norm (v : Fin 2 → ℝ) : v 0 ^ 2 + v 1 ^ 2 ≤ 2 * ‖v‖ ^ 2 := by
  have h0 : |v 0| ≤ ‖v‖ := by simpa using norm_le_pi_norm v 0
  have h1 : |v 1| ≤ ‖v‖ := by simpa using norm_le_pi_norm v 1
  have e0 : v 0 ^ 2 ≤ ‖v‖ ^ 2 := by rw [← sq_abs]; exact pow_le_pow_left₀ (abs_nonneg _) h0 2
  have e1 : v 1 ^ 2 ≤ ‖v‖ ^ 2 := by rw [← sq_abs]; exact pow_le_pow_left₀ (abs_nonneg _) h1 2
  linarith

lemma norm_lt_of_sq {v : Fin 2 → ℝ} {ε : ℝ} (hε : 0 < ε) (h : v 0 ^ 2 + v 1 ^ 2 < ε ^ 2) :
    ‖v‖ < ε := by
  rw [pi_norm_lt_iff hε]
  intro i
  rw [Real.norm_eq_abs]
  apply abs_lt_of_sq_lt_sq _ hε.le
  fin_cases i <;> simp <;> nlinarith [sq_nonneg (v 0), sq_nonneg (v 1)]

lemma stable_of {A : Matrix (Fin 2) (Fin 2) ℝ} (hΔ : 0 < A.det) (hτ : A.trace ≤ 0) :
    EquilibriumStable A := by
  intro ε hε
  obtain ⟨M, hM⟩ : ∃ M, M = A 0 0 ^ 2 + A 0 1 ^ 2 + A 1 0 ^ 2 + A 1 1 ^ 2 := ⟨_, rfl⟩
  have hM0 : 0 ≤ M := by rw [hM]; positivity
  obtain ⟨K, hK⟩ : ∃ K, K = 2 * (A.det + M) / A.det := ⟨_, rfl⟩
  have hK0 : 0 ≤ K := by rw [hK]; positivity
  have hKΔ : K * A.det = 2 * (A.det + M) := by rw [hK]; field_simp
  refine ⟨ε / (K + 1), by positivity, fun x hx h0 t ht => ?_⟩
  have hanti := antitone_of_hasDerivAt_nonpos (lyap_hasDerivAt hx) (fun s => by
    have : 0 ≤ (A 0 0 * x s 0 + A 0 1 * x s 1) ^ 2 + (A 1 0 * x s 0 + A 1 1 * x s 1) ^ 2 := by
      positivity
    show 2 * A.trace * _ ≤ 0
    nlinarith)
  have hVt := hanti ht
  simp only at hVt
  have hY := ysq_le (A 0 0) (A 0 1) (A 1 0) (A 1 1) (x 0 0) (x 0 1)
  rw [← hM] at hY
  have hn := sq_add_sq_le_norm (x 0)
  have hn' := mul_le_mul_of_nonneg_left hn (by positivity : 0 ≤ A.det + M)
  have hYt : 0 ≤ (A 0 0 * x t 0 + A 0 1 * x t 1) ^ 2 + (A 1 0 * x t 0 + A 1 1 * x t 1) ^ 2 := by
    positivity
  have e : A.det * (K * ‖x 0‖ ^ 2) = 2 * (A.det + M) * ‖x 0‖ ^ 2 := by
    rw [← hKΔ]; ring
  have h1 : A.det * (x t 0 ^ 2 + x t 1 ^ 2) ≤ A.det * (K * ‖x 0‖ ^ 2) := by
    nlinarith
  have h2 : x t 0 ^ 2 + x t 1 ^ 2 ≤ K * ‖x 0‖ ^ 2 := le_of_mul_le_mul_left h1 hΔ
  apply norm_lt_of_sq hε
  have hδ : 0 < K + 1 := by linarith
  have hx0 : ‖x 0‖ ^ 2 < (ε / (K + 1)) ^ 2 := by
    have := norm_nonneg (x 0)
    exact pow_lt_pow_left₀ h0 this (by norm_num)
  have h3 : K * (ε / (K + 1)) ^ 2 < ε ^ 2 := by
    rw [div_pow, mul_div_assoc', div_lt_iff₀ (by positivity)]
    have : 0 < ε ^ 2 * (K ^ 2 + K + 1) := by positivity
    nlinarith
  nlinarith

lemma asymp_of {A : Matrix (Fin 2) (Fin 2) ℝ} (hΔ : 0 < A.det) (hτ : A.trace < 0) :
    EquilibriumAsymptoticallyStable A := by
  refine ⟨stable_of hΔ hτ.le, 1, one_pos, fun x hx _ => ?_⟩
  obtain ⟨M, hM⟩ : ∃ M, M = A 0 0 ^ 2 + A 0 1 ^ 2 + A 1 0 ^ 2 + A 1 1 ^ 2 := ⟨_, rfl⟩
  have hM0 : 0 ≤ M := by rw [hM]; positivity
  obtain ⟨κ, hκ⟩ : ∃ κ, κ = -2 * A.trace * A.det / (M + A.det) := ⟨_, rfl⟩
  have hκ0 : 0 < κ := by
    rw [hκ]; apply div_pos
    · nlinarith
    · linarith
  have hκM : κ * (M + A.det) = -2 * A.trace * A.det := by
    rw [hκ]; field_simp
  have hW : ∀ s, HasDerivAt
      (fun s => (A.det * (x s 0 ^ 2 + x s 1 ^ 2) + (A 0 0 * x s 0 + A 0 1 * x s 1) ^ 2
        + (A 1 0 * x s 0 + A 1 1 * x s 1) ^ 2) * Real.exp (κ * s))
      ((2 * A.trace * ((A 0 0 * x s 0 + A 0 1 * x s 1) ^ 2
        + (A 1 0 * x s 0 + A 1 1 * x s 1) ^ 2)) * Real.exp (κ * s) +
        (A.det * (x s 0 ^ 2 + x s 1 ^ 2) + (A 0 0 * x s 0 + A 0 1 * x s 1) ^ 2
        + (A 1 0 * x s 0 + A 1 1 * x s 1) ^ 2) * (Real.exp (κ * s) * (κ * 1))) s := fun s =>
    (lyap_hasDerivAt hx s).mul (((hasDerivAt_id' s).const_mul κ).exp)
  have hanti := antitone_of_hasDerivAt_nonpos hW (fun s => by
    have hdet := det_sq_le (A 0 0) (A 0 1) (A 1 0) (A 1 1) (x s 0) (x s 1)
    rw [← hM, ← det_fin_two] at hdet
    have key : A.det * (A.det * (x s 0 ^ 2 + x s 1 ^ 2) + ((A 0 0 * x s 0 + A 0 1 * x s 1) ^ 2
        + (A 1 0 * x s 0 + A 1 1 * x s 1) ^ 2)) ≤ (M + A.det) * ((A 0 0 * x s 0 + A 0 1 * x s 1) ^ 2
        + (A 1 0 * x s 0 + A 1 1 * x s 1) ^ 2) := by nlinarith
    have h3 : κ * (A.det * (x s 0 ^ 2 + x s 1 ^ 2) + ((A 0 0 * x s 0 + A 0 1 * x s 1) ^ 2
        + (A 1 0 * x s 0 + A 1 1 * x s 1) ^ 2)) * (M + A.det) ≤ (-2 * A.trace *
        ((A 0 0 * x s 0 + A 0 1 * x s 1) ^ 2 + (A 1 0 * x s 0 + A 1 1 * x s 1) ^ 2)) *
        (M + A.det) := by
      have := mul_le_mul_of_nonneg_left key (by linarith : (0 : ℝ) ≤ -2 * A.trace)
      linear_combination this + (A.det * (x s 0 ^ 2 + x s 1 ^ 2) + ((A 0 0 * x s 0 + A 0 1 * x s 1) ^ 2
        + (A 1 0 * x s 0 + A 1 1 * x s 1) ^ 2)) * hκM
    have h4 := le_of_mul_le_mul_right h3 (by linarith)
    have he := Real.exp_pos (κ * s)
    show _ ≤ 0
    nlinarith)
  -- bound for t ≥ 0
  set V0 := A.det * (x 0 0 ^ 2 + x 0 1 ^ 2) + (A 0 0 * x 0 0 + A 0 1 * x 0 1) ^ 2
        + (A 1 0 * x 0 0 + A 1 1 * x 0 1) ^ 2 with hV0
  have hbound : ∀ t ≥ 0, ∀ i, x t i ^ 2 ≤ V0 / A.det * Real.exp (-(κ * t)) := by
    intro t ht i
    have h := hanti ht
    simp only [mul_zero, Real.exp_zero, mul_one] at h
    have he := Real.exp_pos (κ * t)
    have hY : 0 ≤ (A 0 0 * x t 0 + A 0 1 * x t 1) ^ 2 + (A 1 0 * x t 0 + A 1 1 * x t 1) ^ 2 := by
      positivity
    have hxi : x t i ^ 2 ≤ x t 0 ^ 2 + x t 1 ^ 2 := by
      fin_cases i <;> simp <;> nlinarith [sq_nonneg (x t 0), sq_nonneg (x t 1)]
    rw [Real.exp_neg, div_mul_eq_mul_div, le_div_iff₀ hΔ, ← div_eq_mul_inv, le_div_iff₀ he]
    nlinarith [mul_le_mul_of_nonneg_right hxi (le_of_lt (mul_pos hΔ he))]
  have hlim : Tendsto (fun t => Real.sqrt (V0 / A.det * Real.exp (-(κ * t)))) atTop (𝓝 0) := by
    have h1 : Tendsto (fun t => Real.exp (-(κ * t))) atTop (𝓝 0) :=
      Real.tendsto_exp_neg_atTop_nhds_zero.comp (tendsto_id.const_mul_atTop hκ0)
    have h2 := (h1.const_mul (V0 / A.det)).sqrt
    simpa using h2
  rw [tendsto_pi_nhds]
  intro i
  apply squeeze_zero_norm' _ hlim
  filter_upwards [eventually_ge_atTop 0] with t ht
  rw [Real.norm_eq_abs]
  exact Real.abs_le_sqrt (hbound t ht i)

lemma unstable_of_unbounded {A : Matrix (Fin 2) (Fin 2) ℝ} (y : ℝ → Fin 2 → ℝ)
    (hy : SolvesLinear A y) (i : Fin 2) (hunb : ∀ M : ℝ, ∃ t ≥ 0, M ≤ |y t i|) :
    EquilibriumUnstable A := by
  refine ⟨1, one_pos, fun δ hδ => ?_⟩
  obtain ⟨c, hc⟩ : ∃ c, c = δ / (‖y 0‖ + 1) := ⟨_, rfl⟩
  have hc0 : 0 < c := by rw [hc]; positivity
  obtain ⟨t, ht, hM⟩ := hunb (1 / c)
  refine ⟨fun s => c • y s, fun s => ?_, ?_, t, ht, ?_⟩
  · have := (hy s).const_smul c
    rw [Matrix.mulVec_smul]; exact this
  · show ‖c • y 0‖ < δ
    rw [norm_smul, Real.norm_eq_abs, abs_of_pos hc0, hc,
      div_mul_eq_mul_div, div_lt_iff₀ (by positivity)]
    nlinarith [norm_nonneg (y 0)]
  · show 1 ≤ ‖c • y t‖
    calc (1 : ℝ) = c * (1 / c) := by field_simp
      _ ≤ c * |y t i| := mul_le_mul_of_nonneg_left hM hc0.le
      _ = ‖(c • y t) i‖ := by simp [abs_of_pos hc0]
      _ ≤ ‖c • y t‖ := norm_le_pi_norm _ i

lemma unstable_of_eig {A : Matrix (Fin 2) (Fin 2) ℝ} (r w0 w1 : ℝ) (hr : 0 < r)
    (hw : w0 ≠ 0 ∨ w1 ≠ 0)
    (h0 : A 0 0 * w0 + A 0 1 * w1 = r * w0) (h1 : A 1 0 * w0 + A 1 1 * w1 = r * w1) :
    EquilibriumUnstable A := by
  have hsol : SolvesLinear A (fun t => ![Real.exp (r * t) * w0, Real.exp (r * t) * w1]) := by
    apply solves_of_coord
    · intro t
      have := (((hasDerivAt_id' t).const_mul r).exp).mul_const w0
      simp only [Matrix.cons_val_zero, Matrix.cons_val_one]
      convert this using 1
      linear_combination Real.exp (r * t) * h0
    · intro t
      have := (((hasDerivAt_id' t).const_mul r).exp).mul_const w1
      simp only [Matrix.cons_val_zero, Matrix.cons_val_one]
      convert this using 1
      linear_combination Real.exp (r * t) * h1
  have key : ∀ w : ℝ, w ≠ 0 → ∀ M : ℝ, ∃ t ≥ 0, M ≤ |Real.exp (r * t) * w| := by
    intro w hw M
    have hwpos : 0 < |w| := abs_pos.2 hw
    refine ⟨|M| / (r * |w|), by positivity, ?_⟩
    have := Real.add_one_le_exp (r * (|M| / (r * |w|)))
    rw [abs_mul, abs_of_pos (Real.exp_pos _)]
    have e : r * (|M| / (r * |w|)) * |w| = |M| := by field_simp
    nlinarith [le_abs_self M, abs_nonneg M]
  rcases hw with hw | hw
  · exact unstable_of_unbounded _ hsol 0 (by simpa using key w0 hw)
  · exact unstable_of_unbounded _ hsol 1 (by simpa using key w1 hw)

lemma spiral_solves {A : Matrix (Fin 2) (Fin 2) ℝ} (p q v0 v1 : ℝ) (hp : 2 * p = A.trace)
    (hq2 : q ^ 2 = A.det - p ^ 2) :
    SolvesLinear A (fun t => ![Real.exp (p * t) * (q * v0 * Real.cos (q * t)
        + Real.sin (q * t) * ((A 0 0 - p) * v0 + A 0 1 * v1)),
      Real.exp (p * t) * (q * v1 * Real.cos (q * t)
        + Real.sin (q * t) * (A 1 0 * v0 + (A 1 1 - p) * v1))]) := by
  rw [trace_fin_two] at hp
  rw [det_fin_two] at hq2
  apply solves_of_coord
  · intro t
    have := (((hasDerivAt_id' t).const_mul p).exp).mul
      (((((hasDerivAt_id' t).const_mul q).cos).const_mul (q * v0)).add
        ((((hasDerivAt_id' t).const_mul q).sin).mul_const ((A 0 0 - p) * v0 + A 0 1 * v1)))
    simp only [Matrix.cons_val_zero, Matrix.cons_val_one]
    convert this using 1
    simp only [Pi.add_apply]
    linear_combination (-(Real.exp (p * t) * Real.sin (q * t))) *
      ((A 0 0 * v0 + A 0 1 * v1) * hp - v0 * hq2)
  · intro t
    have := (((hasDerivAt_id' t).const_mul p).exp).mul
      (((((hasDerivAt_id' t).const_mul q).cos).const_mul (q * v1)).add
        ((((hasDerivAt_id' t).const_mul q).sin).mul_const (A 1 0 * v0 + (A 1 1 - p) * v1)))
    simp only [Matrix.cons_val_zero, Matrix.cons_val_one]
    convert this using 1
    simp only [Pi.add_apply]
    linear_combination (-(Real.exp (p * t) * Real.sin (q * t))) *
      ((A 1 0 * v0 + A 1 1 * v1) * hp - v1 * hq2)

lemma unstable_of_spiral {A : Matrix (Fin 2) (Fin 2) ℝ} (p q : ℝ) (hp0 : 0 < p) (hq0 : 0 < q)
    (hp : 2 * p = A.trace) (hq2 : q ^ 2 = A.det - p ^ 2) : EquilibriumUnstable A := by
  refine unstable_of_unbounded _ (spiral_solves p q 1 0 hp hq2) 0 (fun M => ?_)
  obtain ⟨n, hn⟩ : ∃ n : ℕ, n = ⌈|M| / (2 * Real.pi * p)⌉₊ := ⟨_, rfl⟩
  have hn' : |M| / (2 * Real.pi * p) ≤ n := hn ▸ Nat.le_ceil _
  have hpi := Real.pi_pos
  refine ⟨2 * Real.pi * n / q, by positivity, ?_⟩
  have harg : q * (2 * Real.pi * n / q) = n * (2 * Real.pi) := by field_simp
  have hsin : Real.sin (n * (2 * Real.pi)) = 0 := by
    rw [show (n : ℝ) * (2 * Real.pi) = ((2 * n : ℕ) : ℝ) * Real.pi by push_cast; ring]
    exact Real.sin_nat_mul_pi _
  simp only [Matrix.cons_val_zero, harg, Real.cos_nat_mul_two_pi, hsin]
  have hexp := Real.add_one_le_exp (p * (2 * Real.pi * n / q))
  have e : p * (2 * Real.pi * n / q) * q = 2 * Real.pi * p * n := by field_simp
  have hM : |M| ≤ 2 * Real.pi * p * n := by
    rw [div_le_iff₀ (by positivity)] at hn'; linarith
  simp only [mul_one, zero_mul, add_zero]
  rw [abs_of_pos (by positivity)]
  nlinarith [le_abs_self M, abs_nonneg M, Real.exp_pos (p * (2 * Real.pi * n / q))]

lemma not_asymp_of_centre {A : Matrix (Fin 2) (Fin 2) ℝ} (hΔ : 0 < A.det) (hτ : A.trace = 0) :
    ¬ EquilibriumAsymptoticallyStable A := by
  rintro ⟨_, δ, hδ, hAS⟩
  obtain ⟨q, hq⟩ : ∃ q, q = Real.sqrt A.det := ⟨_, rfl⟩
  have hq0 : 0 < q := hq ▸ Real.sqrt_pos.2 hΔ
  have hq2 : q ^ 2 = A.det - 0 ^ 2 := by rw [hq, Real.sq_sqrt hΔ.le]; ring
  have hsol := spiral_solves (A := A) 0 q (δ / (2 * q)) 0 (by rw [hτ]; ring) hq2
  set x := (fun t => ![Real.exp (0 * t) * (q * (δ / (2 * q)) * Real.cos (q * t)
        + Real.sin (q * t) * ((A 0 0 - 0) * (δ / (2 * q)) + A 0 1 * 0)),
      Real.exp (0 * t) * (q * 0 * Real.cos (q * t)
        + Real.sin (q * t) * (A 1 0 * (δ / (2 * q)) + (A 1 1 - 0) * 0))]) with hx
  have hx00 : x 0 0 = δ / 2 := by
    simp [hx]; field_simp
  have hx01 : x 0 1 = 0 := by simp [hx]
  have hx0 : ‖x 0‖ < δ := by
    apply norm_lt_of_sq hδ
    rw [hx00, hx01]; nlinarith
  have hlim := hAS x hsol hx0
  let F : (Fin 2 → ℝ) → ℝ := fun y => A.det * (y 0 ^ 2 + y 1 ^ 2) + (A 0 0 * y 0 + A 0 1 * y 1) ^ 2
    + (A 1 0 * y 0 + A 1 1 * y 1) ^ 2
  have hFc : Continuous F := by fun_prop
  have h1 : Tendsto (fun t => F (x t)) atTop (𝓝 (F 0)) := (hFc.tendsto 0).comp hlim
  have hconst : ∀ t, F (x t) = F (x 0) := by
    have hd : ∀ t, HasDerivAt (fun t => F (x t)) 0 t := by
      intro t
      have := lyap_hasDerivAt hsol t
      rw [hτ] at this
      simpa using this
    intro t
    exact is_const_of_deriv_eq_zero (fun t => (hd t).differentiableAt)
      (fun t => (hd t).deriv) t 0
  have h2 : Tendsto (fun t => F (x t)) atTop (𝓝 (F (x 0))) := by
    simp only [hconst]; exact tendsto_const_nhds
  have heq := tendsto_nhds_unique h2 h1
  have hpos : 0 < F (x 0) := by
    simp only [F, hx00, hx01]
    have : 0 < A.det * ((δ / 2) ^ 2 + 0 ^ 2) := by positivity
    nlinarith [sq_nonneg (A 0 0 * (δ / 2) + A 0 1 * 0), sq_nonneg (A 1 0 * (δ / 2) + A 1 1 * 0)]
  have hF0 : F 0 = 0 := by simp [F]
  rw [hF0] at heq
  linarith

lemma unstable_of_real_roots {A : Matrix (Fin 2) (Fin 2) ℝ} (r1 r2 : ℝ) (hr1 : 0 < r1)
    (hsum : r1 + r2 = A.trace) (hprod : r1 * r2 = A.det)
    (hnot : ¬ (A 0 0 = r2 ∧ A 1 0 = 0 ∧ A 0 1 = 0 ∧ A 1 1 = r2)) : EquilibriumUnstable A := by
  rw [trace_fin_two] at hsum
  rw [det_fin_two] at hprod
  by_cases h : A 0 0 - r2 ≠ 0 ∨ A 1 0 ≠ 0
  · refine unstable_of_eig r1 (A 0 0 - r2) (A 1 0) hr1 h ?_ ?_
    · linear_combination (-(A 0 0)) * hsum + hprod
    · linear_combination (-(A 1 0)) * hsum
  · push Not at h
    by_cases h' : A 0 1 ≠ 0 ∨ A 1 1 - r2 ≠ 0
    · refine unstable_of_eig r1 (A 0 1) (A 1 1 - r2) hr1 h' ?_ ?_
      · linear_combination (-(A 0 1)) * hsum
      · linear_combination (-(A 1 1)) * hsum + hprod
    · push Not at h'
      exact absurd ⟨by linarith [h.1], h.2, h'.1, by linarith [h'.2]⟩ hnot

lemma vieta_two (A : Matrix (Fin 2) (Fin 2) ℝ) (l1 l2 : ℂ)
    (h : A.charpoly.map (algebraMap ℝ ℂ) = (X - C l1) * (X - C l2)) :
    l1 + l2 = (A.trace : ℂ) ∧ l1 * l2 = (A.det : ℂ) := by
  rw [charpoly_fin_two] at h
  have e : (X - C l1) * (X - C l2) = X ^ 2 - C (l1 + l2) * X + C (l1 * l2) := by
    rw [C_add, C_mul]; ring
  rw [e] at h
  have h0 := congrArg (coeff · 0) h
  have h1 := congrArg (coeff · 1) h
  simp [coeff_X, coeff_C] at h0 h1
  exact ⟨by linear_combination h1, h0.symm⟩

/-- The card's main claim, the trace-determinant chart. For a two-variable system `x' = A x` with
constant entries, off the boundary line `Δ = 0`, the trace `τ` and determinant `Δ` of `A` decide
the equilibrium's stability:
* `Δ < 0`: a saddle, unstable;
* `Δ > 0` and `τ < 0`: a stable node or spiral, asymptotically stable;
* `Δ > 0` and `τ > 0`: an unstable node or spiral, unstable;
* `Δ > 0` and `τ = 0`: a centre, stable but not asymptotically stable. -/
theorem trace_and_det_decide_stability (A : Matrix (Fin 2) (Fin 2) ℝ) :
    (A.det < 0 → EquilibriumUnstable A) ∧
      (0 < A.det → A.trace < 0 → EquilibriumAsymptoticallyStable A) ∧
      (0 < A.det → 0 < A.trace → EquilibriumUnstable A) ∧
      (0 < A.det → A.trace = 0 →
        EquilibriumStable A ∧ ¬ EquilibriumAsymptoticallyStable A) := by
  refine ⟨fun hΔ => ?_, fun hΔ hτ => asymp_of hΔ hτ, fun hΔ hτ => ?_,
    fun hΔ hτ => ⟨stable_of hΔ hτ.le, not_asymp_of_centre hΔ hτ⟩⟩
  · have hD : 0 < A.trace ^ 2 - 4 * A.det := by nlinarith [sq_nonneg A.trace]
    obtain ⟨s, hs⟩ : ∃ s, s = Real.sqrt (A.trace ^ 2 - 4 * A.det) := ⟨_, rfl⟩
    have hs2 : s ^ 2 = A.trace ^ 2 - 4 * A.det := by rw [hs, Real.sq_sqrt hD.le]
    have hs0 : 0 ≤ s := hs ▸ Real.sqrt_nonneg _
    have hr1 : 0 < (A.trace + s) / 2 := by nlinarith
    refine unstable_of_real_roots ((A.trace + s) / 2) ((A.trace - s) / 2) hr1 (by ring)
      (by linear_combination (-1 / 4 : ℝ) * hs2) ?_
    rintro ⟨h1, h2, h3, h4⟩
    rw [det_fin_two, h1, h2, h3, h4] at hΔ
    nlinarith [sq_nonneg ((A.trace - s) / 2)]
  · by_cases hD : 0 ≤ A.trace ^ 2 - 4 * A.det
    · obtain ⟨s, hs⟩ : ∃ s, s = Real.sqrt (A.trace ^ 2 - 4 * A.det) := ⟨_, rfl⟩
      have hs2 : s ^ 2 = A.trace ^ 2 - 4 * A.det := by rw [hs, Real.sq_sqrt hD]
      have hs0 : 0 ≤ s := hs ▸ Real.sqrt_nonneg _
      have hr1 : 0 < (A.trace + s) / 2 := by linarith
      have hr2 : 0 < (A.trace - s) / 2 := by nlinarith
      by_cases hn : A 0 0 = (A.trace - s) / 2 ∧ A 1 0 = 0 ∧ A 0 1 = 0 ∧ A 1 1 = (A.trace - s) / 2
      · exact unstable_of_eig ((A.trace - s) / 2) 1 0 hr2 (Or.inl one_ne_zero)
          (by simp [hn.1, hn.2.2.1]) (by simp [hn.2.1])
      · exact unstable_of_real_roots ((A.trace + s) / 2) ((A.trace - s) / 2) hr1 (by ring)
          (by linear_combination (-1 / 4 : ℝ) * hs2) hn
    · push Not at hD
      have hq : 0 < Real.sqrt (4 * A.det - A.trace ^ 2) := Real.sqrt_pos.2 (by linarith)
      exact unstable_of_spiral (A.trace / 2) (Real.sqrt (4 * A.det - A.trace ^ 2) / 2)
        (by linarith) (by positivity) (by ring)
        (by rw [div_pow, Real.sq_sqrt (by linarith)]; ring)

/-- Step 1: the eigenvalue equation is `λ² - τλ + Δ = 0`, and its two roots add to the trace and
multiply to the determinant. -/
theorem eigenvalues_add_to_trace_and_multiply_to_det (A : Matrix (Fin 2) (Fin 2) ℝ) :
    A.charpoly = X ^ 2 - C A.trace * X + C A.det ∧
      ∃ l1 l2 : ℂ, A.charpoly.map (algebraMap ℝ ℂ) = (X - C l1) * (X - C l2) ∧
        l1 + l2 = (A.trace : ℂ) ∧ l1 * l2 = (A.det : ℂ) := by
  refine ⟨charpoly_fin_two A, ?_⟩
  obtain ⟨s, hs⟩ := IsAlgClosed.isSquare ((A.trace : ℂ) ^ 2 - 4 * (A.det : ℂ))
  have h1 : (A.trace + s) / 2 + (A.trace - s) / 2 = (A.trace : ℂ) := by ring
  have h2 : (A.trace + s) / 2 * ((A.trace - s) / 2) = (A.det : ℂ) := by
    linear_combination (1/4 : ℂ) * hs
  refine ⟨(A.trace + s) / 2, (A.trace - s) / 2, ?_, h1, h2⟩
  have e : (X - C ((A.trace + s) / 2)) * (X - C ((A.trace - s) / 2)) =
      X ^ 2 - C ((A.trace + s) / 2 + (A.trace - s) / 2) * X
        + C ((A.trace + s) / 2 * ((A.trace - s) / 2)) := by
    rw [C_add, C_mul]; ring
  rw [e, h1, h2, charpoly_fin_two]
  simp

/-- Step 2: reading the signs. For the eigenvalues `l1`, `l2` of `A`:
* `Δ < 0`: both real, of opposite sign (a saddle);
* `Δ > 0` and `τ² - 4Δ ≥ 0`: both real, both with the sign of `τ` (a node);
* `τ² - 4Δ < 0`: a complex pair `p ± iq` with `p = τ/2` and `q = √(4Δ - τ²)/2` (a spiral, or a
  centre when `τ = 0`). -/
theorem eigenvalue_signs_from_trace_and_det (A : Matrix (Fin 2) (Fin 2) ℝ) (l1 l2 : ℂ)
    (h : A.charpoly.map (algebraMap ℝ ℂ) = (X - C l1) * (X - C l2)) :
    (A.det < 0 → l1.im = 0 ∧ l2.im = 0 ∧ l1.re * l2.re < 0) ∧
      (0 < A.det → 0 ≤ A.trace ^ 2 - 4 * A.det →
        l1.im = 0 ∧ l2.im = 0 ∧
          (A.trace < 0 → l1.re < 0 ∧ l2.re < 0) ∧ (0 < A.trace → 0 < l1.re ∧ 0 < l2.re)) ∧
      (A.trace ^ 2 - 4 * A.det < 0 →
        l1.re = A.trace / 2 ∧ l2.re = A.trace / 2 ∧ l2.im = -l1.im ∧
          |l1.im| = Real.sqrt (4 * A.det - A.trace ^ 2) / 2) := by
  obtain ⟨hs, hp⟩ := vieta_two A l1 l2 h
  have hs' := Complex.ext_iff.1 hs
  have hp' := Complex.ext_iff.1 hp
  simp only [Complex.add_re, Complex.add_im, Complex.mul_re, Complex.mul_im,
    Complex.ofReal_re, Complex.ofReal_im] at hs' hp'
  obtain ⟨sr, si⟩ := hs'
  obtain ⟨pr, pi⟩ := hp'
  set τ := A.trace
  set Δ := A.det
  set a := l1.re
  set b := l1.im
  set c := l2.re
  set e := l2.im
  clear_value a b c e τ Δ
  subst sr pr
  have he : e = -b := by linarith
  subst he
  have key : b * (c - a) = 0 := by linear_combination pi
  refine ⟨fun hΔ => ?_, fun hΔ hD => ?_, fun hD => ?_⟩
  · have hb : b = 0 := by
      rcases mul_eq_zero.1 key with hb | hca
      · exact hb
      · exfalso; have : c = a := by linarith
        subst this; nlinarith [sq_nonneg c, sq_nonneg b]
    subst hb
    refine ⟨rfl, by simp, by nlinarith⟩
  · have hb : b = 0 := by
      rcases mul_eq_zero.1 key with hb | hca
      · exact hb
      · have : c = a := by linarith
        subst this
        by_contra hb
        have : 0 < b ^ 2 := by positivity
        nlinarith
    subst hb
    refine ⟨rfl, by simp, fun ht => ?_, fun ht => ?_⟩
    · have hpr : 0 < a * c := by linarith
      constructor <;> nlinarith
    · have hpr : 0 < a * c := by linarith
      constructor <;> nlinarith
  · have hca : c = a := by
      rcases mul_eq_zero.1 key with hb | hca
      · exfalso; subst hb; nlinarith [sq_nonneg (a - c)]
      · linarith
    subst hca
    have hc : c = (c + c) / 2 := by ring
    refine ⟨hc, hc, rfl, ?_⟩
    have : 4 * (c * c - b * -b) - (c + c) ^ 2 = (2 * |b|) ^ 2 := by
      rw [mul_pow, sq_abs]; ring
    rw [this, Real.sqrt_sq (by positivity)]
    ring

/-! ### The card's worked numbers, checked exactly -/

/-- The rooms `[[-2, 1], [1, -2]]`: trace -4, determinant 3, discriminant 4. -/
example :
    (!![-2, 1; 1, -2] : Matrix (Fin 2) (Fin 2) ℝ).trace = -4 ∧
      (!![-2, 1; 1, -2] : Matrix (Fin 2) (Fin 2) ℝ).det = 3 ∧
      ((-4 : ℝ) ^ 2 - 4 * 3 = 4) := by
  norm_num [Matrix.trace_fin_two_of, Matrix.det_fin_two_of]

/-- The rooms' eigenvalues -1 and -3 add to -4, multiply to 3, and solve `λ² + 4λ + 3 = 0`. -/
example :
    ((-1 : ℝ) + -3 = -4) ∧ ((-1 : ℝ) * -3 = 3) ∧
      ((-1 : ℝ) ^ 2 - (-4) * (-1) + 3 = 0) ∧ ((-3 : ℝ) ^ 2 - (-4) * (-3) + 3 = 0) := by
  norm_num

/-- The shock absorber `[[0, 1], [-5, -2]]`: trace -2, determinant 5, discriminant -16. -/
example :
    (!![0, 1; -5, -2] : Matrix (Fin 2) (Fin 2) ℝ).trace = -2 ∧
      (!![0, 1; -5, -2] : Matrix (Fin 2) (Fin 2) ℝ).det = 5 ∧
      ((-2 : ℝ) ^ 2 - 4 * 5 = -16) := by
  norm_num [Matrix.trace_fin_two_of, Matrix.det_fin_two_of]

/-- The absorber's eigenvalues `-1 ± 2i` solve `λ² + 2λ + 5 = 0`. -/
example :
    ((-1 + 2 * Complex.I) ^ 2 - (-2) * (-1 + 2 * Complex.I) + 5 = 0) ∧
      ((-1 - 2 * Complex.I) ^ 2 - (-2) * (-1 - 2 * Complex.I) + 5 = 0) := by
  constructor <;> ring_nf <;> simp [Complex.I_sq] <;> ring_nf

/-- The spring `[[0, 1], [-1, 0]]`: trace 0, determinant 1, discriminant -4; eigenvalues `±i`. -/
example :
    (!![0, 1; -1, 0] : Matrix (Fin 2) (Fin 2) ℝ).trace = 0 ∧
      (!![0, 1; -1, 0] : Matrix (Fin 2) (Fin 2) ℝ).det = 1 ∧
      ((0 : ℝ) ^ 2 - 4 * 1 = -4) ∧ (Complex.I ^ 2 - 0 * Complex.I + 1 = 0) := by
  norm_num [Matrix.trace_fin_two_of, Matrix.det_fin_two_of]

/-- The broom (saddle) `[[1, 0], [0, -1]]`: trace 0, determinant -1, discriminant 4. -/
example :
    (!![1, 0; 0, -1] : Matrix (Fin 2) (Fin 2) ℝ).trace = 0 ∧
      (!![1, 0; 0, -1] : Matrix (Fin 2) (Fin 2) ℝ).det = -1 ∧
      ((0 : ℝ) ^ 2 - 4 * (-1) = 4) := by
  norm_num [Matrix.trace_fin_two_of, Matrix.det_fin_two_of]

/-- Mistake 1: `[[1, 0], [0, -2]]` has negative trace -1 but determinant -2, a saddle. -/
example :
    (!![1, 0; 0, -2] : Matrix (Fin 2) (Fin 2) ℝ).trace = -1 ∧
      (!![1, 0; 0, -2] : Matrix (Fin 2) (Fin 2) ℝ).det = -2 := by
  norm_num [Matrix.trace_fin_two_of, Matrix.det_fin_two_of]

/-- Mistake 3, the sign slip `λ² + τλ + Δ` on the rooms: `λ² - 4λ + 3` has roots 3 and 1. -/
example : ((3 : ℝ) ^ 2 + (-4) * 3 + 3 = 0) ∧ ((1 : ℝ) ^ 2 + (-4) * 1 + 3 = 0) := by
  norm_num

/-- The boundary case `[[-1, 0], [0, 0]]` has determinant 0. -/
example : (!![-1, 0; 0, 0] : Matrix (Fin 2) (Fin 2) ℝ).det = 0 := by
  norm_num [Matrix.det_fin_two_of]

/-- The figure's points, at 30 px per unit of trace and 24 per unit of determinant from (180, 180):
rooms (60, 108), absorber (120, 60), spring (180, 156), saddle (180, 204). -/
example :
    (180 + 30 * (-4) = (60 : ℤ)) ∧ (180 - 24 * 3 = (108 : ℤ)) ∧
      (180 + 30 * (-2) = (120 : ℤ)) ∧ (180 - 24 * 5 = (60 : ℤ)) ∧
      (180 + 30 * 0 = (180 : ℤ)) ∧ (180 - 24 * 1 = (156 : ℤ)) ∧
      (180 - 24 * (-1) = (204 : ℤ)) := by
  decide

#print axioms trace_and_det_decide_stability
#print axioms eigenvalues_add_to_trace_and_multiply_to_det
#print axioms eigenvalue_signs_from_trace_and_det
#print axioms solves_coord
#print axioms solves_of_coord
#print axioms lyap_hasDerivAt
#print axioms ysq_le
#print axioms det_sq_le
#print axioms sq_add_sq_le_norm
#print axioms norm_lt_of_sq
#print axioms stable_of
#print axioms asymp_of
#print axioms unstable_of_unbounded
#print axioms unstable_of_eig
#print axioms spiral_solves
#print axioms unstable_of_spiral
#print axioms not_asymp_of_centre
#print axioms unstable_of_real_roots
#print axioms vieta_two
