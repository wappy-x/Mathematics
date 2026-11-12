-- Error bounds and Romberg: the trapezoid sum's error is the Euler–Maclaurin series h^2/12 D₁ - h^4/720 D₃ + ... in even powers of the step with an explicitly bounded remainder, four times the halved-step sum minus the other, over 3, is Simpson's rule, and each Romberg column removes the next even power of h.
import Mathlib.NumberTheory.ZetaValues
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Asymptotics.Defs
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum

/-! `f` is the curve on `[a, b]`, cut into `n` equal slices of width `h = (b - a)/n`.
"`f` has `2p` continuous derivatives across the whole interval" is Mathlib's
`ContDiffOn ℝ (2 * p) f (Icc a b)`, and the k-th derivative `f^(k)` is taken within the interval
with `iteratedDerivWithin k f (Icc a b)` (one-sided at the two ends). The Bernoulli numbers
`B_k` are Mathlib's `bernoulli k`, and the Bernoulli polynomials `B_k(x)` are Mathlib's
`bernoulliFun k x`; both use the card's normalisation `B₁(x) = x - 1/2`, `B₂ = 1/6`. -/

open Set Filter Asymptotics Topology

/-- The trapezoid sum `T_n` with `n` slices of width `h = (b - a)/n` at the points
`x_i = a + i h`: `h · (f(x_0)/2 + f(x_1) + ... + f(x_{n-1}) + f(x_n)/2)`. -/
noncomputable def trapezoidSum (f : ℝ → ℝ) (a b : ℝ) (n : ℕ) : ℝ :=
  (b - a) / n * (f a / 2 + ∑ i ∈ Finset.Ico 1 n, f (a + (i : ℝ) * ((b - a) / n)) + f b / 2)

/-- Simpson's sum `S_n` with `n` (even) slices of width `h = (b - a)/n`:
`(h/3) · (f(x_0) + 4 f(x_1) + 2 f(x_2) + ... + 4 f(x_{n-1}) + f(x_n))`. -/
noncomputable def simpsonSum (f : ℝ → ℝ) (a b : ℝ) (n : ℕ) : ℝ :=
  (b - a) / n / 3 * (f a + ∑ i ∈ Finset.Ico 1 n,
    (if i % 2 = 1 then (4 : ℝ) else 2) * f (a + (i : ℝ) * ((b - a) / n)) + f b)

/-- One Romberg step at column `j`: from the column `j - 1` value `R` at step `h` and at the
doubled step `2h` (the coarser row), `R(h) + (R(h) - R(2h)) / (4^j - 1)`. -/
noncomputable def rombergStep (j : ℕ) (R : ℝ → ℝ) (h : ℝ) : ℝ :=
  R h + (R h - R (2 * h)) / (4 ^ j - 1)

