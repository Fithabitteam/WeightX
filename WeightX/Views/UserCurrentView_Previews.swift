struct UserCurrentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UserCurrentView(
                selectedGoal: "Weight Loss",
                userSex: "Male",
                motivations: ["Health", "Fitness"],
                height: 175.0
            )
        }
    }
} 