-- Greeks from a tree or grid: Taylor's theorem bounds how far the node delta and node gamma read off three neighbouring prices sit from the true slope and bend, the node gamma is exactly the curvature of the one parabola through the three unequally spaced prices, and a log-grid's slopes convert to dollar Greeks by C_S = U_x / S and C_SS = (U_xx - U_x) / S^2.
import Mathlib.Analysis.Calculus.Taylor
import Mathlib.Analysis.Calculus.IteratedDeriv.Lemmas
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Set Real

theorem taylor_two_sided_aux {f : ℝ → ℝ} {s t : ℝ} (n : ℕ) (hst : s ≠ t)
    (hf : ContDiffOn ℝ (n + 1) f (uIcc s t)) (hfs : ContDiffAt ℝ n f s) :
    ∃ x' ∈ uIoo s t, f t - ∑ k ∈ Finset.range (n + 1),
        ((Nat.factorial k : ℝ)⁻¹ * (t - s) ^ k) * iteratedDeriv k f s =
      iteratedDeriv (n + 1) f x' * (t - s) ^ (n + 1) / (Nat.factorial (n + 1) : ℝ) := by
  obtain ⟨x', hx', h⟩ := taylor_mean_remainder_lagrange_iteratedDeriv hst hf
  refine ⟨x', hx', ?_⟩
  rw [← h, taylor_within_apply]
  congr 1
  refine Finset.sum_congr rfl fun k hk => ?_
  rw [smul_eq_mul, iteratedDerivWithin_eq_iteratedDeriv (uniqueDiffOn_uIcc hst)
    (hfs.of_le (by exact_mod_cast Nat.lt_succ_iff.mp (Finset.mem_range.mp hk))) left_mem_uIcc]

