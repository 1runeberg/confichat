# Contributing to ConfiChat

Thank you for your interest in contributing to **ConfiChat**! We welcome contributions from everyone and are excited to see what you bring to the project. Below are the guidelines for contributing to this Flutter application.

## I. Getting Started

1. **Fork the Repository**
   - Start by forking the ConfiChat repository on GitHub. This creates your own copy of the project where you can make changes.

2. **Clone Your Fork**
   - Clone your forked repository to your local machine.
   ```bash
   git clone https://github.com/your-username/ConfiChat.git
   cd ConfiChat
   ```

3. **Set Upstream Remote**
   - Set the original repository as the upstream remote to easily sync changes.
   ```bash
   git remote add upstream https://github.com/original-owner/ConfiChat.git
   ```

4. **Create a New Branch**
   - Always create a new branch for your work to keep your changes organized and separate from the main codebase.
   ```bash
   git checkout -b your-feature-branch
   ```

## II. Adding a New Language/Localization

1. **Create a New Language File**
   - Create a new language file in the `confichat/assets/i18n` directory by
     copying the en.json file and rename it to the language code (e.g., fr.json for French). 
     Use language code (Set1) from ISO 639: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes


2. **Update the `languages.yaml` and add the language/local you wish to contribute.**
    Endonmyns can be found from ISO 639: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes and country codes from ISO 3166: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2


3. **Add the new language file to the `assets` section of the `pubspec.yaml` file**
   - Add the new language file to the `assets` section of the `pubspec.yaml` file.
   - 
   ```yaml
   assets:
     - assets/i18n/en.json
     - assets/i18n/fr.json
   ```
   

4. **Translate the Strings**
   - Translate the strings in the new language file to the desired language. Make sure to keep the same key names as the English file.
   

5. **Create a Pull Request**
   - Once you have translated the strings, create a pull request to add the new language to the project.

## III. Best Practices

- **Follow Flutter Best Practices**: Ensure your code follows Flutter's [best practices](https://flutter.dev/docs/development/ui/layout/best-practices).
- **Prioritize Privacy and Security**:
  - **Data Encryption**: Ensure that you maintain features on sensitive data, such as chat histories, is encrypted and stored locally.
  - **Secure API Calls**: Use HTTPS for all online API calls and handle API keys securely, avoiding hardcoding them in the codebase. Check out the LlmApi class.
  - **Minimal Data Retention**: Retain only the necessary data and implement clear data deletion mechanisms.
  - **User Permissions**: Request only the necessary permissions from users, and ensure these permissions are handled securely.
  - **Sensitive Data Handling**: Avoid logging sensitive information such as API keys, user credentials, or private conversations.
- **Focus on Memory and Resource Efficiency**: 
  - Use lazy initialization to avoid unnecessary memory usage.
  - Dispose of controllers and listeners properly to free up resources.
  - Prefer `const` constructors where possible to reduce widget rebuilds.
  - Avoid unnecessary object creation inside loops or frequently called methods.
  - Use efficient data structures like `List` or `Set` instead of less efficient ones.
- **Write Clear and Descriptive Commit Messages**: Provide clear and concise commit messages to describe your changes.
- **Keep Commits Small and Focused**: Break down large changes into smaller, focused commits for easier review.
- **Test Your Changes**: Make sure your changes don’t break any existing functionality. Write tests if applicable.

## IV. Submitting a Pull Request

1. **Push Your Changes**
   - Once you’re happy with your changes, push your branch to your forked repository.
   ```bash
   git push origin your-feature-branch
   ```

2. **Create a Pull Request**
   - Go to the original ConfiChat repository on GitHub and create a pull request from your branch. Describe your changes in detail and mention any related issues.

3. **CI Checks**
   - GitHub CI is enabled to automatically check pull requests. This includes tests and linting to ensure code quality. Please review any feedback from CI and make necessary adjustments.

4. **Code Review**
   - Your pull request will be reviewed by the maintainers. Be open to feedback and make any requested changes.

5. **Merge**
   - Once approved, your pull request will be merged into the main codebase.

## V. Keeping Your Fork Updated

To keep your fork up to date with the latest changes from the original repository:

```bash
git fetch upstream
git checkout main
git merge upstream/main
```

## VI. Need Help?

If you have any questions or need help, feel free to open an issue on GitHub or reach out to the community.

Happy coding! 🚀
