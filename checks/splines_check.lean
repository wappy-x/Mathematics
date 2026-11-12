-- Cubic splines: the natural cubic spline through any data at strictly increasing knots exists, is unique and twice continuously differentiable, its knot curvatures solve the tridiagonal moment system, and it bends least.
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Calculus.IteratedDeriv.Lemmas
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.TangentCone.Real
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.IntervalCases

open Set

/-- A natural cubic spline through the quotes `y 0, …, y n` at the knots `t 0, …, t n`:
it passes through every quote, it is one cubic on each gap `[t i, t (i+1)]`, it is twice
continuously differentiable on `[t 0, t n]` (neighbouring cubics meet with equal height,
slope and curvature), and its curvature is zero at both ends (the natural end condition). -/
def IsNaturalCubicSpline (n : ℕ) (t y : ℕ → ℝ) (s : ℝ → ℝ) : Prop :=
  (∀ i ≤ n, s (t i) = y i) ∧
  (∀ i < n, ∃ a b c d : ℝ, ∀ x ∈ Icc (t i) (t (i + 1)),
      s x = a + b * x + c * x ^ 2 + d * x ^ 3) ∧
  ContDiffOn ℝ 2 s (Icc (t 0) (t n)) ∧
  iteratedDerivWithin 2 s (Icc (t 0) (t n)) (t 0) = 0 ∧
  iteratedDerivWithin 2 s (Icc (t 0) (t n)) (t n) = 0

lemma spl_le {n : ℕ} {t : ℕ → ℝ} (ht : ∀ i < n, t i < t (i + 1)) {i j : ℕ} (hij : i ≤ j)
    (hj : j ≤ n) : t i ≤ t j := by
  induction j, hij using Nat.le_induction with
  | base => exact le_rfl
  | succ m hm ih => exact (ih (by omega)).trans (ht m (by omega)).le
#print axioms spl_le

lemma spl_lt {n : ℕ} {t : ℕ → ℝ} (ht : ∀ i < n, t i < t (i + 1)) {i j : ℕ} (hij : i < j)
    (hj : j ≤ n) : t i < t j :=
  (ht i (by omega)).trans_le (spl_le ht (by omega : i + 1 ≤ j) hj)
#print axioms spl_lt

lemma spl_hasDerivAt_of_mem {a b : ℝ} {g : ℝ → ℝ} (hg : ContDiffOn ℝ 1 g (Icc a b)) {x : ℝ}
    (hx : x ∈ Ioo a b) : HasDerivAt g (derivWithin g (Icc a b) x) x := by
  have hN : Icc a b ∈ nhds x := Icc_mem_nhds hx.1 hx.2
  rw [derivWithin_of_mem_nhds hN]
  exact ((hg.differentiableOn one_ne_zero x (Ioo_subset_Icc_self hx)).differentiableAt hN).hasDerivAt
#print axioms spl_hasDerivAt_of_mem

lemma spl_cubic_hasDerivAt (a b c d x : ℝ) :
    HasDerivAt (fun x => a + b * x + c * x ^ 2 + d * x ^ 3) (b + 2 * c * x + 3 * d * x ^ 2) x := by
  have h := ((((hasDerivAt_id x).const_mul b).const_add a).add
    ((hasDerivAt_pow 2 x).const_mul c)).add ((hasDerivAt_pow 3 x).const_mul d)
  convert h using 1
  · funext y; simp only [Pi.add_apply, id]
  · norm_num; ring
#print axioms spl_cubic_hasDerivAt

lemma spl_quad_hasDerivAt (b c d x : ℝ) :
    HasDerivAt (fun x => b + 2 * c * x + 3 * d * x ^ 2) (2 * c + 6 * d * x) x := by
  have h := (((hasDerivAt_id x).const_mul (2 * c)).const_add b).add
    ((hasDerivAt_pow 2 x).const_mul (3 * d))
  convert h using 1
  · funext y; simp only [Pi.add_apply, id]
  · norm_num; ring
#print axioms spl_quad_hasDerivAt

lemma spl_piece {n : ℕ} {t : ℕ → ℝ} (ht : ∀ i < n, t i < t (i + 1)) {s : ℝ → ℝ}
    (hs : ContDiffOn ℝ 2 s (Icc (t 0) (t n))) {i : ℕ} (hi : i < n) {a b c d : ℝ}
    (hp : ∀ x ∈ Icc (t i) (t (i + 1)), s x = a + b * x + c * x ^ 2 + d * x ^ 3) :
    ∀ x ∈ Icc (t i) (t (i + 1)), derivWithin s (Icc (t 0) (t n)) x = b + 2 * c * x + 3 * d * x ^ 2 ∧
      iteratedDerivWithin 2 s (Icc (t 0) (t n)) x = 2 * c + 6 * d * x := by
  have h0i : t 0 ≤ t i := spl_le ht (Nat.zero_le _) hi.le
  have hin : t (i + 1) ≤ t n := spl_le ht hi le_rfl
  have hii : t i < t (i + 1) := ht i hi
  have hU : UniqueDiffOn ℝ (Icc (t 0) (t n)) := uniqueDiffOn_Icc (h0i.trans_lt (hii.trans_le hin))
  have hsub : Ioo (t i) (t (i + 1)) ⊆ Icc (t i) (t (i + 1)) := Ioo_subset_Icc_self
  have hcl : Icc (t i) (t (i + 1)) ⊆ closure (Ioo (t i) (t (i + 1))) := by
    rw [closure_Ioo hii.ne]
  have hJI : Icc (t i) (t (i + 1)) ⊆ Icc (t 0) (t n) := Icc_subset_Icc h0i hin
  have hN : ∀ x ∈ Ioo (t i) (t (i + 1)), Icc (t 0) (t n) ∈ nhds x := fun x hx =>
    Icc_mem_nhds (h0i.trans_lt hx.1) (hx.2.trans_le hin)
  have hD1 : ∀ x ∈ Ioo (t i) (t (i + 1)),
      derivWithin s (Icc (t 0) (t n)) x = b + 2 * c * x + 3 * d * x ^ 2 := by
    intro x hx
    rw [derivWithin_of_mem_nhds (hN x hx)]
    have hev : s =ᶠ[nhds x] (fun x => a + b * x + c * x ^ 2 + d * x ^ 3) := by
      filter_upwards [Ioo_mem_nhds hx.1 hx.2] with z hz using hp z (hsub hz)
    rw [hev.deriv_eq]
    exact (spl_cubic_hasDerivAt a b c d x).deriv
  have hD2 : ∀ x ∈ Ioo (t i) (t (i + 1)),
      iteratedDerivWithin 2 s (Icc (t 0) (t n)) x = 2 * c + 6 * d * x := by
    intro x hx
    rw [iteratedDerivWithin_succ, iteratedDerivWithin_one, derivWithin_of_mem_nhds (hN x hx)]
    have hev : derivWithin s (Icc (t 0) (t n)) =ᶠ[nhds x]
        (fun x => b + 2 * c * x + 3 * d * x ^ 2) := by
      filter_upwards [Ioo_mem_nhds hx.1 hx.2] with z hz using hD1 z hz
    rw [hev.deriv_eq]
    exact (spl_quad_hasDerivAt b c d x).deriv
  have e1 := Set.EqOn.of_subset_closure hD1 ((hs.continuousOn_derivWithin hU (by norm_num)).mono hJI)
    (by fun_prop) hsub hcl
  have e2 := Set.EqOn.of_subset_closure hD2
    ((hs.continuousOn_iteratedDerivWithin (by norm_num) hU).mono hJI) (by fun_prop) hsub hcl
  exact fun x hx => ⟨e1 hx, e2 hx⟩
