-- Eigenvalue problems: the pinned problem -y'' = λy, y(0) = y(1) = 0 on [0, 1] has a nonzero solution exactly when λ = n^2π^2 for some n = 1, 2, 3, ..., every such solution is a nonzero multiple of sin(nπx), and sin(nπx) is zero inside the string only at the n - 1 nodes k/n.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.ODE.Gronwall
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp

open Real Set

lemma pinned_aux_unique (lam : ℝ) (E E' : ℝ → ℝ)
    (hd : ∀ x ∈ Icc (0 : ℝ) 1,
      HasDerivWithinAt E (E' x) (Icc 0 1) x ∧ HasDerivWithinAt E' (-lam * E x) (Icc 0 1) x)
    (h0 : E 0 = 0) (h0' : E' 0 = 0) : ∀ x ∈ Icc (0 : ℝ) 1, E x = 0 := by
  have key := eq_zero_of_abs_deriv_le_mul_abs_self_of_eq_zero_right
    (f := fun t => (E t, E' t)) (f' := fun t => (E' t, -lam * E t)) (K := 1 + |lam|) (a := 0) (b := 1)
    ?_ ?_ (by simp [h0, h0']) ?_
  · intro x hx
    have := key x hx
    simp only [Prod.mk_eq_zero] at this
    exact this.1
  · intro x hx
    exact (HasDerivWithinAt.prodMk (hd x hx).1 (hd x hx).2).continuousWithinAt
  · intro x hx
    have hx' := Ico_subset_Icc_self hx
    exact (HasDerivWithinAt.prodMk (hd x hx').1 (hd x hx').2).mono_of_mem_nhdsWithin (Icc_mem_nhdsGE_of_mem hx)
  · intro x _
    simp only [Prod.norm_def, Real.norm_eq_abs, abs_mul, abs_neg]
    have h1 := le_max_left |E x| |E' x|
    have h2 := le_max_right |E x| |E' x|
    have h3 := abs_nonneg lam
    have h4 := abs_nonneg (E x)
    apply max_le <;> nlinarith

#print axioms pinned_aux_unique

lemma pinned_aux_eq (lam : ℝ) (y y' z z' : ℝ → ℝ)
    (hd : ∀ x ∈ Icc (0 : ℝ) 1,
      HasDerivWithinAt y (y' x) (Icc 0 1) x ∧ HasDerivWithinAt y' (-lam * y x) (Icc 0 1) x)
    (hz : ∀ x, HasDerivAt z (z' x) x ∧ HasDerivAt z' (-lam * z x) x)
    (h0 : y 0 = z 0) (h0' : y' 0 = z' 0) : ∀ x ∈ Icc (0 : ℝ) 1, y x = z x := by
  intro x hx
  have := pinned_aux_unique lam (fun t => y t - z t) (fun t => y' t - z' t) ?_ (by simp [h0])
    (by simp [h0']) x hx
  · simpa [sub_eq_zero] using this
  · intro t ht
    refine ⟨(hd t ht).1.sub (hz t).1.hasDerivWithinAt, ?_⟩
    have := (hd t ht).2.sub (hz t).2.hasDerivWithinAt
    convert this using 1
    ring

#print axioms pinned_aux_eq

lemma pinned_aux_sine (lam : ℝ) (y y' : ℝ → ℝ)
    (hd : ∀ x ∈ Icc (0 : ℝ) 1,
      HasDerivWithinAt y (y' x) (Icc 0 1) x ∧ HasDerivWithinAt y' (-lam * y x) (Icc 0 1) x)
    (h0 : y 0 = 0) (h1 : y 1 = 0) (hne : ∃ x ∈ Icc (0 : ℝ) 1, y x ≠ 0) :
    ∃ n : ℕ, 0 < n ∧ lam = (n * π) ^ 2 ∧
      ∃ B : ℝ, B ≠ 0 ∧ ∀ x ∈ Icc (0 : ℝ) 1, y x = B * sin (n * π * x) := by
  obtain ⟨x₀, hx₀, hyx₀⟩ := hne
  set p := y' 0 with hp
  rcases lt_trichotomy lam 0 with hl | hl | hl
  · -- lam < 0
    exfalso
    set μ := √(-lam) with hμ
    have hμpos : 0 < μ := Real.sqrt_pos.mpr (by linarith)
    have hμsq : μ ^ 2 = -lam := Real.sq_sqrt (by linarith)
    have heq := pinned_aux_eq lam y y' (fun x => p / μ * sinh (μ * x)) (fun x => p * cosh (μ * x))
      hd ?_ (by simp [h0]) (by simp [hp])
    · have h1' := heq 1 ⟨zero_le_one, le_rfl⟩
      rw [h1, mul_one] at h1'
      have hs : 0 < sinh μ := Real.sinh_pos_iff.mpr hμpos
      have hp0 : p = 0 := by
        rcases mul_eq_zero.mp h1'.symm with h | h
        · rcases div_eq_zero_iff.mp h with h | h
          · exact h
          · exact absurd h hμpos.ne'
        · exact absurd h hs.ne'
      apply hyx₀
      rw [heq x₀ hx₀, hp0]; simp
    · intro x
      constructor
      · have := ((hasDerivAt_id' x).const_mul μ).sinh.const_mul (p / μ)
        convert this using 1
        field_simp
      · have := ((hasDerivAt_id' x).const_mul μ).cosh.const_mul p
        convert this using 1
        have : lam = -μ ^ 2 := by linarith
        rw [this]
        field_simp
  · -- lam = 0
    exfalso
    subst hl
    have heq := pinned_aux_eq 0 y y' (fun x => p * x) (fun _ => p)
      hd ?_ (by simp [h0]) (by simp [hp])
    · have h1' := heq 1 ⟨zero_le_one, le_rfl⟩
      rw [h1, mul_one] at h1'
      apply hyx₀
      rw [heq x₀ hx₀, ← h1']; simp
    · intro x
      constructor
      · simpa using (hasDerivAt_id' x).const_mul p
      · simpa using hasDerivAt_const x p
  · -- lam > 0
    set ω := √lam with hω
    have hωpos : 0 < ω := Real.sqrt_pos.mpr hl
    have hωsq : ω ^ 2 = lam := Real.sq_sqrt hl.le
    have heq := pinned_aux_eq lam y y' (fun x => p / ω * sin (ω * x)) (fun x => p * cos (ω * x))
      hd ?_ (by simp [h0]) (by simp [hp])
    · have h1' := heq 1 ⟨zero_le_one, le_rfl⟩
      rw [h1, mul_one] at h1'
      have hp0 : p ≠ 0 := by
        intro hp0
        apply hyx₀
        rw [heq x₀ hx₀, hp0]; simp
      have hs : sin ω = 0 := by
        rcases mul_eq_zero.mp h1'.symm with h | h
        · rcases div_eq_zero_iff.mp h with h | h
          · exact absurd h hp0
          · exact absurd h hωpos.ne'
        · exact h
      obtain ⟨k, hk⟩ := Real.sin_eq_zero_iff.mp hs
      have hkpos : (0 : ℝ) < k := by
        by_contra hneg
        push Not at hneg
        have : (k : ℝ) * π ≤ 0 := mul_nonpos_of_nonpos_of_nonneg hneg pi_pos.le
        linarith
      have hkpos' : 0 < k := by exact_mod_cast hkpos
      refine ⟨k.toNat, by omega, ?_, p / ω, div_ne_zero hp0 hωpos.ne', ?_⟩
      · have hcast : ((k.toNat : ℕ) : ℝ) = (k : ℝ) := by
          have : ((k.toNat : ℤ) : ℝ) = (k : ℝ) := by rw [Int.toNat_of_nonneg hkpos'.le]
          exact_mod_cast this
        rw [hcast, hk, hωsq]
      · intro x hx
        have hcast : ((k.toNat : ℕ) : ℝ) = (k : ℝ) := by
          have : ((k.toNat : ℤ) : ℝ) = (k : ℝ) := by rw [Int.toNat_of_nonneg hkpos'.le]
          exact_mod_cast this
        rw [heq x hx, hcast, hk]
    · intro x
      constructor
      · have := ((hasDerivAt_id' x).const_mul ω).sin.const_mul (p / ω)
        convert this using 1
        field_simp
      · have := ((hasDerivAt_id' x).const_mul ω).cos.const_mul p
        convert this using 1
        rw [← hωsq]
        field_simp

#print axioms pinned_aux_sine

/-- The eigenvalues of the pinned string. Take a real number λ. Call y a solution if y has a
slope y' at every point of the string 0 ≤ x ≤ 1 (one-sided at the ends), the slope y' has slope
-λ y there (so -y'' = λ y), and y is zero at both pins: y(0) = 0 and y(1) = 0. Then a solution
that is not zero everywhere on the string exists exactly when λ = n^2π^2 for some whole number
n = 1, 2, 3, .... -/
theorem pinned_string_eigenvalue_iff (lam : ℝ) :
    (∃ y y' : ℝ → ℝ,
      (∀ x ∈ Icc (0 : ℝ) 1,
        HasDerivWithinAt y (y' x) (Icc 0 1) x ∧ HasDerivWithinAt y' (-lam * y x) (Icc 0 1) x) ∧
      y 0 = 0 ∧ y 1 = 0 ∧ ∃ x ∈ Icc (0 : ℝ) 1, y x ≠ 0) ↔
    ∃ n : ℕ, 0 < n ∧ lam = (n * π) ^ 2 := by
  constructor
  · rintro ⟨y, y', hd, h0, h1, hne⟩
    obtain ⟨n, hn, hl, -⟩ := pinned_aux_sine lam y y' hd h0 h1 hne
    exact ⟨n, hn, hl⟩
  · rintro ⟨n, hn, rfl⟩
    refine ⟨fun x => sin (n * π * x), fun x => n * π * cos (n * π * x), ?_, by simp, ?_, ?_⟩
    · intro x _
      constructor
      · have := ((hasDerivAt_id' x).const_mul ((n : ℝ) * π)).sin
        convert this.hasDerivWithinAt using 1
        ring
      · have := (((hasDerivAt_id' x).const_mul ((n : ℝ) * π)).cos).const_mul ((n : ℝ) * π)
        convert this.hasDerivWithinAt using 1
        ring
    · simp only [mul_one]
      exact Real.sin_nat_mul_pi n
    · refine ⟨1 / (2 * n), ⟨by positivity, ?_⟩, ?_⟩
      · have : (1 : ℝ) ≤ n := by exact_mod_cast hn
        rw [div_le_one (by positivity)]; linarith
      · have hn' : (n : ℝ) ≠ 0 := by exact_mod_cast hn.ne'
        have : (n : ℝ) * π * (1 / (2 * n)) = π / 2 := by field_simp
        simp only [this, sin_pi_div_two]
        norm_num

/-- The eigenfunctions. If y solves -y'' = λ y on the string 0 ≤ x ≤ 1, is zero at both pins,
and is not zero everywhere on the string, then for some n = 1, 2, 3, ... the number λ is
n^2π^2 and y is a nonzero multiple of sin(nπx) at every point of the string: the n-th harmonic. -/
theorem pinned_string_eigenfunction_is_sine (lam : ℝ) (y y' : ℝ → ℝ)
    (hd : ∀ x ∈ Icc (0 : ℝ) 1,
      HasDerivWithinAt y (y' x) (Icc 0 1) x ∧ HasDerivWithinAt y' (-lam * y x) (Icc 0 1) x)
    (h0 : y 0 = 0) (h1 : y 1 = 0) (hne : ∃ x ∈ Icc (0 : ℝ) 1, y x ≠ 0) :
    ∃ n : ℕ, 0 < n ∧ lam = (n * π) ^ 2 ∧
      ∃ B : ℝ, B ≠ 0 ∧ ∀ x ∈ Icc (0 : ℝ) 1, y x = B * sin (n * π * x) := by
  exact pinned_aux_sine lam y y' hd h0 h1 hne

/-- The nodes. For n = 1, 2, 3, ..., the n-th mode sin(nπx) is zero at a point x strictly
inside the string exactly when x = k/n for a whole number k with 0 < k < n: n - 1 nodes,
evenly spaced. -/
theorem sine_mode_nodes (n : ℕ) (hn : 0 < n) (x : ℝ) (hx : x ∈ Ioo (0 : ℝ) 1) :
    sin (n * π * x) = 0 ↔ ∃ k : ℕ, 0 < k ∧ k < n ∧ x = k / n := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  constructor
  · intro h
    obtain ⟨k, hk⟩ := Real.sin_eq_zero_iff.mp h
    have hkx : (k : ℝ) = n * x := by
      have := pi_pos
      have : (k : ℝ) * π = (n * x) * π := by rw [hk]; ring
      exact mul_right_cancel₀ pi_pos.ne' this
    have hk0 : (0 : ℝ) < k := by rw [hkx]; exact mul_pos hn' hx.1
    have hkn : (k : ℝ) < n := by rw [hkx]; nlinarith [hx.2]
    have hk0' : 0 < k := by exact_mod_cast hk0
    refine ⟨k.toNat, by omega, ?_, ?_⟩
    · have : k < (n : ℤ) := by exact_mod_cast hkn
      omega
    · have hcast : ((k.toNat : ℕ) : ℝ) = (k : ℝ) := by
        have : ((k.toNat : ℤ) : ℝ) = (k : ℝ) := by rw [Int.toNat_of_nonneg hk0'.le]
        exact_mod_cast this
      rw [hcast, hkx]; field_simp
  · rintro ⟨k, -, -, rfl⟩
    have : (n : ℝ) * π * (k / n) = k * π := by field_simp
    rw [this]
    exact Real.sin_nat_mul_pi k

-- Notes on the 220 m/s string: c × nπ/(2π) = 220n/2 = 110n, so 110, 220 and 330 Hz.
example : (List.range' 1 3).map (fun n => 220 * n / 2) = [110, 220, 330] := by decide
-- The pitch formula c√λ/(2π) at λ = (3π)^2 gives 330 Hz exactly.
example : (220 : ℝ) * √((3 * π) ^ 2) / (2 * π) = 330 := by
  rw [Real.sqrt_sq (by positivity)]; field_simp; norm_num
-- Eigenvalues grow 1 : 4 : 9 while the notes grow 1 : 2 : 3.
example : (List.range' 1 3).map (fun n => n ^ 2) = [1, 4, 9] := by decide
-- The mistake "pitch in proportion to λ": 110 × n^2 gives 110, 440 and 990 Hz.
example : (List.range' 1 3).map (fun n => 110 * n ^ 2) = [110, 440, 990] := by decide
-- Nodes inside the string, n - 1 for n = 1, 2, 3: 0, 1, 2; for n = 3 they sit at 1/3 and 2/3.
example : (List.range' 1 3).map (fun n => n - 1) = [0, 1, 2] := by decide
example : (0 : ℚ) < 1 / 3 ∧ (1 : ℚ) / 3 < 2 / 3 ∧ (2 : ℚ) / 3 < 1 := by norm_num
-- The midpoint node lies at figure pixel 30 + 220 × 1/2 = 140.
example : (30 : ℚ) + 220 * (1 / 2) = 140 := by norm_num
-- Far end free: √λ = (n - 1/2)π gives notes 220(2n - 1)/4 = 55, 165, 275 Hz, ratio 1 : 3 : 5.
example : (List.range' 1 3).map (fun n => 220 * (2 * n - 1) / 4) = [55, 165, 275] := by decide
example : (List.range' 1 3).map (fun n => 2 * n - 1) = [1, 3, 5] := by decide

#print axioms pinned_string_eigenvalue_iff
#print axioms pinned_string_eigenfunction_is_sine
#print axioms sine_mode_nodes
