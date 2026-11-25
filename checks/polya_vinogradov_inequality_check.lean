-- Polya-Vinogradov: a primitive character summed over any stretch of consecutive whole numbers has size less than root q times log q.
import Mathlib.Analysis.Fourier.ZMod
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Tactic.NormNum.LegendreSymbol
import Mathlib.Data.Int.Interval
import Mathlib.NumberTheory.LSeries.Nonvanishing
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds

open ZMod

theorem pv_inv_lt_log_sub {k : ℝ} (hk : 1 ≤ k) :
    1 / k < Real.log (2 * k + 1) - Real.log (2 * k - 1) := by
  set x : ℝ := 1 / (2 * k) with hxdef
  have hx0 : 0 < x := by positivity
  have hx : |x| < 1 := by
    rw [abs_of_pos hx0, hxdef, div_lt_one (by positivity)]; linarith
  have hs := Real.hasSum_log_sub_log_of_abs_lt_one hx
  have hle := sum_le_hasSum (Finset.range 2)
    (fun i _ => mul_nonneg (by positivity) (pow_nonneg hx0.le _)) hs
  have e1 : Real.log (1 + x) - Real.log (1 - x) =
      Real.log (2 * k + 1) - Real.log (2 * k - 1) := by
    have h1 : 1 + x = (2 * k + 1) / (2 * k) := by rw [hxdef]; field_simp
    have h2 : 1 - x = (2 * k - 1) / (2 * k) := by rw [hxdef]; field_simp
    rw [h1, h2, Real.log_div (by linarith) (by positivity),
      Real.log_div (by linarith) (by positivity)]
    ring
  rw [e1] at hle
  simp only [Finset.sum_range_succ, Finset.sum_range_zero] at hle
  have h3 : 0 < x ^ 3 := by positivity
  have hkx : 1 / k = 2 * x := by rw [hxdef]; field_simp
  push_cast at hle
  rw [hkx]
  nlinarith

theorem pv_inv_lt_two_log_sub {v : ℝ} (hv : 1 ≤ v) :
    1 / v < 2 * (Real.log (2 * v) - Real.log (2 * v - 1)) := by
  have h := Real.log_lt_sub_one_of_pos (x := (2 * v - 1) / (2 * v)) (by
    apply div_pos <;> linarith) (by
    intro h; rw [div_eq_one_iff_eq (by linarith)] at h; linarith)
  rw [Real.log_div (by linarith) (by linarith)] at h
  have : (2 * v - 1) / (2 * v) - 1 = -(1 / v) / 2 := by field_simp; ring
  rw [this] at h
  linarith

theorem pv_expansion {q : ℕ} [NeZero q]
    (χ : DirichletCharacter ℂ q) (hχ : χ.IsPrimitive) (n : ZMod q) :
    χ n = (gaussSum (star χ) stdAddChar)⁻¹ *
      ∑ a : ZMod q, (star χ) a * stdAddChar (a * n) := by
  have hst : star χ = χ⁻¹ := MulChar.star_eq_inv χ
  have hg : gaussSum χ⁻¹ stdAddChar ≠ 0 := by
    intro h
    have := DirichletCharacter.norm_gaussSum_stdAddChar hχ.inv
    rw [h, norm_zero] at this
    have hq : (0 : ℝ) < q := by exact_mod_cast Nat.pos_of_ne_zero (NeZero.ne q)
    have := Real.sqrt_pos.mpr hq
    linarith
  have hsum : ∑ a : ZMod q, χ⁻¹ a * stdAddChar (a * n) =
      gaussSum χ⁻¹ (stdAddChar.mulShift n) := by
    simp only [gaussSum, AddChar.mulShift_apply, mul_comm n]
  rw [hst, hsum, gaussSum_mulShift_of_isPrimitive _ hχ.inv, inv_inv]
  field_simp


