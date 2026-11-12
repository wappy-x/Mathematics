-- The Cauchy-Euler equation: for x > 0 the trial y = x^r turns x^2 y'' + a x y' + b y = 0 into the quadratic r(r - 1) + a r + b = 0, and its real roots give every solution, x^r1 and x^r2 mixed, or (A + B ln x) x^r at a repeated root.
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Log.Deriv

open Real

lemma ce_const_of_hasDerivAt_zero (f : ℝ → ℝ) (hf : ∀ x > 0, HasDerivAt f 0 x) :
    ∀ x > 0, f x = f 1 := by
  intro x hx
  exact isOpen_Ioi.is_const_of_deriv_eq_zero isPreconnected_Ioi
    (fun z hz => (hf z hz).differentiableAt.differentiableWithinAt)
    (fun z hz => (hf z hz).deriv) hx (by norm_num : (1:ℝ) ∈ Set.Ioi (0:ℝ))

lemma ce_second (y f f' f'' : ℝ → ℝ) (hyf : ∀ x > 0, y x = f x)
    (hf : ∀ x > 0, HasDerivAt f (f' x) x) (hf' : ∀ x > 0, HasDerivAt f' (f'' x) x) :
    ∀ x > 0, deriv y x = f' x ∧ deriv (deriv y) x = f'' x := by
  have h1 : ∀ x > 0, deriv y x = f' x := by
    intro x hx
    have he : y =ᶠ[nhds x] f :=
      Filter.eventually_of_mem (Ioi_mem_nhds hx) (fun z hz => hyf z hz)
    rw [he.deriv_eq]; exact (hf x hx).deriv
  intro x hx
  refine ⟨h1 x hx, ?_⟩
  have he : deriv y =ᶠ[nhds x] f' :=
    Filter.eventually_of_mem (Ioi_mem_nhds hx) (fun z hz => h1 z hz)
  rw [he.deriv_eq]; exact (hf' x hx).deriv

lemma ce_rpow_hasDerivAt (r x : ℝ) (hx : 0 < x) :
    HasDerivAt (fun t : ℝ => t ^ r) (r * x ^ (r - 1)) x :=
  Real.hasDerivAt_rpow_const (Or.inl hx.ne')

lemma ce_rpow_sub_one (s x : ℝ) (hx : 0 < x) : x ^ s = x ^ (s - 1) * x := by
  rw [← Real.rpow_add_one hx.ne']; ring_nf

lemma ce_rpow_mul_neg (s x : ℝ) (hx : 0 < x) : x ^ s * x ^ (-s) = 1 := by
  rw [← Real.rpow_add hx]; simp

lemma ce_rpow_add (s t x : ℝ) (hx : 0 < x) : x ^ (s + t) = x ^ s * x ^ t :=
  Real.rpow_add hx s t

#print axioms ce_const_of_hasDerivAt_zero
#print axioms ce_second
#print axioms ce_rpow_hasDerivAt
#print axioms ce_rpow_sub_one
#print axioms ce_rpow_mul_neg
#print axioms ce_rpow_add

/-- Two different real roots: if r1 and r2 are different roots of the indicial equation
r(r - 1) + a r + b = 0, then a twice-differentiable function y solves
x^2 y'' + a x y' + b y = 0 for every x > 0 exactly when y = A x^r1 + B x^r2 on x > 0
for some constants A and B. -/
theorem cauchy_euler_distinct_roots (a b r₁ r₂ : ℝ) (hne : r₁ ≠ r₂)
    (h₁ : r₁ * (r₁ - 1) + a * r₁ + b = 0) (h₂ : r₂ * (r₂ - 1) + a * r₂ + b = 0)
    (y : ℝ → ℝ) (hy : ∀ x > 0, DifferentiableAt ℝ y x ∧ DifferentiableAt ℝ (deriv y) x) :
    (∀ x > 0, x ^ 2 * deriv (deriv y) x + a * x * deriv y x + b * y x = 0) ↔
      ∃ A B : ℝ, ∀ x > 0, y x = A * x ^ r₁ + B * x ^ r₂ := by
  have ha : a = 1 - r₁ - r₂ := by
    have : (r₁ - r₂) * (r₁ + r₂ - 1 + a) = 0 := by linear_combination h₁ - h₂
    rcases mul_eq_zero.1 this with h | h
    · exact absurd (sub_eq_zero.1 h) hne
    · linarith
  have hb : b = r₁ * r₂ := by subst ha; linear_combination h₁
  subst ha hb
  have hd : r₁ - r₂ ≠ 0 := sub_ne_zero.2 hne
  constructor
  · intro hode
    let w : ℝ → ℝ := fun x => x * deriv y x - r₂ * y x
    have hw' : ∀ x > 0, HasDerivAt w (deriv y x + x * deriv (deriv y) x - r₂ * deriv y x) x := by
      intro x hx
      have := ((hasDerivAt_id' x).mul (hy x hx).2.hasDerivAt).sub
        ((hy x hx).1.hasDerivAt.const_mul r₂)
      convert this using 1; ring
    let F : ℝ → ℝ := fun x => x ^ (-r₁) * w x
    have hF : ∀ x > 0, HasDerivAt F 0 x := by
      intro x hx
      have := (ce_rpow_hasDerivAt (-r₁) x hx).mul (hw' x hx)
      convert this using 1
      have e := ce_rpow_sub_one (-r₁) x hx
      rw [e]
      have := hode x hx
      linear_combination (-(x ^ (-r₁ - 1))) * this
    set C := F 1
    have hwC : ∀ x > 0, w x = C * x ^ r₁ := by
      intro x hx
      have h := ce_const_of_hasDerivAt_zero F hF x hx
      have e := ce_rpow_mul_neg r₁ x hx
      calc w x = (x ^ r₁ * x ^ (-r₁)) * w x := by rw [e, one_mul]
        _ = x ^ r₁ * F x := by ring
        _ = C * x ^ r₁ := by rw [h]; ring
    let G : ℝ → ℝ := fun x => x ^ (-r₂) * y x - C / (r₁ - r₂) * x ^ (r₁ - r₂)
    have hG : ∀ x > 0, HasDerivAt G 0 x := by
      intro x hx
      have := ((ce_rpow_hasDerivAt (-r₂) x hx).mul (hy x hx).1.hasDerivAt).sub
        ((ce_rpow_hasDerivAt (r₁ - r₂) x hx).const_mul (C / (r₁ - r₂)))
      convert this using 1
      have e1 := ce_rpow_sub_one (-r₂) x hx
      have e2 : x ^ (r₁ - r₂ - 1) = x ^ (-r₂ - 1) * x ^ r₁ := by
        rw [← ce_rpow_add _ _ _ hx]; ring_nf
      have hw := hwC x hx
      simp only [w] at hw
      rw [e1, e2]
      field_simp
      linear_combination (-(x ^ (-r₂ - 1))) * hw
    refine ⟨C / (r₁ - r₂), G 1, fun x hx => ?_⟩
    have h := ce_const_of_hasDerivAt_zero G hG x hx
    have e := ce_rpow_mul_neg r₂ x hx
    have e3 : x ^ r₁ = x ^ r₂ * x ^ (r₁ - r₂) := by rw [← ce_rpow_add _ _ _ hx]; ring_nf
    rw [← h, e3]
    simp only [G]
    linear_combination (-(y x)) * e
  · rintro ⟨A, B, hAB⟩ x hx
    obtain ⟨h1, h2⟩ := ce_second y (fun t => A * t ^ r₁ + B * t ^ r₂)
      (fun t => A * (r₁ * t ^ (r₁ - 1)) + B * (r₂ * t ^ (r₂ - 1)))
      (fun t => A * (r₁ * ((r₁ - 1) * t ^ (r₁ - 1 - 1))) + B * (r₂ * ((r₂ - 1) * t ^ (r₂ - 1 - 1))))
      hAB
      (fun z hz => ((ce_rpow_hasDerivAt r₁ z hz).const_mul A).add
        ((ce_rpow_hasDerivAt r₂ z hz).const_mul B))
      (fun z hz => (((ce_rpow_hasDerivAt (r₁ - 1) z hz).const_mul r₁).const_mul A).add
        (((ce_rpow_hasDerivAt (r₂ - 1) z hz).const_mul r₂).const_mul B)) x hx
    rw [h1, h2, hAB x hx]
    rw [ce_rpow_sub_one r₁ x hx, ce_rpow_sub_one (r₁ - 1) x hx,
      ce_rpow_sub_one r₂ x hx, ce_rpow_sub_one (r₂ - 1) x hx]
    ring

/-- A repeated root: if r is a root of r(r - 1) + a r + b = 0 and the root is repeated,
(a - 1)^2 = 4b, then a twice-differentiable function y solves x^2 y'' + a x y' + b y = 0 for
every x > 0 exactly when y = (A + B ln x) x^r on x > 0 for some constants A and B. -/
theorem cauchy_euler_repeated_root (a b r : ℝ) (hr : r * (r - 1) + a * r + b = 0)
    (hrep : (a - 1) ^ 2 = 4 * b)
    (y : ℝ → ℝ) (hy : ∀ x > 0, DifferentiableAt ℝ y x ∧ DifferentiableAt ℝ (deriv y) x) :
    (∀ x > 0, x ^ 2 * deriv (deriv y) x + a * x * deriv y x + b * y x = 0) ↔
      ∃ A B : ℝ, ∀ x > 0, y x = (A + B * Real.log x) * x ^ r := by
  have ha : a = 1 - 2 * r := by
    have : (2 * r + a - 1) ^ 2 = 0 := by linear_combination 4 * hr + hrep
    linarith [pow_eq_zero_iff (n := 2) (two_ne_zero) |>.1 this]
  have hb : b = r ^ 2 := by subst ha; linear_combination hr
  subst ha hb
  constructor
  · intro hode
    let w : ℝ → ℝ := fun x => x * deriv y x - r * y x
    have hw' : ∀ x > 0, HasDerivAt w (deriv y x + x * deriv (deriv y) x - r * deriv y x) x := by
      intro x hx
      have := ((hasDerivAt_id' x).mul (hy x hx).2.hasDerivAt).sub
        ((hy x hx).1.hasDerivAt.const_mul r)
      convert this using 1; ring
    let F : ℝ → ℝ := fun x => x ^ (-r) * w x
    have hF : ∀ x > 0, HasDerivAt F 0 x := by
      intro x hx
      have := (ce_rpow_hasDerivAt (-r) x hx).mul (hw' x hx)
      convert this using 1
      have e := ce_rpow_sub_one (-r) x hx
      rw [e]
      have := hode x hx
      linear_combination (-(x ^ (-r - 1))) * this
    set C := F 1
    have hwC : ∀ x > 0, w x = C * x ^ r := by
      intro x hx
      have h := ce_const_of_hasDerivAt_zero F hF x hx
      have e := ce_rpow_mul_neg r x hx
      calc w x = (x ^ r * x ^ (-r)) * w x := by rw [e, one_mul]
        _ = x ^ r * F x := by ring
        _ = C * x ^ r := by rw [h]; ring
    let G : ℝ → ℝ := fun x => x ^ (-r) * y x - C * Real.log x
    have hG : ∀ x > 0, HasDerivAt G 0 x := by
      intro x hx
      have := ((ce_rpow_hasDerivAt (-r) x hx).mul (hy x hx).1.hasDerivAt).sub
        ((Real.hasDerivAt_log hx.ne').const_mul C)
      convert this using 1
      have e1 := ce_rpow_sub_one (-r) x hx
      have e2 : x ^ (-r - 1) * x ^ r = x⁻¹ := by
        rw [← ce_rpow_add _ _ _ hx]; ring_nf; exact Real.rpow_neg_one x
      have hw := hwC x hx
      simp only [w] at hw
      rw [e1]
      linear_combination (-(x ^ (-r - 1))) * hw - C * e2
    refine ⟨G 1, C, fun x hx => ?_⟩
    have h := ce_const_of_hasDerivAt_zero G hG x hx
    have e := ce_rpow_mul_neg r x hx
    rw [← h]
    simp only [G]
    linear_combination (-(y x)) * e
  · rintro ⟨A, B, hAB⟩ x hx
    obtain ⟨h1, h2⟩ := ce_second y (fun t => (A + B * Real.log t) * t ^ r)
      (fun t => (B * t⁻¹) * t ^ r + (A + B * Real.log t) * (r * t ^ (r - 1)))
      (fun t => (B * (-(t ^ 2)⁻¹)) * t ^ r + (B * t⁻¹) * (r * t ^ (r - 1))
        + ((B * t⁻¹) * (r * t ^ (r - 1)) + (A + B * Real.log t) * (r * ((r - 1) * t ^ (r - 1 - 1)))))
      hAB
      (fun z hz => (((Real.hasDerivAt_log hz.ne').const_mul B).const_add A).mul
        (ce_rpow_hasDerivAt r z hz))
      (fun z hz => (((hasDerivAt_inv hz.ne').const_mul B).mul (ce_rpow_hasDerivAt r z hz)).add
        ((((Real.hasDerivAt_log hz.ne').const_mul B).const_add A).mul
          ((ce_rpow_hasDerivAt (r - 1) z hz).const_mul r))) x hx
    rw [h1, h2, hAB x hx]
    rw [ce_rpow_sub_one r x hx, ce_rpow_sub_one (r - 1) x hx]
    field_simp
    ring

/-- The trial power: for x > 0, putting y = x^r into x^2 y'' + a x y' + b y gives
(r(r - 1) + a r + b) x^r, the indicial polynomial times the same power. -/
theorem cauchy_euler_trial_power (a b r x : ℝ) (hx : 0 < x) :
    x ^ 2 * deriv (deriv (fun t : ℝ => t ^ r)) x + a * x * deriv (fun t : ℝ => t ^ r) x
        + b * x ^ r = (r * (r - 1) + a * r + b) * x ^ r := by
  obtain ⟨h1, h2⟩ := ce_second (fun t : ℝ => t ^ r) (fun t : ℝ => t ^ r)
    (fun t => r * t ^ (r - 1)) (fun t => r * ((r - 1) * t ^ (r - 1 - 1)))
    (fun _ _ => rfl) (fun z hz => ce_rpow_hasDerivAt r z hz)
    (fun z hz => (ce_rpow_hasDerivAt (r - 1) z hz).const_mul r) x hx
  rw [h1, h2]
  have e1 := ce_rpow_sub_one r x hx
  have e2 := ce_rpow_sub_one (r - 1) x hx
  rw [e1, e2]
  ring

-- The pipe, a = 1 and b = -1: the indicial polynomial r(r - 1) + r - 1 has roots 1 and -1.
example : (1 : ℝ) * (1 - 1) + 1 * 1 + (-1) = 0 := by norm_num
example : (-1 : ℝ) * (-1 - 1) + 1 * (-1) + (-1) = 0 := by norm_num

-- The repeated case, a = -1 and b = 1: r = 1 is a root and (a - 1)^2 = 4b.
example : (1 : ℝ) * (1 - 1) + (-1) * 1 + 1 = 0 := by norm_num
example : ((-1 : ℝ) - 1) ^ 2 = 4 * 1 := by norm_num

-- Lame's formula for the hoop stress at the bore, 20 (100^2 + 50^2) / (100^2 - 50^2) = 100/3 MPa.
example : (20 : ℚ) * (100 ^ 2 + 50 ^ 2) / (100 ^ 2 - 50 ^ 2) = 100 / 3 := by norm_num

-- The thin-wall mistake: pressure x mean radius / thickness = 20 x 75 / 50 = 30 MPa.
example : (20 : ℚ) * 75 / 50 = 30 := by norm_num

#print axioms cauchy_euler_distinct_roots
#print axioms cauchy_euler_repeated_root
#print axioms cauchy_euler_trial_power
