-- Schrodinger's equation: in a box with walls that cannot be crossed, the time-independent equation has a nonzero solution exactly at the energies n^2 pi^2 hbar^2 / (2 m L^2), and the sine shapes sqrt(2/L) sin(n pi x / L) have total chance one and are perpendicular.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib

open Real Set

/-- The card's standing shape: the n-th wave in a box of width `L`,
`φ_n(x) = √(2/L) · sin(nπx/L)`. -/
noncomputable def boxShape (L : ℝ) (n : ℕ) (x : ℝ) : ℝ :=
  Real.sqrt (2 / L) * Real.sin (n * π * x / L)

lemma box_integral_cos_mul {c : ℝ} (hc : c ≠ 0) (a b : ℝ) :
    ∫ x in a..b, Real.cos (c * x) = (Real.sin (c * b) - Real.sin (c * a)) / c := by
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (f := fun x => Real.sin (c * x) / c)]
  · ring
  · intro x _
    have h := (((hasDerivAt_id x).const_mul c).sin).div_const c
    simp only [id_eq, mul_one] at h
    convert h using 1
    field_simp
  · exact (by fun_prop : Continuous fun x => Real.cos (c * x)).intervalIntegrable _ _

#print axioms box_integral_cos_mul

lemma box_const_of_hasDerivAt_zero {L : ℝ} {g : ℝ → ℂ}
    (h : ∀ x ∈ Ioo 0 L, HasDerivAt g 0 x) : ∃ A, ∀ x ∈ Ioo 0 L, g x = A :=
  isOpen_Ioo.exists_is_const_of_deriv_eq_zero isPreconnected_Ioo
    (fun x hx => (h x hx).differentiableAt.differentiableWithinAt)
    (fun x hx => (h x hx).deriv)

#print axioms box_const_of_hasDerivAt_zero

lemma box_hasDerivAt_ofReal (x : ℝ) : HasDerivAt (fun y : ℝ => (y : ℂ)) 1 x := by
  simpa using (hasDerivAt_id x).ofReal_comp

#print axioms box_hasDerivAt_ofReal

lemma box_hasDerivAt_cexp (c : ℂ) (x : ℝ) :
    HasDerivAt (fun y : ℝ => Complex.exp (c * y)) (Complex.exp (c * x) * c) x := by
  simpa using ((box_hasDerivAt_ofReal x).const_mul c).cexp

#print axioms box_hasDerivAt_cexp

lemma box_eq_on_Icc {L : ℝ} (hL : 0 < L) {φ f : ℝ → ℂ} (hφ : ContinuousOn φ (Icc 0 L))
    (hf : Continuous f) (h : ∀ x ∈ Ioo 0 L, φ x = f x) : φ 0 = f 0 ∧ φ L = f L := by
  have := Set.EqOn.of_subset_closure h hφ hf.continuousOn Ioo_subset_Icc_self
    (closure_Ioo hL.ne).superset
  exact ⟨this (left_mem_Icc.2 hL.le), this (right_mem_Icc.2 hL.le)⟩

#print axioms box_eq_on_Icc

lemma box_middle_third_general {L : ℝ} (hL : 0 < L) {n : ℕ} (hn : 1 ≤ n) :
    (∫ x in L / 3..2 * L / 3, boxShape L n x ^ 2) =
      1 / 3 - (Real.sin (4 * n * π / 3) - Real.sin (2 * n * π / 3)) / (2 * n * π) := by
  set a : ℝ := n * π / L with ha
  have h2 : √(2 / L) * √(2 / L) = 2 / L := Real.mul_self_sqrt (by positivity)
  have hpt : ∀ x, boxShape L n x ^ 2 = 1 / L * (1 - Real.cos ((2 * a) * x)) := by
    intro x
    simp only [boxShape]
    rw [show (2 * a) * x = 2 * (n * π * x / L) by rw [ha]; ring, Real.cos_two_mul,
      Real.cos_sq']
    linear_combination (Real.sin (n * π * x / L)) ^ 2 * h2
  have hn' : (1 : ℝ) ≤ n := by exact_mod_cast hn
  have ha0 : 2 * a ≠ 0 := by
    have : 0 < 2 * a := by rw [ha]; positivity
    exact this.ne'
  simp_rw [hpt]
  rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_sub
    intervalIntegrable_const
    ((by fun_prop : Continuous fun x => Real.cos ((2 * a) * x)).intervalIntegrable _ _),
    box_integral_cos_mul ha0]
  rw [show 2 * a * (2 * L / 3) = 4 * n * π / 3 by rw [ha]; field_simp; ring,
    show 2 * a * (L / 3) = 2 * n * π / 3 by rw [ha]; field_simp]
  simp only [intervalIntegral.integral_const, smul_eq_mul, mul_one]
  rw [ha]
  field_simp
  ring