theorem pv_term (q v : ℕ) (Φ : ℝ → ℝ)
    (hΦ : ∀ u, Φ u = if u ≤ q then Real.log u else 2 * Real.log q - Real.log (2 * q - u))
    (hv : 1 ≤ v) (hvq : v < q) :
    1 / ((min v (q - v) : ℕ) : ℝ) < Φ (2 * v + 1) - Φ (2 * v - 1) := by
  have hV : (1 : ℝ) ≤ v := by exact_mod_cast hv
  have hVQ : (v : ℝ) + 1 ≤ q := by exact_mod_cast hvq
  rcases (by omega : 2 * v + 1 ≤ q ∨ 2 * v = q ∨ q + 1 ≤ 2 * v) with h | h | h
  · have hm : min v (q - v) = v := by omega
    have h1 : (2 * (v : ℝ) + 1) ≤ q := by exact_mod_cast h
    have h2 : (2 * (v : ℝ) - 1) ≤ q := by linarith
    rw [hm, hΦ, hΦ, ite_eq_left h1, ite_eq_left h2]
    exact pv_inv_lt_log_sub hV
  · have hm : min v (q - v) = v := by omega
    have hQ : (q : ℝ) = 2 * v := by exact_mod_cast h.symm
    have h1 : ¬ (2 * (v : ℝ) + 1) ≤ q := by rw [hQ]; linarith
    have h2 : (2 * (v : ℝ) - 1) ≤ q := by linarith
    rw [hm, hΦ, hΦ, ite_eq_right h1, ite_eq_left h2, hQ]
    have e : 2 * (2 * (v : ℝ)) - (2 * v + 1) = 2 * v - 1 := by ring
    rw [e]
    have := pv_inv_lt_two_log_sub hV
    have e2 : Real.log (2 * (v : ℝ)) * 2 = 2 * Real.log (2 * v) := by ring
    linarith
  · have hm : min v (q - v) = q - v := by omega
    have hc : ((q - v : ℕ) : ℝ) = q - v := Nat.cast_sub hvq.le
    have hk : (1 : ℝ) ≤ q - v := by linarith
    have hqv : (q : ℝ) + 1 ≤ 2 * v := by exact_mod_cast h
    have h1 : ¬ (2 * (v : ℝ) + 1) ≤ q := by linarith
    have key := pv_inv_lt_log_sub hk
    have e2 : 2 * ((q : ℝ) - v) - 1 = 2 * q - (2 * v + 1) := by ring
    rw [e2] at key
    rw [hm, hc, hΦ, hΦ, ite_eq_right h1]
    by_cases h2 : (2 * (v : ℝ) - 1) ≤ q
    · rw [ite_eq_left h2]
      have e3 : 2 * (v : ℝ) - 1 = q := by linarith
      have e1 : 2 * ((q : ℝ) - v) + 1 = 2 * v - 1 := by linarith
      rw [e1, e3] at key
      rw [e3]
      linarith
    · rw [ite_eq_right h2]
      have e1 : 2 * ((q : ℝ) - v) + 1 = 2 * q - (2 * v - 1) := by ring
      rw [e1] at key
      linarith

