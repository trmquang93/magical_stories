import SwiftData
import SwiftUI

// MARK: - Collection Form Components

struct CollectionFormBackgroundView: View {
    @Binding var animateBackground: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .light {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#F3F7FF"),
                        Color(hex: "#FFF3F7"),
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .hueRotation(Angle(degrees: animateBackground ? 10 : 0))
                .animation(
                    Animation.easeInOut(duration: 6).repeatForever(autoreverses: true),
                    value: animateBackground
                )
            } else {
                Color(hex: "#121828")
            }
        }
        .onAppear { animateBackground = true }
    }
}

struct CollectionFormHeader: View {
    let title: String
    let subtitle: String
    @Environment(\.colorScheme) private var colorScheme
    @State private var titleOffset: CGFloat = 20
    @State private var subtitleOffset: CGFloat = 40
    @State private var opacity: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(
                    colorScheme == .light ? Color(hex: "#222B45") : Color(hex: "#f9fafb")
                )
                .offset(y: titleOffset)
                .opacity(opacity)

            Text(subtitle)
                .font(.system(size: 18))
                .foregroundColor(
                    colorScheme == .light ? Color(hex: "#6B7280") : Color(hex: "#d1d5db")
                )
                .offset(y: subtitleOffset)
                .opacity(opacity)
        }
        .padding(.vertical, UITheme.Spacing.md)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                titleOffset = 0
                opacity = 1
            }

            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                subtitleOffset = 0
            }
        }
    }
}

struct CollectionFormFieldContainer<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: UITheme.Spacing.sm) {
            content
        }
        .padding(UITheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: UITheme.CornerRadius.standard)
                .fill(colorScheme == .light ? .white : Color(hex: "#1F2937"))
                .shadow(
                    color: colorScheme == .light ? Color.black.opacity(0.05) : Color.clear,
                    radius: 8, x: 0, y: 4
                )
        )
        .padding(.horizontal, UITheme.Spacing.md)
    }
}

extension Text {
    func formSectionLabel(iconName: String) -> some View {
        HStack(spacing: UITheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#7B61FF").opacity(0.2),
                                Color(hex: "#FF617B").opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)

                Image(systemName: iconName)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#7B61FF"))
            }

            self
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#4A5568"))
        }
        .padding(.bottom, UITheme.Spacing.sm)
    }
}

extension View {
    func collectionFormFieldStyle() -> some View {
        self
            .padding(UITheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: UITheme.CornerRadius.standard)
                    .stroke(Color(hex: "#E2E8F0"), lineWidth: 1)
            )
    }
}

struct AgeGroupField: View {
    @Binding var selectedAgeGroup: AgeGroup
    let ageGroups: [AgeGroup]
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedScale: CGFloat = 0.95
    @State private var opacity: Double = 0

    var body: some View {
        CollectionFormFieldContainer {
            Text("Age Group")
                .formSectionLabel(iconName: "person.2.fill")

            Picker("Age Group", selection: $selectedAgeGroup) {
                ForEach(ageGroups, id: \.self) { group in
                    Text(group.rawValue).tag(group)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .scaleEffect(animatedScale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                animatedScale = 1.0
                opacity = 1
            }
        }
    }
}

struct DevelopmentalFocusField: View {
    @Binding var selectedFocus: DevelopmentalFocus
    let focuses: [DevelopmentalFocus]
    @State private var animatedScale: CGFloat = 0.95
    @State private var opacity: Double = 0

    var body: some View {
        CollectionFormFieldContainer {
            Text("Developmental Focus")
                .formSectionLabel(iconName: "lightbulb.fill")

            Menu {
                ForEach(focuses, id: \.self) { focus in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFocus = focus
                        }
                    }) {
                        HStack {
                            Text(focus.rawValue)
                            if focus == selectedFocus {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "#7B61FF"))
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedFocus.rawValue)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#7B61FF"))
                }
                .padding(UITheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: UITheme.CornerRadius.standard)
                        .stroke(Color(hex: "#E2E8F0"), lineWidth: 1)
                )
            }
            .scaleEffect(animatedScale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
                animatedScale = 1.0
                opacity = 1
            }
        }
    }
}

struct InterestsField: View {
    @Binding var interests: String
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedScale: CGFloat = 0.95
    @State private var opacity: Double = 0

