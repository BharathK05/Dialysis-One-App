//
//  AddDietWatchView.swift
//  DialysisOneWatch Watch App
//
//  Multi-step diet flow mirroring the iPhone app:
//  Step 1: Food input (scribble / dictation / recent)
//  Step 2: Loading (iPhone calls Gemini API)
//  Step 3: Nutrition review (calories, protein, etc.)
//  Step 4: Confirmation
//

import SwiftUI

// MARK: - Flow Step
private enum DietFlowStep {
    case input
    case loading
    case review
    case error
    case done
}

struct AddDietWatchView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager = WatchDataManager.shared
    
    @State private var step: DietFlowStep = .input
    @State private var foodName: String = ""
    @State private var selectedQuantity: Int = 100
    @State private var selectedMealType: String = "Lunch"
    @State private var confirmedFoodName: String = ""
    
    let mealTypes = ["Breakfast", "Lunch", "Dinner"]
    
    var body: some View {
        Group {
            switch step {
            case .input:
                inputStep
            case .loading:
                loadingStep
            case .review:
                reviewStep
            case .error:
                errorStep
            case .done:
                doneStep
            }
        }
        .navigationTitle(stepTitle)
        .onChange(of: dataManager.pendingNutritionResult) { result in
            if result != nil && step == .loading {
                confirmedFoodName = result?.foodName ?? foodName
                withAnimation(.easeInOut(duration: 0.3)) {
                    step = .review
                }
            }
        }
        .onChange(of: dataManager.nutritionLookupError) { error in
            if error != nil && step == .loading {
                withAnimation(.easeInOut(duration: 0.3)) {
                    step = .error
                }
            }
        }
    }
    
    private var stepTitle: String {
        switch step {
        case .input: return "Add Food"
        case .loading: return ""
        case .review: return ""
        case .error: return ""
        case .done: return ""
        }
    }
    
    // MARK: - Step 1: Food Input
    
    private var inputStep: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Food Name Input
                VStack(alignment: .leading, spacing: 4) {
                    Text("What did you eat?")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    TextField("Type or dictate…", text: $foodName)
                        .font(.system(size: 15, weight: .medium))
                }
                .padding(.horizontal, 4)
                
                // Recent suggestions
                if foodName.isEmpty && !dataManager.recentFoodNames.isEmpty {
                    VStack(spacing: 4) {
                        Text("Recent")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                        
                        ForEach(dataManager.recentFoodNames.prefix(4), id: \.self) { name in
                            Button(action: {
                                foodName = name
                                lookUpNutrition()
                            }) {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    Text(name)
                                        .font(.system(size: 13))
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else if !foodName.isEmpty {
                    // Filtered suggestions
                    let filtered = dataManager.recentFoodNames.filter {
                        $0.localizedCaseInsensitiveContains(foodName)
                    }.prefix(3)
                    
                    if !filtered.isEmpty {
                        VStack(spacing: 4) {
                            ForEach(Array(filtered), id: \.self) { name in
                                Button(action: {
                                    foodName = name
                                    lookUpNutrition()
                                }) {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                        Text(name)
                                            .font(.system(size: 13))
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 8)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                // Look Up button
                Button(action: lookUpNutrition) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkle.magnifyingglass")
                            .font(.system(size: 14))
                        Text("Look Up")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.3, green: 0.7, blue: 0.5),
                                Color(red: 0.2, green: 0.6, blue: 0.4)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(foodName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(foodName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1.0)
                .padding(.top, 6)
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Step 2: Loading
    
    private var loadingStep: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.3, green: 0.7, blue: 0.5)))
                .scaleEffect(1.3)
            
            Text("Looking up nutrition…")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(foodName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Step 3: Nutrition Review
    
    private var reviewStep: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Food name (from AI or user input)
                Text(confirmedFoodName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 2)
                
                // Nutrition card
                if let nutrition = dataManager.pendingNutritionResult {
                    nutritionCard(nutrition: nutrition)
                } else if let error = dataManager.nutritionLookupError {
                    // Error fallback
                    VStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Text("You can still add the food manually.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                }
                
                Divider()
                    .padding(.vertical, 2)
                
                // Quantity stepper
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quantity")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Button(action: {
                            if selectedQuantity > 50 { selectedQuantity -= 50 }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(selectedQuantity > 50 ? Color(red: 0.3, green: 0.7, blue: 0.5) : .gray)
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedQuantity <= 50)
                        
                        Spacer()
                        
                        Text("\(selectedQuantity)g")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            if selectedQuantity < 1000 { selectedQuantity += 50 }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(selectedQuantity < 1000 ? Color(red: 0.3, green: 0.7, blue: 0.5) : .gray)
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedQuantity >= 1000)
                    }
                    .padding(.vertical, 4)
                    
                    // Scaled calories preview
                    if let nutrition = dataManager.pendingNutritionResult {
                        let scaled = nutrition.scaled(by: selectedQuantity)
                        Text("\(scaled.calories) kcal for \(selectedQuantity)g")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(red: 0.3, green: 0.7, blue: 0.5))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.horizontal, 4)
                
                // Meal type picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Meal")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Picker("Meal", selection: $selectedMealType) {
                        ForEach(mealTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 44)
                }
                .padding(.horizontal, 4)
                
                // Add Food button
                Button(action: addFood) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Add Food")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.85, green: 0.55, blue: 0.15),
                                Color(red: 0.75, green: 0.45, blue: 0.10)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Nutrition Card
    
    @ViewBuilder
    private func nutritionCard(nutrition: WatchNutritionResult) -> some View {
        let scaled = nutrition.scaled(by: selectedQuantity)
        
        VStack(spacing: 8) {
            // Calories — prominent
            VStack(spacing: 2) {
                Text("Calories")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                Text("\(scaled.calories)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                Text("kcal")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.08))
            )
            
            // Nutrient rows
            HStack(spacing: 0) {
                nutrientDot(color: .yellow, label: "Protein", value: "\(Int(scaled.protein))g")
                Spacer()
                nutrientDot(color: .green, label: "K+", value: "\(scaled.potassium)mg")
                Spacer()
                nutrientDot(color: .orange, label: "Na+", value: "\(scaled.sodium)mg")
            }
            .padding(.horizontal, 2)
            
            // Source badge
            if let source = nutrition.source {
                HStack(spacing: 3) {
                    Image(systemName: source == "ai" ? "sparkles" : "checkmark.circle")
                        .font(.system(size: 8))
                    Text(source == "ai" ? "AI Estimate" : "Database")
                        .font(.system(size: 9))
                }
                .foregroundColor(.secondary)
            }
        }
    }
    
    private func nutrientDot(color: Color, label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
    }
    
    // MARK: - Error Step
    
    private var errorStep: some View {
        VStack(spacing: 14) {
            Spacer()
            
            Image(systemName: "iphone.slash")
                .font(.system(size: 36))
                .foregroundColor(.orange)
            
            Text("iPhone Not Reachable")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            
            Text(dataManager.nutritionLookupError ?? "Could not connect to iPhone to look up nutrition.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            
            Spacer()
            
            Button(action: {
                // Reset and go back to input
                dataManager.nutritionLookupError = nil
                dataManager.pendingNutritionResult = nil
                withAnimation(.easeInOut(duration: 0.3)) {
                    step = .input
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13))
                    Text("Try Again")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.15))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    // MARK: - Step 4: Done
    
    private var doneStep: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(red: 0.3, green: 0.7, blue: 0.5))
            
            Text("Added!")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text("\(confirmedFoodName)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let nutrition = dataManager.pendingNutritionResult {
                let scaled = nutrition.scaled(by: selectedQuantity)
                Text("\(selectedQuantity)g • \(scaled.calories) kcal")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .onAppear {
            // Auto-dismiss after 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }
    
    // MARK: - Actions
    
    private func lookUpNutrition() {
        let trimmed = foodName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        // Save to recent
        WatchDataManager.shared.addRecentFood(trimmed)
        
        // Transition to loading
        withAnimation(.easeInOut(duration: 0.3)) {
            step = .loading
        }
        
        // Request nutrition from iPhone
        WatchConnectivityManager.shared.requestNutritionLookup(foodName: trimmed)
        
        // Timeout: if no response in 15 seconds, show error
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            if step == .loading {
                dataManager.isLookingUpNutrition = false
                if dataManager.pendingNutritionResult == nil && dataManager.nutritionLookupError == nil {
                    dataManager.nutritionLookupError = "Request timed out. iPhone may not be reachable."
                }
                withAnimation {
                    step = .error
                }
            }
        }
    }
    
    private func addFood() {
        let name = confirmedFoodName.isEmpty ? foodName : confirmedFoodName
        
        // Calculate final scaled nutrition
        let calories: Int
        let protein: Double
        let potassium: Int
        let sodium: Int
        
        if let nutrition = dataManager.pendingNutritionResult {
            let scaled = nutrition.scaled(by: selectedQuantity)
            calories = scaled.calories
            protein = scaled.protein
            potassium = scaled.potassium
            sodium = scaled.sodium
        } else {
            // Fallback: rough estimate (2 cal/g)
            calories = selectedQuantity * 2
            protein = Double(selectedQuantity) * 0.05
            potassium = selectedQuantity * 2
            sodium = selectedQuantity * 2
        }
        
        // Send to iPhone with pre-computed nutrition
        WatchConnectivityManager.shared.sendAddDiet(
            foodName: name,
            quantity: selectedQuantity,
            mealType: selectedMealType,
            calories: calories,
            protein: protein,
            potassium: potassium,
            sodium: sodium
        )
        
        // Transition to done
        withAnimation(.easeInOut(duration: 0.3)) {
            step = .done
        }
        
        // Clean up
        dataManager.pendingNutritionResult = nil
        dataManager.nutritionLookupError = nil
    }
}