theorem pv_harmonic_bound (q : ℕ) (hq : 2 ≤ q) :
    ∑ i ∈ Finset.range (q - 1), 1 / ((min (i + 1) (q - (i + 1)) : ℕ) : ℝ) <
      2 * Real.log q := by
  set Φ : ℝ → ℝ := fun u =>
    if u ≤ q then Real.log u else 2 * Real.log q - Real.log (2 * q - u) with hΦdef
  have hΦ : ∀ u, Φ u = if u ≤ q then Real.log u else 2 * Real.log q - Real.log (2 * q - u) :=
    fun u => rfl
  have hlt : ∀ i ∈ Finset.range (q - 1), 1 / ((min (i + 1) (q - (i + 1)) : ℕ) : ℝ) <
      Φ (2 * ((i + 1 : ℕ) : ℝ) + 1) - Φ (2 * (i : ℝ) + 1) := by
    intro i hi
    rw [Finset.mem_range] at hi
    have := pv_term q (i + 1) Φ hΦ (by omega) (by omega)
    have e : (2 * (i : ℝ) + 1) = 2 * ((i + 1 : ℕ) : ℝ) - 1 := by push_cast; ring
    rw [e]
    exact this
  have hQ : (2 : ℝ) ≤ q := by exact_mod_cast hq
  calc _ < ∑ i ∈ Finset.range (q - 1),
        (Φ (2 * ((i + 1 : ℕ) : ℝ) + 1) - Φ (2 * (i : ℝ) + 1)) :=
        Finset.sum_lt_sum_of_nonempty (by simp; omega) hlt
    _ = Φ (2 * ((q - 1 : ℕ) : ℝ) + 1) - Φ (2 * ((0 : ℕ) : ℝ) + 1) :=
        Finset.sum_range_sub (fun i : ℕ => Φ (2 * (i : ℝ) + 1)) (q - 1)
    _ = 2 * Real.log q := by
        rw [Nat.cast_sub (by omega), hΦ, hΦ]
        have h1 : ¬ (2 * ((q : ℝ) - ((1 : ℕ) : ℝ)) + 1) ≤ q := by push_cast; linarith
        have h2 : (2 * ((0 : ℕ) : ℝ) + 1) ≤ q := by push_cast; linarith
        rw [ite_eq_right h1, ite_eq_left h2]
        push_cast
        have e : 2 * (q : ℝ) - (2 * (q - 1) + 1) = 1 := by ring
        rw [e]
        simp

theorem pv_sum_zmod_val (q : ℕ) [NeZero q] (f : ℕ → ℝ) :
    ∑ a : ZMod q, f a.val = ∑ v ∈ Finset.range q, f v := by
  refine Finset.sum_nbij' (fun a => a.val) (fun v => (v : ZMod q)) ?_ ?_ ?_ ?_ ?_
  · intro a _; simp [ZMod.val_lt]
  · intro v _; simp
  · intro a _; simp
  · intro v hv
    exact ZMod.val_cast_of_lt (by simpa using hv)
  · intro a _; rfl

theorem pv_geom_sum (z : ℂ) (hz : ‖z‖ = 1) (hz1 : z ≠ 1) (M : ℤ) (N : ℕ) :
    ‖∑ n ∈ Finset.Ioc M (M + N), z ^ n‖ ≤ 2 / ‖z - 1‖ := by
  have hz0 : z ≠ 0 := by intro h; rw [h, norm_zero] at hz; norm_num at hz
  have key : ∀ N : ℕ, (z - 1) * ∑ n ∈ Finset.Ioc M (M + N), z ^ n =
      z ^ (M + N + 1) - z ^ (M + 1) := by
    intro N
    induction N with
    | zero => simp
    | succ N ih =>
      have h1 : M + ((N + 1 : ℕ) : ℤ) = (M + N) + 1 := by push_cast; ring
      rw [h1, ← Finset.insert_Ioc_right_eq_Ioc_add_one (by omega),
        Finset.sum_insert (by simp), mul_add, ih, zpow_add_one₀ hz0 (M + N + 1)]
      ring
  have hz1' : z - 1 ≠ 0 := sub_ne_zero.mpr hz1
  have hS : ∑ n ∈ Finset.Ioc M (M + N), z ^ n =
      (z ^ (M + N + 1) - z ^ (M + 1)) / (z - 1) := by
    rw [← key N]; field_simp
  rw [hS, norm_div]
  apply div_le_div_of_nonneg_right _ (norm_nonneg _)
  calc ‖z ^ (M + N + 1) - z ^ (M + 1)‖ ≤ ‖z ^ (M + N + 1)‖ + ‖z ^ (M + 1)‖ :=
        norm_sub_le _ _
    _ = 2 := by rw [norm_zpow, norm_zpow, hz]; norm_num

