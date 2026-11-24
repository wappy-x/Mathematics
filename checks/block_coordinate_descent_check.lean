-- Coordinate descent: on a smooth convex cost with coordinate curvatures L_i, random coordinate steps of length 1/L_i close the expected gap above the minimum to at most 2 n L_max R² / k after k steps; a point no single coordinate can improve is a global minimum when the kink is separable, but |x − y| + 0.1 (x + y)² stalls at (1, 1); the card's exact tilt-problem numbers are checked as fractions.
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Convex.Function
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Algebra.Order.Chebyshev

open scoped Gradient

/-! ### How the card's objects are written here

The unknowns are `n` real numbers, a point of `EuclideanSpace ℝ (Fin n)`, with the usual length
`‖v‖`. Coordinate `i` of a point `x` is `x i`, and the unit move along coordinate `i` is
`e_i = EuclideanSpace.single i 1`. `∇ f x` is Mathlib's gradient of `f` at `x`, so the slope
along coordinate `i` alone is `(∇ f x) i`.

One coordinate step moves coordinate `i` against its own slope, by that slope over the
coordinate's curvature `L i`: `x ↦ x - (1 / L i) (∇ f x) i • e_i`. A run of `k` steps is a list
of `k` coordinates, written `p : Fin k → Fin n` (step `j` moves coordinate `p j`). The random
rule picks each coordinate with probability `1/n`, independently at each step, so all `n ^ k`
runs are equally likely, and the expected cost after `k` steps is the plain average of
`f (x_k)` over all of them. -/

/-- One coordinate step of length `1 / L i` along coordinate `i`. -/
noncomputable def coordStep {n : ℕ} (f : EuclideanSpace ℝ (Fin n) → ℝ) (L : Fin n → ℝ)
    (x : EuclideanSpace ℝ (Fin n)) (i : Fin n) : EuclideanSpace ℝ (Fin n) :=
  x - ((L i)⁻¹ * (∇ f x) i) • EuclideanSpace.single i (1 : ℝ)

/-- The point reached from `x0` after the coordinate steps `p 0, p 1, …, p (k - 1)`, in order. -/
noncomputable def coordRun {n k : ℕ} (f : EuclideanSpace ℝ (Fin n) → ℝ) (L : Fin n → ℝ)
    (x0 : EuclideanSpace ℝ (Fin n)) (p : Fin k → Fin n) : EuclideanSpace ℝ (Fin n) :=
  (List.ofFn p).foldl (coordStep f L) x0

/-- The expected cost `𝔼 f(x_k)` after `k` random coordinate steps from `x0`: the average of
`f (x_k)` over all `n ^ k` equally likely runs. -/
noncomputable def expectedCostAfter {n : ℕ} (f : EuclideanSpace ℝ (Fin n) → ℝ) (L : Fin n → ℝ)
    (x0 : EuclideanSpace ℝ (Fin n)) (k : ℕ) : ℝ :=
  (∑ p : Fin k → Fin n, f (coordRun f L x0 p)) / (n : ℝ) ^ k

/-! ### Helper lemmas for the proofs below -/

theorem bcd_line_hasDerivAt {n : ℕ} (f : EuclideanSpace ℝ (Fin n) → ℝ) (hdiff : Differentiable ℝ f)
    (x w : EuclideanSpace ℝ (Fin n)) (s : ℝ) :
    HasDerivAt (fun s : ℝ => f (x + s • w)) (inner ℝ (∇ f (x + s • w)) w) s := by
  have h1 : HasDerivAt (fun s : ℝ => x + s • w) w s := by
    simpa using ((hasDerivAt_id s).smul_const w).const_add x
  have h2 := (hdiff (x + s • w)).hasGradientAt.hasFDerivAt
  exact h2.comp_hasDerivAt s h1

#print axioms bcd_line_hasDerivAt

theorem bcd_inner_single {n : ℕ} (v : EuclideanSpace ℝ (Fin n)) (i : Fin n) :
    inner ℝ v (EuclideanSpace.single i (1 : ℝ)) = v i := by
  simp [EuclideanSpace.inner_single_right]

#print axioms bcd_inner_single

theorem bcd_slope_le {v : ℝ → ℝ} {d C : ℝ} (hv : HasDerivAt v d 0)
    (h : ∀ s : ℝ, 0 < s → s ≤ 1 → v s - v 0 ≤ s * C) : d ≤ C := by
  apply le_of_tendsto hv.tendsto_slope_zero_right
  filter_upwards [Ioo_mem_nhdsGT (show (0:ℝ) < 1 by norm_num)] with s hs
  have h1 := h s hs.1 hs.2.le
  rw [zero_add, smul_eq_mul, inv_mul_le_iff₀ hs.1]
  exact h1

#print axioms bcd_slope_le