#print axioms box_middle_third_general

/-- Energy levels of a particle in a box. Take a particle of mass `m > 0` in a box of
width `L > 0` with walls it cannot cross, and `ħ > 0`. Inside the box `V = 0`, so the
time-independent Schrodinger equation is `-(ħ²/2m) φ'' = E φ`, and the walls force
`φ(0) = 0` and `φ(L) = 0`. A wavefunction `φ` that is not zero everywhere in the box
solves this exactly when `E = n²π²ħ²/(2mL²)` for some whole number `n ≥ 1`. -/
theorem particle_in_box_energy_levels {ħ m L E : ℝ} (hħ : 0 < ħ) (hm : 0 < m)
    (hL : 0 < L) :
    (∃ φ : ℝ → ℂ, ContinuousOn φ (Icc 0 L) ∧
        DifferentiableOn ℝ φ (Ioo 0 L) ∧
        DifferentiableOn ℝ (deriv φ) (Ioo 0 L) ∧
        (∀ x ∈ Ioo 0 L,
          ((-(ħ ^ 2 / (2 * m)) : ℝ) : ℂ) * deriv (deriv φ) x = (E : ℂ) * φ x) ∧
        φ 0 = 0 ∧ φ L = 0 ∧
        ∃ x ∈ Ioo 0 L, φ x ≠ 0) ↔
      ∃ n : ℕ, 1 ≤ n ∧ E = (n : ℝ) ^ 2 * π ^ 2 * ħ ^ 2 / (2 * m * L ^ 2) := by
  have hħc : (ħ : ℂ) ≠ 0 := by exact_mod_cast hħ.ne'
  have hmc : (m : ℂ) ≠ 0 := by exact_mod_cast hm.ne'
  have hLc : (L : ℂ) ≠ 0 := by exact_mod_cast hL.ne'
  constructor
  · rintro ⟨φ, hcont, hd1, hd2, hode, h0, hφL, x0, hx0, hne⟩
    obtain ⟨c, hc⟩ := IsAlgClosed.exists_pow_nat_eq
      (((-(2 * m * E / ħ ^ 2)) : ℝ) : ℂ) (n := 2) (by norm_num)
    have hode' : ∀ x ∈ Ioo 0 L, deriv (deriv φ) x = c ^ 2 * φ x := by
      intro x hx
      have h := hode x hx
      have ha : ((-(ħ ^ 2 / (2 * m)) : ℝ) : ℂ) ≠ 0 := by
        have : 0 < ħ ^ 2 / (2 * m) := by positivity
        have : -(ħ ^ 2 / (2 * m)) ≠ 0 := by linarith
        exact_mod_cast this
      apply mul_left_cancel₀ ha
      rw [h, hc, ← mul_assoc]
      congr 1
      push_cast
      field_simp
    have hφd : ∀ x ∈ Ioo 0 L, HasDerivAt φ (deriv φ x) x := fun x hx =>
      ((hd1 x hx).differentiableAt (isOpen_Ioo.mem_nhds hx)).hasDerivAt
    have hφdd : ∀ x ∈ Ioo 0 L, HasDerivAt (deriv φ) (deriv (deriv φ) x) x := fun x hx =>
      ((hd2 x hx).differentiableAt (isOpen_Ioo.mem_nhds hx)).hasDerivAt
    obtain ⟨A, hA⟩ := box_const_of_hasDerivAt_zero (L := L)
      (g := fun x : ℝ => (deriv φ x - c * φ x) * Complex.exp (c * x)) (by
        intro x hx
        have := ((hφdd x hx).sub ((hφd x hx).const_mul c)).mul (box_hasDerivAt_cexp c x)
        convert this using 1
        rw [hode' x hx]; simp only [Pi.sub_apply]; ring)
    obtain ⟨B, hB⟩ := box_const_of_hasDerivAt_zero (L := L)
      (g := fun x : ℝ => (deriv φ x + c * φ x) * Complex.exp (-c * x)) (by
        intro x hx
        have := ((hφdd x hx).add ((hφd x hx).const_mul c)).mul (box_hasDerivAt_cexp (-c) x)
        convert this using 1
        rw [hode' x hx]; simp only [Pi.add_apply]; ring)
    by_cases hc0 : c = 0
    · subst hc0
      have hd : ∀ x ∈ Ioo 0 L, deriv φ x = A := by
        intro x hx
        have := hA x hx
        simpa using this
      obtain ⟨C, hC⟩ := box_const_of_hasDerivAt_zero (L := L)
        (g := fun x : ℝ => φ x - A * x) (by
          intro x hx
          have := (hφd x hx).sub ((box_hasDerivAt_ofReal x).const_mul A)
          convert this using 1
          rw [hd x hx]; ring)
      obtain ⟨e0, eL⟩ := box_eq_on_Icc hL hcont (f := fun x : ℝ => A * x + C) (by fun_prop)
        (by
          intro x hx
          have := hC x hx
          beta_reduce at this
          linear_combination this)
      rw [h0] at e0
      rw [hφL] at eL
      have hC0 : C = 0 := by simpa using e0.symm
      have hA0 : A = 0 := by
        rw [hC0, add_zero] at eL
        rcases mul_eq_zero.mp eL.symm with h | h
        · exact h
        · exact absurd h hLc
      exfalso
      apply hne
      have := hC x0 hx0
      beta_reduce at this
      rw [hA0, hC0] at this
      simpa using this
    · have hform : ∀ x ∈ Ioo 0 L, φ x =
          (B * Complex.exp (c * x) - A * Complex.exp (-c * x)) / (2 * c) := by
        intro x hx
        have h1 := hA x hx
        have h2 := hB x hx
        beta_reduce at h1 h2
        have hexp : Complex.exp (c * x) * Complex.exp (-c * x) = 1 := by
          rw [← Complex.exp_add]; simp
        rw [eq_div_iff (mul_ne_zero two_ne_zero hc0)]
        linear_combination Complex.exp (c * x) * h2 - Complex.exp (-c * x) * h1
          - 2 * c * φ x * hexp
      obtain ⟨e0, eL⟩ := box_eq_on_Icc hL hcont
        (f := fun x : ℝ => (B * Complex.exp (c * x) - A * Complex.exp (-c * x)) / (2 * c))
        (by fun_prop) hform
      rw [h0] at e0
      rw [hφL] at eL
      have hBA : B = A := by
        rw [eq_comm, div_eq_zero_iff] at e0
        rcases e0 with h | h
        · simpa [sub_eq_zero] using h
        · exact absurd h (mul_ne_zero two_ne_zero hc0)
      have hA0 : A ≠ 0 := by
        intro hA0
        apply hne
        rw [hform x0 hx0, hBA, hA0]
        simp
      have hEL : Complex.exp (c * L) = Complex.exp (-c * L) := by
        rw [eq_comm, div_eq_zero_iff] at eL
        rcases eL with h | h
        · have h' : A * (Complex.exp (c * L) - Complex.exp (-c * L)) = 0 := by
            rw [← h, hBA]; ring
          rcases mul_eq_zero.mp h' with h'' | h''
          · exact absurd h'' hA0
          · exact sub_eq_zero.mp h''
        · exact absurd h (mul_ne_zero two_ne_zero hc0)
      have h2 : Complex.exp (2 * c * L) = 1 := by
        rw [show 2 * c * L = c * L - -c * L by ring, Complex.exp_sub, hEL,
          div_self (Complex.exp_ne_zero _)]
      obtain ⟨n, hn⟩ := Complex.exp_eq_one_iff.mp h2
      have hc' : c = n * π * Complex.I / L := by
        rw [eq_div_iff hLc]
        linear_combination hn / 2
      have hn0 : n ≠ 0 := by
        rintro rfl
        apply hc0
        rw [hc']
        simp
      have key : (2 * m * E / ħ ^ 2 : ℝ) = (n : ℝ) ^ 2 * π ^ 2 / L ^ 2 := by
        have h3 : ((-(2 * m * E / ħ ^ 2) : ℝ) : ℂ) = ((-((n : ℝ) ^ 2 * π ^ 2 / L ^ 2)) : ℝ) := by
          rw [← hc, hc']
          simp only [div_pow, mul_pow, Complex.I_sq]
          push_cast
          ring
        have := Complex.ofReal_injective h3
        linarith
      refine ⟨n.natAbs, Int.natAbs_pos.mpr hn0, ?_⟩
      have hnn : ((n.natAbs : ℕ) : ℝ) ^ 2 = (n : ℝ) ^ 2 := by
        rw [Nat.cast_natAbs, Int.cast_abs, sq_abs]
      rw [hnn]
      field_simp at key ⊢
      linarith
  · rintro ⟨n, hn, rfl⟩
    set k : ℝ := n * π / L with hk
    have hn' : (1 : ℝ) ≤ n := by exact_mod_cast hn
    have hd1 : ∀ x : ℝ, HasDerivAt (fun x : ℝ => ((Real.sin (k * x) : ℝ) : ℂ))
        ((k * Real.cos (k * x) : ℝ) : ℂ) x := by
      intro x
      have h := (((hasDerivAt_id x).const_mul k).sin).ofReal_comp
      simp only [id_eq, mul_one] at h
      convert h using 2
      ring
    have hd2 : ∀ x : ℝ, HasDerivAt (fun x : ℝ => ((k * Real.cos (k * x) : ℝ) : ℂ))
        ((-(k ^ 2 * Real.sin (k * x)) : ℝ) : ℂ) x := by
      intro x
      have h := ((((hasDerivAt_id x).const_mul k).cos).const_mul k).ofReal_comp
      simp only [id_eq, mul_one] at h
      convert h using 2
      ring
    have hderiv : deriv (fun x : ℝ => ((Real.sin (k * x) : ℝ) : ℂ))
        = fun x : ℝ => ((k * Real.cos (k * x) : ℝ) : ℂ) := funext fun x => (hd1 x).deriv
    refine ⟨fun x : ℝ => ((Real.sin (k * x) : ℝ) : ℂ), by fun_prop,
      fun x _ => (hd1 x).differentiableAt.differentiableWithinAt, ?_, ?_, by simp, ?_, ?_⟩
    · rw [hderiv]
      exact fun x _ => (hd2 x).differentiableAt.differentiableWithinAt
    · intro x _
      rw [hderiv, (hd2 x).deriv, ← Complex.ofReal_mul, ← Complex.ofReal_mul]
      congr 1
      rw [hk]
      field_simp
    · simp only
      rw [show k * L = (n : ℝ) * π by rw [hk]; field_simp, Real.sin_nat_mul_pi]
      simp
    · refine ⟨L / (2 * n), ⟨by positivity, ?_⟩, ?_⟩
      · rw [div_lt_iff₀ (by positivity)]
        nlinarith
      · simp only
        rw [show k * (L / (2 * n)) = π / 2 by rw [hk]; field_simp, Real.sin_pi_div_two]
        simp


/-- The normaliser `√(2/L)` makes the total chance one, and different levels are
perpendicular: for levels `j, k ≥ 1`, `∫₀ᴸ φ_j φ_k dx` is `1` when `j = k` and `0`
otherwise. -/
theorem box_shapes_orthonormal {L : ℝ} (hL : 0 < L) {j k : ℕ} (hj : 1 ≤ j)
    (hk : 1 ≤ k) :
    ∫ x in (0 : ℝ)..L, boxShape L j x * boxShape L k x = if j = k then 1 else 0 := by
  set a : ℝ := j * π / L with ha
  set b : ℝ := k * π / L with hb
  have h2 : √(2 / L) * √(2 / L) = 2 / L := Real.mul_self_sqrt (by positivity)
  have hpt : ∀ x, boxShape L j x * boxShape L k x
      = 1 / L * (Real.cos ((a - b) * x) - Real.cos ((a + b) * x)) := by
    intro x
    simp only [boxShape]
    rw [show (a - b) * x = j * π * x / L - k * π * x / L by rw [ha, hb]; ring,
      show (a + b) * x = j * π * x / L + k * π * x / L by rw [ha, hb]; ring,
      Real.cos_sub, Real.cos_add]
    linear_combination (Real.sin (j * π * x / L) * Real.sin (k * π * x / L)) * h2
  simp_rw [hpt]
  rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_sub
    ((by fun_prop : Continuous fun x => Real.cos ((a - b) * x)).intervalIntegrable _ _)
    ((by fun_prop : Continuous fun x => Real.cos ((a + b) * x)).intervalIntegrable _ _)]
  have hapb : a + b ≠ 0 := by
    have : 0 < a + b := by
      rw [ha, hb]
      have : (1:ℝ) ≤ j := by exact_mod_cast hj
      positivity
    exact this.ne'
  have hs2 : Real.sin ((a + b) * L) = 0 := by
    rw [show (a + b) * L = ((j + k : ℕ) : ℝ) * π by rw [ha, hb]; push_cast; field_simp]
    exact Real.sin_nat_mul_pi _
  rw [box_integral_cos_mul hapb, hs2]
  split_ifs with hjk
  · rw [show a - b = 0 by rw [ha, hb, hjk]; ring]
    simp
    field_simp
  · have hamb : a - b ≠ 0 := by
      intro h
      apply hjk
      have : (j : ℝ) = k := by
        have h' : a = b := sub_eq_zero.mp h
        rw [ha, hb] at h'
        field_simp at h'
        exact h'
      exact_mod_cast this
    have hs1 : Real.sin ((a - b) * L) = 0 := by
      rw [show (a - b) * L = (((j : ℤ) - k : ℤ) : ℝ) * π by rw [ha, hb]; push_cast; field_simp]
      exact Real.sin_int_mul_pi _
    rw [box_integral_cos_mul hamb, hs1]
    simp

/-- The chance of finding the particle in the middle third of the box is
`1/3 + √3/(2π)` in level 1 and `1/3 - √3/(4π)` in level 2. -/
theorem box_middle_third_chance {L : ℝ} (hL : 0 < L) :
    (∫ x in L / 3..2 * L / 3, boxShape L 1 x ^ 2) = 1 / 3 + Real.sqrt 3 / (2 * π) ∧
    (∫ x in L / 3..2 * L / 3, boxShape L 2 x ^ 2) = 1 / 3 - Real.sqrt 3 / (4 * π) := by
  have s1 : Real.sin (2 * π / 3) = √3 / 2 := by
    rw [show 2 * π / 3 = π - π / 3 by ring, Real.sin_pi_sub, Real.sin_pi_div_three]
  have s2 : Real.sin (4 * π / 3) = -(√3 / 2) := by
    rw [show 4 * π / 3 = π / 3 + π by ring, Real.sin_add_pi, Real.sin_pi_div_three]
  have s3 : Real.sin (8 * π / 3) = √3 / 2 := by
    rw [show 8 * π / 3 = 2 * π / 3 + 2 * π by ring, Real.sin_add_two_pi, s1]
  have hπ : π ≠ 0 := Real.pi_ne_zero
  constructor
  · rw [box_middle_third_general hL le_rfl]
    push_cast
    rw [show 4 * (1 : ℝ) * π / 3 = 4 * π / 3 by ring, show 2 * (1 : ℝ) * π / 3 = 2 * π / 3 by ring,
      s1, s2]
    field_simp
    ring
  · rw [box_middle_third_general hL (by norm_num)]
    push_cast
    rw [show 4 * (2 : ℝ) * π / 3 = 8 * π / 3 by ring, show 2 * (2 : ℝ) * π / 3 = 4 * π / 3 by ring,
      s3, s2]
    field_simp
    ring

-- The electron's levels climb as n²: 1 : 4 : 9 : 16 : 25.
example : (List.range 5).map (fun n => (n + 1) ^ 2) = [1, 4, 9, 16, 25] := by decide

-- The gaps between neighbouring levels go 3 : 5 : 7, each next odd number.
example : (2 ^ 2 - 1 ^ 2, 3 ^ 2 - 2 ^ 2, 4 ^ 2 - 3 ^ 2) = (3, 5, 7) := by decide

-- The string's notes climb as n: 110, 220, 330, 440, 550 Hz.
example : (List.range 5).map (fun n => (n + 1) * 110) = [110, 220, 330, 440, 550] := by
  decide

#print axioms particle_in_box_energy_levels
#print axioms box_shapes_orthonormal
#print axioms box_middle_third_chance
