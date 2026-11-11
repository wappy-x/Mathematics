-- Numerical integration: on n equal slices of [a, b], the midpoint and trapezoid rules miss the integral by at most K₂(b - a)h^2/24 and K₂(b - a)h^2/12 when the second derivative exists with size at most K₂, and Simpson's rule (n even) by at most K₄(b - a)h^4/180 when the fourth derivative exists with size at most K₄.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum

open Set

theorem ni_integrate_bound {g g' : ℝ → ℝ} {r C : ℝ} (k : ℕ)
    (hg : ∀ t ∈ Icc 0 r, HasDerivWithinAt g (g' t) (Icc 0 r) t) (h0 : g 0 = 0)
    (hbd : ∀ t ∈ Icc 0 r, |g' t| ≤ C * t ^ k) :
    ∀ t ∈ Icc 0 r, |g t| ≤ C * t ^ (k + 1) / (k + 1) := by
  intro t ht
  have h0r : (0:ℝ) ∈ Icc 0 r := ⟨le_rfl, ht.1.trans ht.2⟩
  have hB : ∀ s : ℝ, HasDerivAt (fun t : ℝ => C * t ^ (k + 1) / (k + 1)) (C * s ^ k) s := by
    intro s
    have := ((hasDerivAt_pow (k + 1) s).const_mul C).div_const ((k : ℝ) + 1)
    convert this using 1
    have hk : (k : ℝ) + 1 ≠ 0 := by positivity
    field_simp
    push_cast
    ring
  have mono1 : MonotoneOn (fun t => C * t ^ (k + 1) / (k + 1) - g t) (Icc 0 r) := by
    apply monotoneOn_of_hasDerivWithinAt_nonneg (convex_Icc 0 r)
      (f' := fun t => C * t ^ k - g' t)
    · intro s hs
      exact ((hB s).continuousAt.continuousWithinAt).sub (hg s hs).continuousWithinAt
    · intro s hs
      rw [interior_Icc] at hs ⊢
      exact (hB s).hasDerivWithinAt.sub ((hg s (Ioo_subset_Icc_self hs)).mono Ioo_subset_Icc_self)
    · intro s hs
      rw [interior_Icc] at hs
      have h1 := hbd s (Ioo_subset_Icc_self hs)
      have h2 := le_abs_self (g' s)
      linarith
  have mono2 : MonotoneOn (fun t => C * t ^ (k + 1) / (k + 1) + g t) (Icc 0 r) := by
    apply monotoneOn_of_hasDerivWithinAt_nonneg (convex_Icc 0 r)
      (f' := fun t => C * t ^ k + g' t)
    · intro s hs
      exact ((hB s).continuousAt.continuousWithinAt).add (hg s hs).continuousWithinAt
    · intro s hs
      rw [interior_Icc] at hs ⊢
      exact (hB s).hasDerivWithinAt.add ((hg s (Ioo_subset_Icc_self hs)).mono Ioo_subset_Icc_self)
    · intro s hs
      rw [interior_Icc] at hs
      have h1 := hbd s (Ioo_subset_Icc_self hs)
      have h2 := neg_abs_le (g' s)
      linarith
  have e1 := mono1 h0r ht ht.1
  have e2 := mono2 h0r ht ht.1
  have z : C * (0:ℝ) ^ (k + 1) / (k + 1) = 0 := by simp
  dsimp only at e1 e2
  rw [h0, z] at e1 e2
  rw [abs_le]
  constructor <;> linarith

theorem ni_odd {G g : ℝ → ℝ} {a b c r : ℝ}
    (hG : ∀ x ∈ Icc a b, HasDerivWithinAt G (g x) (Icc a b) x) (h1 : a ≤ c - r) (h2 : c + r ≤ b) :
    ∀ t ∈ Icc 0 r, HasDerivWithinAt (fun t => G (c + t) - G (c - t))
      (g (c + t) + g (c - t)) (Icc 0 r) t := by
  intro t ht
  have hp : MapsTo (fun t => c + t) (Icc 0 r) (Icc a b) := fun s hs =>
    ⟨by linarith [hs.1, hs.2], by linarith [hs.1, hs.2]⟩
  have hm : MapsTo (fun t => c - t) (Icc 0 r) (Icc a b) := fun s hs =>
    ⟨by linarith [hs.1, hs.2], by linarith [hs.1, hs.2]⟩
  have d1 : HasDerivWithinAt (fun t => G (c + t)) (g (c + t)) (Icc 0 r) t := by
    have := (hG _ (hp ht)).comp t ((hasDerivWithinAt_id t (Icc 0 r)).const_add c) hp
    simpa [Function.comp_def] using this
  have d2 : HasDerivWithinAt (fun t => G (c - t)) (-g (c - t)) (Icc 0 r) t := by
    have := (hG _ (hm ht)).comp t ((hasDerivWithinAt_id t (Icc 0 r)).const_sub c) hm
    simpa [Function.comp_def] using this
  exact (d1.sub d2).congr_deriv (by ring)

theorem ni_even {G g : ℝ → ℝ} {a b c r : ℝ}
    (hG : ∀ x ∈ Icc a b, HasDerivWithinAt G (g x) (Icc a b) x) (h1 : a ≤ c - r) (h2 : c + r ≤ b) :
    ∀ t ∈ Icc 0 r, HasDerivWithinAt (fun t => G (c + t) + G (c - t))
      (g (c + t) - g (c - t)) (Icc 0 r) t := by
  intro t ht
  have hp : MapsTo (fun t => c + t) (Icc 0 r) (Icc a b) := fun s hs =>
    ⟨by linarith [hs.1, hs.2], by linarith [hs.1, hs.2]⟩
  have hm : MapsTo (fun t => c - t) (Icc 0 r) (Icc a b) := fun s hs =>
    ⟨by linarith [hs.1, hs.2], by linarith [hs.1, hs.2]⟩
  have d1 : HasDerivWithinAt (fun t => G (c + t)) (g (c + t)) (Icc 0 r) t := by
    have := (hG _ (hp ht)).comp t ((hasDerivWithinAt_id t (Icc 0 r)).const_add c) hp
    simpa [Function.comp_def] using this
  have d2 : HasDerivWithinAt (fun t => G (c - t)) (-g (c - t)) (Icc 0 r) t := by
    have := (hG _ (hm ht)).comp t ((hasDerivWithinAt_id t (Icc 0 r)).const_sub c) hm
    simpa [Function.comp_def] using this
  exact (d1.add d2).congr_deriv (by ring)

theorem ni_primitive {f : ℝ → ℝ} {a b : ℝ} (hf : ContinuousOn f (Icc a b)) :
    ∀ x ∈ Icc a b, HasDerivWithinAt (fun u => ∫ y in a..u, f y) (f x) (Icc a b) x := by
  intro x hx
  have : Fact (x ∈ Icc a b) := ⟨hx⟩
  have hint : IntervalIntegrable f MeasureTheory.volume a x :=
    (hf.mono (by rw [uIcc_of_le hx.1]; exact Icc_subset_Icc_right hx.2)).intervalIntegrable
  exact intervalIntegral.integral_hasDerivWithinAt_right hint
    (hf.stronglyMeasurableAtFilter_nhdsWithin measurableSet_Icc x) (hf x hx)

theorem ni_trap_sum (y : ℕ → ℝ) (m : ℕ) :
    ∑ i ∈ Finset.range (m + 1), (y i + y (i + 1)) / 2
      = y 0 / 2 + ∑ i ∈ Finset.Ico 1 (m + 1), y i + y (m + 1) / 2 := by
  induction m with
  | zero => simp; ring
  | succ k ih =>
    rw [Finset.sum_range_succ, ih, Finset.sum_Ico_succ_top (by omega : 1 ≤ k + 1)]
    ring

theorem ni_simp_sum (y : ℕ → ℝ) (m : ℕ) :
    ∑ j ∈ Finset.range (m + 1), (y (2 * j) + 4 * y (2 * j + 1) + y (2 * (j + 1)))
      = y 0 + ∑ i ∈ Finset.Ico 1 (2 * (m + 1)), (if i % 2 = 1 then (4 : ℝ) else 2) * y i
        + y (2 * (m + 1)) := by
  induction m with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_range_succ, ih, show 2 * (k + 1 + 1) = 2 * (k + 1) + 1 + 1 by ring,
      Finset.sum_Ico_succ_top (by omega), Finset.sum_Ico_succ_top (by omega)]
    have h1 : 2 * (k + 1) % 2 = 0 := by omega
    have h2 : (2 * (k + 1) + 1) % 2 = 1 := by omega
    simp only [h1, h2]
    norm_num
    ring

theorem ni_mid_slice {F f f' f'' : ℝ → ℝ} {a b K x h : ℝ} (hh : 0 ≤ h) (hx : a ≤ x)
    (hxh : x + h ≤ b)
    (hF : ∀ y ∈ Icc a b, HasDerivWithinAt F (f y) (Icc a b) y)
    (hf : ∀ y ∈ Icc a b, HasDerivWithinAt f (f' y) (Icc a b) y)
    (hf' : ∀ y ∈ Icc a b, HasDerivWithinAt f' (f'' y) (Icc a b) y)
    (hK : ∀ y ∈ Icc a b, |f'' y| ≤ K) :
    |F (x + h) - F x - h * f (x + h / 2)| ≤ K * h ^ 3 / 24 := by
  have h1 : a ≤ x + h / 2 - h / 2 := by linarith
  have h2 : x + h / 2 + h / 2 ≤ b := by linarith
  have hmem : ∀ t ∈ Icc 0 (h / 2), x + h / 2 + t ∈ Icc a b ∧ x + h / 2 - t ∈ Icc a b :=
    fun t ht => ⟨⟨by linarith [ht.1, ht.2], by linarith [ht.1, ht.2]⟩,
      ⟨by linarith [ht.1, ht.2], by linarith [ht.1, ht.2]⟩⟩
  have s1 := ni_integrate_bound (g := fun t => f' (x + h / 2 + t) - f' (x + h / 2 - t))
    (g' := fun t => f'' (x + h / 2 + t) + f'' (x + h / 2 - t)) (C := 2 * K) 0
    (ni_odd hf' h1 h2) (by simp) (fun t ht => by
      obtain ⟨m1, m2⟩ := hmem t ht
      have := abs_add_le (f'' (x + h / 2 + t)) (f'' (x + h / 2 - t))
      simp only [pow_zero, mul_one]
      linarith [hK _ m1, hK _ m2])
  have s2 := ni_integrate_bound
    (g := fun t => f (x + h / 2 + t) + f (x + h / 2 - t) - 2 * f (x + h / 2))
    (g' := fun t => f' (x + h / 2 + t) - f' (x + h / 2 - t)) (C := 2 * K) 1
    (fun t ht => (ni_even hf h1 h2 t ht).sub_const _) (by simp; ring)
    (fun t ht => (s1 t ht).trans_eq (by push_cast; ring))
  have s3 := ni_integrate_bound
    (g := fun t => F (x + h / 2 + t) - F (x + h / 2 - t) - 2 * t * f (x + h / 2))
    (g' := fun t => f (x + h / 2 + t) + f (x + h / 2 - t) - 2 * f (x + h / 2)) (C := K) 2
    (fun t ht => ((ni_odd hF h1 h2 t ht).sub
      (((hasDerivWithinAt_id t (Icc 0 (h / 2))).const_mul 2).mul_const
        (f (x + h / 2)))).congr_deriv (by ring)) (by simp)
    (fun t ht => (s2 t ht).trans_eq (by push_cast; ring))
  have := s3 (h / 2) ⟨by linarith, le_rfl⟩
  rw [show x + h / 2 + h / 2 = x + h by ring, show x + h / 2 - h / 2 = x by ring,
    show 2 * (h / 2) = h by ring] at this
  exact this.trans_eq (by push_cast; ring)

theorem ni_trap_slice {F f f' f'' : ℝ → ℝ} {a b K x h : ℝ} (hh : 0 ≤ h) (hx : a ≤ x)
    (hxh : x + h ≤ b)
    (hF : ∀ y ∈ Icc a b, HasDerivWithinAt F (f y) (Icc a b) y)
    (hf : ∀ y ∈ Icc a b, HasDerivWithinAt f (f' y) (Icc a b) y)
    (hf' : ∀ y ∈ Icc a b, HasDerivWithinAt f' (f'' y) (Icc a b) y)
    (hK : ∀ y ∈ Icc a b, |f'' y| ≤ K) :
    |F (x + h) - F x - h * ((f x + f (x + h)) / 2)| ≤ K * h ^ 3 / 12 := by
  have h1 : a ≤ x + h / 2 - h / 2 := by linarith
  have h2 : x + h / 2 + h / 2 ≤ b := by linarith
  have hmem : ∀ t ∈ Icc 0 (h / 2), x + h / 2 + t ∈ Icc a b ∧ x + h / 2 - t ∈ Icc a b :=
    fun t ht => ⟨⟨by linarith [ht.1, ht.2], by linarith [ht.1, ht.2]⟩,
      ⟨by linarith [ht.1, ht.2], by linarith [ht.1, ht.2]⟩⟩
  have s1 := ni_integrate_bound (g := fun t => f' (x + h / 2 + t) - f' (x + h / 2 - t))
    (g' := fun t => f'' (x + h / 2 + t) + f'' (x + h / 2 - t)) (C := 2 * K) 0
    (ni_odd hf' h1 h2) (by simp) (fun t ht => by
      obtain ⟨m1, m2⟩ := hmem t ht
      have := abs_add_le (f'' (x + h / 2 + t)) (f'' (x + h / 2 - t))
      simp only [pow_zero, mul_one]
      linarith [hK _ m1, hK _ m2])
  have s3 := ni_integrate_bound
    (g := fun t => F (x + h / 2 + t) - F (x + h / 2 - t)
      - t * (f (x + h / 2 + t) + f (x + h / 2 - t)))
    (g' := fun t => -(t * (f' (x + h / 2 + t) - f' (x + h / 2 - t)))) (C := 2 * K) 2
    (fun t ht => ((ni_odd hF h1 h2 t ht).sub
      ((hasDerivWithinAt_id t (Icc 0 (h / 2))).mul
        (ni_even hf h1 h2 t ht))).congr_deriv (by (try simp only [id_eq]); ring)) (by simp)
    (fun t ht => by
      rw [abs_neg, abs_mul, abs_of_nonneg ht.1]
      calc t * |f' (x + h / 2 + t) - f' (x + h / 2 - t)|
          ≤ t * (2 * K * t ^ (0 + 1) / ((0 : ℕ) + 1)) :=
            mul_le_mul_of_nonneg_left (s1 t ht) ht.1
        _ = 2 * K * t ^ 2 := by push_cast; ring)
  have := s3 (h / 2) ⟨by linarith, le_rfl⟩
  rw [show x + h / 2 + h / 2 = x + h by ring, show x + h / 2 - h / 2 = x by ring] at this
  calc |F (x + h) - F x - h * ((f x + f (x + h)) / 2)|
      = |F (x + h) - F x - h / 2 * (f (x + h) + f x)| := by congr 1; ring
    _ ≤ _ := this
    _ = _ := by push_cast; ring

theorem ni_simpson_slice {F f f₁ f₂ f₃ f₄ : ℝ → ℝ} {a b K x h : ℝ} (hh : 0 ≤ h) (hx : a ≤ x)
    (hxh : x + 2 * h ≤ b)
    (hF : ∀ y ∈ Icc a b, HasDerivWithinAt F (f y) (Icc a b) y)
    (hf : ∀ y ∈ Icc a b, HasDerivWithinAt f (f₁ y) (Icc a b) y)
    (hf₁ : ∀ y ∈ Icc a b, HasDerivWithinAt f₁ (f₂ y) (Icc a b) y)
    (hf₂ : ∀ y ∈ Icc a b, HasDerivWithinAt f₂ (f₃ y) (Icc a b) y)
    (hf₃ : ∀ y ∈ Icc a b, HasDerivWithinAt f₃ (f₄ y) (Icc a b) y)
    (hK : ∀ y ∈ Icc a b, |f₄ y| ≤ K) :
    |F (x + 2 * h) - F x - h / 3 * (f x + 4 * f (x + h) + f (x + 2 * h))| ≤ K * h ^ 5 / 90 := by
  have h1 : a ≤ x + h - h := by linarith
  have h2 : x + h + h ≤ b := by linarith
  have hmem : ∀ t ∈ Icc 0 h, x + h + t ∈ Icc a b ∧ x + h - t ∈ Icc a b :=
    fun t ht => ⟨⟨by linarith [ht.1, ht.2], by linarith [ht.1, ht.2]⟩,
      ⟨by linarith [ht.1, ht.2], by linarith [ht.1, ht.2]⟩⟩
  have s1 := ni_integrate_bound (g := fun t => f₃ (x + h + t) - f₃ (x + h - t))
    (g' := fun t => f₄ (x + h + t) + f₄ (x + h - t)) (C := 2 * K) 0
    (ni_odd hf₃ h1 h2) (by simp) (fun t ht => by
      obtain ⟨m1, m2⟩ := hmem t ht
      have := abs_add_le (f₄ (x + h + t)) (f₄ (x + h - t))
      simp only [pow_zero, mul_one]
      linarith [hK _ m1, hK _ m2])
  have s2 := ni_integrate_bound
    (g := fun t => 1 / 3 * (f₁ (x + h + t) - f₁ (x + h - t))
      - t / 3 * (f₂ (x + h + t) + f₂ (x + h - t)))
    (g' := fun t => -(t / 3 * (f₃ (x + h + t) - f₃ (x + h - t)))) (C := 2 * K / 3) 2
    (fun t ht => (((ni_odd hf₁ h1 h2 t ht).const_mul (1 / 3)).sub
      (((hasDerivWithinAt_id t (Icc 0 h)).div_const 3).mul
        (ni_even hf₂ h1 h2 t ht))).congr_deriv (by (try simp only [id_eq]); ring)) (by simp)
    (fun t ht => by
      rw [abs_neg, abs_mul, abs_div, abs_of_nonneg ht.1, abs_of_pos (by norm_num : (0:ℝ) < 3)]
      calc t / 3 * |f₃ (x + h + t) - f₃ (x + h - t)|
          ≤ t / 3 * (2 * K * t ^ (0 + 1) / ((0 : ℕ) + 1)) :=
            mul_le_mul_of_nonneg_left (s1 t ht) (by linarith [ht.1])
        _ = 2 * K / 3 * t ^ 2 := by push_cast; ring)
  have s3 := ni_integrate_bound
    (g := fun t => 2 / 3 * (f (x + h + t) + f (x + h - t)) - 4 / 3 * f (x + h)
      - t / 3 * (f₁ (x + h + t) - f₁ (x + h - t)))
    (g' := fun t => 1 / 3 * (f₁ (x + h + t) - f₁ (x + h - t))
      - t / 3 * (f₂ (x + h + t) + f₂ (x + h - t))) (C := 2 * K / 9) 3
    (fun t ht => ((((ni_even hf h1 h2 t ht).const_mul (2 / 3)).sub_const (4 / 3 * f (x + h))).sub
      (((hasDerivWithinAt_id t (Icc 0 h)).div_const 3).mul
        (ni_odd hf₁ h1 h2 t ht))).congr_deriv (by (try simp only [id_eq]); ring)) (by simp; ring)
    (fun t ht => (s2 t ht).trans_eq (by push_cast; ring))
  have s4 := ni_integrate_bound
    (g := fun t => F (x + h + t) - F (x + h - t) - t / 3 * (f (x + h + t) + f (x + h - t))
      - 4 / 3 * t * f (x + h))
    (g' := fun t => 2 / 3 * (f (x + h + t) + f (x + h - t)) - 4 / 3 * f (x + h)
      - t / 3 * (f₁ (x + h + t) - f₁ (x + h - t))) (C := K / 18) 4
    (fun t ht => (((ni_odd hF h1 h2 t ht).sub
      (((hasDerivWithinAt_id t (Icc 0 h)).div_const 3).mul
        (ni_even hf h1 h2 t ht))).sub
      (((hasDerivWithinAt_id t (Icc 0 h)).const_mul (4 / 3)).mul_const
        (f (x + h)))).congr_deriv (by (try simp only [id_eq]); ring)) (by simp)
    (fun t ht => (s3 t ht).trans_eq (by push_cast; ring))
  have := s4 h ⟨hh, le_rfl⟩
  rw [show x + h + h = x + 2 * h by ring, show x + h - h = x by ring] at this
  calc |F (x + 2 * h) - F x - h / 3 * (f x + 4 * f (x + h) + f (x + 2 * h))|
      = |F (x + 2 * h) - F x - h / 3 * (f (x + 2 * h) + f x) - 4 / 3 * h * f (x + h)| := by
        congr 1; ring
    _ ≤ _ := this
    _ = _ := by push_cast; ring

#print axioms ni_integrate_bound
#print axioms ni_odd
#print axioms ni_even
#print axioms ni_primitive
#print axioms ni_trap_sum
#print axioms ni_simp_sum
#print axioms ni_mid_slice
#print axioms ni_trap_slice
#print axioms ni_simpson_slice

/-- **Midpoint rule error bound.** Cut [a, b] into n equal slices of width h = (b - a)/n and
let M_n = h · (f(a + h/2) + f(a + 3h/2) + ... + f(b - h/2)), the centre heights times the width.
If f has a first derivative f' and a second derivative f'' at every point of [a, b] (one-sided
at the two ends) and the size of f'' never exceeds K₂ there, then the integral of f from a to b
differs from M_n by at most K₂ (b - a) h^2 / 24. -/
theorem midpoint_rule_error_bound (f f' f'' : ℝ → ℝ) (a b K₂ : ℝ) (n : ℕ)
    (hab : a ≤ b) (hn : 0 < n)
    (hf : ∀ x ∈ Icc a b, HasDerivWithinAt f (f' x) (Icc a b) x)
    (hf' : ∀ x ∈ Icc a b, HasDerivWithinAt f' (f'' x) (Icc a b) x)
    (hK : ∀ x ∈ Icc a b, |f'' x| ≤ K₂) :
    |(∫ x in a..b, f x) -
        (b - a) / n * ∑ i ∈ Finset.range n, f (a + ((i : ℝ) + 1 / 2) * ((b - a) / n))|
      ≤ K₂ * (b - a) * ((b - a) / n) ^ 2 / 24 := by
  have hF := ni_primitive (fun x hx => (hf x hx).continuousWithinAt)
  set F : ℝ → ℝ := fun u => ∫ y in a..u, f y with hFdef
  set h := (b - a) / n with hhdef
  have hn' : (0 : ℝ) < n := Nat.cast_pos.2 hn
  have hh : 0 ≤ h := div_nonneg (sub_nonneg.2 hab) hn'.le
  have hnh : (n : ℝ) * h = b - a := by rw [hhdef]; field_simp
  have htel : (∫ x in a..b, f x)
      = ∑ i ∈ Finset.range n, (F (a + ((i + 1 : ℕ) : ℝ) * h) - F (a + (i : ℝ) * h)) := by
    have := Finset.sum_range_sub (fun i : ℕ => F (a + (i : ℝ) * h)) n
    rw [this, show a + (n : ℝ) * h = b by rw [hnh]; ring]
    simp [hFdef]
  rw [htel, Finset.mul_sum, ← Finset.sum_sub_distrib]
  refine (Finset.abs_sum_le_sum_abs _ _).trans ?_
  have hterm : ∀ i ∈ Finset.range n, |F (a + ((i + 1 : ℕ) : ℝ) * h) - F (a + (i : ℝ) * h)
      - h * f (a + ((i : ℝ) + 1 / 2) * h)| ≤ K₂ * h ^ 3 / 24 := by
    intro i hi
    have hi' : (i : ℝ) + 1 ≤ n := by exact_mod_cast Finset.mem_range.1 hi
    have hx : a ≤ a + i * h := by have : 0 ≤ (i : ℝ) * h := by positivity
                                  linarith
    have hxh : a + i * h + h ≤ b := by nlinarith [mul_le_mul_of_nonneg_right hi' hh]
    have := ni_mid_slice hh hx hxh hF hf hf' hK
    rwa [show a + (i : ℝ) * h + h / 2 = a + ((i : ℝ) + 1 / 2) * h by ring,
      show a + (i : ℝ) * h + h = a + ((i + 1 : ℕ) : ℝ) * h by push_cast; ring] at this
  refine (Finset.sum_le_sum hterm).trans (le_of_eq ?_)
  rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul, ← hnh]
  ring

/-- **Trapezoid rule error bound.** Cut [a, b] into n equal slices of width h = (b - a)/n at the
points x_i = a + i h, and let T_n = h · (f(x_0)/2 + f(x_1) + ... + f(x_{n-1}) + f(x_n)/2), the
cut heights with the two ends halved. If f has a first derivative f' and a second derivative f''
at every point of [a, b] (one-sided at the two ends) and the size of f'' never exceeds K₂ there,
then the integral of f from a to b differs from T_n by at most K₂ (b - a) h^2 / 12. -/
theorem trapezoid_rule_error_bound (f f' f'' : ℝ → ℝ) (a b K₂ : ℝ) (n : ℕ)
    (hab : a ≤ b) (hn : 0 < n)
    (hf : ∀ x ∈ Icc a b, HasDerivWithinAt f (f' x) (Icc a b) x)
    (hf' : ∀ x ∈ Icc a b, HasDerivWithinAt f' (f'' x) (Icc a b) x)
    (hK : ∀ x ∈ Icc a b, |f'' x| ≤ K₂) :
    |(∫ x in a..b, f x) -
        (b - a) / n * (f a / 2 + ∑ i ∈ Finset.Ico 1 n, f (a + (i : ℝ) * ((b - a) / n)) + f b / 2)|
      ≤ K₂ * (b - a) * ((b - a) / n) ^ 2 / 12 := by
  have hF := ni_primitive (fun x hx => (hf x hx).continuousWithinAt)
  set F : ℝ → ℝ := fun u => ∫ y in a..u, f y with hFdef
  set h := (b - a) / n with hhdef
  have hn' : (0 : ℝ) < n := Nat.cast_pos.2 hn
  have hh : 0 ≤ h := div_nonneg (sub_nonneg.2 hab) hn'.le
  have hnh : (n : ℝ) * h = b - a := by rw [hhdef]; field_simp
  have htel : (∫ x in a..b, f x)
      = ∑ i ∈ Finset.range n, (F (a + ((i + 1 : ℕ) : ℝ) * h) - F (a + (i : ℝ) * h)) := by
    have := Finset.sum_range_sub (fun i : ℕ => F (a + (i : ℝ) * h)) n
    rw [this, show a + (n : ℝ) * h = b by rw [hnh]; ring]
    simp [hFdef]
  obtain ⟨m, hm⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  have alg := ni_trap_sum (fun i : ℕ => f (a + (i : ℝ) * h)) m
  rw [← hm, show a + ((0 : ℕ) : ℝ) * h = a by simp,
    show a + (n : ℝ) * h = b by rw [hnh]; ring] at alg
  rw [← alg, htel, Finset.mul_sum, ← Finset.sum_sub_distrib]
  refine (Finset.abs_sum_le_sum_abs _ _).trans ?_
  have hterm : ∀ i ∈ Finset.range n, |F (a + ((i + 1 : ℕ) : ℝ) * h) - F (a + (i : ℝ) * h)
      - h * ((f (a + (i : ℝ) * h) + f (a + ((i + 1 : ℕ) : ℝ) * h)) / 2)| ≤ K₂ * h ^ 3 / 12 := by
    intro i hi
    have hi' : (i : ℝ) + 1 ≤ n := by exact_mod_cast Finset.mem_range.1 hi
    have hx : a ≤ a + i * h := by have : 0 ≤ (i : ℝ) * h := by positivity
                                  linarith
    have hxh : a + i * h + h ≤ b := by nlinarith [mul_le_mul_of_nonneg_right hi' hh]
    have := ni_trap_slice hh hx hxh hF hf hf' hK
    rwa [show a + (i : ℝ) * h + h = a + ((i + 1 : ℕ) : ℝ) * h by push_cast; ring] at this
  refine (Finset.sum_le_sum hterm).trans (le_of_eq ?_)
  rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul, ← hnh]
  ring

/-- **Simpson's rule error bound.** Cut [a, b] into an even number n of equal slices of width
h = (b - a)/n at the points x_i = a + i h, and let
S_n = (h/3) · (f(x_0) + 4 f(x_1) + 2 f(x_2) + ... + 4 f(x_{n-1}) + f(x_n)), the inside heights
weighted 4 at odd i and 2 at even i. If f has derivatives f', f'', f''' and a fourth derivative
f'''' at every point of [a, b] (one-sided at the two ends) and the size of f'''' never exceeds
K₄ there, then the integral of f from a to b differs from S_n by at most K₄ (b - a) h^4 / 180. -/
theorem simpson_rule_error_bound (f f₁ f₂ f₃ f₄ : ℝ → ℝ) (a b K₄ : ℝ) (n : ℕ)
    (hab : a ≤ b) (hn : 0 < n) (heven : Even n)
    (hf : ∀ x ∈ Icc a b, HasDerivWithinAt f (f₁ x) (Icc a b) x)
    (hf₁ : ∀ x ∈ Icc a b, HasDerivWithinAt f₁ (f₂ x) (Icc a b) x)
    (hf₂ : ∀ x ∈ Icc a b, HasDerivWithinAt f₂ (f₃ x) (Icc a b) x)
    (hf₃ : ∀ x ∈ Icc a b, HasDerivWithinAt f₃ (f₄ x) (Icc a b) x)
    (hK : ∀ x ∈ Icc a b, |f₄ x| ≤ K₄) :
    |(∫ x in a..b, f x) -
        (b - a) / n / 3 * (f a + ∑ i ∈ Finset.Ico 1 n,
          (if i % 2 = 1 then (4 : ℝ) else 2) * f (a + (i : ℝ) * ((b - a) / n)) + f b)|
      ≤ K₄ * (b - a) * ((b - a) / n) ^ 4 / 180 := by
  have hF := ni_primitive (fun x hx => (hf x hx).continuousWithinAt)
  set F : ℝ → ℝ := fun u => ∫ y in a..u, f y with hFdef
  set h := (b - a) / n with hhdef
  have hn' : (0 : ℝ) < n := Nat.cast_pos.2 hn
  have hh : 0 ≤ h := div_nonneg (sub_nonneg.2 hab) hn'.le
  have hnh : (n : ℝ) * h = b - a := by rw [hhdef]; field_simp
  obtain ⟨m, hm⟩ : ∃ m, n = 2 * (m + 1) := by
    obtain ⟨k, hk⟩ := heven
    exact ⟨k - 1, by omega⟩
  have htel : (∫ x in a..b, f x)
      = ∑ j ∈ Finset.range (m + 1),
          (F (a + ((2 * (j + 1) : ℕ) : ℝ) * h) - F (a + ((2 * j : ℕ) : ℝ) * h)) := by
    have := Finset.sum_range_sub (fun j : ℕ => F (a + ((2 * j : ℕ) : ℝ) * h)) (m + 1)
    rw [this, ← hm, show a + (n : ℝ) * h = b by rw [hnh]; ring]
    simp [hFdef]
  have alg := ni_simp_sum (fun i : ℕ => f (a + (i : ℝ) * h)) m
  rw [← hm, show a + ((0 : ℕ) : ℝ) * h = a by simp,
    show a + (n : ℝ) * h = b by rw [hnh]; ring] at alg
  rw [← alg, htel, Finset.mul_sum, ← Finset.sum_sub_distrib]
  refine (Finset.abs_sum_le_sum_abs _ _).trans ?_
  have hterm : ∀ j ∈ Finset.range (m + 1),
      |F (a + ((2 * (j + 1) : ℕ) : ℝ) * h) - F (a + ((2 * j : ℕ) : ℝ) * h)
        - h / 3 * (f (a + ((2 * j : ℕ) : ℝ) * h) + 4 * f (a + ((2 * j + 1 : ℕ) : ℝ) * h)
          + f (a + ((2 * (j + 1) : ℕ) : ℝ) * h))| ≤ K₄ * h ^ 5 / 90 := by
    intro j hj
    have hj' : (2 * (j : ℝ) + 2) ≤ n := by
      have := Finset.mem_range.1 hj
      rw [hm]; push_cast; have : (j : ℝ) + 1 ≤ m + 1 := by exact_mod_cast this
      linarith
    have hx : a ≤ a + ((2 * j : ℕ) : ℝ) * h := by
      have : 0 ≤ ((2 * j : ℕ) : ℝ) * h := by positivity
      linarith
    have hxh : a + ((2 * j : ℕ) : ℝ) * h + 2 * h ≤ b := by
      push_cast; nlinarith [mul_le_mul_of_nonneg_right hj' hh]
    have := ni_simpson_slice hh hx hxh hF hf hf₁ hf₂ hf₃ hK
    rwa [show a + ((2 * j : ℕ) : ℝ) * h + 2 * h = a + ((2 * (j + 1) : ℕ) : ℝ) * h by
        push_cast; ring,
      show a + ((2 * j : ℕ) : ℝ) * h + h = a + ((2 * j + 1 : ℕ) : ℝ) * h by
        push_cast; ring] at this
  refine (Finset.sum_le_sum hterm).trans (le_of_eq ?_)
  rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul, ← hnh, hm]
  push_cast
  ring

-- The tank: filling at 3 + 2t litres per minute for 10 minutes, so 30 + 100 = 130 litres.
example : ∫ t in (0 : ℝ)..10, (3 + 2 * t) = 130 := by
  rw [intervalIntegral.integral_add intervalIntegrable_const
    (intervalIntegral.intervalIntegrable_id.const_mul 2), intervalIntegral.integral_const_mul,
    integral_id]
  norm_num
-- With n = 10 slices (h = 1), the midpoint, trapezoid and Simpson sums all give 130 litres.
example : (1 : ℚ) * ∑ i ∈ Finset.range 10, (3 + 2 * (0 + ((i : ℚ) + 1 / 2) * 1)) = 130 := by
  norm_num [Finset.sum_range_succ]
example : (1 : ℚ) * ((3 + 2 * 0) / 2 + ∑ i ∈ Finset.Ico (1 : ℕ) 10, (3 + 2 * (0 + (i : ℚ) * 1))
    + (3 + 2 * 10) / 2) = 130 := by
  norm_num [Finset.sum_Ico_eq_sum_range, Finset.sum_range_succ]
example : (1 : ℚ) / 3 * ((3 + 2 * 0) + ∑ i ∈ Finset.Ico (1 : ℕ) 10,
    (if i % 2 = 1 then (4 : ℚ) else 2) * (3 + 2 * (0 + (i : ℚ) * 1)) + (3 + 2 * 10)) = 130 := by
  norm_num [Finset.sum_Ico_eq_sum_range, Finset.sum_range_succ]
-- Simpson's weights on one pair of slices with h = 1 (t from -1 to 1, weights 1/3, 4/3, 1/3):
-- they give the true areas 2, 0, 2/3 and 0 for 1, t, t^2 and t^3.
example : (1 : ℚ) / 3 * (1 + 4 * 1 + 1) = 2 := by norm_num
example : (1 : ℚ) / 3 * (-1 + 4 * 0 + 1) = 0 := by norm_num
example : (1 : ℚ) / 3 * ((-1) ^ 2 + 4 * 0 ^ 2 + 1 ^ 2) = 2 / 3 := by norm_num
example : (1 : ℚ) / 3 * ((-1) ^ 3 + 4 * 0 ^ 3 + 1 ^ 3) = 0 := by norm_num

#print axioms midpoint_rule_error_bound
#print axioms trapezoid_rule_error_bound
#print axioms simpson_rule_error_bound