    var body: some View {
        CollectionFormFieldContainer {
            Text("Interests")
                .formSectionLabel(iconName: "star.fill")

            ZStack(alignment: .topLeading) {
                if interests.isEmpty {
                    Text("What does the child enjoy? (e.g., dinosaurs, princesses, space)")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#A0AEC0"))
                        .padding(.horizontal, UITheme.Spacing.md)
                        .padding(.vertical, UITheme.Spacing.md)
                        .opacity(isFocused ? 0.5 : 1)
                }

                TextEditor(text: $interests)
                    .frame(minHeight: 120)
                    .padding(UITheme.Spacing.md)
                    .font(.system(size: 16))
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .overlay(
                RoundedRectangle(cornerRadius: UITheme.CornerRadius.standard)
                    .stroke(
                        isFocused
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#7B61FF"), Color(hex: "#FF617B")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            : AnyShapeStyle(Color(hex: "#E2E8F0")),
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .background(colorScheme == .light ? Color.white : Color(hex: "#1F2937"))
            .cornerRadius(UITheme.CornerRadius.standard)
            .scaleEffect(animatedScale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4)) {
                animatedScale = 1.0
                opacity = 1
            }
        }
    }
}

struct CharactersField: View {
    @Binding var characters: String
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedScale: CGFloat = 0.95
    @State private var opacity: Double = 0

    var body: some View {
        CollectionFormFieldContainer {
            Text("Characters")
                .formSectionLabel(iconName: "person.crop.circle")

            ZStack(alignment: .leading) {
                if characters.isEmpty {
                    Text("Optional: favorite characters (e.g., dragon, unicorn)")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#A0AEC0"))
                        .padding(.horizontal, UITheme.Spacing.md)
                        .opacity(isFocused ? 0.5 : 1)
                }

                TextField("", text: $characters)
                    .padding(UITheme.Spacing.md)
                    .font(.system(size: 16))
                    .focused($isFocused)
            }
            .overlay(
                RoundedRectangle(cornerRadius: UITheme.CornerRadius.standard)
                    .stroke(
                        isFocused
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#7B61FF"), Color(hex: "#FF617B")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            : AnyShapeStyle(Color(hex: "#E2E8F0")),
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .background(colorScheme == .light ? Color.white : Color(hex: "#1F2937"))
            .cornerRadius(UITheme.CornerRadius.standard)
            .scaleEffect(animatedScale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) {
                animatedScale = 1.0
                opacity = 1
            }
        }
    }
}

struct GenerateCollectionButton: View {
    let isGenerating: Bool
    let action: () -> Void
    @State private var animatedScale: CGFloat = 0.95
    @State private var opacity: Double = 0
    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                    action()
                }
            }
        }) {
            HStack {
                Spacer()

                if isGenerating {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.trailing, 8)

                    Text("Generate Collection")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()
            }
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#7B61FF"), Color(hex: "#FF617B")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(
                color: Color(hex: "#7B61FF").opacity(0.3),
                radius: 10, x: 0, y: 5
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isGenerating)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .scaleEffect(animatedScale)
        .opacity(opacity)
        .padding(.horizontal, UITheme.Spacing.md)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6)) {
                animatedScale = 1.0
                opacity = 1
            }
        }
    }
}

struct CollectionLoadingOverlayView: View {
    @Binding var isVisible: Bool
    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        if isVisible {
            ZStack {
                // Dimmed background
                Color.black.opacity(0.6)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)

                // Loading content
                VStack(spacing: 24) {
                    // Magic wand icon with rotating stars
                    ZStack {
                        // Pulse effect
                        Circle()
                            .fill(Color(hex: "#7B61FF").opacity(0.2))
                            .frame(width: 80, height: 80)
                            .scaleEffect(pulseScale)

                        // Main icon
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "#7B61FF"))

                        // Rotating stars
                        ForEach(0..<6) { i in
                            Circle()
                                .fill(Color(hex: "#FF617B"))
                                .frame(width: 6, height: 6)
                                .offset(x: 50)
                                .rotationEffect(.degrees(Double(i) * 60 + rotation))
                        }
                    }
                    .frame(width: 100, height: 100)

                    VStack(spacing: 8) {
                        Text("Creating your collection...")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        Text("Weaving together the perfect growth stories")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(hex: "#121828"))
                        .opacity(0.9)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#7B61FF"), Color(hex: "#FF617B")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: Color(hex: "#7B61FF").opacity(0.3), radius: 20, x: 0, y: 10)
                .padding(32)
            }
            .transition(.opacity)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true))
                {
                    pulseScale = 1.3
                }

                withAnimation(Animation.linear(duration: 10).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
    struct CollectionFormViewComponents_Previews: PreviewProvider {
        static var previews: some View {
            VStack {
                CollectionFormHeader(
                    title: "Create Collection", subtitle: "Personalize your growth path")
                // Update preview calls to pass AgeGroup and DevelopmentalFocus enums
                AgeGroupField(selectedAgeGroup: .constant(.preschool), ageGroups: AgeGroup.allCases)
                DevelopmentalFocusField(
                    selectedFocus: .constant(.creativity), focuses: DevelopmentalFocus.allCases)
                InterestsField(interests: .constant("Drawing, Reading"))
                CharactersField(characters: .constant("Dragon, Princess"))
                LanguageField(selectedLanguage: .constant("en"), languages: [])
                GenerateCollectionButton(isGenerating: false, action: {})
                CollectionLoadingOverlayView(isVisible: .constant(true))
            }
            .padding()
            .previewLayout(.sizeThatFits)
        }
    }
#endif