theorem bcd_le_slope {v : ℝ → ℝ} {d C : ℝ} (hv : HasDerivAt v d 0)
    (h : ∀ s : ℝ, 0 < s → s ≤ 1 → s * C ≤ v s - v 0) : C ≤ d := by
  apply ge_of_tendsto hv.tendsto_slope_zero_right
  filter_upwards [Ioo_mem_nhdsGT (show (0:ℝ) < 1 by norm_num)] with s hs
  have h1 := h s hs.1 hs.2.le
  rw [zero_add, smul_eq_mul, le_inv_mul_iff₀ hs.1]
  exact h1

#print axioms bcd_le_slope

theorem bcd_convex_grad {n : ℕ} (f : EuclideanSpace ℝ (Fin n) → ℝ) (hdiff : Differentiable ℝ f)
    (hconv : ConvexOn ℝ Set.univ f) (x z : EuclideanSpace ℝ (Fin n)) :
    inner ℝ (∇ f x) (z - x) ≤ f z - f x := by
  have hd := bcd_line_hasDerivAt f hdiff x (z - x) 0
  simp only [zero_smul, add_zero] at hd
  apply bcd_slope_le hd
  intro s hs0 hs1
  have key := hconv.2 (Set.mem_univ x) (Set.mem_univ z) (by linarith : (0:ℝ) ≤ 1 - s) hs0.le
    (by ring : (1 - s) + s = 1)
  have e : (1 - s) • x + s • z = x + s • (z - x) := by
    rw [smul_sub, sub_smul, one_smul]; abel
  rw [e, smul_eq_mul, smul_eq_mul] at key
  simp only [zero_smul, add_zero]
  nlinarith [key]

#print axioms bcd_convex_grad

