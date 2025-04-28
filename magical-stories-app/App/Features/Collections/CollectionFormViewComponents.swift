// MARK: - Collection Form Components

import SwiftUI

struct CollectionFormBackgroundView: View {
    @Binding var animateBackground: Bool

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(hex: "#7B61FF"), Color(hex: "#a78bfa")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .opacity(animateBackground ? 1.0 : 0.8)
        .animation(
            Animation.easeInOut(duration: 2).repeatForever(autoreverses: true),
            value: animateBackground
        )
    }
}

struct CollectionChildNameField: View {
    @Binding var childName: String

    var body: some View {
        FormFieldContainer {
            Text("Child's Name")
                .formSectionLabel(iconName: "person.fill")

            TextField("Enter child's name", text: $childName)
                .formFieldStyle()
        }
    }
}

struct AgeGroupField: View {
    @Binding var selectedAgeGroup: String
    let ageGroups: [String]

    var body: some View {
        FormFieldContainer {
            Text("Age Group")
                .formSectionLabel(iconName: "person.2.fill")

            Picker("Age Group", selection: $selectedAgeGroup) {
                ForEach(ageGroups, id: \.self) { group in
                    Text(group).tag(group)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.vertical, 8)
        }
    }
}

struct DevelopmentalFocusField: View {
    @Binding var selectedFocus: String
    let focuses: [String]

    var body: some View {
        FormFieldContainer {
            Text("Developmental Focus")
                .formSectionLabel(iconName: "lightbulb.fill")

            Picker("Focus", selection: $selectedFocus) {
                ForEach(focuses, id: \.self) { focus in
                    Text(focus).tag(focus)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .formFieldStyle()
        }
    }
}

struct InterestsField: View {
    @Binding var interests: String

    var body: some View {
        FormFieldContainer {
            Text("Interests")
                .formSectionLabel(iconName: "star.fill")

            TextEditor(text: $interests)
                .formFieldStyle()
                .frame(height: 100)
        }
    }
}

struct CharactersField: View {
    @Binding var favoriteCharacter: String
    let characterSuggestions: [String]

    var body: some View {
        FormFieldContainer {
            Text("Favorite Characters")
                .formSectionLabel(iconName: "heart.fill")

            TextField("Enter a character (dragon, princess...)", text: $favoriteCharacter)
                .formFieldStyle()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(characterSuggestions, id: \.self) { character in
                        Button {
                            favoriteCharacter = character
                        } label: {
                            Text(character)
                                .characterSuggestionStyle(
                                    isSelected: favoriteCharacter == character)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct CollectionLoadingOverlayView: View {
    var isLoading: Bool

    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
        }
    }
}