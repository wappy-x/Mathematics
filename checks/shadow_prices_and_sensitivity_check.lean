-- Shadow prices: at a best corner of a linear program with exactly as many tight limits as products, moving one limit inside its range changes the best profit by that limit's shadow price times the move.
import Mathlib
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Data.Real.Basic
import Mathlib.Order.Bounds.Basic
import Mathlib.Tactic.NormNum

open Matrix


variable {m n : ℕ}

/-- A plan `x` fits the limits `b`: no product count is negative, and the plan uses at most
`b k` of each limit `k`, where `A k j` is how much of limit `k` one batch of product `j` uses. -/
def Fits (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (x : Fin n → ℝ) : Prop :=
  0 ≤ x ∧ A *ᵥ x ≤ b

/-- Every profit `c ⬝ᵥ x` that some plan fitting the limits `b` earns. -/
def profits (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ) : Set ℝ :=
  (fun x => c ⬝ᵥ x) '' {x | Fits A b x}

/-- The corner where the tight limits `σ 0, …, σ (n-1)` all hold as equations:
the plan solving `A_σ x = b_σ`. -/
noncomputable def corner (A : Matrix (Fin m) (Fin n) ℝ) (σ : Fin n → Fin m) (b : Fin m → ℝ) :
    Fin n → ℝ :=
  (A.submatrix σ id)⁻¹ *ᵥ (b ∘ σ)

/-- The shadow prices: on the tight limits they solve `A_σᵀ y_σ = c` (each product's margin equals
the value of the limits it uses), and every limit with slack gets price zero. -/
noncomputable def shadowPrices (A : Matrix (Fin m) (Fin n) ℝ) (σ : Fin n → Fin m) (c : Fin n → ℝ) :
    Fin m → ℝ :=
  Function.extend σ (((A.submatrix σ id)ᵀ)⁻¹ *ᵥ c) 0

/-- Limit `i` moved to the value `s` (every other limit held fixed) is inside its range:
the corner made by the same tight limits still fits, so no product count has gone negative
and no limit with slack has been overrun. -/
def InRange (A : Matrix (Fin m) (Fin n) ℝ) (σ : Fin n → Fin m) (b : Fin m → ℝ) (i : Fin m)
    (s : ℝ) : Prop :=
  Fits A (Function.update b i s) (corner A σ (Function.update b i s))

theorem extend_dotProduct_eq (σ : Fin n → Fin m) (hσ : Function.Injective σ) (z : Fin n → ℝ)
    (w : Fin m → ℝ) : Function.extend σ z 0 ⬝ᵥ w = z ⬝ᵥ (w ∘ σ) := by
  have h : ∀ k, Function.extend σ z 0 k * w k =
      Function.extend σ (fun l => z l * w (σ l)) 0 k := by
    intro k
    by_cases hk : ∃ l, σ l = k
    · obtain ⟨l, rfl⟩ := hk
      simp [hσ.extend_apply]
    · simp [Function.extend_apply' _ _ _ hk]
  simp only [dotProduct, h]
  exact Finset.sum_extend_zero_of_injective _ hσ (by simp)

theorem corner_profit_aux (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (c : Fin n → ℝ) (σ : Fin n → Fin m) (hσ : Function.Injective σ)
    (_hA : IsUnit (A.submatrix σ id).det) :
    c ⬝ᵥ corner A σ b = shadowPrices A σ c ⬝ᵥ b := by
  rw [shadowPrices, extend_dotProduct_eq σ hσ, corner, dotProduct_mulVec, ← mulVec_transpose,
    transpose_nonsing_inv]

theorem prices_certify_aux (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ)
    (y : Fin m → ℝ) (hy : 0 ≤ y) (hcover : c ≤ Aᵀ *ᵥ y) (x : Fin n → ℝ) (hx : Fits A b x) :
    c ⬝ᵥ x ≤ y ⬝ᵥ b := by
  calc c ⬝ᵥ x ≤ (Aᵀ *ᵥ y) ⬝ᵥ x := dotProduct_le_dotProduct_of_nonneg_right hcover hx.1
    _ = y ⬝ᵥ (A *ᵥ x) := by rw [mulVec_transpose, dotProduct_mulVec]
    _ ≤ y ⬝ᵥ b := dotProduct_le_dotProduct_of_nonneg_left hx.2 hy

theorem shadowPrices_cover (A : Matrix (Fin m) (Fin n) ℝ) (c : Fin n → ℝ) (σ : Fin n → Fin m)
    (hσ : Function.Injective σ) (hA : IsUnit (A.submatrix σ id).det) :
    Aᵀ *ᵥ shadowPrices A σ c = c := by
  ext j
  rw [mulVec_transpose]
  change shadowPrices A σ c ⬝ᵥ (fun k => A k j) = c j
  rw [shadowPrices, extend_dotProduct_eq σ hσ]
  change ((((A.submatrix σ id)ᵀ)⁻¹ *ᵥ c) ᵥ* (A.submatrix σ id)) j = c j
  rw [← mulVec_transpose, mulVec_mulVec, mul_nonsing_inv _ (by rwa [det_transpose]),
    one_mulVec]

theorem corner_add_smul (A : Matrix (Fin m) (Fin n) ℝ) (σ : Fin n → Fin m) (b e : Fin m → ℝ)
    (t : ℝ) : corner A σ (b + t • e) = corner A σ b + t • corner A σ e := by
  unfold corner
  rw [show (b + t • e) ∘ σ = b ∘ σ + t • (e ∘ σ) from rfl, mulVec_add, mulVec_smul]

theorem mulVec_corner_tight (A : Matrix (Fin m) (Fin n) ℝ) (σ : Fin n → Fin m)
    (hA : IsUnit (A.submatrix σ id).det) (b : Fin m → ℝ) (l : Fin n) :
    (A *ᵥ corner A σ b) (σ l) = b (σ l) := by
  change (A.submatrix σ id *ᵥ corner A σ b) l = b (σ l)
  rw [corner, mulVec_mulVec, mul_nonsing_inv _ hA, one_mulVec]
  rfl

theorem shadowPrices_nonneg (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (c : Fin n → ℝ) (σ : Fin n → Fin m) (hσ : Function.Injective σ)
    (hA : IsUnit (A.submatrix σ id).det)
    (hmade : ∀ j, 0 < corner A σ b j)
    (hslack : ∀ k, k ∉ Set.range σ → (A *ᵥ corner A σ b) k < b k)
    (hbest : IsGreatest (profits A b c) (c ⬝ᵥ corner A σ b)) :
    0 ≤ shadowPrices A σ c := by
  intro k
  by_cases hk : ∃ j, σ j = k
  swap
  · simp [shadowPrices, Function.extend_apply' _ _ _ hk]
  obtain ⟨j, rfl⟩ := hk
  by_contra hneg
  rw [not_le, Pi.zero_apply] at hneg
  set e : Fin m → ℝ := Pi.single (σ j) (-1) with he
  set d := corner A σ e
  set x0 := corner A σ b
  have hcont : ∀ (u v : ℝ), Filter.Tendsto (fun t : ℝ => u + t * v) (nhds 0) (nhds u) := by
    intro u v
    have hc : Continuous fun t : ℝ => u + t * v := by fun_prop
    simpa using hc.tendsto 0
  have h1 : ∀ᶠ t in nhdsWithin (0 : ℝ) (Set.Ioi 0), ∀ l, 0 < x0 l + t * d l := by
    apply Filter.eventually_all.2
    intro l
    exact nhdsWithin_le_nhds ((hcont _ _).eventually_const_lt (hmade l))
  have h2 : ∀ᶠ t in nhdsWithin (0 : ℝ) (Set.Ioi 0), ∀ k, k ∉ Set.range σ →
      (A *ᵥ x0) k + t * (A *ᵥ d) k < b k := by
    apply Filter.eventually_all.2
    intro k
    by_cases hk : k ∈ Set.range σ
    · exact Filter.Eventually.of_forall fun _ h => absurd hk h
    · exact Filter.Eventually.mono
        (nhdsWithin_le_nhds ((hcont _ _).eventually_lt_const (hslack k hk))) fun _ h _ => h
  obtain ⟨t, ⟨ht1, ht2⟩, ht⟩ := ((h1.and h2).and eventually_mem_nhdsWithin).exists
  have ht0 : (0 : ℝ) < t := ht
  have hx : corner A σ (b + t • e) = x0 + t • d := corner_add_smul A σ b e t
  have hfit : Fits A b (corner A σ (b + t • e)) := by
    constructor
    · intro l
      rw [hx]
      simpa using (ht1 l).le
    · intro k
      by_cases hk : k ∈ Set.range σ
      · obtain ⟨l, rfl⟩ := hk
        rw [mulVec_corner_tight A σ hA]
        have : e (σ l) ≤ 0 := by
          rw [he]
          by_cases hl : σ l = σ j
          · rw [hl]; simp
          · simp [hl]
        simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
        nlinarith
      · rw [hx, mulVec_add, mulVec_smul]
        simpa using (ht2 k hk).le
  have hle := hbest.2 ⟨_, hfit, rfl⟩
  simp only at hle
  rw [corner_profit_aux A _ c σ hσ hA,
    corner_profit_aux A _ c σ hσ hA, dotProduct_add, dotProduct_smul, he,
    dotProduct_single] at hle
  simp only [smul_eq_mul] at hle
  nlinarith

theorem dotProduct_update (y b : Fin m → ℝ) (i : Fin m) (s : ℝ) :
    y ⬝ᵥ Function.update b i s = y ⬝ᵥ b + y i * (s - b i) := by
  have : Function.update b i s = b + Pi.single i (s - b i) := by
    funext k
    by_cases hk : k = i
    · subst hk; simp
    · simp [hk]
  rw [this, dotProduct_add, dotProduct_single]

/-- The card's main claim. Take a linear program "maximise `c ⬝ᵥ x` subject to `A x ≤ b`,
`x ≥ 0`" with real (fractional) quantities. Suppose its best plan is the corner where the
limits `σ` are tight, and that corner has exactly as many tight limits as products: those `n`
limits are tight, every product is made, and every other limit has slack. Move one limit `i`
to a new value `s`, holding the others fixed, staying inside its range. Then the best profit
is the old best profit plus the shadow price of limit `i` times the move `s - b i`. -/
theorem best_profit_moves_by_shadow_price (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (c : Fin n → ℝ) (σ : Fin n → Fin m) (hσ : Function.Injective σ)
    (hA : IsUnit (A.submatrix σ id).det)
    (hmade : ∀ j, 0 < corner A σ b j)
    (hslack : ∀ k, k ∉ Set.range σ → (A *ᵥ corner A σ b) k < b k)
    (hbest : IsGreatest (profits A b c) (c ⬝ᵥ corner A σ b))
    (i : Fin m) (s : ℝ) (hs : InRange A σ b i s) :
    IsGreatest (profits A (Function.update b i s) c)
      (c ⬝ᵥ corner A σ b + shadowPrices A σ c i * (s - b i)) := by
  have hy := shadowPrices_nonneg A b c σ hσ hA hmade hslack hbest
  have hcov := shadowPrices_cover A c σ hσ hA
  rw [corner_profit_aux A b c σ hσ hA, ← dotProduct_update]
  constructor
  · exact ⟨_, hs, corner_profit_aux A _ c σ hσ hA⟩
  · rintro p ⟨x, hx, rfl⟩
    exact prices_certify_aux A _ c _ hy hcov.ge x hx

/-- Step 2: at the corner made by the tight limits, the profit equals the limits times
their shadow prices, `c ⬝ᵥ x = y ⬝ᵥ b` (for the bakery, 60 × 9 + 600 × 1.20 + 30 × 0 = 1,260). -/
theorem corner_profit_eq_limits_times_prices (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (c : Fin n → ℝ) (σ : Fin n → Fin m) (hσ : Function.Injective σ)
    (hA : IsUnit (A.submatrix σ id).det) :
    c ⬝ᵥ corner A σ b = shadowPrices A σ c ⬝ᵥ b := by
  exact corner_profit_aux A b c σ hσ hA

/-- Step 3: prices that are all zero or more and cover every product's margin are a
certificate. No plan that fits the limits earns more than the limits times the prices. -/
theorem prices_certify_best (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ)
    (y : Fin m → ℝ) (hy : 0 ≤ y) (hcover : c ≤ Aᵀ *ᵥ y) (x : Fin n → ℝ) (hx : Fits A b x) :
    c ⬝ᵥ x ≤ y ⬝ᵥ b := by
  exact prices_certify_aux A b c y hy hcover x hx


-- The bakery: 15 sponge and 30 loaf batches use all 60 oven hours and all 600 kg of flour.
example : 2 * 15 + 1 * 30 = 60 ∧ 10 * 15 + 15 * 30 = 600 := by decide

-- Van loads: 0.6 × 15 + 0.6 × 30 = 27 of 30, so 3 loads spare.
example : (3 / 5 : ℚ) * 15 + 3 / 5 * 30 = 27 ∧ (30 : ℚ) - 27 = 3 := by norm_num

-- The best profit: 30 × 15 + 27 × 30 = 1,260.
example : 30 * 15 + 27 * 30 = 1260 := by decide

-- The price equations hold at £9.00 an oven hour and £1.20 a kilogram of flour.
example : (2 : ℚ) * 9 + 10 * (6 / 5) = 30 ∧ (1 : ℚ) * 9 + 15 * (6 / 5) = 27 := by norm_num

-- Profit equals limits times prices: 60 × 9 + 600 × 1.20 + 30 × 0 = 1,260.
example : (60 : ℚ) * 9 + 600 * (6 / 5) + 30 * 0 = 1260 := by norm_num

-- Oven range: one more hour moves sponge by +0.75 and loaf by -0.50. Sponge reaches 0 at
-- 20 hours fewer (40 h); the 3 spare van loads run out at 20 hours more (80 h).
example : (2 : ℚ) * (3 / 4) + 1 * (-1 / 2) = 1 ∧ (10 : ℚ) * (3 / 4) + 15 * (-1 / 2) = 0 ∧
    (15 : ℚ) + 3 / 4 * (-20) = 0 ∧ (3 / 5 : ℚ) * ((15 + 3 / 4 * 20) + (30 - 1 / 2 * 20)) = 30 := by
  norm_num

-- Flour range: one more kg moves sponge by -0.05 and loaf by +0.10. Loaf reaches 0 at
-- 300 kg fewer (300 kg); the vans fill at 100 kg more (700 kg).
example : (2 : ℚ) * (-1 / 20) + 1 * (1 / 10) = 0 ∧ (10 : ℚ) * (-1 / 20) + 15 * (1 / 10) = 1 ∧
    (30 : ℚ) + 1 / 10 * (-300) = 0 ∧
    (3 / 5 : ℚ) * ((15 - 1 / 20 * 100) + (30 + 1 / 10 * 100)) = 30 := by
  norm_num

-- Margin range for sponge: at £54 the flour price is 0 (oven £27), at £18 the oven price is 0
-- (flour £1.80); loaf's £27 margin is still covered exactly at both ends.
example : (2 : ℚ) * 27 + 10 * 0 = 54 ∧ (1 : ℚ) * 27 + 15 * 0 = 27 ∧
    (2 : ℚ) * 0 + 10 * (9 / 5) = 18 ∧ (1 : ℚ) * 0 + 15 * (9 / 5) = 27 := by
  norm_num

-- What breaks: 200 extra kg at £1.20 predicts 1,500, but the re-solved plan (10, 40) earns 1,380.
example : (1260 : ℚ) + 200 * (6 / 5) = 1500 ∧ 30 * 10 + 27 * 40 = 1380 := by norm_num

-- Both changes together: the prices predict 1,560; the re-solved plan (30, 20) earns 1,440,
-- and after paying 20 × 5 for overtime and 100 × 0.80 for flour the net is 0.
example : (1260 : ℚ) + 20 * 9 + 100 * (6 / 5) = 1560 ∧ (30 : ℚ) * 30 + 27 * 20 = 1440 ∧
    (1440 : ℚ) - 1260 - 20 * 5 - 100 * (4 / 5) = 0 := by norm_num

-- Overtime nets 20 × (9 - 5) = 80; extra flour nets 100 × (1.20 - 0.80) = 40.
example : (20 : ℚ) * (9 - 5) = 80 ∧ (100 : ℚ) * (6 / 5 - 4 / 5) = 40 := by norm_num

-- Averages mislead: £1,260 / 600 kg = £2.10 a kg predicts +210 for 100 kg; the true gain is
-- 100 × 1.20 = 120. A van load's average is £1,260 / 30 = £42.
example : (1260 : ℚ) / 600 = 21 / 10 ∧ (100 : ℚ) * (21 / 10) = 210 ∧ (100 : ℚ) * (6 / 5) = 120 ∧
    (1260 : ℚ) / 30 = 42 := by norm_num

-- The most to pay for one more kilogram: 0.50 + 1.20 = 1.70.
example : (1 / 2 : ℚ) + 6 / 5 = 17 / 10 := by norm_num

-- The oven-hour chart: 1,080 at 40 h (loaf only), 1,440 at 80 h, 1,500 at 100 h (sponge only).
example : 27 * 40 = 1080 ∧ 30 * 30 + 27 * 20 = 1440 ∧ 30 * 50 = 1500 := by decide

#print axioms best_profit_moves_by_shadow_price
#print axioms corner_profit_eq_limits_times_prices
#print axioms prices_certify_best
#print axioms extend_dotProduct_eq
#print axioms corner_profit_aux
#print axioms prices_certify_aux
#print axioms shadowPrices_cover
#print axioms corner_add_smul
#print axioms mulVec_corner_tight
#print axioms shadowPrices_nonneg
#print axioms dotProduct_update