theorem bcd_descent_1d (φ φ' : ℝ → ℝ) (L : ℝ) (hd : ∀ t, HasDerivAt φ (φ' t) t)
    (hlip : ∀ t, |φ' t - φ' 0| ≤ L * |t|) (t : ℝ) :
    φ t ≤ φ 0 + t * φ' 0 + L / 2 * t ^ 2 := by
  set ψ : ℝ → ℝ := fun s => φ s - φ 0 - s * φ' 0 - L / 2 * s ^ 2 with hψ
  have hψd : ∀ s, HasDerivAt ψ (φ' s - φ' 0 - L * s) s := by
    intro s
    have h1 := (((hd s).sub_const (φ 0)).sub ((hasDerivAt_id s).mul_const (φ' 0))).sub
      ((hasDerivAt_pow 2 s).const_mul (L / 2))
    have e : ψ = ((fun x => φ x - φ 0) - fun y => id y * φ' 0) - fun y => L / 2 * y ^ 2 := by
      funext y; simp [hψ]
    rw [e]
    convert h1 using 1
    norm_num
    ring
  have hcont : Continuous ψ := continuous_iff_continuousAt.2 fun s => (hψd s).continuousAt
  have hψ0 : ψ 0 = 0 := by simp [hψ]
  suffices ψ t ≤ 0 by simp only [hψ] at this; linarith
  rcases lt_trichotomy t 0 with ht | ht | ht
  · obtain ⟨c, hc, hcd⟩ := exists_hasDerivAt_eq_slope ψ (fun s => φ' s - φ' 0 - L * s) ht
      hcont.continuousOn (fun s _ => hψd s)
    have hl := hlip c
    rw [abs_of_neg hc.2] at hl
    have hl2 := neg_abs_le (φ' c - φ' 0)
    have : 0 ≤ (ψ 0 - ψ t) / (0 - t) := by rw [← hcd]; nlinarith
    rw [hψ0] at this
    have h2 : 0 < 0 - t := by linarith
    have := (div_nonneg_iff.1 this)
    rcases this with h | h
    · linarith [h.1]
    · linarith [h.2]
  · rw [ht, hψ0]
  · obtain ⟨c, hc, hcd⟩ := exists_hasDerivAt_eq_slope ψ (fun s => φ' s - φ' 0 - L * s) ht
      hcont.continuousOn (fun s _ => hψd s)
    have hl := hlip c
    rw [abs_of_pos hc.1] at hl
    have hl2 := le_abs_self (φ' c - φ' 0)
    have : (ψ t - ψ 0) / (t - 0) ≤ 0 := by rw [← hcd]; nlinarith
    rw [hψ0, sub_zero, sub_zero] at this
    exact (div_nonpos_iff.1 this).elim (fun h => absurd h.2 (not_le.2 ht)) (fun h => h.1)

#print axioms bcd_descent_1d

theorem bcd_seq (δ : ℕ → ℝ) (D : ℝ) (hD : 0 ≤ D) (hnn : ∀ k, 0 ≤ δ k)
    (hrec : ∀ k, D * δ (k + 1) ≤ D * δ k - δ k ^ 2) : ∀ k : ℕ, 0 < k → δ k * k ≤ D := by
  have hle : ∀ j, δ j ≤ D := by
    intro j
    have := hrec j
    have := hnn j
    have := hnn (j + 1)
    by_contra hc
    rw [not_le] at hc
    nlinarith [mul_nonneg hD (hnn (j+1)), mul_lt_mul_of_pos_left hc (lt_of_le_of_lt hD hc)]
  intro k hk
  induction k with
  | zero => exact absurd hk (lt_irrefl 0)
  | succ k ih =>
    rcases Nat.eq_zero_or_pos k with h0 | hpos
    · subst h0; simpa using hle 1
    have ihk := ih hpos
    rcases hD.eq_or_lt with hD0 | hDpos
    · have := hle (k + 1); have := hnn (k + 1)
      rw [← hD0] at *
      have : δ (k + 1) = 0 := by linarith
      rw [this]; simp
    · have hk1 : (1 : ℝ) ≤ k := by exact_mod_cast hpos
      have hs := hnn k
      set u := D - δ k * k with hu
      have hu0 : 0 ≤ u := by linarith
      have key : (k + 1 : ℝ) * (D * δ k - δ k ^ 2) ≤ D ^ 2 := by
        have e : D = u + δ k * k := by linarith
        rw [e]
        nlinarith [mul_nonneg (mul_nonneg (by linarith : (0:ℝ) ≤ k - 1) hs) hu0, sq_nonneg u,
          sq_nonneg (δ k)]
      have h2 := hrec k
      push_cast
      have : D * (δ (k + 1) * (k + 1)) ≤ D * D := by
        nlinarith
      exact le_of_mul_le_mul_left this hDpos

#print axioms bcd_seq

theorem bcd_step_le {n : ℕ} (f : EuclideanSpace ℝ (Fin n) → ℝ) (hdiff : Differentiable ℝ f)
    (L : Fin n → ℝ) (i : Fin n) (hLi : 0 < L i)
    (hcurv : ∀ (x : EuclideanSpace ℝ (Fin n)) (t : ℝ),
      |(∇ f (x + t • EuclideanSpace.single i (1 : ℝ))) i - (∇ f x) i| ≤ L i * |t|)
    (x : EuclideanSpace ℝ (Fin n)) :
    f (coordStep f L x i) ≤ f x - ((∇ f x) i) ^ 2 / (2 * L i) := by
  have h := bcd_descent_1d (fun t => f (x + t • EuclideanSpace.single i (1 : ℝ)))
    (fun t => (∇ f (x + t • EuclideanSpace.single i (1 : ℝ))) i) (L i)
    (fun t => by
      have := bcd_line_hasDerivAt f hdiff x (EuclideanSpace.single i (1 : ℝ)) t
      rwa [bcd_inner_single] at this)
    (fun t => by simpa only [zero_smul, add_zero] using hcurv x t)
    (-((L i)⁻¹ * (∇ f x) i))
  simp only [zero_smul, add_zero] at h
  have e : coordStep f L x i = x + (-((L i)⁻¹ * (∇ f x) i)) • EuclideanSpace.single i (1 : ℝ) := by
    unfold coordStep; rw [neg_smul, ← sub_eq_add_neg]
  rw [e]
  have e2 : f x + -((L i)⁻¹ * (∇ f x) i) * (∇ f x) i + L i / 2 * (-((L i)⁻¹ * (∇ f x) i)) ^ 2
      = f x - ((∇ f x) i) ^ 2 / (2 * L i) := by
    field_simp; ring
  linarith

#print axioms bcd_step_le

theorem bcd_fold_le {n : ℕ} (f : EuclideanSpace ℝ (Fin n) → ℝ) (hdiff : Differentiable ℝ f)
    (L : Fin n → ℝ) (hLpos : ∀ i, 0 < L i)
    (hcurv : ∀ (x : EuclideanSpace ℝ (Fin n)) (i : Fin n) (t : ℝ),
      |(∇ f (x + t • EuclideanSpace.single i (1 : ℝ))) i - (∇ f x) i| ≤ L i * |t|)
    (l : List (Fin n)) : ∀ x, f (l.foldl (coordStep f L) x) ≤ f x := by
  induction l with
  | nil => intro x; simp
  | cons a l ih =>
    intro x
    rw [List.foldl_cons]
    refine (ih _).trans ?_
    have := bcd_step_le f hdiff L a (hLpos a) (fun x t => hcurv x a t) x
    have : 0 ≤ ((∇ f x) a) ^ 2 / (2 * L a) := div_nonneg (sq_nonneg _) (by linarith [hLpos a])
    linarith

#print axioms bcd_fold_le

theorem bcd_run_snoc {n k : ℕ} (f : EuclideanSpace ℝ (Fin n) → ℝ) (L : Fin n → ℝ)
    (x0 : EuclideanSpace ℝ (Fin n)) (q : Fin k → Fin n) (i : Fin n) :
    coordRun f L x0 (Fin.snoc (α := fun _ => Fin n) q i) = coordStep f L (coordRun f L x0 q) i := by
  unfold coordRun
  rw [List.ofFn_succ']
  simp [Fin.snoc_castSucc, Fin.snoc_last, List.concat_eq_append]

#print axioms bcd_run_snoc

theorem bcd_sum_succ {n k : ℕ} (g : (Fin (k + 1) → Fin n) → ℝ) :
    ∑ p, g p = ∑ q : Fin k → Fin n, ∑ i, g (Fin.snoc (α := fun _ => Fin n) q i) := by
  rw [← (Fin.snocEquiv (fun _ => Fin n)).sum_comp, Fintype.sum_prod_type, Finset.sum_comm]
  rfl

#print axioms bcd_sum_succ

theorem bcd_point {n : ℕ} (hn : 0 < n)
    (f : EuclideanSpace ℝ (Fin n) → ℝ) (hdiff : Differentiable ℝ f)
    (hconv : ConvexOn ℝ Set.univ f)
    (L : Fin n → ℝ) (hLpos : ∀ i, 0 < L i)
    (hcurv : ∀ (x : EuclideanSpace ℝ (Fin n)) (i : Fin n) (t : ℝ),
      |(∇ f (x + t • EuclideanSpace.single i (1 : ℝ))) i - (∇ f x) i| ≤ L i * |t|)
    (Lmax : ℝ) (hLmax : ∀ i, L i ≤ Lmax)
    (xstar : EuclideanSpace ℝ (Fin n))
    (R : ℝ) (x : EuclideanSpace ℝ (Fin n)) (hxR : ‖x - xstar‖ ≤ R) (hxs : f xstar ≤ f x) :
    (2 * n * Lmax * R ^ 2) * ((∑ i, f (coordStep f L x i)) / n - f xstar) ≤
      (2 * n * Lmax * R ^ 2) * (f x - f xstar) - (f x - f xstar) ^ 2 := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hLm : 0 < Lmax := (hLpos ⟨0, hn⟩).trans_le (hLmax _)
  set g := ∇ f x with hg
  have hsum : ∑ i, f (coordStep f L x i) ≤ ∑ i, (f x - (g i) ^ 2 / (2 * Lmax)) := by
    apply Finset.sum_le_sum
    intro i _
    have h1 := bcd_step_le f hdiff L i (hLpos i) (fun x t => hcurv x i t) x
    have h2 : (g i) ^ 2 / (2 * Lmax) ≤ (g i) ^ 2 / (2 * L i) :=
      div_le_div_of_nonneg_left (sq_nonneg _) (by linarith [hLpos i]) (by linarith [hLmax i])
    linarith
  rw [Finset.sum_sub_distrib, ← Finset.sum_div, ← EuclideanSpace.real_norm_sq_eq,
    Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul] at hsum
  have havg : (∑ i, f (coordStep f L x i)) / n ≤ f x - ‖g‖ ^ 2 / (2 * n * Lmax) := by
    rw [div_le_iff₀ hn']
    have : (f x - ‖g‖ ^ 2 / (2 * n * Lmax)) * n = n * f x - ‖g‖ ^ 2 / (2 * Lmax) := by
      field_simp
    linarith
  have hgap : f x - f xstar ≤ ‖g‖ * R := by
    have h1 := bcd_convex_grad f hdiff hconv x xstar
    have h2 : inner ℝ g (x - xstar) = - inner ℝ g (xstar - x) := by
      rw [← inner_neg_right, neg_sub]
    have h3 := real_inner_le_norm g (x - xstar)
    have h4 : ‖g‖ * ‖x - xstar‖ ≤ ‖g‖ * R := mul_le_mul_of_nonneg_left hxR (norm_nonneg _)
    rw [← hg] at h1
    linarith
  have hsq : (f x - f xstar) ^ 2 ≤ ‖g‖ ^ 2 * R ^ 2 := by
    rw [← mul_pow]; exact pow_le_pow_left₀ (by linarith) hgap 2
  have hD : 0 ≤ 2 * n * Lmax * R ^ 2 := by positivity
  have h5 := mul_le_mul_of_nonneg_left havg hD
  have h6 : 2 * n * Lmax * R ^ 2 * (f x - ‖g‖ ^ 2 / (2 * n * Lmax)) =
      2 * n * Lmax * R ^ 2 * f x - R ^ 2 * ‖g‖ ^ 2 := by
    field_simp
  nlinarith

#print axioms bcd_point

/-- **The random rate** (Nesterov 2012; proved on the card in Why it works, Steps 1 to 3).
Let `f` on `n` coordinates be smooth (differentiable everywhere) and convex, with a minimiser
`x*`. Let coordinate `i` have curvature `L i > 0`: as coordinate `i` alone moves by `t`, the slope
along it changes by at most `L i * |t|`. Let `L_max` be at least every `L i`, and let `R` be at
least the distance from `x*` to every point no higher than the start `x0`. Run coordinate
descent from `x0`, each step moving a coordinate chosen at random (each with probability `1/n`)
by its slope over its curvature. Then after `k ≥ 1` steps the expected height above the minimum
is at most `2 n L_max R² / k`:
`𝔼 f(x_k) − f* ≤ 2 n L_max R² / k`. -/
theorem random_coordinate_descent_rate {n : ℕ} (hn : 0 < n)
    (f : EuclideanSpace ℝ (Fin n) → ℝ) (hdiff : Differentiable ℝ f)
    (hconv : ConvexOn ℝ Set.univ f)
    (L : Fin n → ℝ) (hLpos : ∀ i, 0 < L i)
    (hcurv : ∀ (x : EuclideanSpace ℝ (Fin n)) (i : Fin n) (t : ℝ),
      |(∇ f (x + t • EuclideanSpace.single i (1 : ℝ))) i - (∇ f x) i| ≤ L i * |t|)
    (Lmax : ℝ) (hLmax : ∀ i, L i ≤ Lmax)
    (xstar : EuclideanSpace ℝ (Fin n)) (hmin : ∀ y, f xstar ≤ f y)
    (x0 : EuclideanSpace ℝ (Fin n)) (R : ℝ) (hR : ∀ y, f y ≤ f x0 → ‖y - xstar‖ ≤ R)
    (k : ℕ) (hk : 0 < k) :
    expectedCostAfter f L x0 k - f xstar ≤ 2 * n * Lmax * R ^ 2 / k := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hLm : 0 < Lmax := (hLpos ⟨0, hn⟩).trans_le (hLmax _)
  have hD : 0 ≤ 2 * n * Lmax * R ^ 2 := by positivity
  set D := 2 * n * Lmax * R ^ 2 with hDdef
  have hcard : ∀ j : ℕ, ((Finset.univ : Finset (Fin j → Fin n)).card : ℝ) = (n : ℝ) ^ j := by
    intro j; simp
  have hlev : ∀ {j : ℕ} (p : Fin j → Fin n), f (coordRun f L x0 p) ≤ f x0 :=
    fun p => bcd_fold_le f hdiff L hLpos hcurv _ x0
  set δ : ℕ → ℝ := fun j => expectedCostAfter f L x0 j - f xstar with hδ
  have hδeq : ∀ j, δ j = (∑ p : Fin j → Fin n, (f (coordRun f L x0 p) - f xstar)) / (n : ℝ) ^ j := by
    intro j
    simp only [hδ, expectedCostAfter, Finset.sum_sub_distrib, Finset.sum_const, nsmul_eq_mul,
      hcard]
    have : (0 : ℝ) < (n : ℝ) ^ j := by positivity
    field_simp
  have hnn : ∀ j, 0 ≤ δ j := by
    intro j
    rw [hδeq]
    apply div_nonneg _ (by positivity)
    exact Finset.sum_nonneg fun p _ => by linarith [hmin (coordRun f L x0 p)]
  have hrec : ∀ j, D * δ (j + 1) ≤ D * δ j - δ j ^ 2 := by
    intro j
    set N : ℝ := (n : ℝ) ^ j with hN
    have hNpos : 0 < N := by positivity
    set a : (Fin j → Fin n) → ℝ := fun q => f (coordRun f L x0 q) - f xstar with ha
    set Sa := ∑ q, a q with hSa
    set Sa2 := ∑ q, a q ^ 2 with hSa2
    set X := ∑ q : Fin j → Fin n, (∑ i, f (coordStep f L (coordRun f L x0 q) i)) / n with hX
    have h1 : δ j = Sa / N := hδeq j
    have h2 : δ (j + 1) = (X - N * f xstar) / N := by
      rw [hδeq, bcd_sum_succ, hX, pow_succ]
      simp only [bcd_run_snoc, Finset.sum_sub_distrib, Finset.sum_const, nsmul_eq_mul,
        Finset.card_univ, Fintype.card_fin, ← Finset.sum_div, Fintype.card_fun, Nat.cast_pow]
      simp only [hN]
      field_simp
    have h3 : D * (X - N * f xstar) ≤ D * Sa - Sa2 := by
      have : D * (X - N * f xstar) = ∑ q : Fin j → Fin n,
          D * ((∑ i, f (coordStep f L (coordRun f L x0 q) i)) / n - f xstar) := by
        rw [← Finset.mul_sum, Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ, nsmul_eq_mul]
        simp only [Fintype.card_fun, Fintype.card_fin, Nat.cast_pow, hN, hX]
      rw [this, hSa, hSa2, Finset.mul_sum, ← Finset.sum_sub_distrib]
      apply Finset.sum_le_sum
      intro q _
      exact bcd_point hn f hdiff hconv L hLpos hcurv Lmax hLmax xstar R _
        (hR _ (hlev q)) (hmin _)
    have h4 : Sa ^ 2 ≤ N * Sa2 := by
      have := sq_sum_le_card_mul_sum_sq (s := Finset.univ) (f := a)
      rw [hcard j] at this
      exact this
    rw [h1, h2]
    rw [mul_div_assoc', div_pow]
    rw [div_le_iff₀ hNpos]
    have e : (D * (Sa / N) - Sa ^ 2 / N ^ 2) * N = D * Sa - Sa ^ 2 / N := by
      field_simp
    rw [e]
    have : Sa ^ 2 / N ≤ Sa2 := by rw [div_le_iff₀ hNpos]; linarith
    linarith
  have := bcd_seq δ D hD hnn hrec k hk
  have hk' : (0 : ℝ) < k := by exact_mod_cast hk
  show δ k ≤ D / k
  rw [le_div_iff₀ hk']
  exact this

/-- **A separable kink is safe** (the card's Step 6; Tseng 2001). Let the cost be
`F(x) = f(x) + ∑ᵢ hᵢ(xᵢ)`, with `f` smooth (differentiable everywhere) and convex and each
one-variable charge `hᵢ` convex. If no move of a single coordinate, by any amount `t`, lowers
`F` at `x`, then nothing lowers it at all: `x` is a global minimum of `F`. -/
theorem separable_kink_coordinatewise_min_is_global {n : ℕ}
    (f : EuclideanSpace ℝ (Fin n) → ℝ) (hdiff : Differentiable ℝ f)
    (hconv : ConvexOn ℝ Set.univ f)
    (h : Fin n → ℝ → ℝ) (hh : ∀ i, ConvexOn ℝ Set.univ (h i))
    (x : EuclideanSpace ℝ (Fin n))
    (hstuck : ∀ (i : Fin n) (t : ℝ),
      f x + ∑ j, h j (x j) ≤
        f (x + t • EuclideanSpace.single i (1 : ℝ)) +
          ∑ j, h j ((x + t • EuclideanSpace.single i (1 : ℝ)) j)) :
    ∀ z : EuclideanSpace ℝ (Fin n), f x + ∑ j, h j (x j) ≤ f z + ∑ j, h j (z j) := by
  intro z
  set g := ∇ f x with hg
  have hcoord : ∀ (i : Fin n) (t : ℝ), -(g i * t) ≤ h i (x i + t) - h i (x i) := by
    intro i t
    have hsplit : ∀ c : ℝ, ∑ j, h j ((x + c • EuclideanSpace.single i (1 : ℝ)) j) =
        ∑ j, h j (x j) + (h i (x i + c) - h i (x i)) := by
      intro c
      rw [← sub_eq_iff_eq_add', ← Finset.sum_sub_distrib, Finset.sum_eq_single i]
      · simp
      · intro j _ hj; simp [hj]
      · simp
    have hst : ∀ c : ℝ, f x - f (x + c • EuclideanSpace.single i (1 : ℝ)) ≤
        h i (x i + c) - h i (x i) := by
      intro c; have := hstuck i c; rw [hsplit] at this; linarith
    have hd := bcd_line_hasDerivAt f hdiff x (t • EuclideanSpace.single i (1 : ℝ)) 0
    simp only [zero_smul, add_zero, inner_smul_right, bcd_inner_single] at hd
    have key := bcd_le_slope hd (C := -(h i (x i + t) - h i (x i))) (by
      intro s hs0 hs1
      have hc := (hh i).2 (Set.mem_univ (x i)) (Set.mem_univ (x i + t))
        (by linarith : (0 : ℝ) ≤ 1 - s) hs0.le (by ring)
      simp only [smul_eq_mul] at hc
      have e1 : (1 - s) * x i + s * (x i + t) = x i + s * t := by ring
      rw [e1] at hc
      have := hst (s * t)
      simp only [smul_smul, zero_mul, zero_smul, add_zero]
      nlinarith)
    rw [hg] at *
    linarith
  have hconvg := bcd_convex_grad f hdiff hconv x z
  have hinner : inner ℝ g (z - x) = ∑ j, g j * (z j - x j) := by
    simp [PiLp.inner_apply, mul_comm]
  have hsumh : ∑ j, -(g j * (z j - x j)) ≤ ∑ j, (h j (z j) - h j (x j)) :=
    Finset.sum_le_sum fun j _ => by
      have := hcoord j (z j - x j); rwa [add_sub_cancel] at this
  rw [Finset.sum_neg_distrib, Finset.sum_sub_distrib] at hsumh
  rw [← hg] at hconvg
  linarith

/-- The card's coupling kink: `F(x, y) = |x − y| + 0.1 (x + y)²`. -/
noncomputable def stallCost (x y : ℝ) : ℝ := |x - y| + 1 / 10 * (x + y) ^ 2

/-- **A coupling kink can stall** (the card's Step 6 and What breaks). The cost
`F(x, y) = |x − y| + 0.1 (x + y)²` is convex, and at `(1, 1)`, where `F = 0.4`, no move of `x`
alone and no move of `y` alone lowers it, so coordinate descent stays there; yet
`F(0, 0) = 0` is lower. The kink `|x − y|` couples the two coordinates, so the separable rule
does not apply. -/
theorem coupling_kink_stalls :
    ConvexOn ℝ Set.univ (fun q : ℝ × ℝ => stallCost q.1 q.2) ∧
      stallCost 1 1 = 2 / 5 ∧
      (∀ t : ℝ, stallCost 1 1 ≤ stallCost t 1) ∧
      (∀ t : ℝ, stallCost 1 1 ≤ stallCost 1 t) ∧
      stallCost 0 0 = 0 ∧ stallCost 0 0 < stallCost 1 1 := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
  · refine ⟨convex_univ, ?_⟩
    intro p _ q _ a b ha hb hab
    simp only [stallCost, Prod.fst_add, Prod.snd_add, Prod.smul_fst, Prod.smul_snd, smul_eq_mul]
    have h1 : |a * p.1 + b * q.1 - (a * p.2 + b * q.2)| ≤
        a * |p.1 - p.2| + b * |q.1 - q.2| := by
      calc |a * p.1 + b * q.1 - (a * p.2 + b * q.2)|
          = |a * (p.1 - p.2) + b * (q.1 - q.2)| := by ring_nf
        _ ≤ |a * (p.1 - p.2)| + |b * (q.1 - q.2)| := abs_add_le _ _
        _ = a * |p.1 - p.2| + b * |q.1 - q.2| := by
          rw [abs_mul, abs_mul, abs_of_nonneg ha, abs_of_nonneg hb]
    have hb' : b = 1 - a := by linarith
    subst hb'
    nlinarith [mul_nonneg ha hb, sq_nonneg ((p.1 + p.2) - (q.1 + q.2))]
  · norm_num [stallCost]
  · intro t
    simp only [stallCost, sub_self, abs_zero]
    rcases le_total t 1 with ht | ht
    · rw [abs_of_nonpos (by linarith : t - 1 ≤ 0)]; nlinarith
    · rw [abs_of_nonneg (by linarith : 0 ≤ t - 1)]; nlinarith
  · intro t
    simp only [stallCost, sub_self, abs_zero]
    rcases le_total t 1 with ht | ht
    · rw [abs_of_nonneg (by linarith : 0 ≤ 1 - t)]; nlinarith
    · rw [abs_of_nonpos (by linarith : 1 - t ≤ 0)]; nlinarith
  · norm_num [stallCost]
  · norm_num [stallCost]

/-! ### The card's worked numbers, exactly

The tilt problem `f(x, y) = x² + xy + y² − 3x`, with exact coordinate steps `x = (3 − y)/2`
and `y = −x/2`, from `(0, 0)`. -/

/-- The tilt problem's cost. -/
def tilt (x y : ℝ) : ℝ := x ^ 2 + x * y + y ^ 2 - 3 * x

/-- Exact minimisation along `x`, then along `y`, on a point `(x, y)`. -/
noncomputable def stepX (q : ℝ × ℝ) : ℝ × ℝ := ((3 - q.2) / 2, q.2)
noncomputable def stepY (q : ℝ × ℝ) : ℝ × ℝ := (q.1, -q.1 / 2)
/-- Height above the minimum `f* = −3`. -/
def tiltGap (q : ℝ × ℝ) : ℝ := tilt q.1 q.2 + 3

-- The answer: both slopes are zero at (2, −1) and f* = −3.
example : 2 * 2 + (-1 : ℝ) - 3 = 0 ∧ 2 + 2 * (-1 : ℝ) = 0 ∧ tilt 2 (-1) = -3 := by
  norm_num [tilt]

-- The first two sweeps: x = 1.5, y = −0.75, x = 1.875, y = −0.9375.
example : stepX (0, 0) = (3 / 2, 0) ∧ stepY (stepX (0, 0)) = (3 / 2, -3 / 4) ∧
    stepX (stepY (stepX (0, 0))) = (15 / 8, -3 / 4) ∧
    stepY (stepX (stepY (stepX (0, 0)))) = (15 / 8, -15 / 16) := by
  norm_num [stepX, stepY]

-- The gap after each step: 3, 0.75, 0.1875, 0.046875, 0.01171875.
example : tiltGap (0, 0) = 3 ∧ tiltGap (3 / 2, 0) = 3 / 4 ∧ tiltGap (3 / 2, -3 / 4) = 3 / 16 ∧
    tiltGap (15 / 8, -3 / 4) = 3 / 64 ∧ tiltGap (15 / 8, -15 / 16) = 3 / 256 := by
  norm_num [tiltGap, tilt]

-- The error in x per sweep: (1.875 − 2)/(1.5 − 2) = 1/4.
example : ((15 / 8 : ℝ) - 2) / (3 / 2 - 2) = 1 / 4 := by norm_num

-- Step 4 in general: a sweep multiplies the error in x by 1/4, and after an x step the gap is
-- (3/4)(y + 1)², a quarter of which is left after the next y step.
example (y : ℝ) :
    (stepX (stepY (stepX (0, y)))).1 - 2 = ((stepX (0, y)).1 - 2) / 4 ∧
      tiltGap (stepX (0, y)) = 3 / 4 * (y + 1) ^ 2 ∧
      tiltGap (stepY (stepX (0, y))) = tiltGap (stepX (0, y)) / 4 := by
  refine ⟨?_, ?_, ?_⟩ <;> simp only [stepX, stepY, tiltGap, tilt] <;> ring

-- Step 1 at the start: slope −3 and L_x = 2 promise a drop of 9/4, and the drop is 3 − 3/4.
example : (-3 : ℝ) ^ 2 / (2 * 2) = 9 / 4 ∧ tiltGap (0, 0) - tiltGap (3 / 2, 0) = 9 / 4 := by
  norm_num [tiltGap, tilt]

-- The random rule's exact average after 1 and 2 steps is 3 (5/8)^k, by listing every run.
example : (tiltGap (stepX (0, 0)) + tiltGap (stepY (0, 0))) / 2 = 3 * (5 / 8) ∧
    (tiltGap (stepX (stepX (0, 0))) + tiltGap (stepY (stepX (0, 0))) +
        tiltGap (stepX (stepY (0, 0))) + tiltGap (stepY (stepY (0, 0)))) / 4 =
      3 * (5 / 8) ^ 2 := by
  norm_num [stepX, stepY, tiltGap, tilt]

-- The constant of the 1/k bound: 2 n L_max R² = 2 · 2 · 2 · 6 = 48.
example : (2 : ℝ) * 2 * 2 * 6 = 48 := by norm_num

-- The stall: F(0.5, 0.5) = 0.1 on the way down from (1, 1).
example : stallCost (1 / 2) (1 / 2) = 1 / 10 := by norm_num [stallCost]

-- ALS from v = (1, 0): u = Mv = (3, 1, 0), then v = Mᵀu / ‖u‖² = (1, 3/5), squared misses 7/5.
example : ((3 : ℝ) * 3 + 1 * 1 + 0 * 0) / (3 ^ 2 + 1 ^ 2 + 0 ^ 2) = 1 ∧
    ((2 : ℝ) * 3 + 0 * 1 + 1 * 0) / (3 ^ 2 + 1 ^ 2 + 0 ^ 2) = 3 / 5 ∧
    ((3 : ℝ) - 3 * 1) ^ 2 + (2 - 3 * (3 / 5)) ^ 2 + (1 - 1 * 1) ^ 2 + (0 - 1 * (3 / 5)) ^ 2 +
      (0 - 0 * 1) ^ 2 + (1 - 0 * (3 / 5)) ^ 2 = 7 / 5 := by
  norm_num

-- The certificate: the squares of M add to 15; MᵀM = [[10, 6], [6, 5]] has eigenvalues 14 and 1,
-- so no rank-1 fit misses by less than 15 − 14 = 1.
example : (3 : ℤ) ^ 2 + 2 ^ 2 + 1 ^ 2 + 0 ^ 2 + 0 ^ 2 + 1 ^ 2 = 15 ∧
    (3 : ℤ) * 3 + 1 * 1 + 0 * 0 = 10 ∧ (3 : ℤ) * 2 + 1 * 0 + 0 * 1 = 6 ∧
    (2 : ℤ) * 2 + 0 * 0 + 1 * 1 = 5 ∧
    ((10 : ℤ) - 14) * (5 - 14) - 6 * 6 = 0 ∧ ((10 : ℤ) - 1) * (5 - 1) - 6 * 6 = 0 ∧
    (15 : ℤ) - 14 = 1 := by
  decide

#print axioms random_coordinate_descent_rate
#print axioms separable_kink_coordinatewise_min_is_global
#print axioms coupling_kink_stalls
