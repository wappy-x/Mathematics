-- Torsion and yield: for a point carrying a bending stress σ and a shear stress τ, the Tresca equivalent stress √(σ² + 4τ²) lies between 1 and 2/√3 times the von Mises equivalent stress √(σ² + 3τ²), and both come from the principal stresses.
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Order.Monotone.Basic

/-- The von Mises equivalent stress of a point with bending stress `σ` and shear stress `τ`. -/
noncomputable def vonMises (σ τ : ℝ) : ℝ := Real.sqrt (σ ^ 2 + 3 * τ ^ 2)

/-- The Tresca equivalent stress of a point with bending stress `σ` and shear stress `τ`. -/
noncomputable def tresca (σ τ : ℝ) : ℝ := Real.sqrt (σ ^ 2 + 4 * τ ^ 2)

/-- Under bending plus twist, the Tresca equivalent stress is at least the von Mises equivalent
stress and at most 2/√3 (about 1.1547) times it, for every bending stress σ and shear stress τ. -/
theorem tresca_between_one_and_two_div_sqrt_three_vonMises (σ τ : ℝ) :
    vonMises σ τ ≤ tresca σ τ ∧ tresca σ τ ≤ 2 / Real.sqrt 3 * vonMises σ τ := by
  have h3 : (0:ℝ) < Real.sqrt 3 := Real.sqrt_pos.mpr (by norm_num)
  have h3sq : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  have hb : 0 ≤ σ ^ 2 + 3 * τ ^ 2 := by positivity
  refine ⟨Real.sqrt_le_sqrt (by nlinarith [sq_nonneg τ]), ?_⟩
  unfold tresca vonMises
  rw [Real.sqrt_le_left (by positivity), mul_pow, div_pow, Real.sq_sqrt hb, h3sq]
  rw [div_mul_eq_mul_div, le_div_iff₀ (by norm_num)]
  nlinarith [sq_nonneg σ]

/-- Step 7 in the card's terms: when the bending stress σ is not zero, writing k = τ/σ, the ratio of
Tresca to von Mises is √((1 + 4k²)/(1 + 3k²)); it is at least 1 and never reaches 2/√3; and as a
function of k it grows as k grows from 0. -/
theorem tresca_div_vonMises_eq_and_bounds (σ τ : ℝ) (hσ : σ ≠ 0) :
    tresca σ τ / vonMises σ τ
        = Real.sqrt ((1 + 4 * (τ / σ) ^ 2) / (1 + 3 * (τ / σ) ^ 2)) ∧
      1 ≤ tresca σ τ / vonMises σ τ ∧
      tresca σ τ / vonMises σ τ < 2 / Real.sqrt 3 ∧
      StrictMonoOn (fun k : ℝ => Real.sqrt ((1 + 4 * k ^ 2) / (1 + 3 * k ^ 2))) (Set.Ici 0) := by
  have hσ2 : 0 < σ ^ 2 := by positivity
  have hb : 0 < σ ^ 2 + 3 * τ ^ 2 := by positivity
  have ha : 0 < σ ^ 2 + 4 * τ ^ 2 := by positivity
  have hv : 0 < vonMises σ τ := Real.sqrt_pos.mpr hb
  have h3 : (0:ℝ) < Real.sqrt 3 := Real.sqrt_pos.mpr (by norm_num)
  have hboth := tresca_between_one_and_two_div_sqrt_three_vonMises σ τ
  refine ⟨?_, ?_, ?_, ?_⟩
  · unfold tresca vonMises
    rw [← Real.sqrt_div' _ hb.le]
    congr 1
    field_simp
  · rw [le_div_iff₀ hv, one_mul]
    exact hboth.1
  · rw [div_lt_iff₀ hv]
    have h3sq : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
    have hlt : tresca σ τ * Real.sqrt 3 < 2 * vonMises σ τ := by
      unfold tresca vonMises
      rw [← Real.sqrt_mul ha.le, show (2:ℝ) = Real.sqrt 4 by
        rw [show (4:ℝ) = 2 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)],
        ← Real.sqrt_mul (by norm_num)]
      apply Real.sqrt_lt_sqrt (by positivity)
      nlinarith
    rw [div_mul_eq_mul_div, lt_div_iff₀ h3]
    linarith
  · intro a ha b hb hab
    simp only [Set.mem_Ici] at ha hb
    apply Real.sqrt_lt_sqrt (by positivity)
    rw [div_lt_div_iff₀ (by positivity) (by positivity)]
    have : a ^ 2 < b ^ 2 := by nlinarith
    nlinarith

/-- Steps 4 to 6: the surface cube's principal stresses are σ₁,₃ = σ/2 ± √((σ/2)² + τ²) and σ₂ = 0.
The free face's zero lies between the other two; the gap σ₁ − σ₃ is the Tresca stress
√(σ² + 4τ²); and the principal-stress form of von Mises,
√(½[(σ₁ − σ₂)² + (σ₂ − σ₃)² + (σ₃ − σ₁)²]), equals √(σ² + 3τ²). -/
theorem principal_stresses_give_tresca_and_vonMises (σ τ : ℝ) :
    let σ₁ := σ / 2 + Real.sqrt ((σ / 2) ^ 2 + τ ^ 2)
    let σ₂ : ℝ := 0
    let σ₃ := σ / 2 - Real.sqrt ((σ / 2) ^ 2 + τ ^ 2)
    σ₃ ≤ σ₂ ∧ σ₂ ≤ σ₁ ∧
      σ₁ - σ₃ = tresca σ τ ∧
      Real.sqrt ((1 / 2) * ((σ₁ - σ₂) ^ 2 + (σ₂ - σ₃) ^ 2 + (σ₃ - σ₁) ^ 2)) = vonMises σ τ := by
  intro σ₁ σ₂ σ₃
  set s := Real.sqrt ((σ / 2) ^ 2 + τ ^ 2) with hsdef
  have hs0 : 0 ≤ s := Real.sqrt_nonneg _
  have hs2 : s ^ 2 = (σ / 2) ^ 2 + τ ^ 2 := Real.sq_sqrt (by positivity)
  have h1 : σ₁ = σ / 2 + s := rfl
  have h2 : σ₂ = 0 := rfl
  have h3 : σ₃ = σ / 2 - s := rfl
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [h3, h2]; nlinarith [sq_nonneg τ]
  · rw [h1, h2]; nlinarith [sq_nonneg τ]
  · rw [h1, h3]
    unfold tresca
    rw [show σ ^ 2 + 4 * τ ^ 2 = (2 * s) ^ 2 by nlinarith, Real.sqrt_sq (by positivity)]
    ring
  · rw [h1, h2, h3]
    unfold vonMises
    congr 1
    nlinarith

#print axioms tresca_between_one_and_two_div_sqrt_three_vonMises
#print axioms tresca_div_vonMises_eq_and_bounds
#print axioms principal_stresses_give_tresca_and_vonMises