theorem taylor_expand_in_Icc_aux {f : ℝ → ℝ} {a b s t B : ℝ} (n : ℕ) (hn : n + 1 ≤ 3)
    (hf : ContDiffOn ℝ 3 f (Icc a b)) (hs : s ∈ Ioo a b) (ht : t ∈ Icc a b) (hst : s ≠ t)
    (hB : ∀ x ∈ Icc a b, |iteratedDerivWithin (n + 1) f (Icc a b) x| ≤ B) :
    ∃ R : ℝ, |R| ≤ B ∧ f t - ∑ k ∈ Finset.range (n + 1),
        ((Nat.factorial k : ℝ)⁻¹ * (t - s) ^ k) * iteratedDeriv k f s =
      R * (t - s) ^ (n + 1) / (Nat.factorial (n + 1) : ℝ) := by
  have hsub : uIcc s t ⊆ Icc a b := uIcc_subset_Icc (Ioo_subset_Icc_self hs) ht
  have hn' : ((n + 1 : ℕ) : WithTop ℕ∞) ≤ 3 := by exact_mod_cast hn
  have hn'' : ((n : ℕ) : WithTop ℕ∞) ≤ 3 := by exact_mod_cast (by omega : n ≤ 3)
  obtain ⟨x', hx', h⟩ := taylor_two_sided_aux n hst ((hf.mono hsub).of_le hn')
    ((hf.contDiffAt (Icc_mem_nhds hs.1 hs.2)).of_le hn'')
  have ha : a ≤ s ⊓ t := le_inf hs.1.le ht.1
  have hb : s ⊔ t ≤ b := sup_le hs.2.le ht.2
  have hx'1 : a < x' := lt_of_le_of_lt ha hx'.1
  have hx'2 : x' < b := lt_of_lt_of_le hx'.2 hb
  refine ⟨iteratedDeriv (n + 1) f x', ?_, h⟩
  rw [← iteratedDerivWithin_eq_iteratedDeriv (uniqueDiffOn_Icc (hx'1.trans hx'2))
    ((hf.contDiffAt (Icc_mem_nhds hx'1 hx'2)).of_le hn') ⟨hx'1.le, hx'2.le⟩]
  exact hB x' ⟨hx'1.le, hx'2.le⟩

#print axioms taylor_two_sided_aux
#print axioms taylor_expand_in_Icc_aux

/-- **The node readings sit within Taylor's bounds of the true slope and bend.** Three nodes
on one date hold the option's worth at stock prices s - h₋, s and s + h₊, with gaps
h₋ > 0 and h₊ > 0 (unequal, as on any tree). The true same-date price curve f has three
continuous derivatives across the interval [s - h₋, s + h₊] holding all three prices, and there
|f''| ≤ B₂ and |f'''| ≤ B₃ (derivatives taken within that interval, since nothing is assumed
outside it). The chord reading (f(s + h₊) - f(s - h₋)) / (h₊ + h₋) differs from the true slope
f'(s) by at most B₂ (h₊² + h₋²) / (2 (h₊ + h₋)), and the node gamma
2 / (h₊ + h₋) · ((f(s + h₊) - f(s)) / h₊ - (f(s) - f(s - h₋)) / h₋) differs from the true bend
f''(s) by at most B₃ (h₊² + h₋²) / (3 (h₊ + h₋)). -/
theorem node_greeks_within_taylor_bounds {f : ℝ → ℝ} {s hm hp B₂ B₃ : ℝ}
    (hhm : 0 < hm) (hhp : 0 < hp)
    (hf : ContDiffOn ℝ 3 f (Icc (s - hm) (s + hp)))
    (hB₂ : ∀ x ∈ Icc (s - hm) (s + hp), |iteratedDerivWithin 2 f (Icc (s - hm) (s + hp)) x| ≤ B₂)
    (hB₃ : ∀ x ∈ Icc (s - hm) (s + hp), |iteratedDerivWithin 3 f (Icc (s - hm) (s + hp)) x| ≤ B₃) :
    |(f (s + hp) - f (s - hm)) / (hp + hm) - deriv f s|
        ≤ B₂ * (hp ^ 2 + hm ^ 2) / (2 * (hp + hm)) ∧
      |2 / (hp + hm) * ((f (s + hp) - f s) / hp - (f s - f (s - hm)) / hm) - deriv (deriv f) s|
        ≤ B₃ * (hp ^ 2 + hm ^ 2) / (3 * (hp + hm)) := by
  have hs : s ∈ Ioo (s - hm) (s + hp) := ⟨by linarith, by linarith⟩
  have htp : s + hp ∈ Icc (s - hm) (s + hp) := ⟨by linarith, le_rfl⟩
  have htm : s - hm ∈ Icc (s - hm) (s + hp) := ⟨le_rfl, by linarith⟩
  have hnp : s ≠ s + hp := by intro h; linarith
  have hnm : s ≠ s - hm := by intro h; linarith
  obtain ⟨A1, hA1, e1⟩ := taylor_expand_in_Icc_aux 1 (by norm_num) hf hs htp hnp hB₂
  obtain ⟨A2, hA2, e2⟩ := taylor_expand_in_Icc_aux 1 (by norm_num) hf hs htm hnm hB₂
  obtain ⟨C1, hC1, e3⟩ := taylor_expand_in_Icc_aux 2 (by norm_num) hf hs htp hnp hB₃
  obtain ⟨C2, hC2, e4⟩ := taylor_expand_in_Icc_aux 2 (by norm_num) hf hs htm hnm hB₃
  simp only [Finset.sum_range_succ, Finset.sum_range_zero, iteratedDeriv_zero,
    iteratedDeriv_succ, Nat.factorial] at e1 e2 e3 e4
  norm_num at e1 e2 e3 e4
  set d1 := deriv f s
  set d2 := deriv (deriv f) s
  have hpm : 0 < hp + hm := by linarith
  constructor
  · have key : (f (s + hp) - f (s - hm)) / (hp + hm) - d1
        = (A1 * hp ^ 2 - A2 * hm ^ 2) / (2 * (hp + hm)) := by
      field_simp
      linear_combination (2:ℝ) * e1 - 2 * e2
    rw [key, abs_div, abs_of_pos (by positivity : (0:ℝ) < 2 * (hp + hm))]
    apply div_le_div_of_nonneg_right _ (by positivity)
    calc |A1 * hp ^ 2 - A2 * hm ^ 2| ≤ |A1 * hp ^ 2| + |A2 * hm ^ 2| := abs_sub _ _
      _ = |A1| * hp ^ 2 + |A2| * hm ^ 2 := by
          rw [abs_mul, abs_mul, abs_of_nonneg (sq_nonneg hp), abs_of_nonneg (sq_nonneg hm)]
      _ ≤ B₂ * hp ^ 2 + B₂ * hm ^ 2 := by gcongr
      _ = B₂ * (hp ^ 2 + hm ^ 2) := by ring
  · have key : 2 / (hp + hm) * ((f (s + hp) - f s) / hp - (f s - f (s - hm)) / hm) - d2
        = (C1 * hp ^ 2 - C2 * hm ^ 2) / (3 * (hp + hm)) := by
      have F1 : f (s + hp) = f s + hp * d1 + 1 / 2 * hp ^ 2 * d2 + C1 * hp ^ 3 / 6 := by
        linarith
      have F2 : f (s - hm) = f s - hm * d1 + 1 / 2 * hm ^ 2 * d2 - C2 * hm ^ 3 / 6 := by
        have : (-hm) ^ 3 = -hm ^ 3 := by ring
        rw [this] at e4
        linarith
      rw [F1, F2]
      field_simp
      ring
    rw [key, abs_div, abs_of_pos (by positivity : (0:ℝ) < 3 * (hp + hm))]
    apply div_le_div_of_nonneg_right _ (by positivity)
    calc |C1 * hp ^ 2 - C2 * hm ^ 2| ≤ |C1 * hp ^ 2| + |C2 * hm ^ 2| := abs_sub _ _
      _ = |C1| * hp ^ 2 + |C2| * hm ^ 2 := by
          rw [abs_mul, abs_mul, abs_of_nonneg (sq_nonneg hp), abs_of_nonneg (sq_nonneg hm)]
      _ ≤ B₃ * hp ^ 2 + B₃ * hm ^ 2 := by gcongr
      _ = B₃ * (hp ^ 2 + hm ^ 2) := by ring

/-- **Three prices fix one parabola, and its bend is the node gamma.** Put the middle node at
the origin and measure sideways in dollars, with gaps h₋ > 0 below and h₊ > 0 above. For any
three prices v₋, v₀, v₊ there is exactly one parabola a + b x + c x² passing through
(-h₋, v₋), (0, v₀) and (h₊, v₊). Its curvature 2c equals the node gamma
2 / (h₊ + h₋) · ((v₊ - v₀) / h₊ - (v₀ - v₋) / h₋), and the chord slope (v₊ - v₋) / (h₊ + h₋)
equals b + c (h₊ - h₋). -/
theorem node_gamma_is_curvature_of_unique_parabola (vm v0 vp hm hp : ℝ)
    (hhm : 0 < hm) (hhp : 0 < hp) :
    (∃! p : ℝ × ℝ × ℝ,
        p.1 + p.2.1 * (-hm) + p.2.2 * (-hm) ^ 2 = vm ∧
        p.1 + p.2.1 * 0 + p.2.2 * 0 ^ 2 = v0 ∧
        p.1 + p.2.1 * hp + p.2.2 * hp ^ 2 = vp) ∧
      ∀ a b c : ℝ,
        a + b * (-hm) + c * (-hm) ^ 2 = vm →
        a + b * 0 + c * 0 ^ 2 = v0 →
        a + b * hp + c * hp ^ 2 = vp →
        2 * c = 2 / (hp + hm) * ((vp - v0) / hp - (v0 - vm) / hm) ∧
          (vp - vm) / (hp + hm) = b + c * (hp - hm) := by
  have hpm : 0 < hp + hm := by linarith
  have hne : hp + hm ≠ 0 := hpm.ne'
  have hpne : hp ≠ 0 := hhp.ne'
  have hmne : hm ≠ 0 := hhm.ne'
  -- the explicit solution
  set c : ℝ := 1 / (hp + hm) * ((vp - v0) / hp - (v0 - vm) / hm) with hc
  set b : ℝ := (vp - vm) / (hp + hm) - c * (hp - hm) with hb
  have key : ∀ a b' c' : ℝ,
      a + b' * (-hm) + c' * (-hm) ^ 2 = vm →
      a + b' * 0 + c' * 0 ^ 2 = v0 →
      a + b' * hp + c' * hp ^ 2 = vp →
      a = v0 ∧ c' = c ∧ b' = b := by
    intro a b' c' h1 h2 h3
    have ha : a = v0 := by simpa using h2
    subst ha
    have hc' : c' = c := by
      rw [hc]
      field_simp
      linear_combination hm * h3 + hp * h1
    refine ⟨rfl, hc', ?_⟩
    rw [hb, ← hc']
    field_simp
    linear_combination h3 - h1
  refine ⟨⟨(v0, b, c), ?_, ?_⟩, ?_⟩
  · refine ⟨?_, by simp, ?_⟩
    · simp only [hb, hc]
      field_simp
      ring
    · simp only [hb, hc]
      field_simp
      ring
  · rintro ⟨a', b', c'⟩ ⟨h1, h2, h3⟩
    obtain ⟨rfl, rfl, rfl⟩ := key a' b' c' h1 h2 h3
    rfl
  · intro a b' c' h1 h2 h3
    obtain ⟨rfl, rfl, rfl⟩ := key a b' c' h1 h2 h3
    refine ⟨?_, ?_⟩
    · rw [hc]; ring
    · rw [hb]; ring

/-- **The log-grid conversion.** A grid stores the price against x = ln(S / 100), so its worth
at x is U(x) = C(100 e^x), where C is the option's price as a function of the stock price S.
If C has two continuous derivatives at every positive stock price, then at S = 100 e^x the
dollar delta is the grid slope divided by the price, C'(S) = U'(x) / S, and the dollar gamma is
the grid bend minus the grid slope, divided by the price twice, C''(S) = (U''(x) - U'(x)) / S². -/
theorem log_grid_greeks_conversion {C : ℝ → ℝ} (hC : ContDiffOn ℝ 2 C (Ioi 0)) (x : ℝ) :
    deriv C (100 * exp x) = deriv (fun y => C (100 * exp y)) x / (100 * exp x) ∧
      deriv (deriv C) (100 * exp x) =
        (deriv (deriv fun y => C (100 * exp y)) x - deriv (fun y => C (100 * exp y)) x) /
          (100 * exp x) ^ 2 := by
  have hpos : ∀ y : ℝ, 0 < 100 * exp y := fun y => by positivity
  have hCat : ∀ y : ℝ, ContDiffAt ℝ 2 C (100 * exp y) := fun y =>
    hC.contDiffAt (Ioi_mem_nhds (hpos y))
  have hS : ∀ y : ℝ, HasDerivAt (fun y => 100 * exp y) (100 * exp y) y := fun y => by
    simpa using (hasDerivAt_exp y).const_mul 100
  have hC1 : ∀ y : ℝ, DifferentiableAt ℝ C (100 * exp y) := fun y =>
    (hCat y).differentiableAt (by norm_num)
  have hdC : ∀ y : ℝ, DifferentiableAt ℝ (deriv C) (100 * exp y) := by
    intro y
    have h1 : ContDiffOn ℝ 1 (deriv C) (Ioi 0) := hC.deriv_of_isOpen isOpen_Ioi (by norm_num)
    exact (h1.contDiffAt (Ioi_mem_nhds (hpos y))).differentiableAt (by norm_num)
  have hU : deriv (fun y => C (100 * exp y)) = fun y => deriv C (100 * exp y) * (100 * exp y) := by
    funext y
    exact ((hC1 y).hasDerivAt.comp y (hS y)).deriv
  have hU2 : deriv (deriv fun y => C (100 * exp y)) x =
      deriv (deriv C) (100 * exp x) * (100 * exp x) * (100 * exp x)
        + deriv C (100 * exp x) * (100 * exp x) := by
    rw [hU]
    have h := (((hdC x).hasDerivAt.comp x (hS x)).mul (hS x))
    exact h.deriv
  have hne : 100 * exp x ≠ 0 := (hpos x).ne'
  refine ⟨?_, ?_⟩
  · rw [hU]; field_simp
  · rw [hU2, hU]; field_simp; ring

-- The card's exact fixture, the parabola 3 + 2x + 5x² sampled at gaps h₋ = 1.5 = 3/2 below and
-- h₊ = 4 above: its three values are 45/4 (= 11.25), 3 and 91.
example : (3 : ℚ) + 2 * (-3 / 2) + 5 * (-3 / 2) ^ 2 = 45 / 4 := by norm_num
example : (3 : ℚ) + 2 * 0 + 5 * 0 ^ 2 = 3 := by norm_num
example : (3 : ℚ) + 2 * 4 + 5 * 4 ^ 2 = 91 := by norm_num
-- Its chord slope is 14.5 = 29/2, which is b + c (h₊ - h₋) = 2 + 5 · 5/2.
example : ((91 : ℚ) - 45 / 4) / (4 + 3 / 2) = 29 / 2 := by norm_num
example : (2 : ℚ) + 5 * (4 - 3 / 2) = 29 / 2 := by norm_num
-- Its node gamma is 10, twice the squared coefficient 5.
example : (2 : ℚ) / (4 + 3 / 2) * ((91 - 3) / 4 - (3 - 45 / 4) / (3 / 2)) = 10 := by norm_num
-- Recombination: with u = e^x and d = e^(-x), an up step then a down step returns to S exactly.
example (S x : ℝ) : S * exp x * exp (-x) = S := by
  rw [mul_assoc, ← Real.exp_add, add_neg_cancel, Real.exp_zero, mul_one]

#print axioms node_greeks_within_taylor_bounds
#print axioms node_gamma_is_curvature_of_unique_parabola
#print axioms log_grid_greeks_conversion
