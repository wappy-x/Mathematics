-- Mirror descent: on the simplex, entropy mirror descent from equal weights keeps the best of its first K points within log n/(αK) + αG²/2 of the least cost.
import Mathlib.Analysis.Convex.StdSimplex
import Mathlib.Analysis.Convex.Function
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Order.Filter.Extr
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Algebra.BigOperators.Field

open Finset

lemma md_kfun_hasDeriv (t : ℝ) (ht : 0 < t) :
    HasDerivAt (fun s : ℝ => Real.log s - (5 * s ^ 2 - 4 * s - 1) / (2 * s ^ 2 + 4 * s))
      ((t - 1) ^ 3 / (t ^ 2 * (t + 2) ^ 2)) t := by
  have h1 : HasDerivAt (fun s : ℝ => 5 * s ^ 2 - 4 * s - 1) (5 * (2 * t) - 4) t := by
    have := (((hasDerivAt_pow 2 t).const_mul 5).sub ((hasDerivAt_id t).const_mul 4)).sub_const 1
    convert this using 1; simp; ring
  have h2 : HasDerivAt (fun s : ℝ => 2 * s ^ 2 + 4 * s) (2 * (2 * t) + 4) t := by
    have := (((hasDerivAt_pow 2 t).const_mul 2).add ((hasDerivAt_id t).const_mul 4))
    convert this using 1
    · funext s; simp
    · simp
  have hne : 2 * t ^ 2 + 4 * t ≠ 0 := by positivity
  have := (Real.hasDerivAt_log ht.ne').sub (h1.div h2 hne)
  convert this using 1
  field_simp
  ring

lemma md_log_ge (t : ℝ) (ht : 0 < t) :
    (5 * t ^ 2 - 4 * t - 1) / (2 * t ^ 2 + 4 * t) ≤ Real.log t := by
  set k : ℝ → ℝ := fun s => Real.log s - (5 * s ^ 2 - 4 * s - 1) / (2 * s ^ 2 + 4 * s) with hk
  have hk1 : k 1 = 0 := by simp [hk]; norm_num
  have hcont : ContinuousOn k (Set.Ioi 0) := fun s hs =>
    (md_kfun_hasDeriv s hs).continuousAt.continuousWithinAt
  suffices 0 ≤ k t by simp only [hk] at this; linarith
  rcases le_total 1 t with h | h
  · have hmono : MonotoneOn k (Set.Ici 1) := by
      apply monotoneOn_of_deriv_nonneg (convex_Ici 1)
      · exact hcont.mono (fun s (hs : (1:ℝ) ≤ s) => (show (0:ℝ) < s by linarith))
      · intro s hs
        rw [interior_Ici] at hs
        exact (md_kfun_hasDeriv s (lt_trans one_pos hs)).differentiableAt.differentiableWithinAt
      · intro s hs
        rw [interior_Ici] at hs
        have hs' : (1:ℝ) < s := hs
        rw [(md_kfun_hasDeriv s (by linarith)).deriv]
        apply div_nonneg
        · exact pow_nonneg (by linarith) 3
        · positivity
    have := hmono (Set.self_mem_Ici) h h
    linarith
  · have hanti : AntitoneOn k (Set.Icc t 1) := by
      apply antitoneOn_of_deriv_nonpos (convex_Icc t 1)
      · exact hcont.mono (fun s hs => lt_of_lt_of_le ht hs.1)
      · intro s hs
        rw [interior_Icc] at hs
        exact (md_kfun_hasDeriv s (lt_trans ht hs.1)).differentiableAt.differentiableWithinAt
      · intro s hs
        rw [interior_Icc] at hs
        rw [(md_kfun_hasDeriv s (lt_trans ht hs.1)).deriv]
        apply div_nonpos_of_nonpos_of_nonneg
        · have : s - 1 ≤ 0 := by linarith [hs.2]
          nlinarith [sq_nonneg (s - 1)]
        · have := lt_trans ht hs.1
          positivity
    have := hanti ⟨le_refl t, h⟩ ⟨h, le_refl 1⟩ h
    linarith

lemma md_kl_term_ge (a b : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b) (hab : b = 0 → a = 0) :
    3 / 2 * ((a - b) ^ 2 / (a + 2 * b)) ≤ a * Real.log (a / b) - a + b := by
  rcases hb.eq_or_lt with hb0 | hbpos
  · have ha0 := hab hb0.symm
    subst ha0; rw [← hb0]; simp
  rcases ha.eq_or_lt with ha0 | hapos
  · subst ha0
    have : (0 - b) ^ 2 / (0 + 2 * b) = b / 2 := by field_simp; ring
    rw [this]; simp; linarith
  have ht : 0 < a / b := div_pos hapos hbpos
  have hl := md_log_ge (a / b) ht
  have key : a * ((5 * (a / b) ^ 2 - 4 * (a / b) - 1) / (2 * (a / b) ^ 2 + 4 * (a / b)))
      = a - b + 3 / 2 * ((a - b) ^ 2 / (a + 2 * b)) := by
    field_simp
    ring
  have := mul_le_mul_of_nonneg_left hl ha
  linarith

lemma md_pinsker (n : ℕ) (x y : Fin n → ℝ)
    (hx : x ∈ stdSimplex ℝ (Fin n)) (hy : y ∈ stdSimplex ℝ (Fin n))
    (hfin : ∀ i, y i = 0 → x i = 0) :
    (∑ i, |x i - y i|) ^ 2 / 2 ≤ ∑ i, x i * Real.log (x i / y i) := by
  have hx0 := hx.1
  have hy0 := hy.1
  have hxs := hx.2
  have hys := hy.2
  set Q := ∑ i, (x i - y i) ^ 2 / (x i + 2 * y i) with hQ
  have hCS : (∑ i, |x i - y i|) ^ 2 ≤ Q * ∑ i, (x i + 2 * y i) := by
    apply Finset.sum_sq_le_sum_mul_sum_of_sq_le_mul
    · intro i _
      have := hx0 i; have := hy0 i
      positivity
    · intro i _
      have := hx0 i; have := hy0 i
      positivity
    · intro i _
      have h1 := hx0 i; have h2 := hy0 i
      rcases (add_nonneg h1 (mul_nonneg zero_le_two h2)).eq_or_lt with h | h
      · have hyi : y i = 0 := by linarith
        have hxi : x i = 0 := by linarith
        simp [hxi, hyi]
      · rw [div_mul_cancel₀ _ h.ne', sq_abs]
  have hsum3 : ∑ i, (x i + 2 * y i) = 3 := by
    rw [Finset.sum_add_distrib, ← Finset.mul_sum, hxs, hys]; norm_num
  rw [hsum3] at hCS
  have hKL : 3 / 2 * Q ≤ ∑ i, x i * Real.log (x i / y i) := by
    have h1 : ∑ i, x i * Real.log (x i / y i)
        = ∑ i, (x i * Real.log (x i / y i) - x i + y i) := by
      rw [Finset.sum_add_distrib, Finset.sum_sub_distrib, hxs, hys]; ring
    rw [h1, hQ, Finset.mul_sum]
    exact Finset.sum_le_sum (fun i _ => md_kl_term_ge (x i) (y i) (hx0 i) (hy0 i) (hfin i))
  linarith

lemma md_three_point (n : ℕ) (y u g : Fin n → ℝ) (α : ℝ)
    (hy : y ∈ stdSimplex ℝ (Fin n)) (hypos : ∀ i, 0 < y i)
    (hu : u ∈ stdSimplex ℝ (Fin n)) :
    (∑ i, u i * Real.log (u i / y i))
        - (∑ i, u i * Real.log (u i / (y i * Real.exp (-(α * g i)) /
            ∑ j, y j * Real.exp (-(α * g j)))))
        - (∑ i, (y i * Real.exp (-(α * g i)) / ∑ j, y j * Real.exp (-(α * g j))) *
            Real.log ((y i * Real.exp (-(α * g i)) / ∑ j, y j * Real.exp (-(α * g j))) / y i))
      = α * ∑ i, g i * ((y i * Real.exp (-(α * g i)) / ∑ j, y j * Real.exp (-(α * g j)))
          - u i) := by
  set Z := ∑ j, y j * Real.exp (-(α * g j)) with hZ
  set z : Fin n → ℝ := fun i => y i * Real.exp (-(α * g i)) / Z with hzdef
  have hne : (univ : Finset (Fin n)).Nonempty := by
    by_contra h
    rw [Finset.not_nonempty_iff_eq_empty] at h
    have := hy.2
    rw [h] at this
    simp at this
  have hZpos : 0 < Z := Finset.sum_pos (fun i _ => mul_pos (hypos i) (Real.exp_pos _)) hne
  have hzpos : ∀ i, 0 < z i := fun i => div_pos (mul_pos (hypos i) (Real.exp_pos _)) hZpos
  have hzsum : ∑ i, z i = 1 := by
    simp only [hzdef]
    rw [← Finset.sum_div, div_self hZpos.ne']
  have hlog : ∀ i, Real.log (z i / y i) = -(α * g i) - Real.log Z := by
    intro i
    have : z i / y i = Real.exp (-(α * g i)) / Z := by
      simp only [hzdef]; field_simp [(hypos i).ne']
    rw [this, Real.log_div (Real.exp_pos _).ne' hZpos.ne', Real.log_exp]
  have hterm : ∀ i, u i * Real.log (u i / y i) - u i * Real.log (u i / z i)
      = u i * (-(α * g i) - Real.log Z) := by
    intro i
    rcases (hu.1 i).eq_or_lt with h0 | hpos
    · rw [← h0]; simp
    · rw [Real.log_div hpos.ne' (hypos i).ne', Real.log_div hpos.ne' (hzpos i).ne', ← hlog i,
        Real.log_div (hzpos i).ne' (hypos i).ne']
      ring
  show (∑ i, u i * Real.log (u i / y i)) - (∑ i, u i * Real.log (u i / z i))
        - (∑ i, z i * Real.log (z i / y i)) = α * ∑ i, g i * (z i - u i)
  rw [← Finset.sum_sub_distrib, ← Finset.sum_sub_distrib]
  simp_rw [hterm, hlog]
  have hus := hu.2
  have : ∀ i, u i * (-(α * g i) - Real.log Z) - z i * (-(α * g i) - Real.log Z)
      = α * (g i * (z i - u i)) + Real.log Z * (z i - u i) := fun i => by ring
  simp_rw [this]
  rw [Finset.sum_add_distrib, ← Finset.mul_sum, ← Finset.mul_sum, Finset.sum_sub_distrib,
    hzsum, hus]
  ring

#print axioms md_kfun_hasDeriv
#print axioms md_log_ge
#print axioms md_kl_term_ge
#print axioms md_pinsker
#print axioms md_three_point

/-- The rate of mirror descent with the entropy map (exponentiated gradient).
Let `f` be convex on the simplex with a minimiser `xstar`. Start from equal weights
`x 0 = (1/n, …, 1/n)`, and at each step multiply each weight by `exp (-α * g k i)`,
where `g k` is a subgradient of `f` at `x k` with every entry of size at most `G`,
then rescale so the weights sum to 1. With a fixed step `α > 0` and a budget of `K ≥ 1`
steps, the best of the points `x 0, …, x (K-1)` has cost at most
`f xstar + log n / (α K) + α G² / 2`. -/
theorem mirror_descent_entropy_rate (n : ℕ) (hn : 0 < n)
    (f : (Fin n → ℝ) → ℝ) (hf : ConvexOn ℝ (stdSimplex ℝ (Fin n)) f)
    (xstar : Fin n → ℝ) (hxstar : xstar ∈ stdSimplex ℝ (Fin n))
    (hmin : IsMinOn f (stdSimplex ℝ (Fin n)) xstar)
    (x g : ℕ → Fin n → ℝ) (α G : ℝ) (hα : 0 < α) (K : ℕ) (hK : 0 < K)
    (h0 : ∀ i, x 0 i = 1 / n)
    (hstep : ∀ k i, x (k + 1) i =
      x k i * Real.exp (-(α * g k i)) / ∑ j, x k j * Real.exp (-(α * g k j)))
    (hsub : ∀ k, ∀ y ∈ stdSimplex ℝ (Fin n), f (x k) + ∑ i, g k i * (y i - x k i) ≤ f y)
    (hG : ∀ k i, |g k i| ≤ G) :
    ∃ k < K, f (x k) - f xstar ≤ Real.log n / (α * K) + α * G ^ 2 / 2 := by
  have hnR : (0 : ℝ) < n := Nat.cast_pos.mpr hn
  have hne : (univ : Finset (Fin n)).Nonempty := ⟨⟨0, hn⟩, Finset.mem_univ _⟩
  -- every iterate is on the simplex with positive weights
  have hpos : ∀ k, x k ∈ stdSimplex ℝ (Fin n) ∧ ∀ i, 0 < x k i := by
    intro k
    induction k with
    | zero =>
      refine ⟨⟨fun i => by rw [h0]; positivity, ?_⟩, fun i => by rw [h0]; positivity⟩
      simp only [h0, Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
      field_simp
    | succ k ih =>
      have hZ : 0 < ∑ j, x k j * Real.exp (-(α * g k j)) :=
        Finset.sum_pos (fun j _ => mul_pos (ih.2 j) (Real.exp_pos _)) hne
      have hp : ∀ i, 0 < x (k + 1) i := fun i => by
        rw [hstep]; exact div_pos (mul_pos (ih.2 i) (Real.exp_pos _)) hZ
      refine ⟨⟨fun i => (hp i).le, ?_⟩, hp⟩
      simp only [hstep]
      rw [← Finset.sum_div, div_self hZ.ne']
  set D : (Fin n → ℝ) → ℝ := fun v => ∑ i, xstar i * Real.log (xstar i / v i) with hD
  -- the one-step bound
  have hone : ∀ k, α * ∑ i, g k i * (x k i - xstar i)
      ≤ D (x k) - D (x (k + 1)) + α ^ 2 * G ^ 2 / 2 := by
    intro k
    have h3 := md_three_point n (x k) xstar (g k) α (hpos k).1 (hpos k).2 hxstar
    have hz : ∀ i, x k i * Real.exp (-(α * g k i)) / ∑ j, x k j * Real.exp (-(α * g k j))
        = x (k + 1) i := fun i => (hstep k i).symm
    simp only [hz] at h3
    -- h3 : D (x k) - D (x (k+1)) - KL(x(k+1) ‖ x k) = α * Σ g (x(k+1) - xstar)
    have hP := md_pinsker n (x (k + 1)) (x k) (hpos (k + 1)).1 (hpos k).1
      (fun i h => absurd h ((hpos k).2 i).ne')
    set L := ∑ i, |x (k + 1) i - x k i| with hL
    have hlin : ∑ i, g k i * (x k i - x (k + 1) i) ≤ G * L := by
      rw [hL, Finset.mul_sum]
      apply Finset.sum_le_sum
      intro i _
      calc g k i * (x k i - x (k + 1) i) ≤ |g k i * (x k i - x (k + 1) i)| := le_abs_self _
        _ = |g k i| * |x (k + 1) i - x k i| := by rw [abs_mul, abs_sub_comm]
        _ ≤ G * |x (k + 1) i - x k i| := mul_le_mul_of_nonneg_right (hG k i) (abs_nonneg _)
    have hsplit : ∑ i, g k i * (x k i - xstar i)
        = ∑ i, g k i * (x (k + 1) i - xstar i) + ∑ i, g k i * (x k i - x (k + 1) i) := by
      rw [← Finset.sum_add_distrib]; apply Finset.sum_congr rfl; intro i _; ring
    rw [hsplit, mul_add]
    have hsq : 0 ≤ (L - α * G) ^ 2 := sq_nonneg _
    have := mul_le_mul_of_nonneg_left hlin hα.le
    simp only [hD]
    nlinarith
  -- telescoping
  have htel : ∀ m, α * ∑ k ∈ range m, ∑ i, g k i * (x k i - xstar i)
      ≤ D (x 0) - D (x m) + m * (α ^ 2 * G ^ 2 / 2) := by
    intro m
    induction m with
    | zero => simp
    | succ m ih =>
      rw [Finset.sum_range_succ, mul_add]
      have := hone m
      push_cast
      linarith
  -- the start and the end
  have hD0 : D (x 0) ≤ Real.log n := by
    have : ∀ i, xstar i * Real.log (xstar i / x 0 i) ≤ xstar i * Real.log n := by
      intro i
      rw [h0]
      rcases (hxstar.1 i).eq_or_lt with h | h
      · rw [← h]; simp
      · apply mul_le_mul_of_nonneg_left _ h.le
        apply Real.log_le_log (by positivity)
        have hle : xstar i ≤ 1 := by
          have := hxstar.2
          rw [← this]
          exact Finset.single_le_sum (fun j _ => hxstar.1 j) (Finset.mem_univ i)
        rw [div_div_eq_mul_div, div_one]
        nlinarith
    calc D (x 0) ≤ ∑ i, xstar i * Real.log n := Finset.sum_le_sum (fun i _ => this i)
      _ = Real.log n := by rw [← Finset.sum_mul, hxstar.2, one_mul]
  have hDK : 0 ≤ D (x K) := by
    have := md_pinsker n xstar (x K) hxstar (hpos K).1 (fun i h => absurd h ((hpos K).2 i).ne')
    have h2 : 0 ≤ (∑ i, |xstar i - x K i|) ^ 2 / 2 := by positivity
    exact le_trans h2 this
  -- the gap at each step is at most the linear term
  have hgap : ∀ k, f (x k) - f xstar ≤ ∑ i, g k i * (x k i - xstar i) := by
    intro k
    have := hsub k xstar hxstar
    have he : ∑ i, g k i * (x k i - xstar i) = -∑ i, g k i * (xstar i - x k i) := by
      rw [← Finset.sum_neg_distrib]; apply Finset.sum_congr rfl; intro i _; ring
    rw [he]; linarith
  by_contra hcon
  push_neg at hcon
  set B := Real.log n / (α * K) + α * G ^ 2 / 2 with hB
  have hKR : (0 : ℝ) < K := Nat.cast_pos.mpr hK
  have hrne : (range K).Nonempty := ⟨0, Finset.mem_range.mpr hK⟩
  have hlt : ∑ _k ∈ range K, B < ∑ k ∈ range K, ∑ i, g k i * (x k i - xstar i) := by
    apply Finset.sum_lt_sum_of_nonempty hrne
    intro k hk
    exact lt_of_lt_of_le (hcon k (Finset.mem_range.mp hk)) (hgap k)
  rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul] at hlt
  have hαKB : α * (K * B) = Real.log n + K * (α ^ 2 * G ^ 2 / 2) := by
    rw [hB]; field_simp
  have := htel K
  have := mul_lt_mul_of_pos_left hlt hα
  linarith

/-- The three-point identity for the entropy step. If every weight of `y` is positive and
`z` is the mirror descent step from `y` with slopes `g` and step `α`
(`z i = y i * exp (-α g i) / Z`), then for any comparison weights `u` on the simplex
`D(u ‖ y) - D(u ‖ z) - D(z ‖ y) = α g ⬝ (z - u)`, where `D(p ‖ q) = ∑ p i log (p i / q i)`
is the KL divergence. -/
theorem kl_three_point_identity (n : ℕ) (y u g : Fin n → ℝ) (α : ℝ)
    (hy : y ∈ stdSimplex ℝ (Fin n)) (hypos : ∀ i, 0 < y i)
    (hu : u ∈ stdSimplex ℝ (Fin n)) :
    let Z := ∑ j, y j * Real.exp (-(α * g j))
    let z : Fin n → ℝ := fun i => y i * Real.exp (-(α * g i)) / Z
    (∑ i, u i * Real.log (u i / y i)) - (∑ i, u i * Real.log (u i / z i))
        - (∑ i, z i * Real.log (z i / y i))
      = α * ∑ i, g i * (z i - u i) := by
  intro Z z
  exact md_three_point n y u g α hy hypos hu

/-- Pinsker's inequality: for weights `x` and `y` on the simplex with finite divergence
(no weight of `y` is zero where `x` has weight), the KL divergence
`D(x ‖ y) = ∑ x i log (x i / y i)` is at least half the square of `‖x - y‖₁`. -/
theorem pinsker_kl_ge_half_l1_sq (n : ℕ) (x y : Fin n → ℝ)
    (hx : x ∈ stdSimplex ℝ (Fin n)) (hy : y ∈ stdSimplex ℝ (Fin n))
    (hfin : ∀ i, y i = 0 → x i = 0) :
    (∑ i, |x i - y i|) ^ 2 / 2 ≤ ∑ i, x i * Real.log (x i / y i) := by
  exact md_pinsker n x y hx hy hfin

-- The card's step on three assets: weights 1/3 each, multipliers 2^(-g) = (1/2, 1, 1/4).
example : (1/3 : ℚ) * (1/2) + 1/3 * 1 + 1/3 * (1/4) = 7/12 := by norm_num
example : ((1/3 : ℚ) * (1/2)) / (7/12) = 2/7 := by norm_num
example : ((1/3 : ℚ) * 1) / (7/12) = 4/7 := by norm_num
example : ((1/3 : ℚ) * (1/4)) / (7/12) = 1/7 := by norm_num
-- The l1 size of the move in the Pinsker row: 1/21 + 5/21 + 4/21 = 10/21.
example : |(2/7 : ℚ) - 1/3| + |4/7 - 1/3| + |1/7 - 1/3| = 10/21 := by norm_num [abs_of_nonneg, abs_of_nonpos]
-- Cost x_A + 2 x_C after k = 1, 2, 3 steps with the slopes held at (1, 0, 2).
example : ((1/2 : ℚ) + 2 * (1/4)) / (1/2 + 1 + 1/4) = 4/7 := by norm_num
example : ((1/4 : ℚ) + 2 * (1/16)) / (1/4 + 1 + 1/16) = 2/7 := by norm_num
example : ((1/8 : ℚ) + 2 * (1/64)) / (1/8 + 1 + 1/64) = 10/73 := by norm_num

#print axioms mirror_descent_entropy_rate
#print axioms kl_three_point_identity
#print axioms pinsker_kl_ge_half_l1_sq
