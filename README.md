# Youtube MySubs Application
### Example of usage of NavigationFlow as an application backbone

Application is using Google API to authorize app using Oauth2 to access youtube online services for Youtube subscription list/details (google account needs to be provided to add as a tester)
- List of subscriptions is using progressive loading (page of 10 items) incremetally loaded when reaching the list end
- NavigatioFlow defines all destinations as a view with actions submitted back to flow (returns new navigation action as a result)
- Views are separated from logic, easy to mock data/write tests (possible implementation of viewModel using StateObject, EnvironmentObject, IOC on developer)
- RefreshToken is stored securely inside Keychain
- Some View modifiers are provided to ilustrate usage of general styling
- Custom Gesture - based modifier is provided to simulate selection/highlithing of items
