-- The circle method: the five-square count is exactly the circle integral of the fifth power of the wave sum, Weyl's inequality bounds the wave sum of the squares, and the local factor at an odd prime not dividing n is 1 + (n/p)/p².
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Algebra.Order.Round
import Mathlib.Data.Fintype.Pi
import Mathlib.NumberTheory.LegendreSymbol.Basic
import Mathlib.Tactic.NormNum.LegendreSymbol
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.Analysis.SpecialFunctions.Complex.CircleAddChar
import Mathlib.NumberTheory.GaussSum
import Mathlib.NumberTheory.LegendreSymbol.QuadraticChar.Basic

open Complex

lemma circle_integral_exp_int (m : ℤ) :
    ∫ α in (0 : ℝ)..1, exp (2 * Real.pi * I * (m : ℂ) * (α : ℂ)) = if m = 0 then 1 else 0 := by
  split_ifs with hm
  · subst hm; simp
  · have hc : (2 * Real.pi * I * (m : ℂ)) ≠ 0 := by
      have : (m : ℂ) ≠ 0 := by exact_mod_cast hm
      have hpi : (Real.pi : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
      simp [hpi, I_ne_zero, this]
    rw [integral_exp_mul_complex hc]
    have : exp (2 * Real.pi * I * (m : ℂ) * ((1:ℝ) : ℂ)) = 1 := by
      rw [show 2 * Real.pi * I * (m : ℂ) * ((1:ℝ) : ℂ) = m * (2 * Real.pi * I) by push_cast; ring]
      exact exp_int_mul_two_pi_mul_I m
    rw [this]; simp

/-- Step 1, the count is an integral: with P = ⌊√n⌋ and the wave sum
f(α) = Σ e(αx²) over the whole numbers x from −P to P, where e(t) = exp(2πit),
the average of f(α)⁵ e(−nα) round the circle 0 ≤ α ≤ 1 is exactly r₅(n), the number of
ways to write n as a sum of five squares of whole numbers, signs and order counted. -/
theorem five_squares_count_eq_circle_integral (n : ℕ) :
    ∫ α in (0 : ℝ)..1,
        (∑ x ∈ Finset.Icc (-(Nat.sqrt n : ℤ)) (Nat.sqrt n),
            exp (2 * Real.pi * I * (α : ℂ) * ((x : ℂ) ^ 2))) ^ 5 *
          exp (-(2 * Real.pi * I * (n : ℂ) * (α : ℂ))) =
      (Nat.card {x : Fin 5 → ℤ // ∑ i, x i ^ 2 = (n : ℤ)} : ℂ) := by
  set S := Finset.Icc (-(Nat.sqrt n : ℤ)) (Nat.sqrt n) with hS
  set T := Fintype.piFinset (fun _ : Fin 5 => S) with hT
  have hexp : ∀ α : ℝ, (∑ x ∈ S, exp (2 * Real.pi * I * (α : ℂ) * ((x : ℂ) ^ 2))) ^ 5 *
          exp (-(2 * Real.pi * I * (n : ℂ) * (α : ℂ))) =
        ∑ v ∈ T, exp (2 * Real.pi * I * (((∑ i, v i ^ 2 - n : ℤ)) : ℂ) * (α : ℂ)) := by
    intro α
    have h5 : (∑ x ∈ S, exp (2 * Real.pi * I * (α : ℂ) * ((x : ℂ) ^ 2))) ^ 5 =
        ∏ _i : Fin 5, ∑ x ∈ S, exp (2 * Real.pi * I * (α : ℂ) * ((x : ℂ) ^ 2)) := by
      simp
    rw [h5, Finset.prod_univ_sum, Finset.sum_mul]
    refine Finset.sum_congr rfl fun v _ => ?_
    rw [← exp_sum, ← exp_add]
    congr 1
    push_cast
    rw [sub_eq_add_neg, mul_add, add_mul, Finset.mul_sum, Finset.sum_mul]
    congr 1
    · refine Finset.sum_congr rfl fun i _ => by ring
    · ring
  simp_rw [hexp]
  rw [intervalIntegral.integral_finsetSum]
  swap
  · intro v _
    apply Continuous.intervalIntegrable
    fun_prop
  simp_rw [circle_integral_exp_int]
  rw [Finset.sum_ite, Finset.sum_const_zero, add_zero, Finset.sum_const, nsmul_eq_mul, mul_one]
  norm_cast
  have hmem : ∀ x : Fin 5 → ℤ, ∑ i, x i ^ 2 = (n : ℤ) → x ∈ T := by
    intro x hx
    rw [hT, Fintype.mem_piFinset]
    intro i
    rw [hS, Finset.mem_Icc, ← abs_le]
    have hle : x i ^ 2 ≤ n := by
      rw [← hx]
      exact Finset.single_le_sum (f := fun j => x j ^ 2) (fun j _ => sq_nonneg _) (Finset.mem_univ i)
    have h1 : (x i).natAbs ^ 2 ≤ n := by
      have : ((x i).natAbs ^ 2 : ℤ) ≤ n := by rw [Int.natAbs_sq]; exact hle
      exact_mod_cast this
    have h2 : (x i).natAbs ≤ Nat.sqrt n := Nat.le_sqrt'.mpr h1
    rw [Int.abs_eq_natAbs]; exact_mod_cast h2
  have e : {x : Fin 5 → ℤ // ∑ i, x i ^ 2 = (n : ℤ)} ≃
      {x // x ∈ T.filter (fun v => ∑ i, v i ^ 2 - (n:ℤ) = 0)} :=
    Equiv.subtypeEquivRight (fun x => by
      rw [Finset.mem_filter, sub_eq_zero]
      exact ⟨fun h => ⟨hmem x h, h⟩, fun h => h.2⟩)
  rw [Nat.card_congr e, Nat.card_eq_fintype_card, Fintype.card_coe]

lemma weyl_geom_identity (z : ℂ) (h0 : z ≠ 0) (a : ℤ) (m : ℕ) :
    (z - 1) * ∑ y ∈ Finset.Icc a (a + m - 1), z ^ y = z ^ (a + m) - z ^ a := by
  induction m with
  | zero =>
    have : Finset.Icc a (a + ((0:ℕ):ℤ) - 1) = ∅ := by
      ext y; simp only [Finset.mem_Icc, Finset.notMem_empty, iff_false]; omega
    rw [this]; simp
  | succ m ih =>
    have hins : Finset.Icc a (a + ((m + 1 : ℕ) : ℤ) - 1) = insert (a + m) (Finset.Icc a (a + m - 1)) := by
      ext y; simp only [Finset.mem_Icc, Finset.mem_insert]; push_cast; omega
    have hnot : (a + m) ∉ Finset.Icc a (a + m - 1) := by simp
    rw [hins, Finset.sum_insert hnot, mul_add, ih]
    have hz : z ^ (a + ((m + 1 : ℕ) : ℤ)) = z ^ (a + m) * z := by
      rw [← zpow_add_one₀ h0]; push_cast; ring_nf
    rw [hz]; ring

lemma weyl_norm_sub_one (θ : ℝ) :
    4 * |θ - round θ| ≤ ‖exp (2 * Real.pi * I * (θ : ℂ)) - 1‖ := by
  set δ := θ - round θ with hδ
  have hz : exp (2 * Real.pi * I * (θ : ℂ)) = exp (I * ((2 * Real.pi * δ : ℝ) : ℂ)) := by
    have : (2 * Real.pi * I * (θ : ℂ)) = I * ((2 * Real.pi * δ : ℝ) : ℂ) + (round θ : ℤ) * (2 * Real.pi * I) := by
      rw [hδ]; push_cast; ring
    rw [this, exp_add, exp_int_mul_two_pi_mul_I, mul_one]
  rw [hz, norm_exp_I_mul_ofReal_sub_one]
  have hb : |δ| ≤ 1 / 2 := abs_sub_round θ
  have h1 : |Real.pi * δ| ≤ Real.pi / 2 := by
    rw [abs_mul, abs_of_pos Real.pi_pos]
    nlinarith [Real.pi_pos]
  have h2 := Real.mul_abs_le_abs_sin h1
  rw [abs_mul, abs_of_pos Real.pi_pos] at h2
  have h3 : 2 / Real.pi * (Real.pi * |δ|) = 2 * |δ| := by
    field_simp
  rw [h3] at h2
  rw [show 2 * Real.pi * δ / 2 = Real.pi * δ by ring, Real.norm_eq_abs, abs_mul]
  norm_num
  linarith

lemma weyl_geom_bound (θ : ℝ) (a b : ℤ) (hδ : θ - round θ ≠ 0) :
    ‖∑ y ∈ Finset.Icc a b, exp (2 * Real.pi * I * (θ : ℂ) * (y : ℂ))‖ ≤
      1 / (2 * |θ - round θ|) := by
  set z := exp (2 * Real.pi * I * (θ : ℂ)) with hzdef
  have hpow : ∀ y : ℤ, exp (2 * Real.pi * I * (θ : ℂ) * (y : ℂ)) = z ^ y := by
    intro y; rw [hzdef, ← exp_int_mul]; ring_nf
  simp_rw [hpow]
  have hpos : 0 < |θ - round θ| := abs_pos.mpr hδ
  have hz1 := weyl_norm_sub_one θ
  rw [← hzdef] at hz1
  have hzn : ‖z‖ = 1 := by
    rw [hzdef, show 2 * Real.pi * I * (θ : ℂ) = ((2 * Real.pi * θ : ℝ) : ℂ) * I by push_cast; ring]
    exact norm_exp_ofReal_mul_I _
  have hzpos : 0 < ‖z - 1‖ := by linarith
  have hz0 : z ≠ 0 := by intro h; rw [h] at hzn; simp at hzn
  have key : ‖∑ y ∈ Finset.Icc a b, z ^ y‖ * ‖z - 1‖ ≤ 2 := by
    by_cases hab : b < a
    · rw [Finset.Icc_eq_empty (by omega)]; simp
    · obtain ⟨m, hm⟩ : ∃ m : ℕ, b = a + m - 1 := ⟨(b - a + 1).toNat, by omega⟩
      rw [hm, mul_comm, ← norm_mul, weyl_geom_identity z hz0]
      calc ‖z ^ (a + m) - z ^ a‖ ≤ ‖z ^ (a + m)‖ + ‖z ^ a‖ := norm_sub_le _ _
        _ = 2 := by rw [norm_zpow, norm_zpow, hzn]; norm_num
  rw [le_div_iff₀ (by positivity)]
  calc ‖∑ y ∈ Finset.Icc a b, z ^ y‖ * (2 * |θ - round θ|)
      = (‖∑ y ∈ Finset.Icc a b, z ^ y‖ * (4 * |θ - round θ|)) / 2 := by ring
    _ ≤ (‖∑ y ∈ Finset.Icc a b, z ^ y‖ * ‖z - 1‖) / 2 := by gcongr
    _ ≤ 2 / 2 := by gcongr
    _ = 1 := by norm_num

lemma weyl_norm_sum_le_card (θ : ℝ) (s : Finset ℤ) :
    ‖∑ y ∈ s, exp (2 * Real.pi * I * (θ : ℂ) * (y : ℂ))‖ ≤ s.card := by
  calc ‖∑ y ∈ s, exp (2 * Real.pi * I * (θ : ℂ) * (y : ℂ))‖
      ≤ ∑ y ∈ s, ‖exp (2 * Real.pi * I * (θ : ℂ) * (y : ℂ))‖ := norm_sum_le _ _
    _ = ∑ _y ∈ s, (1 : ℝ) := by
        refine Finset.sum_congr rfl fun y _ => ?_
        rw [show 2 * Real.pi * I * (θ : ℂ) * (y : ℂ) = ((2 * Real.pi * θ * y : ℝ) : ℂ) * I by
          push_cast; ring]
        exact norm_exp_ofReal_mul_I _
    _ = s.card := by simp

lemma weyl_reindex (P : ℕ) (F : ℤ → ℤ → ℂ) :
    ∑ x ∈ Finset.Icc (-(P : ℤ)) P, ∑ y ∈ Finset.Icc (-(P : ℤ)) P, F x y =
      ∑ h ∈ Finset.Icc (-(2 * P : ℤ)) (2 * P),
        ∑ y ∈ Finset.Icc (max (-(P : ℤ)) (-(P : ℤ) - h)) (min (P : ℤ) (P - h)), F (y + h) y := by
  rw [← Finset.sum_product' (f := fun x y => F x y)]
  rw [← Finset.sum_finset_product' (((Finset.Icc (-(2 * P : ℤ)) (2 * P)) ×ˢ
      (Finset.Icc (-(P : ℤ)) P)).filter
      (fun q => q.2 ∈ Finset.Icc (max (-(P : ℤ)) (-(P : ℤ) - q.1)) (min (P : ℤ) (P - q.1))))
      _ _ ?_ (f := fun h y => F (y + h) y)]
  swap
  · intro q
    simp only [Finset.mem_filter, Finset.mem_product, Finset.mem_Icc]
    omega
  refine Finset.sum_nbij' (fun p => (p.1 - p.2, p.2)) (fun q => (q.2 + q.1, q.2)) ?_ ?_ ?_ ?_ ?_
  · intro p hp
    simp only [Finset.mem_filter, Finset.mem_product, Finset.mem_Icc] at hp ⊢
    omega
  · intro q hq
    simp only [Finset.mem_filter, Finset.mem_product, Finset.mem_Icc] at hq ⊢
    omega
  · intro p _; ext <;> simp
  · intro q _; ext <;> simp
  · intro p _; simp

/-- Step 5, Weyl's inequality for squares: for every whole number P and every real α, the wave
sum f(α) = Σ e(αx²) over x from −P to P satisfies
|f(α)|² ≤ Σ over |h| ≤ 2P of min(2P + 1, 1/(2‖2hα‖)), where ‖θ‖ = |θ − round θ| is the distance
from θ to the nearest whole number, and a term with ‖2hα‖ = 0 is 2P + 1. -/
theorem weyl_inequality_for_squares (P : ℕ) (α : ℝ) :
    ‖∑ x ∈ Finset.Icc (-(P : ℤ)) P, exp (2 * Real.pi * I * (α : ℂ) * ((x : ℂ) ^ 2))‖ ^ 2 ≤
      ∑ h ∈ Finset.Icc (-(2 * P : ℤ)) (2 * P),
        (if |2 * h * α - round (2 * h * α)| = 0 then (2 * P + 1 : ℝ)
          else min (2 * P + 1 : ℝ) (1 / (2 * |2 * h * α - round (2 * h * α)|))) := by
  set f := ∑ x ∈ Finset.Icc (-(P : ℤ)) P, exp (2 * Real.pi * I * (α : ℂ) * ((x : ℂ) ^ 2)) with hf
  have hsq : ‖f‖ ^ 2 = ‖f * (starRingEnd ℂ) f‖ := by
    rw [norm_mul, Complex.norm_conj, sq]
  have hconj : ∀ y : ℤ, (starRingEnd ℂ) (exp (2 * Real.pi * I * (α : ℂ) * ((y : ℂ) ^ 2))) =
      exp (-(2 * Real.pi * I * (α : ℂ) * ((y : ℂ) ^ 2))) := by
    intro y
    rw [← exp_conj]; congr 1
    simp [map_mul, conj_ofReal, conj_I, map_ofNat]
  have hprod : f * (starRingEnd ℂ) f =
      ∑ h ∈ Finset.Icc (-(2 * P : ℤ)) (2 * P),
        exp (2 * Real.pi * I * (α : ℂ) * ((h : ℂ) ^ 2)) *
        ∑ y ∈ Finset.Icc (max (-(P : ℤ)) (-(P : ℤ) - h)) (min (P : ℤ) (P - h)),
          exp (2 * Real.pi * I * ((2 * h * α : ℝ) : ℂ) * (y : ℂ)) := by
    rw [hf, map_sum, Finset.sum_mul_sum, weyl_reindex]
    refine Finset.sum_congr rfl fun h _ => ?_
    rw [Finset.mul_sum]
    refine Finset.sum_congr rfl fun y _ => ?_
    rw [hconj, ← exp_add, ← exp_add]
    congr 1
    push_cast; ring
  rw [hsq, hprod]
  refine (norm_sum_le _ _).trans (Finset.sum_le_sum fun h hh => ?_)
  rw [norm_mul, show 2 * Real.pi * I * (α : ℂ) * ((h : ℂ) ^ 2) = ((2 * Real.pi * α * h ^ 2 : ℝ) : ℂ) * I by
    push_cast; ring, norm_exp_ofReal_mul_I, one_mul]
  have hcard : ‖∑ y ∈ Finset.Icc (max (-(P : ℤ)) (-(P : ℤ) - h)) (min (P : ℤ) (P - h)),
          exp (2 * Real.pi * I * ((2 * h * α : ℝ) : ℂ) * (y : ℂ))‖ ≤ (2 * P + 1 : ℝ) := by
    refine (weyl_norm_sum_le_card _ _).trans ?_
    rw [Int.card_Icc]
    have : (min (P : ℤ) (P - h) + 1 - max (-(P : ℤ)) (-(P : ℤ) - h)).toNat ≤ 2 * P + 1 := by omega
    exact_mod_cast this
  split_ifs with h0
  · exact hcard
  · refine le_min hcard ?_
    have := weyl_geom_bound (2 * h * α) (max (-(P : ℤ)) (-(P : ℤ) - h)) (min (P : ℤ) (P - h))
      (fun h1 => h0 (by rw [h1, abs_zero]))
    exact this

lemma five_sq_fourier_count (p : ℕ) [Fact p.Prime] (hp : p ≠ 2) (a : ZMod p) (ha : a ≠ 0) :
    ((Finset.univ.filter (fun x : Fin 5 → ZMod p => ∑ i, x i ^ 2 = a)).card : ℂ) =
      (p : ℂ) ^ 4 + (p : ℂ) ^ 2 * (quadraticChar (ZMod p) a : ℂ) := by
  classical
  have hF : ringChar (ZMod p) ≠ 2 := by rwa [ZMod.ringChar_zmod_n]
  have hcard : Fintype.card (ZMod p) = p := ZMod.card p
  set χ : MulChar (ZMod p) ℂ := (quadraticChar (ZMod p)).ringHomComp (Int.castRingHom ℂ) with hχ
  have hχapp : ∀ t, χ t = (quadraticChar (ZMod p) t : ℂ) := fun t => rfl
  have hχ1 : χ ≠ 1 := (MulChar.ringHomComp_ne_one_iff (RingHom.injective_int _)).mpr
    (quadraticChar_ne_one hF)
  have hχq : χ.IsQuadratic := (quadraticChar_isQuadratic (ZMod p)).comp _
  set ψ : AddChar (ZMod p) ℂ := ZMod.stdAddChar (N := p) with hψ
  have hψp : ψ.IsPrimitive := ZMod.isPrimitive_stdAddChar p
  set g := gaussSum χ ψ with hg
  have hg2 : g ^ 2 = χ (-1) * p := by
    rw [hg, gaussSum_sq hχ1 hχq hψp, hcard]
  -- the sum over a shifted Gauss sum
  have hshift : ∀ t : ZMod p, t ≠ 0 → ∑ y, χ y * ψ (t * y) = χ t * g := by
    intro t ht
    have := gaussSum_mulShift_eq χ ψ (Units.mk0 t ht)
    rw [hχq.inv] at this
    simpa [gaussSum, AddChar.mulShift_apply, hg] using this
  -- the one-variable sum
  have hS : ∀ t : ZMod p, t ≠ 0 → ∑ x : ZMod p, ψ (t * x ^ 2) = χ t * g := by
    intro t ht
    have hfib : ∑ x : ZMod p, ψ (t * x ^ 2) =
        ∑ y : ZMod p, ((Finset.univ.filter (fun x : ZMod p => x ^ 2 = y)).card : ℂ) * ψ (t * y) := by
      rw [← Finset.sum_fiberwise Finset.univ (fun x : ZMod p => x ^ 2)]
      refine Finset.sum_congr rfl fun y _ => ?_
      rw [Finset.sum_congr rfl (g := fun _ => ψ (t * y)), Finset.sum_const, nsmul_eq_mul]
      intro x hx
      rw [(Finset.mem_filter.mp hx).2]
    have hsq : ∀ y : ZMod p, ((Finset.univ.filter (fun x : ZMod p => x ^ 2 = y)).card : ℂ) = χ y + 1 := by
      intro y
      have h := quadraticChar_card_sqrts hF y
      rw [Set.toFinset_ofPred] at h
      rw [hχapp]
      exact_mod_cast h
    rw [hfib]
    simp_rw [hsq, add_mul, one_mul, Finset.sum_add_distrib]
    rw [hshift t ht]
    have h0 : ∑ y : ZMod p, ψ (t * y) = 0 := by
      have := AddChar.sum_mulShift (ψ := ψ) t hψp
      rw [ite_eq_right_of_eq_false _ _ (eq_false ht)] at this
      simpa [mul_comm] using this
    rw [h0, add_zero]
  have hS' : ∀ t : ZMod p, (∑ x : ZMod p, ψ (t * x ^ 2)) ^ 5 =
      (if t = 0 then (p : ℂ) ^ 5 else 0) + χ t * g ^ 5 := by
    intro t
    by_cases ht : t = 0
    · subst ht; simp [hcard, MulChar.map_zero]
    · rw [hS t ht, ite_eq_right_of_eq_false _ _ (eq_false ht), zero_add, mul_pow]
      congr 1
      rcases quadraticChar_dichotomy ht with h | h <;> norm_num [hχapp, h]
  -- orthogonality
  have horth : ∀ x : Fin 5 → ZMod p,
      ∑ t : ZMod p, ψ (t * (∑ i, x i ^ 2 - a)) = if ∑ i, x i ^ 2 = a then (p : ℂ) else 0 := by
    intro x
    rw [AddChar.sum_mulShift _ hψp, hcard]
    simp [sub_eq_zero]
  have hcount : (p : ℂ) * ((Finset.univ.filter (fun x : Fin 5 → ZMod p => ∑ i, x i ^ 2 = a)).card : ℂ)
      = ∑ x : Fin 5 → ZMod p, ∑ t : ZMod p, ψ (t * (∑ i, x i ^ 2 - a)) := by
    simp_rw [horth]
    rw [Finset.sum_ite, Finset.sum_const_zero, add_zero, Finset.sum_const, nsmul_eq_mul, mul_comm]
  have hsplit : ∀ (t : ZMod p) (x : Fin 5 → ZMod p),
      ψ (t * (∑ i, x i ^ 2 - a)) = ψ (-(t * a)) * ∏ i, ψ (t * x i ^ 2) := by
    intro t x
    rw [mul_sub, sub_eq_add_neg, AddChar.map_add_eq_mul, mul_comm, Finset.mul_sum]
    congr 1
    simp only [Fin.sum_univ_five, Fin.prod_univ_five, AddChar.map_add_eq_mul]
  have hmain : (p : ℂ) * ((Finset.univ.filter (fun x : Fin 5 → ZMod p => ∑ i, x i ^ 2 = a)).card : ℂ)
      = ∑ t : ZMod p, ψ (-(t * a)) * (∑ y : ZMod p, ψ (t * y ^ 2)) ^ 5 := by
    rw [hcount, Finset.sum_comm]
    refine Finset.sum_congr rfl fun t _ => ?_
    simp_rw [hsplit]
    rw [← Finset.mul_sum]
    congr 1
    rw [← Finset.card_fin 5, ← Finset.prod_const, Finset.card_fin]
    rw [Fintype.prod_sum]
  simp_rw [hS', mul_add, Finset.sum_add_distrib] at hmain
  have h1 : ∑ t : ZMod p, ψ (-(t * a)) * (if t = 0 then (p : ℂ) ^ 5 else 0) = (p : ℂ) ^ 5 := by
    simp
  have h2 : ∑ t : ZMod p, ψ (-(t * a)) * (χ t * g ^ 5) = g ^ 6 * χ (-a) := by
    have := hshift (-a) (neg_ne_zero.mpr ha)
    calc ∑ t : ZMod p, ψ (-(t * a)) * (χ t * g ^ 5) = g ^ 5 * ∑ t, χ t * ψ (-a * t) := by
          rw [Finset.mul_sum]
          refine Finset.sum_congr rfl fun t _ => ?_
          rw [show -a * t = -(t * a) by ring]; ring
      _ = g ^ 6 * χ (-a) := by rw [this]; ring
  rw [h1, h2] at hmain
  have hg6 : g ^ 6 = χ (-1) * (p : ℂ) ^ 3 := by
    rw [show g ^ 6 = (g ^ 2) ^ 3 by ring, hg2, mul_pow]
    congr 1
    rcases quadraticChar_dichotomy (F := ZMod p) (a := -1) (by simp) with h | h <;> norm_num [hχapp, h]
  have hneg : χ (-1) * χ (-a) = χ a := by
    rw [← map_mul]; congr 1; ring
  rw [hg6, mul_assoc, mul_comm ((p : ℂ) ^ 3), ← mul_assoc, hneg] at hmain
  have hp0 : (p : ℂ) ≠ 0 := by exact_mod_cast (Fact.out : p.Prime).ne_zero
  apply mul_left_cancel₀ hp0
  rw [hmain, hχapp]
  ring

open Finset in
lemma five_sq_linear_count (p : ℕ) [Fact p.Prime] (w : Fin 5 → ZMod p) (i0 : Fin 5)
    (hw : w i0 ≠ 0) (c : ZMod p) :
    (univ.filter (fun b : Fin 5 → ZMod p => c + ∑ i, w i * b i = 0)).card = p ^ 4 := by
  classical
  have hind : ∀ c c' : ZMod p, (univ.filter (fun b : Fin 5 → ZMod p => c + ∑ i, w i * b i = 0)).card =
      (univ.filter (fun b : Fin 5 → ZMod p => c' + ∑ i, w i * b i = 0)).card := by
    intro c c'
    set s := (c - c') / w i0 with hs
    have hlin : ∀ b : Fin 5 → ZMod p, ∀ t : ZMod p,
        ∑ i, w i * (b + (Pi.single i0 t : Fin 5 → ZMod p)) i = ∑ i, w i * b i + w i0 * t := by
      intro b t
      simp only [Pi.add_apply, mul_add, Finset.sum_add_distrib, Pi.single_apply, mul_ite, mul_zero,
        Finset.sum_ite_eq', Finset.mem_univ, ite_true]
    refine Finset.card_bij' (fun b _ => b + (Pi.single i0 s : Fin 5 → ZMod p)) (fun b _ => b + (Pi.single i0 (-s) : Fin 5 → ZMod p))
      ?_ ?_ ?_ ?_
    · intro b hb
      simp only [mem_filter, mem_univ, true_and] at hb ⊢
      rw [hlin, hs, mul_div_cancel₀ _ hw]
      linear_combination hb
    · intro b hb
      simp only [mem_filter, mem_univ, true_and] at hb ⊢
      rw [hlin, hs, mul_neg, mul_div_cancel₀ _ hw]
      linear_combination hb
    · intro b _
      ext i; simp only [Pi.add_apply, Pi.single_apply]; split_ifs <;> ring
    · intro b _
      ext i; simp only [Pi.add_apply, Pi.single_apply]; split_ifs <;> ring
  have htot := Finset.card_eq_sum_card_fiberwise (s := (univ : Finset (Fin 5 → ZMod p)))
    (t := univ) (f := fun b => -∑ i, w i * b i) (fun _ _ => Finset.mem_coe.mpr (mem_univ _))
  have hfib : ∀ c' : ZMod p, (univ.filter (fun b : Fin 5 → ZMod p => -∑ i, w i * b i = c')).card =
      (univ.filter (fun b : Fin 5 → ZMod p => c + ∑ i, w i * b i = 0)).card := by
    intro c'
    rw [hind c c']
    congr 1
    apply Finset.filter_congr
    intro b _
    rw [neg_eq_iff_add_eq_zero, add_comm]
  rw [Finset.sum_congr rfl (fun c' _ => hfib c'), Finset.sum_const, Finset.card_univ,
    Finset.card_univ, ZMod.card, smul_eq_mul, Fintype.card_fun, ZMod.card, Fintype.card_fin] at htot
  have hp : 0 < p := (Fact.out : p.Prime).pos
  have : p * p ^ 4 = p * (univ.filter (fun b : Fin 5 → ZMod p => c + ∑ i, w i * b i = 0)).card := by
    rw [← htot]; ring
  exact (Nat.eq_of_mul_eq_mul_left hp this).symm

lemma five_sq_digit_equiv (q p : ℕ) [NeZero q] [NeZero p] :
    Function.Bijective (fun ab : ZMod q × ZMod p =>
      (((ab.1.val + q * ab.2.val : ℕ)) : ZMod (q * p))) := by
  have : NeZero (q * p) := ⟨Nat.mul_ne_zero (NeZero.ne q) (NeZero.ne p)⟩
  rw [Fintype.bijective_iff_injective_and_card]
  refine ⟨?_, by simp [ZMod.card]⟩
  rintro ⟨a, b⟩ ⟨a', b'⟩ h
  rw [ZMod.natCast_eq_natCast_iff'] at h
  have ha := a.val_lt; have hb := b.val_lt; have ha' := a'.val_lt; have hb' := b'.val_lt
  have hlt : ∀ x y : ℕ, x < q → y < p → x + q * y < q * p := by
    intro x y hx hy
    calc x + q * y < q + q * y := by omega
      _ = q * (y + 1) := by ring
      _ ≤ q * p := Nat.mul_le_mul_left _ hy
  rw [Nat.mod_eq_of_lt (hlt _ _ ha hb), Nat.mod_eq_of_lt (hlt _ _ ha' hb')] at h
  have hq : 0 < q := Nat.pos_of_ne_zero (NeZero.ne q)
  have h1 : a.val = a'.val := by
    have := congrArg (· % q) h
    simpa [Nat.add_mul_mod_self_left, Nat.mod_eq_of_lt ha, Nat.mod_eq_of_lt ha'] using this
  have h2 : b.val = b'.val := by
    have := congrArg (· / q) h
    rwa [Nat.add_mul_div_left _ _ hq, Nat.add_mul_div_left _ _ hq, Nat.div_eq_of_lt ha,
      Nat.div_eq_of_lt ha', zero_add, zero_add] at this
  rw [ZMod.val_injective _ h1, ZMod.val_injective _ h2]

open Finset in
lemma five_sq_lift_count (p q n : ℕ) [Fact p.Prime] [NeZero q] (hp : p ≠ 2) (hpq : p ∣ q)
    (hn : ¬ p ∣ n) :
    (univ.filter (fun x : Fin 5 → ZMod (q * p) => ∑ i, x i ^ 2 = (n : ZMod (q * p)))).card =
      p ^ 4 * (univ.filter (fun x : Fin 5 → ZMod q => ∑ i, x i ^ 2 = (n : ZMod q))).card := by
  classical
  have : NeZero p := ⟨(Fact.out : p.Prime).ne_zero⟩
  have : NeZero (q * p) := ⟨Nat.mul_ne_zero (NeZero.ne q) (NeZero.ne p)⟩
  have hq : (0 : ℤ) < q := by exact_mod_cast Nat.pos_of_ne_zero (NeZero.ne q)
  set ef := fun ab : ZMod q × ZMod p => (((ab.1.val + q * ab.2.val : ℕ)) : ZMod (q * p)) with hef
  have hbij := five_sq_digit_equiv q p
  set eq := Equiv.ofBijective ef hbij with heq
  -- the integer form of the condition mod q·p
  set A : (Fin 5 → ZMod q) → Fin 5 → ℤ := fun a i => ((a i).val : ℤ) with hA
  set B : (Fin 5 → ZMod p) → Fin 5 → ℤ := fun b i => ((b i).val : ℤ) with hB
  set D : (Fin 5 → ZMod q) → ℤ := fun a => ∑ i, A a i ^ 2 - n with hD
  have hcondq : ∀ a : Fin 5 → ZMod q, (∑ i, a i ^ 2 = (n : ZMod q)) ↔ (q : ℤ) ∣ D a := by
    intro a
    rw [← sub_eq_zero, ← ZMod.intCast_zmod_eq_zero_iff_dvd]
    simp only [hD, hA]
    push_cast
    simp
  have hcondqp : ∀ (a : Fin 5 → ZMod q) (b : Fin 5 → ZMod p),
      (∑ i, (ef (a i, b i)) ^ 2 = (n : ZMod (q * p))) ↔
        ((q * p : ℕ) : ℤ) ∣ D a + q * (2 * ∑ i, A a i * B b i + q * ∑ i, B b i ^ 2) := by
    intro a b
    rw [← sub_eq_zero, ← ZMod.intCast_zmod_eq_zero_iff_dvd]
    simp only [hef, hD, hA, hB]
    push_cast
    simp only [Fin.sum_univ_five]
    constructor <;> intro h <;> linear_combination h
  have hint : ∀ (a : Fin 5 → ZMod q) (b : Fin 5 → ZMod p),
      ((q * p : ℕ) : ℤ) ∣ D a + q * (2 * ∑ i, A a i * B b i + q * ∑ i, B b i ^ 2) ↔
        (q : ℤ) ∣ D a ∧ (p : ℤ) ∣ D a / q + 2 * ∑ i, A a i * B b i := by
    intro a b
    obtain ⟨r, hr⟩ := hpq
    have hpq' : (p : ℤ) ∣ q := ⟨r, by exact_mod_cast hr⟩
    push_cast
    constructor
    · intro h
      have hqD : (q : ℤ) ∣ D a := by
        have h1 : (q : ℤ) ∣ D a + q * (2 * ∑ i, A a i * B b i + q * ∑ i, B b i ^ 2) :=
          (Dvd.intro _ rfl).trans h
        have h2 : (q : ℤ) ∣ q * (2 * ∑ i, A a i * B b i + q * ∑ i, B b i ^ 2) := Dvd.intro _ rfl
        simpa using (Int.dvd_add_left h2).mp h1
      refine ⟨hqD, ?_⟩
      obtain ⟨E, hE⟩ := hqD
      rw [hE] at h
      rw [hE, Int.mul_ediv_cancel_left _ hq.ne']
      rw [← mul_add] at h
      have h3 := (mul_dvd_mul_iff_left hq.ne').mp h
      have h4 : (p : ℤ) ∣ q * ∑ i, B b i ^ 2 := hpq'.mul_right _
      rw [← add_assoc] at h3
      exact (Int.dvd_add_left h4).mp h3
    · rintro ⟨⟨E, hE⟩, h⟩
      rw [hE, Int.mul_ediv_cancel_left _ hq.ne'] at h
      rw [hE, ← mul_add, ← add_assoc]
      exact mul_dvd_mul_left _ (dvd_add h (hpq'.mul_right _))
  -- some coordinate is a unit mod p
  have hunit : ∀ a : Fin 5 → ZMod q, (q : ℤ) ∣ D a → ∃ i0, (2 * (A a i0 : ZMod p)) ≠ 0 := by
    intro a hqa
    have hpD : (p : ℤ) ∣ D a := (Int.natCast_dvd_natCast.mpr hpq).trans hqa
    rw [← ZMod.intCast_zmod_eq_zero_iff_dvd] at hpD
    simp only [hD] at hpD
    push_cast at hpD
    by_contra hall
    push Not at hall
    have h2 : (2 : ZMod p) ≠ 0 := by
      intro h2
      have : ((2 : ℕ) : ZMod p) = 0 := by exact_mod_cast h2
      rw [ZMod.natCast_eq_zero_iff] at this
      have := (Nat.prime_dvd_prime_iff_eq (Fact.out : p.Prime) Nat.prime_two).mp this
      exact hp this
    have hz : ∀ i, (A a i : ZMod p) = 0 := fun i => (mul_eq_zero.mp (hall i)).resolve_left h2
    simp only [hz] at hpD
    norm_num at hpD
    exact hn ((ZMod.natCast_eq_zero_iff n p).mp hpD)
  -- counting
  have hcard_lhs : (univ.filter (fun x : Fin 5 → ZMod (q * p) => ∑ i, x i ^ 2 = (n : ZMod (q * p)))).card
      = (univ.filter (fun y : (Fin 5 → ZMod q) × (Fin 5 → ZMod p) =>
          ∑ i, (ef (y.1 i, y.2 i)) ^ 2 = (n : ZMod (q * p)))).card := by
    symm
    refine Finset.card_bij (fun y _ => fun i => ef (y.1 i, y.2 i)) ?_ ?_ ?_
    · intro y hy
      simpa using hy
    · intro y _ y' _ h
      have h' : ∀ i, (y.1 i, y.2 i) = (y'.1 i, y'.2 i) := fun i => hbij.1 (congrFun h i)
      ext i
      · exact congrArg Prod.fst (h' i)
      · exact congrArg Prod.snd (h' i)
    · intro x hx
      have hsym : ∀ z, ef ((eq.symm z).1, (eq.symm z).2) = z := fun z => by
        rw [Prod.mk.eta]; exact eq.apply_symm_apply z
      refine ⟨(fun i => (eq.symm (x i)).1, fun i => (eq.symm (x i)).2), ?_, ?_⟩
      · simp only [mem_filter, mem_univ, true_and] at hx ⊢
        simp only [hsym]; exact hx
      · funext i
        exact hsym (x i)
  rw [hcard_lhs, Finset.card_filter, Fintype.sum_prod_type]
  have hinner : ∀ a : Fin 5 → ZMod q,
      (∑ b : Fin 5 → ZMod p, if ∑ i, (ef (a i, b i)) ^ 2 = (n : ZMod (q * p)) then 1 else 0) =
        if ∑ i, a i ^ 2 = (n : ZMod q) then p ^ 4 else 0 := by
    intro a
    rw [← Finset.card_filter]
    simp_rw [hcondqp, hint]
    split_ifs with ha
    · have hqa := (hcondq a).mp ha
      obtain ⟨i0, hi0⟩ := hunit a hqa
      rw [← five_sq_linear_count p (fun i => 2 * (A a i : ZMod p)) i0 hi0 ((D a / q : ℤ) : ZMod p)]
      congr 1
      apply Finset.filter_congr
      intro b _
      rw [and_iff_right hqa, ← ZMod.intCast_zmod_eq_zero_iff_dvd]
      push_cast
      simp only [hB, Int.cast_natCast, ZMod.natCast_zmod_val, Finset.mul_sum, mul_assoc]
    · have : ¬ (q : ℤ) ∣ D a := fun h => ha ((hcondq a).mpr h)
      simp [this]
  simp_rw [hinner]
  rw [Finset.sum_ite, Finset.sum_const_zero, add_zero, Finset.sum_const, smul_eq_mul, mul_comm]

lemma five_sq_lift_count_of_eq (p q m n : ℕ) [Fact p.Prime] [NeZero q] [NeZero m] (hp : p ≠ 2)
    (hpq : p ∣ q) (hn : ¬ p ∣ n) (hm : m = q * p) :
    (Finset.univ.filter (fun x : Fin 5 → ZMod m => ∑ i, x i ^ 2 = (n : ZMod m))).card =
      p ^ 4 * (Finset.univ.filter (fun x : Fin 5 → ZMod q => ∑ i, x i ^ 2 = (n : ZMod q))).card := by
  subst hm
  convert five_sq_lift_count p q n hp hpq hn

lemma five_sq_prime_power_count (p n : ℕ) [Fact p.Prime] (hp : p ≠ 2) (hn : ¬ p ∣ n) (j : ℕ) :
    (Finset.univ.filter (fun x : Fin 5 → ZMod (p ^ (j + 1)) =>
        ∑ i, x i ^ 2 = (n : ZMod (p ^ (j + 1))))).card =
      p ^ (4 * j) * (Finset.univ.filter (fun x : Fin 5 → ZMod p => ∑ i, x i ^ 2 = (n : ZMod p))).card := by
  have : NeZero p := ⟨(Fact.out : p.Prime).ne_zero⟩
  induction j with
  | zero =>
    have h1 : ∀ m : ℕ, [NeZero m] → m = p →
        (Finset.univ.filter (fun x : Fin 5 → ZMod m => ∑ i, x i ^ 2 = (n : ZMod m))).card =
        (Finset.univ.filter (fun x : Fin 5 → ZMod p => ∑ i, x i ^ 2 = (n : ZMod p))).card := by
      intro m _ hm; subst hm; convert rfl
    rw [h1 _ (by simp)]; simp
  | succ j ih =>
    rw [five_sq_lift_count_of_eq p (p ^ (j + 1)) (p ^ (j + 1 + 1)) n hp (dvd_pow_self p (by omega)) hn
      (pow_succ p (j + 1)), ih]
    ring

/-- Step 4, the local factor: for an odd prime p that does not divide n, and every k ≥ 1, the
number of solutions of x₁² + ⋯ + x₅² ≡ n mod pᵏ, divided by p^(4k), is 1 + (n/p)/p², where
(n/p) is the Legendre symbol. -/
theorem five_squares_local_factor (p k n : ℕ) [Fact p.Prime] (hp : p ≠ 2) (hn : ¬ p ∣ n)
    (hk : 1 ≤ k) :
    ((Finset.univ.filter (fun x : Fin 5 → ZMod (p ^ k) => ∑ i, x i ^ 2 = (n : ZMod (p ^ k)))).card
        : ℚ) / ((p : ℚ) ^ k) ^ 4 = 1 + (legendreSym p n : ℚ) / (p : ℚ) ^ 2 := by
  obtain ⟨j, rfl⟩ : ∃ j, k = j + 1 := ⟨k - 1, by omega⟩
  rw [five_sq_prime_power_count p n hp hn j]
  have hna : (n : ZMod p) ≠ 0 := by
    rw [Ne, ZMod.natCast_eq_zero_iff]; exact hn
  have hC := five_sq_fourier_count p hp (n : ZMod p) hna
  have hZ : ((Finset.univ.filter (fun x : Fin 5 → ZMod p => ∑ i, x i ^ 2 = (n : ZMod p))).card : ℤ) =
      (p : ℤ) ^ 4 + (p : ℤ) ^ 2 * legendreSym p n := by
    have : legendreSym p n = quadraticChar (ZMod p) (n : ZMod p) := by
      rw [legendreSym, Int.cast_natCast]
    rw [this]
    exact_mod_cast hC
  have hQ : ((Finset.univ.filter (fun x : Fin 5 → ZMod p => ∑ i, x i ^ 2 = (n : ZMod p))).card : ℚ) =
      (p : ℚ) ^ 4 + (p : ℚ) ^ 2 * (legendreSym p n : ℚ) := by
    exact_mod_cast hZ
  have hp0 : (p : ℚ) ≠ 0 := by exact_mod_cast (Fact.out : p.Prime).ne_zero
  push_cast
  rw [hQ]
  field_simp
  ring

/-! The card's whole-number examples. -/

-- One of the 352,800 ways: 1,000 = 31² + 6² + 1² + 1² + 1².
example : (31 : ℤ) ^ 2 + 6 ^ 2 + 1 ^ 2 + 1 ^ 2 + 1 ^ 2 = 1000 := by norm_num

-- P = ⌊√1000⌋ = 31, and the exponents run to 5 × 31² = 4,805, below the 5,000 sample points.
example : Nat.sqrt 1000 = 31 := by rw [eq_comm, Nat.eq_sqrt]; norm_num
example : 5 * 31 ^ 2 = 4805 ∧ 4805 < 5000 := by norm_num

-- The factor at 3: 1,000 leaves 1 mod 3, a square, so (1000/3) = +1; solutions mod 3 number
-- 3⁴ + 3² = 90, and 90 / 81 = 10/9 = 1 + 1/9.
section three
local instance : Fact (Nat.Prime 3) := ⟨by norm_num⟩
example : 1000 % 3 = 1 ∧ legendreSym 3 1000 = 1 := by norm_num
example : (Finset.univ.filter (fun x : Fin 5 → ZMod 3 => ∑ i, x i ^ 2 = (1000 : ZMod 3))).card
    = 90 := by decide
end three

-- The factor at 7: 1,000 leaves 6 mod 7, not a square, so (1000/7) = −1 and the factor is 1 − 1/49.
section seven
local instance : Fact (Nat.Prime 7) := ⟨by norm_num⟩
example : 1000 % 7 = 6 ∧ legendreSym 7 1000 = -1 := by norm_num
end seven

-- 1,001 = 7 × 11 × 13.
example : (1001 : ℕ) = 7 * 11 * 13 := by norm_num

-- Three squares at 1,007 = 8 × 125 + 7: no three squares make 7 mod 8, so r₃(1,007) = 0.
example : (1007 : ℕ) = 8 * 125 + 7 := by norm_num
example : ∀ a b c : ZMod 8, a ^ 2 + b ^ 2 + c ^ 2 ≠ 7 := by decide

#print axioms five_squares_count_eq_circle_integral
#print axioms weyl_inequality_for_squares
#print axioms five_squares_local_factor
#print axioms circle_integral_exp_int
#print axioms weyl_geom_identity
#print axioms weyl_norm_sub_one
#print axioms weyl_geom_bound
#print axioms weyl_norm_sum_le_card
#print axioms weyl_reindex
#print axioms five_sq_fourier_count
#print axioms five_sq_linear_count
#print axioms five_sq_digit_equiv
#print axioms five_sq_lift_count
#print axioms five_sq_lift_count_of_eq
#print axioms five_sq_prime_power_count