theorem pv_char_sum_bound (q : ℕ) [NeZero q] (a : ZMod q) (ha : a ≠ 0) (M : ℤ) (N : ℕ) :
    ‖∑ n ∈ Finset.Ioc M (M + N), stdAddChar (a * (n : ZMod q))‖ ≤
      (q : ℝ) / (2 * ((min a.val (q - a.val) : ℕ) : ℝ)) := by
  have hv0 : 0 < a.val := ZMod.val_pos.mpr ha
  have hvq : a.val < q := ZMod.val_lt a
  set v := a.val with hvdef
  set z : ℂ := stdAddChar a with hzdef
  have hterm : ∀ n : ℤ, stdAddChar (a * (n : ZMod q)) = z ^ n := by
    intro n; rw [mul_comm, ← zsmul_eq_mul, AddChar.map_zsmul_eq_zpow]
  rw [Finset.sum_congr rfl (fun n _ => hterm n)]
  have hq0 : (0 : ℝ) < q := by exact_mod_cast (hv0.trans hvq)
  have hzexp : z = Complex.exp (Complex.I * ((2 * Real.pi * v / q : ℝ) : ℂ)) := by
    have : a = ((v : ℤ) : ZMod q) := by rw [Int.cast_natCast, hvdef, ZMod.natCast_zmod_val]
    rw [hzdef, this, ZMod.stdAddChar_coe]
    congr 1; push_cast; ring
  have hnorm : ‖z‖ = 1 := by rw [hzexp, mul_comm]; exact Complex.norm_exp_ofReal_mul_I _
  set k := min v (q - v) with hkdef
  have hk1 : (1 : ℝ) ≤ k := by
    have : 1 ≤ k := by omega
    exact_mod_cast this
  have hsin : 2 * (k : ℝ) / q ≤ Real.sin (Real.pi * v / q) := by
    rcases le_total v (q - v) with h | h
    · have hk : k = v := min_eq_left h
      have h2 : (2 * (v : ℝ)) ≤ q := by
        have : 2 * v ≤ q := by omega
        exact_mod_cast this
      have := Real.mul_le_sin (x := Real.pi * v / q) (by positivity) (by
        rw [div_le_iff₀ hq0]; nlinarith [Real.pi_pos])
      rw [hk]
      calc 2 * (v : ℝ) / q = 2 / Real.pi * (Real.pi * v / q) := by
            field_simp
        _ ≤ _ := this
    · have hk : k = q - v := min_eq_right h
      have hc : ((q - v : ℕ) : ℝ) = q - v := Nat.cast_sub hvq.le
      have h2 : (2 * ((q : ℝ) - v)) ≤ q := by
        have : 2 * (q - v) ≤ q := by omega
        have h3 := (by exact_mod_cast this : ((2 * (q - v) : ℕ) : ℝ) ≤ q)
        rw [Nat.cast_mul, hc] at h3
        push_cast at h3
        linarith
      have hvq' : (v : ℝ) < q := by exact_mod_cast hvq
      have := Real.mul_le_sin (x := Real.pi * (q - v) / q)
        (div_nonneg (mul_nonneg Real.pi_pos.le (by linarith)) hq0.le) (by
        rw [div_le_iff₀ hq0]; nlinarith [Real.pi_pos])
      have hs : Real.sin (Real.pi * v / q) = Real.sin (Real.pi * (q - v) / q) := by
        rw [← Real.sin_pi_sub]; congr 1; field_simp
      rw [hk, hc, hs]
      calc 2 * ((q : ℝ) - v) / q = 2 / Real.pi * (Real.pi * (q - v) / q) := by
            field_simp
        _ ≤ _ := this
  have hzsub : 4 * (k : ℝ) / q ≤ ‖z - 1‖ := by
    rw [hzexp, Complex.norm_exp_I_mul_ofReal_sub_one, Real.norm_eq_abs]
    have e : 2 * Real.pi * v / q / 2 = Real.pi * v / q := by ring
    rw [e]
    calc 4 * (k : ℝ) / q = 2 * (2 * k / q) := by ring
      _ ≤ 2 * Real.sin (Real.pi * v / q) := by linarith
      _ ≤ _ := le_abs_self _
  have hpos : 0 < 4 * (k : ℝ) / q := by positivity
  have hz1 : z ≠ 1 := by intro h; rw [h, sub_self, norm_zero] at hzsub; linarith
  calc _ ≤ 2 / ‖z - 1‖ := pv_geom_sum z hnorm hz1 M N
    _ ≤ 2 / (4 * (k : ℝ) / q) := div_le_div_of_nonneg_left (by norm_num) hpos hzsub
    _ = q / (2 * k) := by field_simp; norm_num