#print axioms spl_piece

lemma spl_alg (a b c d a' b' c' d' u k v : ℝ) (h1 : u < k) (h2 : k < v)
    (hd : b + 2 * c * k + 3 * d * k ^ 2 = b' + 2 * c' * k + 3 * d' * k ^ 2)
    (hval : a + b * k + c * k ^ 2 + d * k ^ 3 = a' + b' * k + c' * k ^ 2 + d' * k ^ 3)
    (hM : 2 * c + 6 * d * k = 2 * c' + 6 * d' * k) :
    (k - u) * (2 * c + 6 * d * u) + 2 * ((k - u) + (v - k)) * (2 * c + 6 * d * k)
        + (v - k) * (2 * c' + 6 * d' * v)
      = 6 * (((a' + b' * v + c' * v ^ 2 + d' * v ^ 3) - (a + b * k + c * k ^ 2 + d * k ^ 3)) / (v - k)
          - ((a + b * k + c * k ^ 2 + d * k ^ 3) - (a + b * u + c * u ^ 2 + d * u ^ 3)) / (k - u)) := by
  have hc' : c' = c + 3 * d * k - 3 * d' * k := by linear_combination -hM / 2
  subst hc'
  have hb' : b' = b + 2 * c * k + 3 * d * k ^ 2 - 2 * (c + 3 * d * k - 3 * d' * k) * k
      - 3 * d' * k ^ 2 := by linear_combination -hd
  subst hb'
  have ha' : a' = a + b * k + c * k ^ 2 + d * k ^ 3 - ((b + 2 * c * k + 3 * d * k ^ 2 -
      2 * (c + 3 * d * k - 3 * d' * k) * k - 3 * d' * k ^ 2) * k
      + (c + 3 * d * k - 3 * d' * k) * k ^ 2 + d' * k ^ 3) := by linear_combination -hval
  subst ha'
  have hku : k - u ≠ 0 := by linarith
  have hvk : v - k ≠ 0 := by linarith
  field_simp
  ring
#print axioms spl_alg

lemma spl_moments (n : ℕ) (t y : ℕ → ℝ) (s : ℝ → ℝ)
    (ht : ∀ i < n, t i < t (i + 1)) (hs : IsNaturalCubicSpline n t y s) :
    let M : ℕ → ℝ := fun i => iteratedDerivWithin 2 s (Icc (t 0) (t n)) (t i)
    M 0 = 0 ∧ M n = 0 ∧
    ∀ i, i + 2 ≤ n →
      (t (i + 1) - t i) * M i + 2 * ((t (i + 1) - t i) + (t (i + 2) - t (i + 1))) * M (i + 1)
          + (t (i + 2) - t (i + 1)) * M (i + 2)
        = 6 * ((y (i + 2) - y (i + 1)) / (t (i + 2) - t (i + 1))
                - (y (i + 1) - y i) / (t (i + 1) - t i)) := by
  intro M
  refine ⟨hs.2.2.2.1, hs.2.2.2.2, ?_⟩
  intro i hi
  obtain ⟨a, b, c, d, hP⟩ := hs.2.1 i (by omega)
  obtain ⟨a', b', c', d', hQ⟩ := hs.2.1 (i + 1) (by omega)
  have hQ' : ∀ x ∈ Icc (t (i + 1)) (t (i + 2)), s x = a' + b' * x + c' * x ^ 2 + d' * x ^ 3 := hQ
  have hC := hs.2.2.1
  have h0 : t i < t (i + 1) := ht i (by omega)
  have h1 : t (i + 1) < t (i + 2) := ht (i + 1) (by omega)
  have m0 : t i ∈ Icc (t i) (t (i + 1)) := ⟨le_rfl, h0.le⟩
  have m1 : t (i + 1) ∈ Icc (t i) (t (i + 1)) := ⟨h0.le, le_rfl⟩
  have m1' : t (i + 1) ∈ Icc (t (i + 1)) (t (i + 2)) := ⟨le_rfl, h1.le⟩
  have m2 : t (i + 2) ∈ Icc (t (i + 1)) (t (i + 2)) := ⟨h1.le, le_rfl⟩
  have P0 := spl_piece ht hC (by omega) hP _ m0
  have P1 := spl_piece ht hC (by omega) hP _ m1
  have Q1 := spl_piece ht hC (i := i + 1) (by omega) hQ' _ m1'
  have Q2 := spl_piece ht hC (i := i + 1) (by omega) hQ' _ m2
  have y0 : y i = a + b * t i + c * t i ^ 2 + d * t i ^ 3 := by
    rw [← hs.1 i (by omega)]; exact hP _ m0
  have y1 : y (i + 1) = a + b * t (i + 1) + c * t (i + 1) ^ 2 + d * t (i + 1) ^ 3 := by
    rw [← hs.1 (i + 1) (by omega)]; exact hP _ m1
  have y1' : y (i + 1) = a' + b' * t (i + 1) + c' * t (i + 1) ^ 2 + d' * t (i + 1) ^ 3 := by
    rw [← hs.1 (i + 1) (by omega)]; exact hQ' _ m1'
  have y2 : y (i + 2) = a' + b' * t (i + 2) + c' * t (i + 2) ^ 2 + d' * t (i + 2) ^ 3 := by
    rw [← hs.1 (i + 2) (by omega)]; exact hQ' _ m2
  simp only [M]
  rw [P0.2, P1.2, Q2.2, y0, y1, y2]
  exact spl_alg a b c d a' b' c' d' _ _ _ h0 h1 (P1.1.symm.trans Q1.1) (y1.symm.trans y1')
    (P1.2.symm.trans Q1.2)
#print axioms spl_moments

lemma spl_tri {n : ℕ} {t D : ℕ → ℝ} (ht : ∀ i < n, t i < t (i + 1)) (h0 : D 0 = 0) (hn : D n = 0)
    (hrow : ∀ i, i + 2 ≤ n → (t (i + 1) - t i) * D i
      + 2 * ((t (i + 1) - t i) + (t (i + 2) - t (i + 1))) * D (i + 1)
      + (t (i + 2) - t (i + 1)) * D (i + 2) = 0) :
    ∀ k ≤ n, D k = 0 := by
  obtain ⟨k, hk, hmax⟩ := Finset.exists_max_image (Finset.range (n + 1)) (fun k => |D k|)
    ⟨0, by simp⟩
  have hk0 : |D k| = 0 := by
    rw [Finset.mem_range] at hk
    rcases Nat.eq_zero_or_pos k with rfl | hkpos
    · simp [h0]
    rcases eq_or_ne k n with rfl | hkn
    · simp [hn]
    obtain ⟨i, rfl⟩ : ∃ i, k = i + 1 := ⟨k - 1, by omega⟩
    have hp : 0 < t (i + 1) - t i := by linarith [ht i (by omega)]
    have hq : 0 < t (i + 2) - t (i + 1) := by linarith [ht (i + 1) (by omega)]
    set p := t (i + 1) - t i
    set q := t (i + 2) - t (i + 1)
    have hr := hrow i (by omega)
    have e : 2 * (p + q) * D (i + 1) = -(p * D i + q * D (i + 2)) := by linarith
    have hA : |2 * (p + q) * D (i + 1)| = 2 * (p + q) * |D (i + 1)| := by
      rw [abs_mul, abs_of_pos (by positivity)]
    have hB : |p * D i + q * D (i + 2)| ≤ p * |D i| + q * |D (i + 2)| := by
      refine (abs_add_le _ _).trans ?_
      rw [abs_mul, abs_mul, abs_of_pos hp, abs_of_pos hq]
    have hi1 := hmax i (Finset.mem_range.2 (by omega))
    have hi2 := hmax (i + 2) (Finset.mem_range.2 (by omega))
    rw [e, abs_neg] at hA
    have h3 : (p + q) * |D (i + 1)| ≤ 0 := by
      nlinarith [mul_le_mul_of_nonneg_left hi1 hp.le, mul_le_mul_of_nonneg_left hi2 hq.le]
    have h4 : 0 ≤ |D (i + 1)| := abs_nonneg _
    nlinarith
  intro j hj
  have := hmax j (Finset.mem_range.2 (by omega))
  rw [hk0] at this
  exact abs_nonpos_iff.1 this
#print axioms spl_tri

lemma spl_cover {n : ℕ} {t : ℕ → ℝ} (hn : 0 < n) {x : ℝ} (hx : x ∈ Icc (t 0) (t n)) :
    ∃ i < n, x ∈ Icc (t i) (t (i + 1)) := by
  induction n with
  | zero => omega
  | succ m ih =>
    rcases Nat.eq_zero_or_pos m with rfl | hm
    · exact ⟨0, by omega, hx⟩
    by_cases hxm : x ≤ t m
    · obtain ⟨i, hi, h⟩ := ih hm ⟨hx.1, hxm⟩
      exact ⟨i, by omega, h⟩
    · exact ⟨m, by omega, (not_le.1 hxm).le, hx.2⟩
#print axioms spl_cover

lemma spl_cubic_zero {u v x A B C D : ℝ} (huv : u < v) (h1 : A + B * u + C * u ^ 2 + D * u ^ 3 = 0)
    (h2 : A + B * v + C * v ^ 2 + D * v ^ 3 = 0) (h3 : 2 * C + 6 * D * u = 0)
    (h4 : 2 * C + 6 * D * v = 0) : A + B * x + C * x ^ 2 + D * x ^ 3 = 0 := by
  have hvu : v - u ≠ 0 := by linarith
  have hD : D = 0 := by
    have : D * (v - u) = 0 := by linarith
    rcases mul_eq_zero.1 this with h | h
    · exact h
    · exact absurd h hvu
  subst hD
  have hC : C = 0 := by linarith
  subst hC
  have hB : B = 0 := by
    have : B * (v - u) = 0 := by linarith
    rcases mul_eq_zero.1 this with h | h
    · exact h
    · exact absurd h hvu
  subst hB
  have hA : A = 0 := by linarith
  subst hA
  ring
#print axioms spl_cubic_zero

lemma spl_unique {n : ℕ} {t y : ℕ → ℝ} {s₁ s₂ : ℝ → ℝ} (ht : ∀ i < n, t i < t (i + 1))
    (h1 : IsNaturalCubicSpline n t y s₁) (h2 : IsNaturalCubicSpline n t y s₂) :
    EqOn s₁ s₂ (Icc (t 0) (t n)) := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · intro x hx
    have : x = t 0 := le_antisymm hx.2 hx.1
    subst this
    rw [h1.1 0 le_rfl, h2.1 0 le_rfl]
  have T1 := spl_moments n t y s₁ ht h1
  have T2 := spl_moments n t y s₂ ht h2
  dsimp only at T1 T2
  have hD := spl_tri (D := fun k => iteratedDerivWithin 2 s₁ (Icc (t 0) (t n)) (t k)
      - iteratedDerivWithin 2 s₂ (Icc (t 0) (t n)) (t k)) ht
    (by simp [T1.1, T2.1]) (by simp [T1.2.1, T2.2.1])
    (fun i hi => by linear_combination T1.2.2 i hi - T2.2.2 i hi)
  intro x hx
  obtain ⟨i, hi, hxi⟩ := spl_cover hn hx
  obtain ⟨a, b, c, d, hP⟩ := h1.2.1 i hi
  obtain ⟨a', b', c', d', hQ⟩ := h2.2.1 i hi
  have h0 : t i < t (i + 1) := ht i hi
  have m0 : t i ∈ Icc (t i) (t (i + 1)) := ⟨le_rfl, h0.le⟩
  have m1 : t (i + 1) ∈ Icc (t i) (t (i + 1)) := ⟨h0.le, le_rfl⟩
  have P0 := spl_piece ht h1.2.2.1 hi hP _ m0
  have P1 := spl_piece ht h1.2.2.1 hi hP _ m1
  have Q0 := spl_piece ht h2.2.2.1 hi hQ _ m0
  have Q1 := spl_piece ht h2.2.2.1 hi hQ _ m1
  have D0 := hD i hi.le
  have D1 := hD (i + 1) hi
  rw [P0.2, Q0.2] at D0
  rw [P1.2, Q1.2] at D1
  have v0 := (hP _ m0).symm.trans ((h1.1 i hi.le).trans ((h2.1 i hi.le).symm.trans (hQ _ m0)))
  have v1 := (hP _ m1).symm.trans ((h1.1 (i + 1) hi).trans ((h2.1 (i + 1) hi).symm.trans (hQ _ m1)))
  rw [hP x hxi, hQ x hxi]
  have := spl_cubic_zero (x := x) (A := a - a') (B := b - b') (C := c - c') (D := d - d') h0
    (by linear_combination v0) (by linear_combination v1) (by linear_combination D0)
    (by linear_combination D1)
  linear_combination this
#print axioms spl_unique

lemma spl_orth {n : ℕ} {t y : ℕ → ℝ} {s f : ℝ → ℝ} (ht : ∀ i < n, t i < t (i + 1)) (hn : 0 < n)
    (hs : IsNaturalCubicSpline n t y s) (hf : ContDiffOn ℝ 2 f (Icc (t 0) (t n)))
    (hfy : ∀ i ≤ n, f (t i) = y i) :
    ∫ x in t 0..t n, iteratedDerivWithin 2 s (Icc (t 0) (t n)) x *
      (iteratedDerivWithin 2 f (Icc (t 0) (t n)) x - iteratedDerivWithin 2 s (Icc (t 0) (t n)) x)
      = 0 := by
  set I := Icc (t 0) (t n) with hIdef
  have hC : ContDiffOn ℝ 2 s I := hs.2.2.1
  have hU : UniqueDiffOn ℝ I := uniqueDiffOn_Icc (spl_lt ht hn le_rfl)
  have cS := hC.continuousOn_iteratedDerivWithin (m := 2) (by norm_num) hU
  have cF := hf.continuousOn_iteratedDerivWithin (m := 2) (by norm_num) hU
  have cs1 := hC.continuousOn_derivWithin hU (by norm_num)
  have cf1 := hf.continuousOn_derivWithin hU (by norm_num)
  have cs0 := hC.continuousOn
  have cf0 := hf.continuousOn
  have hd1 : ∀ g : ℝ → ℝ, ContDiffOn ℝ 2 g I → ∀ x ∈ Ioo (t 0) (t n),
      HasDerivAt g (derivWithin g I x) x := fun g hg x hx =>
    spl_hasDerivAt_of_mem (hg.of_le (by norm_num)) hx
  have hd2 : ∀ g : ℝ → ℝ, ContDiffOn ℝ 2 g I → ∀ x ∈ Ioo (t 0) (t n),
      HasDerivAt (derivWithin g I) (iteratedDerivWithin 2 g I x) x := by
    intro g hg x hx
    rw [iteratedDerivWithin_succ, iteratedDerivWithin_one]
    exact spl_hasDerivAt_of_mem (hg.derivWithin hU (by norm_num)) hx
  have hsubI : ∀ i < n, Icc (t i) (t (i + 1)) ⊆ I := fun i hi =>
    Icc_subset_Icc (spl_le ht (Nat.zero_le _) hi.le) (spl_le ht hi le_rfl)
  have hsubO : ∀ i < n, Ioo (t i) (t (i + 1)) ⊆ Ioo (t 0) (t n) := fun i hi =>
    Ioo_subset_Ioo (spl_le ht (Nat.zero_le _) hi.le) (spl_le ht hi le_rfl)
  have hInt : ∀ g : ℝ → ℝ, ContinuousOn g I → ∀ i < n,
      IntervalIntegrable g MeasureTheory.volume (t i) (t (i + 1)) := by
    intro g hg i hi
    apply ContinuousOn.intervalIntegrable
    rw [uIcc_of_le (ht i hi).le]
    exact hg.mono (hsubI i hi)
  have hpiece : ∀ i < n,
      ∫ x in t i..t (i + 1), iteratedDerivWithin 2 s I x *
        (iteratedDerivWithin 2 f I x - iteratedDerivWithin 2 s I x)
      = iteratedDerivWithin 2 s I (t (i + 1)) *
          (derivWithin f I (t (i + 1)) - derivWithin s I (t (i + 1)))
        - iteratedDerivWithin 2 s I (t i) * (derivWithin f I (t i) - derivWithin s I (t i)) := by
    intro i hi
    obtain ⟨a, b, c, d, hP⟩ := hs.2.1 i hi
    have hP2 : ∀ x ∈ Icc (t i) (t (i + 1)), derivWithin s I x = b + 2 * c * x + 3 * d * x ^ 2 ∧
        iteratedDerivWithin 2 s I x = 2 * c + 6 * d * x := spl_piece ht hC hi hP
    have h0 : t i < t (i + 1) := ht i hi
    have hcongr : ∫ x in t i..t (i + 1), iteratedDerivWithin 2 s I x *
        (iteratedDerivWithin 2 f I x - iteratedDerivWithin 2 s I x)
        = ∫ x in t i..t (i + 1), (2 * c + 6 * d * x) *
        (iteratedDerivWithin 2 f I x - iteratedDerivWithin 2 s I x) := by
      apply intervalIntegral.integral_congr
      intro x hx
      rw [uIcc_of_le h0.le] at hx
      simp only [(hP2 x hx).2]
    have FTC1 := intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le h0.le
      (f := fun x => (2 * c + 6 * d * x) * (derivWithin f I x - derivWithin s I x))
      (f' := fun x => 6 * d * (derivWithin f I x - derivWithin s I x) +
        (2 * c + 6 * d * x) * (iteratedDerivWithin 2 f I x - iteratedDerivWithin 2 s I x))
      (by
        apply ContinuousOn.mul (by fun_prop)
        exact (cf1.sub cs1).mono (hsubI i hi))
      (by
        intro x hx
        have hx' := hsubO i hi hx
        have := ((spl_quad_hasDerivAt (2 * c) (3 * d) 0 x).mul
          ((hd2 f hf x hx').sub (hd2 s hC x hx')))
        convert this using 1
        · funext z; simp only [Pi.mul_apply, Pi.sub_apply]; ring
        · simp only [Pi.sub_apply]; ring)
      (by
        apply ContinuousOn.intervalIntegrable
        rw [uIcc_of_le h0.le]
        apply ContinuousOn.add
        · exact (continuousOn_const.mul (cf1.sub cs1)).mono (hsubI i hi)
        · exact ContinuousOn.mul (by fun_prop) ((cF.sub cS).mono (hsubI i hi)))
    have FTC2 := intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le h0.le
      (f := fun x => f x - s x)
      (f' := fun x => derivWithin f I x - derivWithin s I x)
      ((cf0.sub cs0).mono (hsubI i hi))
      (fun x hx => (hd1 f hf x (hsubO i hi hx)).sub (hd1 s hC x (hsubO i hi hx)))
      (hInt _ (cf1.sub cs1) i hi)
    rw [intervalIntegral.integral_add, intervalIntegral.integral_const_mul] at FTC1
    · rw [FTC2, hfy i hi.le, hfy (i + 1) hi, hs.1 i hi.le, hs.1 (i + 1) hi] at FTC1
      rw [hcongr, (hP2 _ ⟨le_rfl, h0.le⟩).2, (hP2 _ ⟨h0.le, le_rfl⟩).2]
      linarith
    · exact (hInt _ (continuousOn_const.mul (cf1.sub cs1)) i hi)
    · apply ContinuousOn.intervalIntegrable
      rw [uIcc_of_le h0.le]
      exact ContinuousOn.mul (by fun_prop) ((cF.sub cS).mono (hsubI i hi))
  rw [← intervalIntegral.sum_integral_adjacent_intervals (a := t) (f := fun x =>
    iteratedDerivWithin 2 s I x * (iteratedDerivWithin 2 f I x - iteratedDerivWithin 2 s I x))
    (fun i hi => hInt _ (cS.mul (cF.sub cS)) i hi)]
  rw [Finset.sum_congr rfl (fun i hi => hpiece i (Finset.mem_range.1 hi))]
  rw [Finset.sum_range_sub (fun k => iteratedDerivWithin 2 s I (t k) *
    (derivWithin f I (t k) - derivWithin s I (t k)))]
  have e0 : iteratedDerivWithin 2 s I (t 0) = 0 := hs.2.2.2.1
  have e1 : iteratedDerivWithin 2 s I (t n) = 0 := hs.2.2.2.2
  simp only [e0, e1]
  ring
#print axioms spl_orth

noncomputable def splTp (x : ℝ) : ℝ := (max x 0) ^ 3

lemma spl_pp_hasDerivAt (k : ℕ) (x : ℝ) :
    HasDerivAt (fun y : ℝ => (max y 0) ^ (k + 2)) (((k : ℝ) + 2) * (max x 0) ^ (k + 1)) x := by
  rcases lt_trichotomy x 0 with hx | rfl | hx
  · have hev : (fun y : ℝ => (max y 0) ^ (k + 2)) =ᶠ[nhds x] fun _ => 0 := by
      filter_upwards [Iio_mem_nhds hx] with y hy
      simp [max_eq_right (Set.mem_Iio.1 hy).le]
    rw [max_eq_right hx.le]
    simpa using (hasDerivAt_const x (0 : ℝ)).congr_of_eventuallyEq hev
  · have h1 : HasDerivWithinAt (fun y : ℝ => (max y 0) ^ (k + 2)) 0 (Iic 0) 0 :=
      (hasDerivWithinAt_const (0 : ℝ) (Iic 0) (0 : ℝ)).congr
        (fun y hy => by simp [max_eq_right (show y ≤ 0 from hy)]) (by simp)
    have h2 : HasDerivWithinAt (fun y : ℝ => (max y 0) ^ (k + 2)) 0 (Ici 0) 0 := by
      have := ((hasDerivAt_pow (k + 2) (0 : ℝ)).hasDerivWithinAt (s := Ici 0)).congr
        (f₁ := fun y : ℝ => (max y 0) ^ (k + 2))
        (fun y hy => by simp [max_eq_left (show (0:ℝ) ≤ y from hy)]) (by simp)
      convert this using 1
      simp
    have := h1.union h2
    rw [Iic_union_Ici, hasDerivWithinAt_univ] at this
    simpa using this
  · have hev : (fun y : ℝ => (max y 0) ^ (k + 2)) =ᶠ[nhds x] fun y => y ^ (k + 2) := by
      filter_upwards [Ioi_mem_nhds hx] with y hy
      simp [max_eq_left (show (0:ℝ) ≤ y from le_of_lt hy)]
    rw [max_eq_left hx.le]
    have := (hasDerivAt_pow (k + 2) x).congr_of_eventuallyEq hev
    convert this using 1
    push_cast
    ring_nf
#print axioms spl_pp_hasDerivAt

lemma splTp_contDiff : ContDiff ℝ 2 splTp := by
  have hd1 : ∀ x, HasDerivAt splTp (3 * (max x 0) ^ 2) x := by
    intro x
    have := spl_pp_hasDerivAt 1 x
    norm_num at this
    exact this
  have hd2 : ∀ x, HasDerivAt (fun y : ℝ => 3 * (max y 0) ^ 2) (6 * max x 0) x := by
    intro x
    have := (spl_pp_hasDerivAt 0 x).const_mul 3
    norm_num at this
    convert this using 1
    ring
  have e1 : deriv splTp = fun y => 3 * (max y 0) ^ 2 := funext fun x => (hd1 x).deriv
  have e2 : deriv (fun y : ℝ => 3 * (max y 0) ^ 2) = fun y => 6 * max y 0 :=
    funext fun x => (hd2 x).deriv
  show ContDiff ℝ (1 + 1) splTp
  rw [contDiff_succ_iff_deriv]
  refine ⟨fun x => (hd1 x).differentiableAt, by simp, ?_⟩
  rw [e1, contDiff_one_iff_deriv, e2]
  exact ⟨fun x => (hd2 x).differentiableAt, by fun_prop⟩
#print axioms splTp_contDiff

lemma splTp_of_nonpos {x : ℝ} (hx : x ≤ 0) : splTp x = 0 := by
  simp [splTp, max_eq_right hx]
#print axioms splTp_of_nonpos

lemma splTp_of_nonneg {x : ℝ} (hx : 0 ≤ x) : splTp x = x ^ 3 := by
  simp [splTp, max_eq_left hx]
#print axioms splTp_of_nonneg

noncomputable def splF (t z : ℕ → ℝ) (p0 : ℝ → ℝ) : ℕ → ℝ → ℝ
  | 0 => p0
  | j + 1 => fun x => splF t z p0 j x +
      (z (j + 2) - splF t z p0 j (t (j + 2))) / (t (j + 2) - t (j + 1)) ^ 3 * splTp (x - t (j + 1))

lemma splF_contDiff (t z : ℕ → ℝ) {p0 : ℝ → ℝ} (hp : ContDiff ℝ 2 p0) (j : ℕ) :
    ContDiff ℝ 2 (splF t z p0 j) := by
  induction j with
  | zero => exact hp
  | succ j ih =>
    exact ih.add (contDiff_const.mul (splTp_contDiff.comp (contDiff_id.sub contDiff_const)))
#print axioms splF_contDiff

lemma splF_left {n : ℕ} {t : ℕ → ℝ} (ht : ∀ i < n, t i < t (i + 1)) (z : ℕ → ℝ) (p0 : ℝ → ℝ) :
    ∀ j, j + 1 ≤ n → ∀ x ≤ t 1, splF t z p0 j x = p0 x := by
  intro j
  induction j with
  | zero => intro _ x _; rfl
  | succ j ih =>
    intro hj x hx
    simp only [splF]
    rw [ih (by omega) x hx, splTp_of_nonpos (by linarith [spl_le ht (by omega : 1 ≤ j + 1) (by omega : j + 1 ≤ n)])]
    ring
#print axioms splF_left

lemma splF_interp {n : ℕ} {t : ℕ → ℝ} (ht : ∀ i < n, t i < t (i + 1)) (z : ℕ → ℝ) (p0 : ℝ → ℝ)
    (h0 : p0 (t 0) = z 0) (h1 : p0 (t 1) = z 1) :
    ∀ j, j + 1 ≤ n → ∀ k ≤ j + 1, splF t z p0 j (t k) = z k := by
  intro j
  induction j with
  | zero =>
    intro _ k hk
    interval_cases k
    · exact h0
    · exact h1
  | succ j ih =>
    intro hj k hk
    simp only [splF]
    rcases Nat.lt_or_ge k (j + 2) with hk' | hk'
    · rw [ih (by omega) k (by omega),
        splTp_of_nonpos (by linarith [spl_le ht (by omega : k ≤ j + 1) (by omega : j + 1 ≤ n)])]
      ring
    · obtain rfl : k = j + 2 := by omega
      have hpos : 0 < t (j + 2) - t (j + 1) := by linarith [ht (j + 1) (by omega)]
      rw [splTp_of_nonneg hpos.le]
      field_simp
      ring
#print axioms splF_interp

lemma splF_piece {n : ℕ} {t : ℕ → ℝ} (ht : ∀ i < n, t i < t (i + 1)) (z : ℕ → ℝ) (p0 : ℝ → ℝ)
    {a0 b0 c0 d0 : ℝ} (hp : ∀ x, p0 x = a0 + b0 * x + c0 * x ^ 2 + d0 * x ^ 3) :
    ∀ j, j + 1 ≤ n → ∀ i < n, ∃ a b c d : ℝ, ∀ x ∈ Icc (t i) (t (i + 1)),
      splF t z p0 j x = a + b * x + c * x ^ 2 + d * x ^ 3 := by
  intro j
  induction j with
  | zero => intro _ i _; exact ⟨a0, b0, c0, d0, fun x _ => hp x⟩
  | succ j ih =>
    intro hj i hi
    obtain ⟨a, b, c, d, h⟩ := ih (by omega) i hi
    set C := (z (j + 2) - splF t z p0 j (t (j + 2))) / (t (j + 2) - t (j + 1)) ^ 3
    set T := t (j + 1)
    rcases Nat.lt_or_ge i (j + 1) with hij | hij
    · refine ⟨a, b, c, d, fun x hx => ?_⟩
      simp only [splF]
      rw [h x hx, splTp_of_nonpos (by linarith [hx.2, spl_le ht (by omega : i + 1 ≤ j + 1) (by omega : j + 1 ≤ n)])]
      ring
    · refine ⟨a - C * T ^ 3, b + 3 * C * T ^ 2, c - 3 * C * T, d + C, fun x hx => ?_⟩
      simp only [splF]
      rw [h x hx, splTp_of_nonneg (by linarith [hx.1, spl_le ht hij hi.le])]
      ring
#print axioms splF_piece

/-- Main claim. If every gap width `h i = t (i+1) - t i` is positive, then for any quotes
there is a natural cubic spline through them, it is twice continuously differentiable on
`[t 0, t n]`, and any other natural cubic spline through the same quotes equals it on
`[t 0, t n]`. -/
theorem natural_cubic_spline_exists_unique (n : ℕ) (t y : ℕ → ℝ)
    (ht : ∀ i < n, t i < t (i + 1)) :
    ∃ s : ℝ → ℝ, IsNaturalCubicSpline n t y s ∧
      ContDiffOn ℝ 2 s (Icc (t 0) (t n)) ∧
      ∀ s' : ℝ → ℝ, IsNaturalCubicSpline n t y s' → EqOn s' s (Icc (t 0) (t n)) := by
  suffices h : ∃ s : ℝ → ℝ, IsNaturalCubicSpline n t y s by
    obtain ⟨s, hs⟩ := h
    exact ⟨s, hs, hs.2.2.1, fun s' hs' => spl_unique ht hs' hs⟩
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · refine ⟨fun _ => y 0, ?_, ?_, contDiffOn_const, ?_, ?_⟩
    · intro i hi
      obtain rfl : i = 0 := by omega
      rfl
    · intro i hi
      omega
    · simp [iteratedDerivWithin_const]
    · simp [iteratedDerivWithin_const]
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  have h01 : t 0 < t 1 := ht 0 (by omega)
  have h1n : t 1 ≤ t (m + 1) := spl_le ht (by omega) le_rfl
  have hpos : 0 < t 1 - t 0 := by linarith
  obtain ⟨g, hg⟩ : ∃ g : ℝ, g = (y 1 - y 0) / (t 1 - t 0) := ⟨_, rfl⟩
  -- the two starting cubics
  obtain ⟨pv, hpv⟩ : ∃ pv : ℝ → ℝ, ∀ x, pv x = (y 0 - g * t 0) + g * x + 0 * x ^ 2 + 0 * x ^ 3 :=
    ⟨_, fun x => rfl⟩
  obtain ⟨pu, hpu⟩ : ∃ pu : ℝ → ℝ, ∀ x, pu x = (t 0 ^ 3 - t 0 * (t 1 - t 0) ^ 2)
      + ((t 1 - t 0) ^ 2 - 3 * t 0 ^ 2) * x + (3 * t 0) * x ^ 2 + (-1) * x ^ 3 :=
    ⟨_, fun x => rfl⟩
  have pv0 : pv (t 0) = y 0 := by rw [hpv]; ring
  have pv1 : pv (t 1) = y 1 := by
    rw [hpv, hg]; field_simp; ring
  have pu0 : pu (t 0) = (fun _ => (0 : ℝ)) 0 := by rw [hpu]; ring
  have pu1 : pu (t 1) = (fun _ => (0 : ℝ)) 1 := by rw [hpu]; ring
  have cpv : ContDiff ℝ 2 pv := by rw [funext hpv]; fun_prop
  have cpu : ContDiff ℝ 2 pu := by rw [funext hpu]; fun_prop
  have cv := splF_contDiff t y cpv m
  have cu := splF_contDiff t (fun _ => 0) cpu m
  have iv := splF_interp ht y pv pv0 pv1 m le_rfl
  have iu := splF_interp ht (fun _ => 0) pu pu0 pu1 m le_rfl
  have lv := splF_left ht y pv m le_rfl
  have lu := splF_left ht (fun _ => 0) pu m le_rfl
  have kv := splF_piece ht y pv hpv m le_rfl
  have ku := splF_piece ht (fun _ => 0) pu hpu m le_rfl
  generalize splF t y pv m = v at cv iv lv kv
  generalize splF t (fun _ => 0) pu m = u at cu iu lu ku
  have m0 : t 0 ∈ Icc (t 0) (t (0 + 1)) := ⟨le_rfl, h01.le⟩
  have hu0 : iteratedDerivWithin 2 u (Icc (t 0) (t (m + 1))) (t 0) = 0 := by
    rw [(spl_piece ht cu.contDiffOn (i := 0) (by omega)
      (fun x hx => (lu x hx.2).trans (hpu x)) (t 0) m0).2]
    ring
  obtain ⟨B, hB⟩ : ∃ B, iteratedDerivWithin 2 u (Icc (t 0) (t (m + 1))) (t (m + 1)) = B :=
    ⟨_, rfl⟩
  obtain ⟨A, hA⟩ : ∃ A, iteratedDerivWithin 2 v (Icc (t 0) (t (m + 1))) (t (m + 1)) = A :=
    ⟨_, rfl⟩
  have hBne : B ≠ 0 := by
    intro hB0
    have hU1 : IsNaturalCubicSpline (m + 1) t (fun _ => 0) u :=
      ⟨iu, ku, cu.contDiffOn, hu0, hB.trans hB0⟩
    have hZ : IsNaturalCubicSpline (m + 1) t (fun _ => 0) (fun _ => 0) :=
      ⟨fun _ _ => rfl, fun _ _ => ⟨0, 0, 0, 0, fun _ _ => by ring⟩, contDiffOn_const,
        by simp, by simp⟩
    have hmid : (t 0 + t 1) / 2 ∈ Icc (t 0) (t (m + 1)) := ⟨by linarith, by linarith⟩
    have h0 : u ((t 0 + t 1) / 2) = 0 := spl_unique ht hU1 hZ hmid
    rw [lu _ (by linarith), hpu] at h0
    nlinarith [pow_pos hpos 3]
  refine ⟨fun x => v x + (-A / B) * u x, fun k hk => ?_, fun i hi => ?_,
    (cv.add (contDiff_const.mul cu)).contDiffOn, ?_, ?_⟩
  · simp only
    rw [iv k hk, iu k hk]
    ring
  · obtain ⟨a, b, c, d, h1⟩ := kv i hi
    obtain ⟨a', b', c', d', h2⟩ := ku i hi
    refine ⟨a + (-A / B) * a', b + (-A / B) * b', c + (-A / B) * c', d + (-A / B) * d',
      fun x hx => ?_⟩
    simp only
    rw [h1 x hx, h2 x hx]
    ring
  · rw [(spl_piece ht (cv.add (contDiff_const.mul cu)).contDiffOn (i := 0) (by omega)
      (a := (y 0 - g * t 0) + (-A / B) * (t 0 ^ 3 - t 0 * (t 1 - t 0) ^ 2))
      (b := g + (-A / B) * ((t 1 - t 0) ^ 2 - 3 * t 0 ^ 2)) (c := 0 + (-A / B) * (3 * t 0))
      (d := 0 + (-A / B) * (-1))
      (fun x hx => by
        show v x + (-A / B) * u x = _
        rw [lv x hx.2, lu x hx.2, hpv, hpu]
        ring) (t 0) m0).2]
    ring
  · obtain ⟨a, b, c, d, h1⟩ := kv m (by omega)
    obtain ⟨a', b', c', d', h2⟩ := ku m (by omega)
    have mm : t (m + 1) ∈ Icc (t m) (t (m + 1)) := ⟨(ht m (by omega)).le, le_rfl⟩
    have eA := (spl_piece ht cv.contDiffOn (by omega) h1 _ mm).2
    have eB := (spl_piece ht cu.contDiffOn (by omega) h2 _ mm).2
    rw [(spl_piece ht (cv.add (contDiff_const.mul cu)).contDiffOn (i := m) (by omega)
      (a := a + (-A / B) * a') (b := b + (-A / B) * b') (c := c + (-A / B) * c')
      (d := d + (-A / B) * d')
      (fun x hx => by
        show v x + (-A / B) * u x = _
        rw [h1 x hx, h2 x hx]
        ring) _ mm).2]
    have : 2 * (c + (-A / B) * c') + 6 * (d + (-A / B) * d') * t (m + 1) = A + (-A / B) * B := by
      rw [← hA, ← hB, eA, eB]; ring
    rw [this]
    field_simp
    ring

/-- The moments `M i = s''(t i)` of a natural cubic spline solve the tridiagonal system:
`M 0 = M n = 0`, and at each inside knot `k = i + 1`,
`h_(k-1) M_(k-1) + 2 (h_(k-1) + h_k) M_k + h_k M_(k+1) = 6 (g_k - g_(k-1))`,
where `h_j = t (j+1) - t j` is the gap width and `g_j = (y (j+1) - y j) / h_j` the chord slope. -/
theorem natural_spline_moments_solve_tridiagonal (n : ℕ) (t y : ℕ → ℝ) (s : ℝ → ℝ)
    (ht : ∀ i < n, t i < t (i + 1)) (hs : IsNaturalCubicSpline n t y s) :
    let M : ℕ → ℝ := fun i => iteratedDerivWithin 2 s (Icc (t 0) (t n)) (t i)
    M 0 = 0 ∧ M n = 0 ∧
    ∀ i, i + 2 ≤ n →
      (t (i + 1) - t i) * M i + 2 * ((t (i + 1) - t i) + (t (i + 2) - t (i + 1))) * M (i + 1)
          + (t (i + 2) - t (i + 1)) * M (i + 2)
        = 6 * ((y (i + 2) - y (i + 1)) / (t (i + 2) - t (i + 1))
                - (y (i + 1) - y i) / (t (i + 1) - t i)) := by
  exact spl_moments n t y s ht hs

/-- Holladay's least-bending property. Of all twice continuously differentiable curves
through the same quotes, the natural cubic spline has the smallest bending energy
`∫ s''(x)^2 dx` over `[t 0, t n]`. -/
theorem natural_spline_bends_least (n : ℕ) (t y : ℕ → ℝ) (s f : ℝ → ℝ)
    (ht : ∀ i < n, t i < t (i + 1)) (hs : IsNaturalCubicSpline n t y s)
    (hf : ContDiffOn ℝ 2 f (Icc (t 0) (t n))) (hfy : ∀ i ≤ n, f (t i) = y i) :
    ∫ x in t 0..t n, (iteratedDerivWithin 2 s (Icc (t 0) (t n)) x) ^ 2
      ≤ ∫ x in t 0..t n, (iteratedDerivWithin 2 f (Icc (t 0) (t n)) x) ^ 2 := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  have horth := spl_orth ht hn hs hf hfy
  set I := Icc (t 0) (t n) with hIdef
  have hlt : t 0 < t n := spl_lt ht hn le_rfl
  have hU : UniqueDiffOn ℝ I := uniqueDiffOn_Icc hlt
  have hC : ContDiffOn ℝ 2 s I := hs.2.2.1
  have cS := hC.continuousOn_iteratedDerivWithin (m := 2) (by norm_num) hU
  have cF := hf.continuousOn_iteratedDerivWithin (m := 2) (by norm_num) hU
  have hInt : ∀ g : ℝ → ℝ, ContinuousOn g I → IntervalIntegrable g MeasureTheory.volume (t 0) (t n) := by
    intro g hg
    apply ContinuousOn.intervalIntegrable
    rw [uIcc_of_le hlt.le]
    exact hg
  have key : (∫ x in t 0..t n, (iteratedDerivWithin 2 f I x) ^ 2)
      = (∫ x in t 0..t n, (iteratedDerivWithin 2 s I x) ^ 2)
        + ((∫ x in t 0..t n, (iteratedDerivWithin 2 f I x - iteratedDerivWithin 2 s I x) ^ 2)
        + 2 * ∫ x in t 0..t n, iteratedDerivWithin 2 s I x *
          (iteratedDerivWithin 2 f I x - iteratedDerivWithin 2 s I x)) := by
    have e : (∫ x in t 0..t n, (iteratedDerivWithin 2 f I x) ^ 2)
        = ∫ x in t 0..t n, ((iteratedDerivWithin 2 s I x) ^ 2
          + ((iteratedDerivWithin 2 f I x - iteratedDerivWithin 2 s I x) ^ 2
          + 2 * (iteratedDerivWithin 2 s I x *
            (iteratedDerivWithin 2 f I x - iteratedDerivWithin 2 s I x)))) := by
      apply intervalIntegral.integral_congr
      intro x _
      ring
    rw [e, intervalIntegral.integral_add, intervalIntegral.integral_add,
      intervalIntegral.integral_const_mul]
    · exact hInt _ ((cF.sub cS).pow 2)
    · exact hInt _ (continuousOn_const.mul (cS.mul (cF.sub cS)))
    · exact hInt _ (cS.pow 2)
    · exact (hInt _ ((cF.sub cS).pow 2)).add (hInt _ (continuousOn_const.mul (cS.mul (cF.sub cS))))
  rw [key, horth]
  have : 0 ≤ (∫ x in t 0..t n, (iteratedDerivWithin 2 f I x - iteratedDerivWithin 2 s I x) ^ 2) :=
    intervalIntegral.integral_nonneg hlt.le (fun u _ => sq_nonneg _)
  linarith

-- The card's whole-number arithmetic.
-- Diagonals 2 (h_(i-1) + h_i) of the rows for M3 … M6 (gaps 1, 3, 5, 10, 10).
example : (2 * (1 + 3), 2 * (3 + 5), 2 * (5 + 10), 2 * (10 + 10)) = (8, 16, 30, 40) := by decide
-- Row M6 is 10, 40, 10: the diagonal beats its neighbours by 20.
example : 40 - (10 + 10) = 20 := by decide
-- Flops for 7 gaps: n + 2n + 4(n-1) + (8(n-1) - 7) = 15n - 19 = 86.
example : 7 + 2 * 7 + 4 * (7 - 1) + (8 * (7 - 1) - 7) = 15 * 7 - 19 ∧ 15 * 7 - 19 = 86 := by decide
-- The dense road: 4 coefficients per gap, 28 unknowns for 7 gaps.
example : 4 * 7 = 28 := by decide

#print axioms natural_cubic_spline_exists_unique
#print axioms natural_spline_moments_solve_tridiagonal
#print axioms natural_spline_bends_least