lemma em_hasDerivAt_iteratedDerivWithin (f : ℝ → ℝ) (a b : ℝ) (p j : ℕ) (hab : a < b)
    (hf : ContDiffOn ℝ (2 * p) f (Icc a b)) (hj : j < 2 * p) (x : ℝ) (hx : x ∈ Ioo a b) :
    HasDerivAt (iteratedDerivWithin j f (Icc a b)) (iteratedDerivWithin (j + 1) f (Icc a b) x) x := by
  have hd : DifferentiableOn ℝ (iteratedDerivWithin j f (Icc a b)) (Icc a b) :=
    hf.differentiableOn_iteratedDerivWithin (by exact_mod_cast hj) (uniqueDiffOn_Icc hab)
  have hx' : Icc a b ∈ 𝓝 x := Icc_mem_nhds hx.1 hx.2
  have hda := (hd x (Ioo_subset_Icc_self hx)).differentiableAt hx'
  rw [iteratedDerivWithin_succ, derivWithin_of_mem_nhds hx']
  exact hda.hasDerivAt

lemma em_hasDerivAt_scaledBernoulli (k : ℕ) (c h x : ℝ) (hh : h ≠ 0) :
    HasDerivAt (fun y => h ^ (k + 1) / ((k + 1).factorial : ℝ) * bernoulliFun (k + 1) ((y - c) / h))
      (h ^ k / (k.factorial : ℝ) * bernoulliFun k ((x - c) / h)) x := by
  have h1 := (hasDerivAt_bernoulliFun (k + 1) ((x - c) / h)).comp x
    (((hasDerivAt_id x).sub_const c).div_const h)
  have h2 := h1.const_mul (h ^ (k + 1) / ((k + 1).factorial : ℝ))
  have e : (fun y => h ^ (k + 1) / ((k + 1).factorial : ℝ) * bernoulliFun (k + 1) ((y - c) / h))
      = (fun y => h ^ (k + 1) / ((k + 1).factorial : ℝ) *
          (bernoulliFun (k + 1) ∘ fun x => (id x - c) / h) y) := rfl
  rw [e]
  refine h2.congr_deriv ?_
  simp only [Nat.add_sub_cancel, Nat.factorial_succ]
  push_cast
  field_simp
  ring

lemma em_slice (f : ℝ → ℝ) (a b c h : ℝ) (p : ℕ) (hab : a < b) (hh : 0 < h) (hac : a ≤ c)
    (hcb : c + h ≤ b) (hp : 1 ≤ p) (hf : ContDiffOn ℝ (2 * p) f (Icc a b)) :
    ∫ x in c..c + h, f x =
      h * (f c + f (c + h)) / 2 -
      ∑ i ∈ Finset.range p, (bernoulli (2 * i + 2) : ℝ) / ((2 * i + 2).factorial : ℝ) *
          h ^ (2 * i + 2) *
          (iteratedDerivWithin (2 * i + 1) f (Icc a b) (c + h) -
            iteratedDerivWithin (2 * i + 1) f (Icc a b) c) +
      ∫ x in c..c + h, h ^ (2 * p) / ((2 * p).factorial : ℝ) * bernoulliFun (2 * p) ((x - c) / h) *
          iteratedDerivWithin (2 * p) f (Icc a b) x := by
  have hsub : Icc c (c + h) ⊆ Icc a b := Icc_subset_Icc hac hcb
  have hU := uniqueDiffOn_Icc hab
  have hcont : ∀ j ≤ 2 * p, ContinuousOn (iteratedDerivWithin j f (Icc a b)) (Icc c (c + h)) :=
    fun j hj => (hf.continuousOn_iteratedDerivWithin (by exact_mod_cast hj) hU).mono hsub
  have hφc : ∀ k : ℕ, Continuous fun x : ℝ =>
      h ^ k / (k.factorial : ℝ) * bernoulliFun k ((x - c) / h) := fun k =>
    continuous_const.mul ((continuous_bernoulliFun k).comp
      ((continuous_id.sub continuous_const).div_const h))
  have hIoo : ∀ x ∈ Ioo c (c + h), x ∈ Ioo a b := fun x hx =>
    ⟨lt_of_le_of_lt hac hx.1, lt_of_lt_of_le hx.2 hcb⟩
  -- the antiderivative
  set G : ℝ → ℝ := fun x => ∑ i ∈ Finset.range p,
    (h ^ (2 * i + 1) / ((2 * i + 1).factorial : ℝ) * bernoulliFun (2 * i + 1) ((x - c) / h) *
        iteratedDerivWithin (2 * i) f (Icc a b) x -
      h ^ (2 * i + 1 + 1) / ((2 * i + 1 + 1).factorial : ℝ) *
        bernoulliFun (2 * i + 1 + 1) ((x - c) / h) *
        iteratedDerivWithin (2 * i + 1) f (Icc a b) x) with hG
  set R : ℝ → ℝ := fun x => h ^ (2 * p) / ((2 * p).factorial : ℝ) *
    bernoulliFun (2 * p) ((x - c) / h) * iteratedDerivWithin (2 * p) f (Icc a b) x with hR
  have hRc : ContinuousOn R (Icc c (c + h)) := ((hφc (2 * p)).continuousOn).mul (hcont _ le_rfl)
  have hfc : ContinuousOn f (Icc c (c + h)) := by
    have := hcont 0 (Nat.zero_le _)
    simpa [iteratedDerivWithin_zero] using this
  have hGc : ContinuousOn G (Icc c (c + h)) := by
    refine continuousOn_finsetSum _ fun i hi => ?_
    have hi' := Finset.mem_range.mp hi
    exact (((hφc _).continuousOn).mul (hcont _ (by omega))).sub
      (((hφc _).continuousOn).mul (hcont _ (by omega)))
  have hGd : ∀ x ∈ Ioo c (c + h), HasDerivAt G (f x - R x) x := by
    intro x hx
    have hxab := hIoo x hx
    have hsum := HasDerivAt.fun_sum (u := Finset.range p) (x := x) (fun i hi =>
      ((em_hasDerivAt_scaledBernoulli (2 * i) c h x hh.ne').mul
        (em_hasDerivAt_iteratedDerivWithin f a b p (2 * i) hab hf
          (by have := Finset.mem_range.mp hi; omega) x hxab)).sub
      ((em_hasDerivAt_scaledBernoulli (2 * i + 1) c h x hh.ne').mul
        (em_hasDerivAt_iteratedDerivWithin f a b p (2 * i + 1) hab hf
          (by have := Finset.mem_range.mp hi; omega) x hxab)))
    refine hsum.congr_deriv ?_
    set u : ℕ → ℝ := fun i => h ^ (2 * i) / ((2 * i).factorial : ℝ) *
      bernoulliFun (2 * i) ((x - c) / h) * iteratedDerivWithin (2 * i) f (Icc a b) x with hu
    have hterm : ∀ i ∈ Finset.range p,
        (h ^ (2 * i) / ((2 * i).factorial : ℝ) * bernoulliFun (2 * i) ((x - c) / h) *
            iteratedDerivWithin (2 * i) f (Icc a b) x +
          h ^ (2 * i + 1) / ((2 * i + 1).factorial : ℝ) *
            bernoulliFun (2 * i + 1) ((x - c) / h) *
            iteratedDerivWithin (2 * i + 1) f (Icc a b) x -
          (h ^ (2 * i + 1) / ((2 * i + 1).factorial : ℝ) *
              bernoulliFun (2 * i + 1) ((x - c) / h) *
              iteratedDerivWithin (2 * i + 1) f (Icc a b) x +
            h ^ (2 * i + 1 + 1) / ((2 * i + 1 + 1).factorial : ℝ) *
              bernoulliFun (2 * i + 1 + 1) ((x - c) / h) *
              iteratedDerivWithin (2 * i + 1 + 1) f (Icc a b) x)) = u i - u (i + 1) := by
      intro i _
      simp only [hu, show 2 * (i + 1) = 2 * i + 1 + 1 by ring]
      ring
    rw [Finset.sum_congr rfl hterm, Finset.sum_range_sub']
    simp [hu, hR, bernoulliFun_zero, iteratedDerivWithin_zero]
  have hint : IntervalIntegrable (fun x => f x - R x) MeasureTheory.volume c (c + h) := by
    apply ContinuousOn.intervalIntegrable
    rw [uIcc_of_le (by linarith)]
    exact hfc.sub hRc
  have hFTC := intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le (by linarith) hGc hGd hint
  have hfi : IntervalIntegrable f MeasureTheory.volume c (c + h) := by
    apply ContinuousOn.intervalIntegrable; rw [uIcc_of_le (by linarith)]; exact hfc
  have hRi : IntervalIntegrable R MeasureTheory.volume c (c + h) := by
    apply ContinuousOn.intervalIntegrable; rw [uIcc_of_le (by linarith)]; exact hRc
  rw [intervalIntegral.integral_sub hfi hRi] at hFTC
  have hend : G (c + h) - G c = h * (f c + f (c + h)) / 2 -
      ∑ i ∈ Finset.range p, (bernoulli (2 * i + 2) : ℝ) / ((2 * i + 2).factorial : ℝ) *
          h ^ (2 * i + 2) *
          (iteratedDerivWithin (2 * i + 1) f (Icc a b) (c + h) -
            iteratedDerivWithin (2 * i + 1) f (Icc a b) c) := by
    have e1 : (c + h - c) / h = 1 := by field_simp; ring
    have e0 : (c - c) / h = 0 := by simp
    simp only [hG, e1, e0]
    rw [← Finset.sum_sub_distrib]
    have htrap : h * (f c + f (c + h)) / 2 =
        ∑ i ∈ Finset.range p, (if i = 0 then h * (f c + f (c + h)) / 2 else 0) := by
      rw [Finset.sum_ite_eq']; simp; omega
    rw [htrap, ← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl fun i _ => ?_
    simp only [show 2 * i + 1 + 1 = 2 * i + 2 by ring]
    rw [bernoulliFun_endpoints_eq_of_ne_one (by omega : 2 * i + 2 ≠ 1), bernoulliFun_eval_zero]
    rcases Nat.eq_zero_or_pos i with rfl | hi
    · simp [bernoulliFun_one, iteratedDerivWithin_zero]
      ring
    · have hodd : (bernoulli (2 * i + 1) : ℝ) = 0 := by
        rw [bernoulli_eq_zero_of_odd ⟨i, rfl⟩ (by omega)]; simp
      rw [bernoulliFun_endpoints_eq_of_ne_one (by omega : 2 * i + 1 ≠ 1), bernoulliFun_eval_zero,
        hodd]
      simp only [hi.ne', ↓reduceIte]
      ring
  have : (∫ x in c..c + h, R x) = ∫ x in c..c + h, h ^ (2 * p) / ((2 * p).factorial : ℝ) *
      bernoulliFun (2 * p) ((x - c) / h) * iteratedDerivWithin (2 * p) f (Icc a b) x := rfl
  rw [← this, ← hend]
  linarith

lemma em_sum_range_shift_Icc (g : ℕ → ℝ) (p : ℕ) :
    ∑ i ∈ Finset.range p, g (i + 1) = ∑ k ∈ Finset.Icc 1 p, g k := by
  induction p with
  | zero => simp
  | succ p ih => rw [Finset.sum_range_succ, ih, Finset.sum_Icc_succ_top (by omega)]

lemma weighted_sum_range (g : ℕ → ℝ) (m : ℕ) :
    ∑ i ∈ Finset.range (2 * m), (if i % 2 = 1 then (4 : ℝ) else 2) * g i =
      4 * ∑ i ∈ Finset.range (2 * m), g i - 2 * ∑ j ∈ Finset.range m, g (2 * j) := by
  induction m with
  | zero => simp
  | succ m ih =>
    rw [show 2 * (m + 1) = 2 * m + 1 + 1 by ring, Finset.sum_range_succ, Finset.sum_range_succ,
      Finset.sum_range_succ g, Finset.sum_range_succ g, Finset.sum_range_succ, ih]
    have h1 : (2 * m + 1) % 2 = 1 := by omega
    have h2 : (2 * m) % 2 = 0 := by omega
    simp only [h1, h2]
    norm_num
    ring

lemma sum_Icc_drop_first (F : ℕ → ℝ) (j q : ℕ) (hF : F j = 0) :
    ∑ k ∈ Finset.Icc j q, F k = ∑ k ∈ Finset.Icc (j + 1) q, F k := by
  symm
  refine Finset.sum_subset (fun k hk => ?_) (fun k hk hk' => ?_)
  · simp only [Finset.mem_Icc] at hk ⊢; omega
  · simp only [Finset.mem_Icc] at hk hk'
    have : k = j := by omega
    rw [this, hF]

/-- **The Euler–Maclaurin expansion of the trapezoid error, with its remainder.** Cut `[a, b]`
(with `a < b`) into `n ≥ 1` equal slices of width `h = (b - a)/n`, and keep `p ≥ 1` terms. If
`f` has `2p` continuous derivatives across the whole interval, write `D_k = f^(k)(b) - f^(k)(a)`
for how much the k-th derivative changes from end to end. Then the true integral `I` is
`T_n - (B₂/2!) h² D₁ - (B₄/4!) h⁴ D₃ - ... - (B_{2p}/(2p)!) h^{2p} D_{2p-1}`, plus a leftover
of size at most `h^{2p} (b - a) K M / (2p)!`, where `K` is a ceiling on `|f^(2p)|` across
`[a, b]` and `M` a ceiling on `|B_{2p}(x)|` for `x` in `[0, 1]`. Only even powers of `h`
appear, and only the derivatives at the two ends. With `p = 1` this is
`T_n - I = h²/12 · D₁ + (leftover)`. -/
theorem trapezoid_euler_maclaurin_expansion (f : ℝ → ℝ) (a b K M : ℝ) (n p : ℕ)
    (hab : a < b) (hn : 0 < n) (hp : 1 ≤ p)
    (hf : ContDiffOn ℝ (2 * p) f (Icc a b))
    (hK : ∀ x ∈ Icc a b, |iteratedDerivWithin (2 * p) f (Icc a b) x| ≤ K)
    (hM : ∀ x ∈ Icc (0 : ℝ) 1, |bernoulliFun (2 * p) x| ≤ M) :
    |(∫ x in a..b, f x) -
        (trapezoidSum f a b n -
          ∑ k ∈ Finset.Icc 1 p, (bernoulli (2 * k) : ℝ) / ((2 * k).factorial : ℝ) *
            ((b - a) / n) ^ (2 * k) *
            (iteratedDerivWithin (2 * k - 1) f (Icc a b) b -
              iteratedDerivWithin (2 * k - 1) f (Icc a b) a))|
      ≤ ((b - a) / n) ^ (2 * p) * (b - a) * K * M / ((2 * p).factorial : ℝ) := by
  have hnR : (0 : ℝ) < n := by exact_mod_cast hn
  unfold trapezoidSum
  set h := (b - a) / n with hh_def
  have hh : 0 < h := div_pos (by linarith) hnR
  have hnh : (n : ℝ) * h = b - a := by rw [hh_def]; field_simp
  set x : ℕ → ℝ := fun i => a + (i : ℝ) * h with hx
  have hx0 : x 0 = a := by simp [hx]
  have hxn : x n = b := by simp only [hx]; linarith
  have hxs : ∀ k, x (k + 1) = x k + h := by intro k; simp only [hx]; push_cast; ring
  have hxa : ∀ k, a ≤ x k := fun k => by
    simp only [hx]; nlinarith [(Nat.cast_nonneg k : (0 : ℝ) ≤ k)]
  have hxb : ∀ k < n, x k + h ≤ b := fun k hk => by
    rw [← hxs, ← hxn]; simp only [hx]
    have : ((k + 1 : ℕ) : ℝ) ≤ n := by exact_mod_cast hk
    nlinarith
  have hfc : ContinuousOn f (Icc a b) := hf.continuousOn
  have hint : ∀ k < n, IntervalIntegrable f MeasureTheory.volume (x k) (x (k + 1)) := by
    intro k hk
    apply ContinuousOn.intervalIntegrable
    rw [uIcc_of_le (by rw [hxs]; linarith)]
    exact hfc.mono (Icc_subset_Icc (hxa k) (hxs k ▸ hxb k hk))
  have hI := intervalIntegral.sum_integral_adjacent_intervals hint
  rw [hx0, hxn] at hI
  rw [← hI]
  have hsl : ∀ k ∈ Finset.range n, ∫ y in x k..x (k + 1), f y =
      h * (f (x k) + f (x k + h)) / 2 -
      ∑ i ∈ Finset.range p, (bernoulli (2 * i + 2) : ℝ) / ((2 * i + 2).factorial : ℝ) *
          h ^ (2 * i + 2) *
          (iteratedDerivWithin (2 * i + 1) f (Icc a b) (x k + h) -
            iteratedDerivWithin (2 * i + 1) f (Icc a b) (x k)) +
      ∫ y in x k..x k + h, h ^ (2 * p) / ((2 * p).factorial : ℝ) *
          bernoulliFun (2 * p) ((y - x k) / h) * iteratedDerivWithin (2 * p) f (Icc a b) y := by
    intro k hk
    rw [hxs]
    exact em_slice f a b (x k) h p hab hh (hxa k) (hxb k (Finset.mem_range.mp hk)) hp hf
  rw [Finset.sum_congr rfl hsl, Finset.sum_add_distrib, Finset.sum_sub_distrib]
  have hT : ∑ k ∈ Finset.range n, h * (f (x k) + f (x k + h)) / 2 =
      h * (f a / 2 + ∑ i ∈ Finset.Ico 1 n, f (a + (i : ℝ) * h) + f b / 2) := by
    have e1 : ∑ k ∈ Finset.range n, f (x k) = f a + ∑ i ∈ Finset.Ico 1 n, f (a + (i : ℝ) * h) := by
      rw [Finset.range_eq_Ico, Finset.sum_eq_sum_Ico_succ_bot hn (fun k => f (x k)), hx0]
    have e2 : ∑ k ∈ Finset.range n, f (x k + h) =
        ∑ k ∈ Finset.range n, f (x k) + f b - f a := by
      have s1 := Finset.sum_range_succ' (fun k => f (x k)) n
      have s2 := Finset.sum_range_succ (fun k => f (x k)) n
      simp only [hxs] at s1
      rw [hx0] at s1; rw [hxn] at s2
      linarith
    rw [← Finset.sum_div, ← Finset.mul_sum, Finset.sum_add_distrib, e2, e1]
    ring
  have hD : ∑ k ∈ Finset.range n, ∑ i ∈ Finset.range p,
      (bernoulli (2 * i + 2) : ℝ) / ((2 * i + 2).factorial : ℝ) * h ^ (2 * i + 2) *
          (iteratedDerivWithin (2 * i + 1) f (Icc a b) (x k + h) -
            iteratedDerivWithin (2 * i + 1) f (Icc a b) (x k)) =
      ∑ k ∈ Finset.Icc 1 p, (bernoulli (2 * k) : ℝ) / ((2 * k).factorial : ℝ) * h ^ (2 * k) *
            (iteratedDerivWithin (2 * k - 1) f (Icc a b) b -
              iteratedDerivWithin (2 * k - 1) f (Icc a b) a) := by
    rw [Finset.sum_comm, ← em_sum_range_shift_Icc]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [← Finset.mul_sum]
    have := Finset.sum_range_sub (fun k => iteratedDerivWithin (2 * i + 1) f (Icc a b) (x k)) n
    simp only [hxs, hxn, hx0] at this
    rw [this, show 2 * (i + 1) = 2 * i + 2 by ring, show 2 * i + 2 - 1 = 2 * i + 1 by omega]
  rw [hT, hD]
  have hC : ∀ k ∈ Finset.range n, |∫ y in x k..x k + h, h ^ (2 * p) / ((2 * p).factorial : ℝ) *
      bernoulliFun (2 * p) ((y - x k) / h) * iteratedDerivWithin (2 * p) f (Icc a b) y|
      ≤ h ^ (2 * p) / ((2 * p).factorial : ℝ) * M * K * h := by
    intro k hk
    have hkn := Finset.mem_range.mp hk
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := x k) (b := x k + h)
      (C := h ^ (2 * p) / ((2 * p).factorial : ℝ) * M * K)
      (f := fun y => h ^ (2 * p) / ((2 * p).factorial : ℝ) *
        bernoulliFun (2 * p) ((y - x k) / h) * iteratedDerivWithin (2 * p) f (Icc a b) y) ?_
    · rw [Real.norm_eq_abs] at this
      rw [add_sub_cancel_left, abs_of_pos hh] at this
      exact this
    · intro y hy
      rw [uIoc_of_le (by linarith)] at hy
      have hyab : y ∈ Icc a b := ⟨by linarith [hxa k, hy.1], by linarith [hxb k hkn, hy.2]⟩
      have hy01 : (y - x k) / h ∈ Icc (0 : ℝ) 1 :=
        ⟨div_nonneg (by linarith [hy.1]) hh.le, (div_le_one hh).mpr (by linarith [hy.2])⟩
      have hcpos : 0 < h ^ (2 * p) / ((2 * p).factorial : ℝ) := by positivity
      rw [Real.norm_eq_abs, abs_mul, abs_mul, abs_of_pos hcpos, mul_assoc, mul_assoc]
      exact mul_le_mul_of_nonneg_left
        (mul_le_mul (hM _ hy01) (hK _ hyab) (abs_nonneg _)
          ((abs_nonneg _).trans (hM _ hy01))) hcpos.le
  have hsum := (Finset.abs_sum_le_sum_abs _ _).trans (Finset.sum_le_sum hC)
  rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul] at hsum
  calc _ = |∑ k ∈ Finset.range n, ∫ y in x k..x k + h, h ^ (2 * p) / ((2 * p).factorial : ℝ) *
          bernoulliFun (2 * p) ((y - x k) / h) * iteratedDerivWithin (2 * p) f (Icc a b) y| := by
        congr 1; ring
    _ ≤ _ := hsum
    _ = _ := by rw [← hnh]; ring

/-- **Romberg's first column is Simpson's rule.** For any curve and any `m ≥ 1`, four times the
trapezoid sum on `2m` slices minus the trapezoid sum on `m` slices (every second point), all over
3, equals Simpson's rule on the same `2m` slices: `(4 T_{2m} - T_m)/3 = S_{2m}`. Simpson's rule is
the trapezoid rule with its `h²` error cancelled. -/
theorem romberg_first_column_eq_simpson (f : ℝ → ℝ) (a b : ℝ) (m : ℕ) (hm : 0 < m) :
    (4 * trapezoidSum f a b (2 * m) - trapezoidSum f a b m) / 3 = simpsonSum f a b (2 * m) := by
  set g : ℕ → ℝ := fun i => f (a + (i : ℝ) * ((b - a) / ((2 * m : ℕ) : ℝ))) with hg
  have hmR : (m : ℝ) ≠ 0 := by exact_mod_cast hm.ne'
  have hT2 : ∑ i ∈ Finset.Ico 1 (2 * m), f (a + (i : ℝ) * ((b - a) / ((2 * m : ℕ) : ℝ)))
      = ∑ i ∈ Finset.range (2 * m), g i - g 0 := by
    rw [Finset.range_eq_Ico, Finset.sum_eq_sum_Ico_succ_bot (show 0 < 2 * m by omega) g]; ring
  have hT1 : ∑ i ∈ Finset.Ico 1 m, f (a + (i : ℝ) * ((b - a) / (m : ℝ)))
      = ∑ j ∈ Finset.range m, g (2 * j) - g 0 := by
    rw [Finset.range_eq_Ico, Finset.sum_eq_sum_Ico_succ_bot hm (fun j => g (2 * j))]
    simp only [mul_zero, zero_add, add_sub_cancel_left]
    refine Finset.sum_congr rfl fun i _ => ?_
    simp only [hg]; congr 1; push_cast; field_simp
  have hS : ∑ i ∈ Finset.Ico 1 (2 * m), (if i % 2 = 1 then (4 : ℝ) else 2) *
      f (a + (i : ℝ) * ((b - a) / ((2 * m : ℕ) : ℝ)))
      = ∑ i ∈ Finset.range (2 * m), (if i % 2 = 1 then (4 : ℝ) else 2) * g i - 2 * g 0 := by
    rw [Finset.range_eq_Ico, Finset.sum_eq_sum_Ico_succ_bot (show 0 < 2 * m by omega)
      (fun i => (if i % 2 = 1 then (4 : ℝ) else 2) * g i)]
    simp [hg]
  unfold trapezoidSum simpsonSum
  rw [hT2, hT1, hS, weighted_sum_range]
  push_cast
  field_simp
  ring

/-- **Each Romberg column removes the next even power.** Let `j ≥ 1`. Suppose the column
`j - 1` value `R(h)` at step `h` is the true value `I` plus `c_j h^{2j} + c_{j+1} h^{2j+2} + ...
+ c_q h^{2q}` with fixed coefficients `c_k`, up to an error of size `h^{2q+2}` as `h → 0`. Then
the Romberg combination `R(h) + (R(h) - R(2h))/(4^j - 1)` is `I` plus fixed coefficients
`c_k (4^j - 4^k)/(4^j - 1)` on `h^{2j+2}, ..., h^{2q}` only, up to an error of size `h^{2q+2}`:
it keeps `I` and the `h^{2j}` term is gone. -/
theorem romberg_column_removes_next_even_power (R : ℝ → ℝ) (I : ℝ) (c : ℕ → ℝ) (j q : ℕ)
    (hj : 1 ≤ j)
    (hR : (fun h => R h - I - ∑ k ∈ Finset.Icc j q, c k * h ^ (2 * k))
      =O[𝓝 0] (fun h => h ^ (2 * q + 2))) :
    (fun h => rombergStep j R h - I -
        ∑ k ∈ Finset.Icc (j + 1) q, c k * ((4 : ℝ) ^ j - 4 ^ k) / (4 ^ j - 1) * h ^ (2 * k))
      =O[𝓝 0] (fun h => h ^ (2 * q + 2)) := by
  set E := fun h : ℝ => R h - I - ∑ k ∈ Finset.Icc j q, c k * h ^ (2 * k) with hE
  have hd : (4 : ℝ) ^ j - 1 ≠ 0 := by
    have : (4 : ℝ) ≤ 4 ^ j := by
      calc (4 : ℝ) = 4 ^ 1 := by norm_num
        _ ≤ 4 ^ j := pow_le_pow_right₀ (by norm_num) hj
    linarith
  have h2 : Tendsto (fun h : ℝ => 2 * h) (𝓝 0) (𝓝 0) := by
    have := (tendsto_id (x := 𝓝 (0 : ℝ))).const_mul (2 : ℝ)
    simpa using this
  have hE2 : (fun h => E (2 * h)) =O[𝓝 0] (fun h : ℝ => h ^ (2 * q + 2)) := by
    have := hR.comp_tendsto h2
    refine this.trans ?_
    have : (fun h : ℝ => (2 * h) ^ (2 * q + 2)) = fun h => 2 ^ (2 * q + 2) * h ^ (2 * q + 2) := by
      funext h; rw [mul_pow]
    simp only [Function.comp_def]
    rw [this]
    exact (isBigO_refl _ _).const_mul_left _
  have hsum : ∀ h : ℝ, ∑ k ∈ Finset.Icc (j + 1) q, c k * ((4 : ℝ) ^ j - 4 ^ k) / (4 ^ j - 1) * h ^ (2 * k)
      = ∑ k ∈ Finset.Icc j q, c k * h ^ (2 * k) +
        (∑ k ∈ Finset.Icc j q, c k * h ^ (2 * k) - ∑ k ∈ Finset.Icc j q, c k * (2 * h) ^ (2 * k))
          / (4 ^ j - 1) := by
    intro h
    rw [← sum_Icc_drop_first _ j q (by simp), ← Finset.sum_sub_distrib, Finset.sum_div,
      ← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun k _ => ?_
    rw [mul_pow, pow_mul (2 : ℝ)]
    field_simp
    ring
  have hfun : (fun h => rombergStep j R h - I -
        ∑ k ∈ Finset.Icc (j + 1) q, c k * ((4 : ℝ) ^ j - 4 ^ k) / (4 ^ j - 1) * h ^ (2 * k))
      = fun h => E h + (4 ^ j - 1)⁻¹ * (E h - E (2 * h)) := by
    funext h
    rw [hsum h]
    simp only [hE, rombergStep]
    field_simp
    ring
  rw [hfun]
  exact hR.add ((hR.sub hE2).const_mul_left _)

/-! The card's exact arithmetic. -/

-- The coefficients of the expansion: B₂/2! = (1/6)/2 = 1/12, B₄/4! = (-1/30)/24 = -1/720,
-- and B₆/6! = (1/42)/720 = 1/30240.
example : (1 : ℚ) / 6 / 2 = 1 / 12 ∧ (-1 : ℚ) / 30 / 24 = -1 / 720 ∧
    (1 : ℚ) / 42 / 720 = 1 / 30240 := by norm_num
-- Step 1: one slice's error, from the two heights against the exact area:
-- 1/8 - 1/24 = 1/12 on h³ f'' and 1/384 - 1/1920 = 1/480 on h⁵ f''''.
example : (1 : ℚ) / 8 - 1 / 24 = 1 / 12 ∧ (1 : ℚ) / 384 - 1 / 1920 = 1 / 480 := by norm_num
-- Step 2: collecting the h⁴ terms, -1/288 + 1/480 = -1/720, the second coefficient.
example : -(1 : ℚ) / 288 + 1 / 480 = -1 / 720 := by norm_num
-- The weights 4^j and 4^j - 1 in columns 1, 2, 3: 4 and 3, 16 and 15, 64 and 63.
example : (4 ^ 1, 4 ^ 1 - 1, 4 ^ 2, 4 ^ 2 - 1, 4 ^ 3, 4 ^ 3 - 1) = (4, 3, 16, 15, 64, 63) := by
  decide
-- Steps of 1.5 h and 1 h need the factor (3/2)² = 9/4, not 4.
example : ((3 : ℚ) / 2) ^ 2 = 9 / 4 := by norm_num
-- Simpson's weights on the 25 hourly readings (n = 24): 1 + 12 fours + 11 twos + 1 = 72 = 3 · 24,
-- so the weights h × (1, 4, 2, ..., 4, 1) / 3 add up to the 24 hours.
example : 1 + 12 * 4 + 11 * 2 + 1 = 3 * 24 := by decide
-- The log: 145 readings every 10 minutes cover 144 slices; the hourly sum uses every 6th
-- reading, 25 in all, and the 2-hour sum every 12th.
example : 144 / 24 = 6 ∧ 144 / 6 + 1 = 25 ∧ 144 / 12 = 12 := by decide
-- The detailed proof's p = 1 case: ∫₀¹ (x² - x)/2 dx = -1/12, so its size is the 1/12 of the
-- trapezoid bound (1/3 - 1/2 = -1/6, halved).
example : ((1 : ℚ) / 3 - 1 / 2) / 2 = -1 / 12 := by norm_num

#print axioms em_hasDerivAt_iteratedDerivWithin
#print axioms em_hasDerivAt_scaledBernoulli
#print axioms em_slice
#print axioms em_sum_range_shift_Icc
#print axioms weighted_sum_range
#print axioms sum_Icc_drop_first
#print axioms trapezoid_euler_maclaurin_expansion
#print axioms romberg_first_column_eq_simpson
#print axioms romberg_column_removes_next_even_power