#print axioms pv_inv_lt_log_sub
#print axioms pv_inv_lt_two_log_sub
#print axioms pv_expansion
#print axioms pv_term
#print axioms pv_harmonic_bound
#print axioms pv_sum_zmod_val
#print axioms pv_geom_sum
#print axioms pv_char_sum_bound

/-- The Polya-Vinogradov inequality: for every primitive Dirichlet character `χ` mod `q`,
with `q` at least 3, and every stretch of consecutive whole numbers `M < n ≤ M + N`,
the sum of `χ(n)` over the stretch has size less than `√q · log q` (natural log). -/
theorem polya_vinogradov_inequality {q : ℕ} (hq : 3 ≤ q) (χ : DirichletCharacter ℂ q)
    (hχ : χ.IsPrimitive) (M : ℤ) (N : ℕ) :
    ‖∑ n ∈ Finset.Ioc M (M + N), χ (n : ZMod q)‖ < Real.sqrt q * Real.log q := by
  have : NeZero q := ⟨by omega⟩
  have : Fact (1 < q) := ⟨by omega⟩
  have hstarprim : (star χ).IsPrimitive := by rw [MulChar.star_eq_inv]; exact hχ.inv
  have hg : ‖gaussSum (star χ) stdAddChar‖ = Real.sqrt q :=
    DirichletCharacter.norm_gaussSum_stdAddChar hstarprim
  have hexp : ∑ n ∈ Finset.Ioc M (M + N), χ (n : ZMod q) =
      (gaussSum (star χ) stdAddChar)⁻¹ * ∑ a : ZMod q, (star χ) a *
        ∑ n ∈ Finset.Ioc M (M + N), stdAddChar (a * (n : ZMod q)) := by
    rw [Finset.sum_congr rfl (fun (n : ℤ) _ => pv_expansion χ hχ (n : ZMod q)), ← Finset.mul_sum,
      Finset.sum_comm]
    simp_rw [Finset.mul_sum]
  set B : ℕ → ℝ := fun v => if v = 0 then 0 else (q : ℝ) / (2 * ((min v (q - v) : ℕ) : ℝ))
    with hBdef
  have hB : ∀ a : ZMod q, ‖(star χ) a *
      ∑ n ∈ Finset.Ioc M (M + N), stdAddChar (a * (n : ZMod q))‖ ≤ B a.val := by
    intro a
    by_cases ha : a = 0
    · subst ha
      have h0 : (star χ) (0 : ZMod q) = 0 := MulChar.map_zero _
      rw [h0, zero_mul, norm_zero]
      simp [hBdef]
    · have hv : a.val ≠ 0 := (ZMod.val_ne_zero a).mpr ha
      rw [norm_mul, hBdef]
      simp only [hv, ite_false]
      calc _ ≤ 1 * ((q : ℝ) / (2 * ((min a.val (q - a.val) : ℕ) : ℝ))) :=
            mul_le_mul (DirichletCharacter.norm_le_one _ _)
              (pv_char_sum_bound q a ha M N) (norm_nonneg _) zero_le_one
        _ = _ := one_mul _
  have hQ : (0 : ℝ) < q := by exact_mod_cast (show 0 < q by omega)
  have hBsum : ∑ a : ZMod q, B a.val < q * Real.log q := by
    rw [pv_sum_zmod_val q B]
    have h1 := Finset.sum_range_succ' B (q - 1)
    rw [Nat.sub_add_cancel (by omega : 1 ≤ q)] at h1
    rw [h1]
    have h2 : ∀ i ∈ Finset.range (q - 1), B (i + 1) =
        (q : ℝ) / 2 * (1 / ((min (i + 1) (q - (i + 1)) : ℕ) : ℝ)) := by
      intro i _
      simp only [hBdef, Nat.add_one_ne_zero, ite_false]
      ring
    rw [Finset.sum_congr rfl h2, ← Finset.mul_sum]
    have h3 := pv_harmonic_bound q (by omega)
    have h0 : B 0 = 0 := by simp [hBdef]
    rw [h0, add_zero]
    calc (q : ℝ) / 2 * _ < (q : ℝ) / 2 * (2 * Real.log q) :=
          mul_lt_mul_of_pos_left h3 (by positivity)
      _ = q * Real.log q := by ring
  have hs : 0 < Real.sqrt q := Real.sqrt_pos.mpr hQ
  rw [hexp, norm_mul, norm_inv, hg]
  calc (Real.sqrt q)⁻¹ * ‖∑ a : ZMod q, (star χ) a *
        ∑ n ∈ Finset.Ioc M (M + N), stdAddChar (a * (n : ZMod q))‖
      ≤ (Real.sqrt q)⁻¹ * ∑ a : ZMod q, B a.val :=
        mul_le_mul_of_nonneg_left ((norm_sum_le _ _).trans
          (Finset.sum_le_sum fun a _ => hB a)) (inv_nonneg.mpr hs.le)
    _ < (Real.sqrt q)⁻¹ * (q * Real.log q) := mul_lt_mul_of_pos_left hBsum (inv_pos.mpr hs)
    _ = Real.sqrt q * Real.log q := by
        have hsq : Real.sqrt q * Real.sqrt q = q := Real.mul_self_sqrt hQ.le
        rw [inv_mul_eq_iff_eq_mul₀ hs.ne', ← mul_assoc, hsq]

/-- The expansion behind the proof: a primitive character `χ` mod `q` is a blend of rotations,
`χ(n) = (1 / g(χ̄)) · ∑ₐ χ̄(a) ζ_q^(a n)` for every `n`. Here `star χ` is the conjugate
character `χ̄`, `stdAddChar x = e^(2πi x/q)`, so `stdAddChar (a * n) = ζ_q^(a n)`, and
`gaussSum (star χ) stdAddChar` is the Gauss sum `g(χ̄)`. The `a = 0` term is zero when `q > 1`. -/
theorem primitive_character_eq_gaussSum_expansion {q : ℕ} [NeZero q]
    (χ : DirichletCharacter ℂ q) (hχ : χ.IsPrimitive) (n : ZMod q) :
    χ n = (gaussSum (star χ) stdAddChar)⁻¹ *
      ∑ a : ZMod q, (star χ) a * stdAddChar (a * n) := by
  exact pv_expansion χ hχ n

/-- The elementary bound on the least non-residue: for an odd prime `p`, the least positive
`n` with Legendre symbol `(n/p) = -1` satisfies `n < √p + 1`. -/
theorem least_nonresidue_lt_sqrt_add_one {p : ℕ} [Fact p.Prime] (hp : p ≠ 2) {n : ℕ}
    (hn : legendreSym p n = -1) (hmin : ∀ m : ℕ, 0 < m → m < n → legendreSym p m ≠ -1) :
    (n : ℝ) < Real.sqrt p + 1 := by
  have hp2 := (Fact.out : p.Prime).two_le
  have legeq : ∀ a b : ℤ, (a : ZMod p) = (b : ZMod p) → legendreSym p a = legendreSym p b := by
    intro a b h; simp only [legendreSym, h]
  have hzero : ∀ a : ℕ, p ∣ a → legendreSym p a = 0 := by
    intro a ha
    rw [legendreSym.eq_zero_iff, Int.cast_natCast, ZMod.natCast_eq_zero_iff]
    exact ha
  have hn0 : ¬ p ∣ n := by intro h; rw [hzero n h] at hn; norm_num at hn
  have hn1 : n ≠ 1 := by
    rintro rfl; rw [Nat.cast_one, legendreSym.at_one] at hn; norm_num at hn
  have hnpos : 0 < n := Nat.pos_of_ne_zero (by rintro rfl; exact hn0 (dvd_zero p))
  have hnp : n < p := by
    by_contra h
    rw [not_lt] at h
    have hmpos : 0 < n % p := Nat.pos_of_ne_zero (fun h0 => hn0 (Nat.dvd_of_mod_eq_zero h0))
    apply hmin (n % p) hmpos ((Nat.mod_lt _ (by omega)).trans_le h)
    rw [← hn]
    apply legeq
    simp
  have hpn : p % n ≠ 0 := by
    intro h
    rcases (Fact.out : p.Prime).eq_one_or_self_of_dvd n (Nat.dvd_of_mod_eq_zero h) with h1 | h1
    · exact hn1 h1
    · omega
  have hmodlt : p % n < n := Nat.mod_lt _ hnpos
  obtain ⟨d, hd⟩ : ∃ d, p / n = d := ⟨_, rfl⟩
  have hdm : n * d + p % n = p := by rw [← hd]; exact Nat.div_add_mod p n
  have hk : legendreSym p ((d + 1 : ℕ) : ℤ) = -1 := by
    set r := n - p % n with hr
    have hr0 : 0 < r := by omega
    have hrn : r < n := by omega
    have hrp : ((r : ℤ) : ZMod p) ≠ 0 := by
      rw [Int.cast_natCast, Ne, ZMod.natCast_eq_zero_iff]
      intro h; exact absurd (Nat.le_of_dvd hr0 h) (by omega)
    have hr1 : legendreSym p r = 1 := by
      rcases legendreSym.eq_one_or_neg_one p hrp with h | h
      · exact h
      · exact absurd h (hmin r hr0 hrn)
    have hkn : (d + 1) * n = r + p := by
      have : (d + 1) * n = n * d + n := by ring
      omega
    have h4 : legendreSym p (((d + 1) * n : ℕ) : ℤ) = legendreSym p r := by
      apply legeq
      rw [hkn]
      push_cast
      rw [ZMod.natCast_self, add_zero]
    rw [Nat.cast_mul, legendreSym.mul, hn, hr1] at h4
    linarith
  have hkn : n ≤ d + 1 := by
    by_contra h
    rw [not_le] at h
    exact hmin (d + 1) (by omega) h hk
  have hsq : (n - 1) * (n - 1) < p := by
    have h5 : (n - 1) * (n - 1) ≤ n * d := Nat.mul_le_mul (by omega) (by omega)
    omega
  have hn1' : (1 : ℝ) ≤ n := by exact_mod_cast hnpos
  have hsqR : ((n : ℝ) - 1) ^ 2 < p := by
    have := (by exact_mod_cast hsq : (((n - 1) * (n - 1) : ℕ) : ℝ) < p)
    push_cast [Nat.one_le_iff_ne_zero.mpr hnpos.ne'] at this
    nlinarith
  have := (Real.lt_sqrt (by linarith : (0 : ℝ) ≤ n - 1)).mpr hsqR
  linarith

-- 1019 leaves 3 on division by 8.
example : 1019 % 8 = 3 := by decide

-- The walk mod 1019 at the halfway point: S(509) = 39 (274 squares, 235 non-squares).
-- For a prime modulus the Jacobi symbol is the Legendre symbol.
example : ∑ n ∈ Finset.Icc (1 : ℤ) 509, jacobiSym n 1019 = 39 := by decide +kernel

-- 39 is 3 times the class number 13.
example : 3 * 13 = 39 := by decide

-- Mod 1009 the numbers 2 to 10 are squares and 11 is the least non-residue.
example : ∀ m ∈ Finset.Icc (2 : ℤ) 10, jacobiSym m 1009 = 1 := by decide +kernel
example : jacobiSym 11 1009 = -1 := by norm_num

#print axioms polya_vinogradov_inequality
#print axioms primitive_character_eq_gaussSum_expansion
#print axioms least_nonresidue_lt_sqrt_add_one
